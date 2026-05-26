import AVFoundation
import UIKit
import CoreImage
import CoreGraphics
import Vision

struct EyeContactAnalysisResult {
    /// DSE 使用的 key（center / left / right / lookAway / noFace）
    let label: String
    /// 雙眼中心在畫面寬度上的相對位置（0–100），對齊參考碼 `gazeDirection`
    let gazeValue: Double
}

/// 眼神分析：沿用 completedeyecontact.swift 的 Vision 流程（不含 UI 繪製）
final class EyeContactAnalyzer {
    static let defaultMinProcessInterval: TimeInterval = 0.35
    static let defaultVerticalScaleFactor: CGFloat = 1.75
    
    private let queue = DispatchQueue(label: "com.dse.eyeContactAnalyzer", qos: .userInitiated)
    private var isRunning = false
    private var lastProcessedAt = Date.distantPast
    private var minProcessInterval: TimeInterval
    
    /// 可選：手動指定座標系寬高（對應參考碼 `preview.bounds`）。為 `nil` 時改用每幀 `CIImage.extent`。
    var analysisFrameSizeOverride: CGSize?
    /// 僅在手動 override 時，對應參考碼 `preview.height * 1.75`；自動模式建議為 1.0
    var verticalScaleFactor: CGFloat = 1.0
    
    var discussionElapsedProvider: (() -> TimeInterval)?
    
    /// 每次判定眼神方向（已 map 為 DSE key）
    var onGazeDetected: ((EyeContactAnalysisResult) -> Void)?
    /// 判定為 look away 時，附帶討論經過秒數
    var onLookAway: ((Int) -> Void)?
    /// 偵測不到臉
    var onNoFace: (() -> Void)?
    
    private let faceDetection = VNDetectFaceRectanglesRequest()
    private let faceLandmarks = VNDetectFaceLandmarksRequest()
    private let faceDetectionRequest = VNSequenceRequestHandler()
    private let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    
    private var detectedFaceObservations: [VNFaceObservation] = []
    private var leftEyeCoordinates: CGPoint?
    private var rightEyeCoordinates: CGPoint?
    
    init(minProcessInterval: TimeInterval = EyeContactAnalyzer.defaultMinProcessInterval) {
        self.minProcessInterval = minProcessInterval
    }
    
    func start() {
        queue.async {
            self.isRunning = true
            self.lastProcessedAt = .distantPast
            self.detectedFaceObservations.removeAll()
            self.leftEyeCoordinates = nil
            self.rightEyeCoordinates = nil
        }
    }
    
    func stop() {
        queue.async {
            self.isRunning = false
            self.detectedFaceObservations.removeAll()
            self.leftEyeCoordinates = nil
            self.rightEyeCoordinates = nil
        }
    }
    
    // MARK: - 接入
    
    func ingest(ciImage: CIImage) {
        queue.async {
            guard self.isRunning, self.shouldProcessNow() else { return }
            self.detectFace(on: ciImage)
        }
    }
    
    func ingest(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        ingest(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
    }
    
    func ingest(image: UIImage) {
        guard let ciImage = CIImage(image: image) else { return }
        ingest(ciImage: ciImage)
    }
    
    // MARK: - Vision pipeline（對齊參考碼 detectFace → detectLandmarks → determineGazeDirection）
    
    private func detectFace(on image: CIImage) {
        do {
            try faceDetectionRequest.perform([faceDetection], on: image)
        } catch {
            print("[EyeContactAnalyzer] face detection failed: \(error.localizedDescription)")
            return
        }
        
        guard let results = faceDetection.results as? [VNFaceObservation] else { return }
        
        if results.isEmpty {
            noFaceDetected()
            return
        }
        
        faceLandmarks.inputFaceObservations = results
        detectedFaceObservations = results
        detectLandmarks(on: image)
    }
    
    private func detectLandmarks(on image: CIImage) {
        do {
            try faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        } catch {
            print("[EyeContactAnalyzer] landmarks failed: \(error.localizedDescription)")
            return
        }
        
        guard let landmarksResults = faceLandmarks.results as? [VNFaceObservation] else { return }
        
        let frameSize = analysisFrameSizeOverride ?? Self.frameSize(from: image)
        let verticalScale = analysisFrameSizeOverride == nil ? 1.0 : verticalScaleFactor
        
        for observation in landmarksResults {
            guard let faceObservation = detectedFaceObservations.first else { continue }
            
            let faceBoundingBox = Self.scaledBoundingBox(
                faceObservation.boundingBox,
                frameSize: frameSize,
                verticalScaleFactor: verticalScale
            )
            
            guard let leftEye = observation.landmarks?.leftEye,
                  let rightEye = observation.landmarks?.rightEye else { continue }
            
            leftEyeCoordinates = getEyeCoordinates(landmark: leftEye, boundingBox: faceBoundingBox)
            rightEyeCoordinates = getEyeCoordinates(landmark: rightEye, boundingBox: faceBoundingBox)
            determineGazeDirection(screenWidth: frameSize.width)
        }
    }
    
    /// 對齊參考碼 `getEyeCoordinates`
    private func getEyeCoordinates(landmark: VNFaceLandmarkRegion2D, boundingBox: CGRect) -> CGPoint? {
        let points = landmark.normalizedPoints
        guard let firstPoint = points.first else { return nil }
        
        let pointX = firstPoint.x * boundingBox.width + boundingBox.origin.x
        let pointY = firstPoint.y * boundingBox.height + boundingBox.origin.y
        return CGPoint(x: pointX, y: pointY)
    }
    
    /// 對齊參考碼 `determineGazeDirection`（現行閾值版本）
    private func determineGazeDirection(screenWidth: CGFloat) {
        guard screenWidth > 0,
              let leftEye = leftEyeCoordinates,
              let rightEye = rightEyeCoordinates else { return }
        
        let eyeCenterX = (leftEye.x + rightEye.x) / 2.0
        let normalizedPosition = (eyeCenterX / screenWidth) * 100
        let gazeDirection = min(max(Double(normalizedPosition), 0), 100)
        
        let rawLabel: String
        if gazeDirection < 45 {
            rawLabel = "left"
        } else if gazeDirection >= 45, gazeDirection <= 55 {
            rawLabel = "center"
        } else if gazeDirection > 55, gazeDirection <= 65 {
            rawLabel = "right"
        } else {
            rawLabel = "lookaway"
        }
        
        let dseLabel = Self.mapToDSELabel(rawLabel) ?? DSEEyeContactLabel.center.rawValue
        let result = EyeContactAnalysisResult(label: dseLabel, gazeValue: gazeDirection)
        
        DispatchQueue.main.async {
            self.onGazeDetected?(result)
            if rawLabel == "lookaway" {
                let second = Int(self.discussionElapsedProvider?() ?? 0)
                self.onLookAway?(max(0, second))
            }
        }
    }
    
    // MARK: - Helpers
    
    private func noFaceDetected() {
        let label = DSEEyeContactLabel.noFace.rawValue
        let result = EyeContactAnalysisResult(label: label, gazeValue: 0)
        DispatchQueue.main.async {
            self.onGazeDetected?(result)
            self.onNoFace?()
        }
    }
    
    private func shouldProcessNow() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedAt) >= minProcessInterval else { return false }
        lastProcessedAt = now
        return true
    }
    
    /// 參考碼：boundingBox.scaled(to: CGSize(width: scaledWidth, height: scaledHeight * 1.75))
    static func scaledBoundingBox(
        _ normalizedBox: CGRect,
        frameSize: CGSize,
        verticalScaleFactor: CGFloat
    ) -> CGRect {
        let scaledSize = CGSize(
            width: frameSize.width,
            height: frameSize.height * verticalScaleFactor
        )
        return visionNormalizedRectToPixels(normalizedBox, in: scaledSize)
    }
    
    /// Vision 正規化座標（原點左下）→ 像素座標（原點左上）
    static func visionNormalizedRectToPixels(_ rect: CGRect, in size: CGSize) -> CGRect {
        let width = rect.width * size.width
        let height = rect.height * size.height
        let x = rect.minX * size.width
        let y = (1 - rect.maxY) * size.height
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    static func mapToDSELabel(_ rawLabel: String) -> String? {
        DSEEyeContactLabel.key(from: rawLabel)
    }
    
    /// 由當前影像 buffer 取得分析座標系（與相機輸出解析度一致，例如 720×1280）
    static func frameSize(from image: CIImage) -> CGSize {
        let extent = image.extent
        return CGSize(width: max(1, abs(extent.width)), height: max(1, abs(extent.height)))
    }
}

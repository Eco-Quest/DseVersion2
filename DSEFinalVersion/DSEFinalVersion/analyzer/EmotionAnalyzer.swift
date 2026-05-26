import AVFoundation
import CoreML
import CoreVideo
import UIKit

final class EmotionAnalyzer {
    static let modelInputSize = CGSize(width: 299, height: 299)
    static let rotationRadians = CGFloat.pi / 2
    static let defaultMinProcessInterval: TimeInterval = 0.35
    
    private let queue = DispatchQueue(label: "com.dse.emotionAnalyzer", qos: .userInitiated)
    private var isRunning = false
    private var lastProcessedAt = Date.distantPast
    private var minProcessInterval: TimeInterval
    
    private lazy var model: FacialExpressionClassifier1? = {
        do {
            let config = MLModelConfiguration()
            return try FacialExpressionClassifier1(configuration: config)
        } catch {
            print("[EmotionAnalyzer] Failed to load model: \(error.localizedDescription)")
            return nil
        }
    }()
    
    /// 偵測到單一幀的 argmax 表情（已 map 成 DSE label，例如 joy / calm）
    var onDominantEmotion: ((String) -> Void)?
    
    init(minProcessInterval: TimeInterval = EmotionAnalyzer.defaultMinProcessInterval) {
        self.minProcessInterval = minProcessInterval
    }
    
    func start() {
        queue.async {
            self.isRunning = true
            self.lastProcessedAt = .distantPast
        }
    }
    
    func stop() {
        queue.async {
            self.isRunning = false
        }
    }
    
    // MARK: - 接入（與 completedemotion.swift 相同：先轉 UIImage）
    
    func ingest(image: UIImage) {
        queue.async {
            guard self.isRunning, self.shouldProcessNow() else { return }
            self.predictEmotion(images: image)
        }
    }
    
    /// 由 `AVCaptureVideoDataOutput` 的 sample buffer 接入
    func ingest(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let image = Self.uiImage(from: ciImage) else { return }
        let rotated = image.rotate(radians: Self.rotationRadians)
        ingest(image: rotated)
    }
    
    // MARK: - Core ML（對齊參考碼 predictEmotion）
    
    private func predictEmotion(images: UIImage) {
        guard let buffer = images
            .resize(size: Self.modelInputSize)?
            .getCVPixelBuffer() else {
            return
        }
        
        guard let model else { return }
        
        do {
            let input = FacialExpressionClassifier1Input(image: buffer)
            let output = try model.prediction(input: input)
            let probabilities = output.targetProbability
            
            guard let dominant = Self.dominantLabel(from: probabilities),
                  let dseLabel = Self.mapModelLabelToDSE(dominant.key) else {
                return
            }
            
            DispatchQueue.main.async {
                self.onDominantEmotion?(dseLabel)
            }
        } catch {
            print("[EmotionAnalyzer] prediction failed: \(error.localizedDescription)")
        }
    }
    
    private func shouldProcessNow() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedAt) >= minProcessInterval else { return false }
        lastProcessedAt = now
        return true
    }
    
    static func dominantLabel(from probabilities: [String: Double]) -> (key: String, confidence: Double)? {
        probabilities.max { $0.value < $1.value }.map { ($0.key, $0.value) }
    }
    
    /// Core ML 標籤 → DSEDataCollector 使用的 key
    static func mapModelLabelToDSE(_ modelLabel: String) -> String? {
        let normalized = modelLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "happy":
            return DSEEmotionLabel.joy.rawValue
        case "neutral":
            return DSEEmotionLabel.calm.rawValue
        default:
            return DSEEmotionLabel.key(from: normalized)
        }
    }
    
    private static func uiImage(from ciImage: CIImage) -> UIImage? {
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - UIImage（參考 completedemotion.swift）

extension UIImage {
    func rotate(radians: CGFloat) -> UIImage {
        let rotatedSize = CGRect(origin: .zero, size: size)
            .applying(CGAffineTransform(rotationAngle: radians))
            .integral.size
        
        UIGraphicsBeginImageContext(rotatedSize)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return self }
        let origin = CGPoint(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
        context.translateBy(x: origin.x, y: origin.y)
        context.rotate(by: radians)
        draw(in: CGRect(
            x: -origin.y,
            y: -origin.x,
            width: size.width,
            height: size.height
        ))
        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }
    
    func resize(size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func getCVPixelBuffer() -> CVPixelBuffer? {
        let width = Int(size.width)
        let height = Int(size.height)
        
        let attrs: [CFString: Any] = [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true
        ]
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(
            kCFAllocatorDefault,
            width,
            height,
            kCVPixelFormatType_32ARGB,
            attrs as CFDictionary,
            &pixelBuffer
        )
        
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        
        guard let context = CGContext(
            data: CVPixelBufferGetBaseAddress(buffer),
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(buffer),
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
        ) else { return nil }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        UIGraphicsPushContext(context)
        draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        UIGraphicsPopContext()
        
        return buffer
    }
}

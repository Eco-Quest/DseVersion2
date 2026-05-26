//
// VideoRecorderView.swift
// AVAssetWriterDemo
//
// Created by Weisu Yin on 5/6/20.
// Copyright © 2020 UCDavis. All rights reserved.
//
/*
import SwiftUI
import AVFoundation
import AVKit
import Photos

// MARK: - 视频片段模型
struct VideoSegment: Identifiable {
    let id = UUID()
    let url: URL
    let duration: TimeInterval
    let createdAt: Date
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 主视图
struct VideoRecorderView: View {
    @StateObject private var viewModel = VideoRecorderViewModel()
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: viewModel.captureSession)
                .ignoresSafeArea()
            
            VStack {
                // 分段指示器
                if viewModel.segments.count > 0 {
                    HStack {
                        Text("已录制 \(viewModel.segments.count) 段")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 15)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(20)
                    }
                    .padding(.top, 60)
                }
                
                // Timer display
                if viewModel.recording {
                    Text(viewModel.formattedTime)
                        .font(.system(size: 48, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(15)
                        .padding(.top, 20)
                }
                
                Spacer()
                
                // 底部按钮区域
                VStack(spacing: 20) {
                    HStack(spacing: 40) {
                        // 片段列表按钮
                        Button(action: {
                            viewModel.showSegmentList = true
                        }) {
                            VStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .font(.system(size: 30))
                                Text("片段")
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                        
                        // 录制按钮
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            viewModel.recording.toggle()
                        }) {
                            ZStack {
                                Circle()
                                    .fill(viewModel.recording ? Color.red : Color.white)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                    )
                                
                                if viewModel.recording {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white)
                                        .frame(width: 30, height: 30)
                                }
                            }
                        }
                        
                        // 合并按钮
                        Button(action: {
                            viewModel.mergeAllSegments()
                        }) {
                            VStack {
                                Image(systemName: "video.badge.plus")
                                    .font(.system(size: 30))
                                Text("合并")
                                    .font(.caption)
                            }
                            .foregroundColor(viewModel.segments.count >= 2 ? .white : .gray)
                        }
                        .disabled(viewModel.segments.count < 2)
                    }
                    
                    // 重置按钮（当有片段时显示）
                    if viewModel.segments.count > 0 {
                        Button(action: {
                            viewModel.resetAllSegments()
                        }) {
                            Text("清除所有片段")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(20)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .sheet(isPresented: $viewModel.showSegmentList) {
            SegmentListView(viewModel: viewModel)
        }
        .fullScreenCover(isPresented: $viewModel.showMergedVideo) {
            if let url = viewModel.mergedVideoURL {
                VideoPlayerView(url: url, title: "合并后的视频")
            }
        }
        .onAppear {
            viewModel.requestMicrophonePermission()
            viewModel.prePrepareRecording()
        }
    }
}

// MARK: - 相机预览
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        if let connection = previewLayer.connection {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
        
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.main.async {
            previewLayer.frame = view.bounds
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = uiView.bounds
            if let connection = previewLayer.connection,
               connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
        }
    }
}

// MARK: - 片段列表视图
struct SegmentListView: View {
    @ObservedObject var viewModel: VideoRecorderViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedSegment: VideoSegment?
    @State private var showPlayer = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.segments) { segment in
                    SegmentRow(segment: segment)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedSegment = segment
                            showPlayer = true
                        }
                }
                .onDelete { indexSet in
                    viewModel.deleteSegment(at: indexSet)
                }
            }
            .navigationTitle("视频片段 (\(viewModel.segments.count))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("关闭") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let segment = selectedSegment {
                    VideoPlayerView(url: segment.url, title: "片段 \(formattedIndex(for: segment))")
                }
            }
        }
    }
    
    private func formattedIndex(for segment: VideoSegment) -> String {
        guard let index = viewModel.segments.firstIndex(where: { $0.id == segment.id }) else {
            return ""
        }
        return "\(index + 1)"
    }
}

// MARK: - 片段行视图
struct SegmentRow: View {
    let segment: VideoSegment
    @State private var thumbnail: UIImage?
    
    var body: some View {
        HStack(spacing: 15) {
            // 缩略图
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 80, height: 80)
                    .cornerRadius(8)
                    .clipped()
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("视频片段")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                    Text(segment.formattedDuration)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                
                Text(segment.createdAt.formatted())
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "play.circle")
                .font(.title2)
                .foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .onAppear {
            generateThumbnail()
        }
    }
    
    private func generateThumbnail() {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: segment.url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 160, height: 160)
            
            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                DispatchQueue.main.async {
                    thumbnail = UIImage(cgImage: cgImage)
                }
            }
        }
    }
}

// MARK: - 视频播放控制器
struct VideoPlayerController: UIViewControllerRepresentable {
    let player: AVPlayer
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspectFill
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
    
    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player?.pause()
        uiViewController.player = nil
    }
}

// MARK: - 视频播放视图
struct VideoPlayerView: View {
    let url: URL
    let title: String
    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let player = player {
                VideoPlayerController(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.play()
                    }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        player?.pause()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                    
                    Spacer()
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // 保存到相册按钮
                    Button(action: {
                        saveVideoToPhotoLibrary()
                    }) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 25))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                .background(Color.black.opacity(0.5))
                
                Spacer()
            }
        }
        .onAppear {
            player = AVPlayer(url: url)
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
    
    private func saveVideoToPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("视频已保存到相册")
                    } else if let error = error {
                        print("保存失败: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - ViewModel
class VideoRecorderViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var recording = false {
        didSet {
            if recording {
                startRecording()
            } else {
                stopRecording()
            }
        }
    }
    @Published var showSegmentList = false
    @Published var showMergedVideo = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var recordingTime: TimeInterval = 0
    @Published var segments: [VideoSegment] = []
    @Published var mergedVideoURL: URL?
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    let captureSession = AVCaptureSession()
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var audioDataOutput: AVCaptureAudioDataOutput?
    
    // 预准备的 Writer 资源
    private var preparedWriter: AVAssetWriter?
    private var preparedVideoInput: AVAssetWriterInput?
    private var preparedAudioInput: AVAssetWriterInput?
    private var preparedURL: URL?
    private var isPrepared = false
    
    // 实际使用的 Writer 资源
    private var assetWriter: AVAssetWriter?
    private var videoAssetWriterInput: AVAssetWriterInput?
    private var audioAssetWriterInput: AVAssetWriterInput?
    private var currentSegmentURL: URL?
    private var sessionAtSourceTime: CMTime?
    private var timer: Timer?
    private var firstVideoFrameReceived = false
    private var currentSegmentStartTime: Date?
    
    private let videoQueue = DispatchQueue(label: "videoQueue")
    private let audioQueue = DispatchQueue(label: "audioQueue")
    private let writerQueue = DispatchQueue(label: "writerQueue", qos: .userInitiated)
    
    override init() {
        super.init()
        requestCameraPermission()
    }
    
    // MARK: - 预准备录制资源
    func prePrepareRecording() {
        writerQueue.async { [weak self] in
            guard let self = self else { return }
            self.cleanupPreparedWriter()
            
            do {
                let tempURL = self.videoFileLocation()
                let tempWriter = try AVAssetWriter(outputURL: tempURL, fileType: .mov)
                
                let videoSettings: [String: Any] = [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: 720,
                    AVVideoHeightKey: 1280,
                    AVVideoCompressionPropertiesKey: [
                        AVVideoAverageBitRateKey: 2300000
                    ]
                ]
                
                let tempVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                tempVideoInput.expectsMediaDataInRealTime = true
                
                if let transform = self.getVideoTransform() {
                    tempVideoInput.transform = transform
                }
                
                if tempWriter.canAdd(tempVideoInput) {
                    tempWriter.add(tempVideoInput)
                }
                
                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVNumberOfChannelsKey: 2,
                    AVSampleRateKey: 44100.0,
                    AVEncoderBitRateKey: 128000
                ]
                let tempAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                tempAudioInput.expectsMediaDataInRealTime = true
                
                if tempWriter.canAdd(tempAudioInput) {
                    tempWriter.add(tempAudioInput)
                }
                
                let success = tempWriter.startWriting()
                if success {
                    self.preparedWriter = tempWriter
                    self.preparedVideoInput = tempVideoInput
                    self.preparedAudioInput = tempAudioInput
                    self.preparedURL = tempURL
                    self.isPrepared = true
                    print("预准备完成")
                }
            } catch {
                print("预准备失败: \(error)")
            }
        }
    }
    
    private func cleanupPreparedWriter() {
        preparedWriter = nil
        preparedVideoInput = nil
        preparedAudioInput = nil
        if let url = preparedURL {
            try? FileManager.default.removeItem(at: url)
            preparedURL = nil
        }
        isPrepared = false
    }
    
    private func getVideoTransform() -> CGAffineTransform? {
        return CGAffineTransform(rotationAngle: 0)
    }
    
    // MARK: - 开始录制新片段
    private func startRecording() {
        recordingTime = 0
        sessionAtSourceTime = nil
        firstVideoFrameReceived = false
        currentSegmentStartTime = Date()
        startTimer()
        
        writerQueue.async { [weak self] in
            guard let self = self else { return }
            
            if self.isPrepared,
               let preparedWriter = self.preparedWriter,
               let preparedVideoInput = self.preparedVideoInput,
               let preparedAudioInput = self.preparedAudioInput {
                
                self.assetWriter = preparedWriter
                self.videoAssetWriterInput = preparedVideoInput
                self.audioAssetWriterInput = preparedAudioInput
                self.currentSegmentURL = self.preparedURL
                
                self.isPrepared = false
                self.preparedWriter = nil
                self.preparedVideoInput = nil
                self.preparedAudioInput = nil
                self.preparedURL = nil
                
                print("开始录制新片段")
            } else {
                self.setupWriterFallback()
            }
        }
    }
    
    private func setupWriterFallback() {
        do {
            self.currentSegmentURL = self.videoFileLocation()
            self.assetWriter = try AVAssetWriter(outputURL: self.currentSegmentURL!, fileType: .mov)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 720,
                AVVideoHeightKey: 1280,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 2300000
                ]
            ]
            
            self.videoAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            guard let videoInput = self.videoAssetWriterInput, let assetWriter = self.assetWriter else { return }
            videoInput.expectsMediaDataInRealTime = true
            
            if let transform = self.getVideoTransform() {
                videoInput.transform = transform
            }
            
            if assetWriter.canAdd(videoInput) {
                assetWriter.add(videoInput)
            }
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 128000
            ]
            
            self.audioAssetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            guard let audioInput = self.audioAssetWriterInput else { return }
            audioInput.expectsMediaDataInRealTime = true
            
            if assetWriter.canAdd(audioInput) {
                assetWriter.add(audioInput)
            }
            
            let success = assetWriter.startWriting()
            if !success {
                DispatchQueue.main.async {
                    self.showError(message: "启动录制失败")
                    self.recording = false
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.showError(message: error.localizedDescription)
                self.recording = false
            }
        }
    }
    
    private func canWrite() -> Bool {
        return recording && assetWriter != nil && assetWriter?.status == .writing
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard recording else { return }
        
        if output is AVCaptureVideoDataOutput {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            
            if !firstVideoFrameReceived {
                firstVideoFrameReceived = true
            }
        }
        
        let writable = canWrite()
        
        if writable, sessionAtSourceTime == nil {
            let timestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            sessionAtSourceTime = timestamp
            assetWriter?.startSession(atSourceTime: timestamp)
            print("录制会话开始")
        }
        
        guard writable, let assetWriter = assetWriter else { return }
        
        if output == videoDataOutput, let videoInput = videoAssetWriterInput, videoInput.isReadyForMoreMediaData {
            videoInput.append(sampleBuffer)
        } else if output == audioDataOutput, let audioInput = audioAssetWriterInput, audioInput.isReadyForMoreMediaData {
            audioInput.append(sampleBuffer)
        }
    }
    
    // MARK: - 停止录制，保存片段
    private func stopRecording() {
        stopTimer()
        let duration = recordingTime
        
        writerQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.videoAssetWriterInput?.markAsFinished()
            self.audioAssetWriterInput?.markAsFinished()
            
            self.assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let url = self.currentSegmentURL,
                       FileManager.default.fileExists(atPath: url.path) {
                        let segment = VideoSegment(
                            url: url,
                            duration: duration,
                            createdAt: self.currentSegmentStartTime ?? Date()
                        )
                        self.segments.append(segment)
                        print("片段已保存，总片段数: \(self.segments.count)")
                    }
                    
                    self.sessionAtSourceTime = nil
                    self.assetWriter = nil
                    self.videoAssetWriterInput = nil
                    self.audioAssetWriterInput = nil
                    self.currentSegmentURL = nil
                    
                    // 为下一段预准备
                    self.prePrepareRecording()
                }
            }
        }
    }
    
    // MARK: - 片段管理
    func deleteSegment(at offsets: IndexSet) {
        for index in offsets {
            let segment = segments[index]
            try? FileManager.default.removeItem(at: segment.url)
        }
        segments.remove(atOffsets: offsets)
    }
    
    func resetAllSegments() {
        for segment in segments {
            try? FileManager.default.removeItem(at: segment.url)
        }
        segments.removeAll()
    }
    
    // MARK: - 合并视频
    func mergeAllSegments() {
        guard segments.count >= 2 else {
            showError(message: "至少需要2个片段才能合并")
            return
        }
        
        print("开始合并 \(segments.count) 个视频片段")
        
        let composition = AVMutableComposition()
        
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ),
        let audioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            showError(message: "无法创建合成轨道")
            return
        }
        
        var currentTime = CMTime.zero
        
        for (index, segment) in segments.enumerated() {
            let asset = AVAsset(url: segment.url)
            
            guard let assetVideoTrack = asset.tracks(withMediaType: .video).first,
                  let assetAudioTrack = asset.tracks(withMediaType: .audio).first else {
                print("片段 \(index) 缺少视频或音频轨道")
                continue
            }
            
            do {
                try videoTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: assetVideoTrack,
                    at: currentTime
                )
                
                try audioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: asset.duration),
                    of: assetAudioTrack,
                    at: currentTime
                )
                
                currentTime = CMTimeAdd(currentTime, asset.duration)
                print("已添加片段 \(index + 1)，时长: \(asset.duration.seconds)")
            } catch {
                print("插入片段失败: \(error)")
            }
        }
        
        // 导出合并后的视频
        let outputURL = videoFileLocation()
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            showError(message: "无法创建导出会话")
            return
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        exportSession.exportAsynchronously { [weak self] in
            DispatchQueue.main.async {
                switch exportSession.status {
                case .completed:
                    self?.mergedVideoURL = outputURL
                    self?.showMergedVideo = true
                    print("视频合并成功")
                case .failed:
                    self?.showError(message: exportSession.error?.localizedDescription ?? "合并失败")
                case .cancelled:
                    print("合并取消")
                default:
                    break
                }
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.recordingTime += 0.1
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    func showError(message: String) {
        DispatchQueue.main.async {
            self.errorMessage = message
            self.showError = true
        }
    }
    
    // MARK: - 相机和麦克风设置
    func requestMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            setupAudioInput()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupAudioInput()
                    }
                }
            }
        case .denied, .restricted:
            showError(message: "麦克风权限被拒绝")
        @unknown default:
            fatalError()
        }
    }
    
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            showError(message: "相机权限被拒绝")
        @unknown default:
            fatalError()
        }
    }
    
    private func setupCaptureSession() {
        captureSession.beginConfiguration()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession.canAddInput(videoDeviceInput) else {
            showError(message: "无法添加相机输入")
            return
        }
        captureSession.addInput(videoDeviceInput)
        
        let tempVideoDataOutput = AVCaptureVideoDataOutput()
        tempVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        tempVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        tempVideoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        guard captureSession.canAddOutput(tempVideoDataOutput) else {
            showError(message: "无法添加视频输出")
            return
        }
        captureSession.addOutput(tempVideoDataOutput)
        
        if let connection = tempVideoDataOutput.connection(with: .video),
           connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
        
        captureSession.commitConfiguration()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
        
        videoDataOutput = tempVideoDataOutput
    }
    
    private func setupAudioInput() {
        captureSession.beginConfiguration()
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
              captureSession.canAddInput(audioDeviceInput) else {
            return
        }
        captureSession.addInput(audioDeviceInput)
        
        let tempAudioDataOutput = AVCaptureAudioDataOutput()
        tempAudioDataOutput.setSampleBufferDelegate(self, queue: audioQueue)
        
        guard captureSession.canAddOutput(tempAudioDataOutput) else {
            return
        }
        captureSession.addOutput(tempAudioDataOutput)
        
        captureSession.commitConfiguration()
        audioDataOutput = tempAudioDataOutput
    }
    
    private func videoFileLocation() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
    }
}
*/

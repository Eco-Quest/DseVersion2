//
//  VideoCallView.swift
//  dse_test
//
//  Created by Matt on 2026/5/3.
//

import SwiftUI
import AVFoundation
import AVKit
import Photos
import Combine

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

// MARK: - 辅助视图类型
enum FuzhuViewType {
    case test
    case note
    case subtitle
}

// MARK: - 声音枚举
enum Voice: String, CaseIterable {
    case cherry = "Cherry"
    case kai = "Kai"
    case jennifer = "Jennifer"
    
    var displayName: String {
        switch self {
        case .cherry: return "Cherry"
        case .kai: return "Kai"
        case .jennifer: return "Jennifer"
        }
    }
}

// MARK: - 数据模型
struct Candidate: Identifiable {
    let id: String
    let name: String
    let icon: String
    let bgColor: Color
    var voice: Voice?
    var isSpeaking: Bool = false
    var isMe: Bool = false
}

// MARK: - 三个点动画的说话指示器
struct SpeakingIndicator: View {
    @State private var animationOffset = 0
    let isActive: Bool
    
    init(isActive: Bool = true) {
        self.isActive = isActive
    }
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: 10, height: 10)
                    .foregroundColor(.white)
                    .scaleEffect(isActive && animationOffset == index ? 1.4 : 0.7)
                    .animation(isActive ? Animation.easeInOut(duration: 0.5).repeatForever().delay(Double(index) * 0.2) : .default, value: animationOffset)
            }
        }
        .onAppear {
            if isActive {
                animationOffset = 0
                Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
                    withAnimation {
                        animationOffset = (animationOffset + 1) % 3
                    }
                }
            }
        }
    }
}

// MARK: - 相机预览
struct FullCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .black
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
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
        }
    }
}

// MARK: - 单个候选人视图
struct CandidateView: View {
    let candidate: Candidate
    let isAISpeaking: Bool
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let avatarSize: CGFloat = min(size.width, size.height) * 0.55
            
            ZStack {
                if candidate.isMe {
                    FullCameraPreview(session: VideoRecorderViewModel.getSharedSession())
                        .frame(width: size.width, height: size.height)
                } else {
                    candidate.bgColor
                }
                
                if !candidate.isMe {
                    VStack {
                        Spacer()
                        if !candidate.icon.isEmpty {
                            Image(candidate.icon)
                                .resizable()
                                .scaledToFit()
                                .frame(width: avatarSize, height: avatarSize)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: isAISpeaking ? 3 : 0)
                                )
                        } else {
                            Circle()
                                .fill(Color.white)
                                .frame(width: avatarSize, height: avatarSize)
                                .overlay(
                                    Text("👤")
                                        .font(.system(size: avatarSize * 0.5))
                                )
                        }
                        Spacer()
                    }
                }
                
                VStack {
                    Spacer()
                    if isAISpeaking && !candidate.isMe {
                        SpeakingIndicator(isActive: true)
                            .padding(.bottom, 8)
                    }
                    Text("\(candidate.name)")
                        .font(.headline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.bottom, 16)
                }
            }
            .overlay(
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.5), lineWidth: isAISpeaking ? 3 : 0)
            )
        }
    }
}

// MARK: - AI对话记录视图
struct AISubtitleView: View {
    @ObservedObject var webSocketManager: WebSocketManager
    
    var body: some View {
        if webSocketManager.chatMessages.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 50))
                    .foregroundColor(Color("blackorwhitecolor").opacity(0.8))
                Text("暂无对话记录")
                    .font(.headline)
                    .foregroundColor(Color("blackorwhitecolor").opacity(0.8))
                Text("点击「开始讨论」按钮开始AI对话练习")
                    .font(.caption)
                    .foregroundColor(Color("blackorwhitecolor").opacity(0.8))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            LazyVStack(spacing: 12) {
                ForEach(webSocketManager.chatMessages) { message in
                    AIChatBubble(message: message)
                }
                
                if !webSocketManager.currentStreamingText.isEmpty && webSocketManager.isAITalking {
                    AIChatBubble(
                        message: ChatMessage(
                            role: .ai,
                            content: webSocketManager.currentStreamingText,
                            timestamp: Date(),
                            voice: webSocketManager.currentVoiceDisplay,
                            speakerName: webSocketManager.currentSpeakerName ?? "Candidate"
                        ),
                        isStreaming: true
                    )
                }
            }
            .padding()
        }
    }
}

// MARK: - 辅助内容视图
struct FuzhuContentView: View {
    let type: FuzhuViewType
    let onClose: () -> Void
    let paper: Paper?
    @ObservedObject var webSocketManager: WebSocketManager
    @Binding var noteText: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(Color(red: 0.27, green: 0.36, blue: 0.71))
            
            ScrollView(showsIndicators: false) {
                switch type {
                case .subtitle:
                    LazyVStack {
                        AISubtitleView(webSocketManager: webSocketManager)
                    }
                case .test:
                    LazyVStack {
                        TestView(paper: paper)
                    }
                case .note:
                    LazyVStack {
                        NoteView(noteText: $noteText)
                    }
                }
            }
            .background(Color("systemBackgroundColor"))
        }
        .cornerRadius(0)
        .shadow(radius: 10)
        .id(type)
    }
    
    private var title: String {
        switch type {
        case .subtitle: return "字幕"
        case .test: return "试题"
        case .note: return "稿纸"
        }
    }
}




// MARK: - 预览
struct FuzhuContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        // 字幕视图预览
        FuzhuContentView(
            type: .subtitle,
            onClose: {},
            paper: nil,
            webSocketManager: {
                let manager = WebSocketManager()
                // 添加一些示例消息用于预览
                return manager
            }(),
            noteText: .constant("")
        )
    }
    
}



// MARK: - 试题视图
struct TestView: View {
    let paper: Paper?
    @Environment(\.dismiss) private var dismiss  // 如果需要关闭弹窗时可保留，否则可选
    let themeColor = Color(red: 0.39, green: 0.75, blue: 0.95) // 或者从外部传入

    private var titleText: String {
        paper?.partA.title ?? "PART A Group Interaction"
    }
    
    private var contentText: String {
        paper?.partA.content ?? readingContent
    }
    
    private var taskText: String {
        paper?.partA.task ?? "You are preparing to give a talk in your school to school leavers about writing emails in their lives after leaving school."
    }
    
    private var points: [String] {
        let dynamicPoints = paper?.partA.discussionPoints ?? []
        if !dynamicPoints.isEmpty { return dynamicPoints }
        return [
            "whether young people write emails in their daily lives",
            "the challenges young people may face when writing formal emails",
            "the advantages of using email over other forms of communication",
            "anything else you think is important"
        ]
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // 头部信息（保持与 PaperDetailPopupView 风格一致，但缺少 year/type，这里简化或隐藏）
                VStack(spacing: 12) {
              
                    
                    Text("ENGLISH LANGUAGE PAPER 4")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // 核心外框：Part A + 标题 + 阅读材料
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("PART A Group Interaction")
                            .font(.headline)
                            .foregroundColor(themeColor)
                    }
                    
                    Text(titleText)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    Text(contentText)
                        .font(.body)
                        .lineSpacing(6)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                
                // Task（无外框，与 Popup 风格一致）
                Text(taskText)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Discussion Points（使用圆点 + 主题色）
                ForEach(points, id: \.self) { point in
                    HStack(alignment: .top, spacing: 12) {
                        Circle()
                            .fill(themeColor)
                            .frame(width: 6, height: 6)
                            .padding(.top, 8)
                        Text(point)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
    
    private let readingContent = """
    Below is an extract from a website about email:
    
    Why Are Young People Abandoning Email?
    
    Having an email account used to be cool. You could send people in Africa your thoughts on a new K-Pop song, receive email confirmation for movie tickets you bought on the phone and ignore scam messages. Not anymore.
    """
}


// MARK: - 笔记视图
// MARK: - 笔记视图
struct NoteView: View {
    @Binding var noteText: String
    @State private var textHeight: CGFloat = 200
    @State private var screenHeight: CGFloat = UIScreen.main.bounds.height
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 隐藏的 Text 用于计算高度
            Text(noteText.isEmpty ? " " : noteText)
                .font(.body)
                .padding()
                .opacity(0)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .preference(
                                key: ContentHeightKey.self,
                                value: geometry.size.height
                            )
                    }
                )
            
            // 真正的 TextEditor
            TextEditor(text: $noteText)
                .font(.body)
                .padding()
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .frame(height: max(screenHeight * 0.8, textHeight))
        }
        .onPreferenceChange(ContentHeightKey.self) { value in
            textHeight = value
        }
    }
    
    struct ContentHeightKey: PreferenceKey {
        static let defaultValue: CGFloat = 200
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = max(value, nextValue())
        }
    }
}


// MARK: - AI聊天气泡
// MARK: - AI聊天气泡
struct AIChatBubble: View {
    let message: ChatMessage
    var isStreaming: Bool = false
    
    // 根据说话者名称获取对应的图标名称
    private func getIconName(for speakerName: String?) -> String {
        guard let name = speakerName else { return "waveform.circle.fill" }
        
        if name.contains("Candidate A") || name == "Candidate A" {
            return "user1icon"
        } else if name.contains("Candidate B") || name == "Candidate B" {
            return "user2icon"
        } else if name.contains("Candidate C") || name == "Candidate C" {
            return "user3icon"
        } else if name.contains("Examiner") {
            return "teachericon"
        }
        return "waveform.circle.fill"
    }
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack {
                    // 使用自定义图标而不是系统图标
                    if message.role == .user {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color(hex: "5C43A8"))
                            .font(.caption)
                    } else {
                        // 根据说话者显示对应的头像
                        let iconName = getIconName(for: message.speakerName)
                        if UIImage(named: iconName) != nil {
                            Image(iconName)
                                .resizable()
                                .frame(width: 20, height: 20)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "waveform.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }
                    
                    Text(message.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(
                        message.role == .user ?
                        Color(hex: "5C43A8").opacity(0.15) :
                            Color("baiseanniucolor")
                    )
                    .cornerRadius(16)
                
                if isStreaming && message.role == .ai {
                    HStack {
                        Text("Speaking...")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "5C43A8").opacity(0.85))
                        Image(systemName: "speaker.wave.2")
                            .font(.caption2)
                            .foregroundColor(Color(hex: "5C43A8").opacity(0.85))
                    }
                }
            }
            
            if message.role == .ai {
                Spacer()
            }
        }
        .id(message.id)
    }
}


// MARK: - ChatMessage Model
// MARK: - ChatMessage Model
struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    let voice: String?
    let speakerName: String?
    
    enum MessageRole {
        case user
        case ai
    }
    
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: timestamp)
    }
    
    var displayName: String {
        if role == .user {
            return "You"
        } else {
            // 确保显示正确的名称
            if let name = speakerName {
                // 如果名称已经包含 "Candidate"，直接返回
                if name.hasPrefix("Candidate") {
                    return name
                }
                return name
            }
            return "Group Member"
        }
    }
    
    // 获取用于显示的头像图标名称
    var iconName: String {
        if role == .user {
            return "person.circle.fill"
        }
        
        guard let name = speakerName else { return "waveform.circle.fill" }
        
        if name.contains("Candidate A") {
            return "user1icon"
        } else if name.contains("Candidate B") {
            return "user2icon"
        } else if name.contains("Candidate C") {
            return "user3icon"
        } else if name.contains("Examiner") {
            return "teachericon"
        }
        return "waveform.circle.fill"
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
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .fullScreenCover(isPresented: $showPlayer) {
                if let segment = selectedSegment {
                    VideoPlayerView(url: segment.url, title: "片段")
                }
            }
        }
    }
}

// MARK: - 片段行视图
struct SegmentRow: View {
    let segment: VideoSegment
    @State private var thumbnail: UIImage?
    
    var body: some View {
        HStack(spacing: 15) {
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
                    .overlay(ProgressView().scaleEffect(0.8))
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("视频片段").font(.headline)
                HStack {
                    Image(systemName: "clock").font(.caption)
                    Text(segment.formattedDuration).font(.caption)
                }
                .foregroundColor(.secondary)
                Text(segment.createdAt.formatted()).font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            Image(systemName: "play.circle").font(.title2).foregroundColor(.blue)
        }
        .padding(.vertical, 8)
        .onAppear { generateThumbnail() }
    }
    
    private func generateThumbnail() {
        DispatchQueue.global(qos: .background).async {
            let asset = AVAsset(url: segment.url)
            let generator = AVAssetImageGenerator(asset: asset)
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 160, height: 160)
            let time = CMTime(seconds: 0.5, preferredTimescale: 600)
            if let cgImage = try? generator.copyCGImage(at: time, actualTime: nil) {
                DispatchQueue.main.async { thumbnail = UIImage(cgImage: cgImage) }
            }
        }
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
                    .onAppear { player.play() }
            }
            VStack {
                HStack {
                    Button(action: { player?.pause(); dismiss() }) {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 30)).foregroundColor(.white).padding()
                    }
                    Spacer()
                    Text(title).font(.headline).foregroundColor(.white)
                    Spacer()
                    Button(action: saveVideoToPhotoLibrary) {
                        Image(systemName: "square.and.arrow.down").font(.system(size: 25)).foregroundColor(.white).padding()
                    }
                }
                .background(Color.black.opacity(0.5))
                Spacer()
            }
        }
        .onAppear { player = AVPlayer(url: url) }
        .onDisappear { player?.pause(); player = nil }
    }
    
    private func saveVideoToPhotoLibrary() {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                if success { print("视频已保存到相册") }
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
}

// MARK: - 麦克风音频处理
class MicrophoneMonitor: ObservableObject {
    @Published var averageDb: Float = 0.0
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private let bufferSize = 1024
    
    init() {
        setupMicrophone()
    }
    
    private func setupMicrophone() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, bufferSize: UInt32(bufferSize), format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            self.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine?.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        if let rms = VolumeAnalyzer.rms(from: buffer) {
            let speechDb = VolumeAnalyzer.speechDecibels(fromRMS: rms)
            let uiLevel = Float(min(max(speechDb / 100.0, 0), 1))
            DispatchQueue.main.async {
                self.averageDb = uiLevel
            }
            return
        }
        
        guard let channelData = buffer.floatChannelData?[0] else { return }
        var sum: Float = 0
        let frameLength = Int(buffer.frameLength)
        for i in 0..<frameLength {
            sum += abs(channelData[i])
        }
        let average = sum / Float(frameLength)
        let normalizedDb = min(max(average * 20, 0), 1.0)
        DispatchQueue.main.async {
            self.averageDb = normalizedDb
        }
    }
    
    func stopMonitoring() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
    }
}

// MARK: - 音频波形视图
struct SoundChartView: View {
    @ObservedObject var micMonitor: MicrophoneMonitor
    let isUserSpeaking: Bool
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 5) {
                let barCount = max(Int(geometry.size.width / 12), 6)
                
                ForEach(0..<barCount, id: \.self) { index in
                    let height = isUserSpeaking ? getBarHeight(index: index, total: barCount) : 6
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#63BEF3"), Color(hex: "#5C43A9")]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 6, height: height)
                        .animation(.easeInOut(duration: 0.1), value: height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 60)
        .clipped()
    }
    
    private func getBarHeight(index: Int, total: Int) -> CGFloat {
        let normalizedDb = min(max(CGFloat(micMonitor.averageDb), 0.03), 0.4)
        let baseHeight: CGFloat = 6
        let maxHeight: CGFloat = 40
        
        let randomFactor = 0.5 + (CGFloat(index) / CGFloat(total)) * 0.6
        let height = baseHeight + (maxHeight - baseHeight) * normalizedDb * randomFactor
        
        return min(max(height, 6), 40)
    }
}

// MARK: - VideoRecorderViewModel
class VideoRecorderViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    @Published var recording = false { didSet { recording ? startRecording() : stopRecording() } }
    @Published var showSegmentList = false
    @Published var showMergedVideo = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var recordingTime: TimeInterval = 0
    @Published var segments: [VideoSegment] = []
    @Published var mergedVideoURL: URL?
    @Published var hasEnded = false
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    static let captureSession = AVCaptureSession()
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var audioDataOutput: AVCaptureAudioDataOutput?
    
    static func getSharedSession() -> AVCaptureSession { return captureSession }
    
    private var preparedWriter: AVAssetWriter?
    private var preparedVideoInput: AVAssetWriterInput?
    private var preparedAudioInput: AVAssetWriterInput?
    private var preparedURL: URL?
    private var isPrepared = false
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
    let emotionAnalyzer = EmotionAnalyzer()
    let eyeContactAnalyzer = EyeContactAnalyzer()
    
    var onDominantEmotion: ((String) -> Void)?
    var onEyeContactGaze: ((EyeContactAnalysisResult) -> Void)?
    var onEyeContactLookAway: ((Int) -> Void)?
    
    override init() {
        super.init()
        emotionAnalyzer.onDominantEmotion = { [weak self] label in
            self?.onDominantEmotion?(label)
        }
        eyeContactAnalyzer.onGazeDetected = { [weak self] result in
            self?.onEyeContactGaze?(result)
        }
        eyeContactAnalyzer.onLookAway = { [weak self] second in
            self?.onEyeContactLookAway?(second)
        }
        requestCameraPermission()
    }
    
    func configureEyeContactDiscussionTiming(provider: @escaping () -> TimeInterval) {
        eyeContactAnalyzer.discussionElapsedProvider = provider
    }
    
    // 清除所有录制资源（不进行合成）
    func cleanupRecording() {
        // 停止当前录制
        if recording {
            stopRecording()
        }
        
        // 删除所有视频片段文件
        for segment in segments {
            do {
                try FileManager.default.removeItem(at: segment.url)
            } catch {
                print("删除视频片段失败: \(error.localizedDescription)")
            }
        }
        
        // 清空片段数组
        segments.removeAll()
        
        // 清除合成视频URL
        if let mergedURL = mergedVideoURL {
            do {
                try FileManager.default.removeItem(at: mergedURL)
            } catch {
                print("删除合成视频失败: \(error.localizedDescription)")
            }
            mergedVideoURL = nil
        }
        
        // 重置状态
        recording = false
        recordingTime = 0
        currentSegmentIndex = 0
        hasEnded = false
    }
    
    private var currentSegmentIndex = 0
    
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
                    AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2300000]
                ]
                let tempVideoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
                tempVideoInput.expectsMediaDataInRealTime = true
                tempVideoInput.transform = CGAffineTransform(rotationAngle: 0)
                if tempWriter.canAdd(tempVideoInput) { tempWriter.add(tempVideoInput) }
                
                let audioSettings: [String: Any] = [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVNumberOfChannelsKey: 2,
                    AVSampleRateKey: 44100.0,
                    AVEncoderBitRateKey: 128000
                ]
                let tempAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
                tempAudioInput.expectsMediaDataInRealTime = true
                if tempWriter.canAdd(tempAudioInput) { tempWriter.add(tempAudioInput) }
                
                if tempWriter.startWriting() {
                    self.preparedWriter = tempWriter
                    self.preparedVideoInput = tempVideoInput
                    self.preparedAudioInput = tempAudioInput
                    self.preparedURL = tempURL
                    self.isPrepared = true
                }
            } catch { print("预准备失败: \(error)") }
        }
    }
    
    private func cleanupPreparedWriter() {
        preparedWriter = nil
        preparedVideoInput = nil
        preparedAudioInput = nil
        if let url = preparedURL { try? FileManager.default.removeItem(at: url); preparedURL = nil }
        isPrepared = false
    }
    
    private func startRecording() {
        recordingTime = 0
        sessionAtSourceTime = nil
        firstVideoFrameReceived = false
        currentSegmentStartTime = Date()
        emotionAnalyzer.start()
        eyeContactAnalyzer.start()
        startTimer()
        
        writerQueue.async { [weak self] in
            guard let self = self else { return }
            if self.isPrepared, let preparedWriter = self.preparedWriter,
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
            } else { self.setupWriterFallback() }
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
                AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 2300000]
            ]
            self.videoAssetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            guard let videoInput = self.videoAssetWriterInput, let assetWriter = self.assetWriter else { return }
            videoInput.expectsMediaDataInRealTime = true
            videoInput.transform = CGAffineTransform(rotationAngle: 0)
            if assetWriter.canAdd(videoInput) { assetWriter.add(videoInput) }
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 2,
                AVSampleRateKey: 44100.0,
                AVEncoderBitRateKey: 128000
            ]
            self.audioAssetWriterInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            guard let audioInput = self.audioAssetWriterInput else { return }
            audioInput.expectsMediaDataInRealTime = true
            if assetWriter.canAdd(audioInput) { assetWriter.add(audioInput) }
            
            if !assetWriter.startWriting() {
                DispatchQueue.main.async { self.showError(message: "启动录制失败"); self.recording = false }
            }
        } catch {
            DispatchQueue.main.async { self.showError(message: error.localizedDescription); self.recording = false }
        }
    }
    
    private func canWrite() -> Bool {
        return recording && assetWriter != nil && assetWriter?.status == .writing
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard recording else { return }
        
        if output is AVCaptureVideoDataOutput {
            if connection.isVideoOrientationSupported { connection.videoOrientation = .portrait }
            if !firstVideoFrameReceived { firstVideoFrameReceived = true }
            emotionAnalyzer.ingest(sampleBuffer: sampleBuffer)
            eyeContactAnalyzer.ingest(sampleBuffer: sampleBuffer)
        }
        
        let writable = canWrite()
        if writable, sessionAtSourceTime == nil {
            let timestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
            sessionAtSourceTime = timestamp
            assetWriter?.startSession(atSourceTime: timestamp)
        }
        
        guard writable, let assetWriter = assetWriter else { return }
        
        if output == videoDataOutput, let videoInput = videoAssetWriterInput, videoInput.isReadyForMoreMediaData {
            videoInput.append(sampleBuffer)
        } else if output == audioDataOutput, let audioInput = audioAssetWriterInput, audioInput.isReadyForMoreMediaData {
            audioInput.append(sampleBuffer)
        }
    }
    
    private func stopRecording() {
        stopTimer()
        emotionAnalyzer.stop()
        eyeContactAnalyzer.stop()
        let duration = recordingTime
        
        writerQueue.async { [weak self] in
            guard let self = self else { return }
            self.videoAssetWriterInput?.markAsFinished()
            self.audioAssetWriterInput?.markAsFinished()
            self.assetWriter?.finishWriting { [weak self] in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if let url = self.currentSegmentURL, FileManager.default.fileExists(atPath: url.path) {
                        let segment = VideoSegment(url: url, duration: duration, createdAt: self.currentSegmentStartTime ?? Date())
                        self.segments.append(segment)
                    }
                    self.sessionAtSourceTime = nil
                    self.assetWriter = nil
                    self.videoAssetWriterInput = nil
                    self.audioAssetWriterInput = nil
                    self.currentSegmentURL = nil
                    self.prePrepareRecording()
                }
            }
        }
    }
    
    func deleteSegment(at offsets: IndexSet) {
        for index in offsets { try? FileManager.default.removeItem(at: segments[index].url) }
        segments.remove(atOffsets: offsets)
    }
    
    func mergeAllSegments() -> URL? {
        guard segments.count >= 1 else {
            showError(message: "至少需要1个片段才能合成")
            return nil
        }
        
        let composition = AVMutableComposition()
        guard let videoTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
              let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            showError(message: "无法创建合成轨道")
            return nil
        }
        
        var currentTime = CMTime.zero
        for segment in segments {
            let asset = AVAsset(url: segment.url)
            guard let assetVideoTrack = asset.tracks(withMediaType: .video).first,
                  let assetAudioTrack = asset.tracks(withMediaType: .audio).first else { continue }
            do {
                try videoTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetVideoTrack, at: currentTime)
                try audioTrack.insertTimeRange(CMTimeRange(start: .zero, duration: asset.duration), of: assetAudioTrack, at: currentTime)
                currentTime = CMTimeAdd(currentTime, asset.duration)
            } catch { print("插入片段失败: \(error)") }
        }
        
        let outputURL = videoFileLocation()
        guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
            showError(message: "无法创建导出会话")
            return nil
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.shouldOptimizeForNetworkUse = true
        
        let semaphore = DispatchSemaphore(value: 0)
        var resultURL: URL?
        
        exportSession.exportAsynchronously {
            if exportSession.status == .completed {
                resultURL = outputURL
            }
            semaphore.signal()
        }
        semaphore.wait()
        
        if let resultURL = resultURL {
            mergedVideoURL = resultURL
        }
        return resultURL
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            DispatchQueue.main.async { self?.recordingTime += 0.1 }
        }
    }
    
    private func stopTimer() { timer?.invalidate(); timer = nil }
    
    func showError(message: String) {
        DispatchQueue.main.async { self.errorMessage = message; self.showError = true }
    }
    
    func requestMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: setupAudioInput()
        case .notDetermined: AVCaptureDevice.requestAccess(for: .audio) { granted in if granted { DispatchQueue.main.async { self.setupAudioInput() } } }
        default: break
        }
    }
    
    private func requestCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: setupCaptureSession()
        case .notDetermined: AVCaptureDevice.requestAccess(for: .video) { granted in if granted { DispatchQueue.main.async { self.setupCaptureSession() } } }
        default: break
        }
    }
    
    private func setupCaptureSession() {
        VideoRecorderViewModel.captureSession.beginConfiguration()
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: frontCamera),
              VideoRecorderViewModel.captureSession.canAddInput(videoDeviceInput) else { return }
        VideoRecorderViewModel.captureSession.addInput(videoDeviceInput)
        
        let tempVideoDataOutput = AVCaptureVideoDataOutput()
        tempVideoDataOutput.alwaysDiscardsLateVideoFrames = true
        tempVideoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
        tempVideoDataOutput.setSampleBufferDelegate(self, queue: videoQueue)
        
        guard VideoRecorderViewModel.captureSession.canAddOutput(tempVideoDataOutput) else { return }
        VideoRecorderViewModel.captureSession.addOutput(tempVideoDataOutput)
        
        if let connection = tempVideoDataOutput.connection(with: .video), connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
            connection.isVideoMirrored = true
        }
        
        VideoRecorderViewModel.captureSession.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async { VideoRecorderViewModel.captureSession.startRunning() }
        videoDataOutput = tempVideoDataOutput
    }
    
    private func setupAudioInput() {
        VideoRecorderViewModel.captureSession.beginConfiguration()
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
              VideoRecorderViewModel.captureSession.canAddInput(audioDeviceInput) else { return }
        VideoRecorderViewModel.captureSession.addInput(audioDeviceInput)
        
        let tempAudioDataOutput = AVCaptureAudioDataOutput()
        tempAudioDataOutput.setSampleBufferDelegate(self, queue: audioQueue)
        guard VideoRecorderViewModel.captureSession.canAddOutput(tempAudioDataOutput) else { return }
        VideoRecorderViewModel.captureSession.addOutput(tempAudioDataOutput)
        VideoRecorderViewModel.captureSession.commitConfiguration()
        audioDataOutput = tempAudioDataOutput
    }
    
    private func videoFileLocation() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
    }
}

// MARK: - 默认试题
let defaultExamText = """
Redevelopment in Western District leaves residents without a good night's sleep

Your class is discussing the redevelopment of older districts in Hong Kong. Your group has been asked to discuss the problems redevelopment causes. You may want to talk about:

• why old districts are redeveloped
• what problems redevelopments cause
• what the government should do to reduce the problems residents face
• anything else you think is important
"""

// MARK: - Config
struct AliyunConfig {
    static let apiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    static let endpoint = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime"
    static let model = "qwen3-omni-flash-realtime"
    static let sampleRate: Double = 16000
    static let bytesPerFrame = 2
}

// MARK: - Participant Model
struct Participant {
    let name: String
    let voice: Voice
    let personality: String
    let proficiencyLevel: ProficiencyLevel
    
    enum ProficiencyLevel: String {
        case beginner = "beginner, non-native english speaker (simple and repeated vocabulary, basic sentences, slow speaking pace)"
        case intermediate = "intermediate (common vocabulary, can express opinions, slow speaking pace)"
        case advanced = "advanced (fluent, sophisticated vocabulary, complex arguments)"
        case native = "native (natural and conversational, impressive range of vocabulary and expressions, able to manage the disucssion)"
        
        var style: String {
            switch self {
            case .beginner:
                return """
                    - Vocabulary: Use basic vocabulary.
                    - Grammar: Use simple and short sentences with mistakes that affect understanding.
                    - Flow: Have hesitations and mistakes or use simple fillers often. Speaking lack of organization and clarity.
                """
            case .intermediate:
                return """
                    - Vocabulary: Use common but limited vocabulary.
                    - Grammar: Use basic connectors like 'because', 'although', 'so' with often mistakes.
                    - Flow: Have hesitations on expressing opinions but avoid overly complex language and sentence patterns.
                """
            case .advanced:
                return """
                    - Vocabulary: Use precise adjectives and complex expressions.
                    - Grammar: Use complex structures (relative clauses, conditionals).
                    - Logic: Able to express opinions clearly. Synthesize others' points before adding your own.
                """
            case .native:
                return """
                    - Vocabulary: Use impressive range of vocabulary and phrasal verbs naturally.
                    - Grammar: Flawless and varied sentence structures.
                    - Flow: Highly persuasive, uses rhetorical questions and nuanced tone.
                """
            }
        }
    }
    
    init(name: String, voice: Voice, personality: String, proficiency: ProficiencyLevel = .intermediate) {
        self.name = name
        self.voice = voice
        self.personality = personality
        self.proficiencyLevel = proficiency
    }
}

// MARK: - Discussion Topic
struct DiscussionTopic {
    let fullText: String
    let participants: [Participant]
    
    var article: String { return fullText }
    
    func buildInstructions(with participant: Participant) -> String {
        return """
        You are now role-playing as \(participant.name), a participant in a DSE English group discussion.
        
        Your personality: \(participant.personality)
        Your voice: \(participant.voice.displayName)
        Your English proficiency: \(participant.proficiencyLevel.rawValue)
        
        --- COMPLETE EXAM MATERIAL ---
        \(fullText)
        --- END OF EXAM MATERIAL ---
        
        Based on this material, you are having a group discussion.
        
        Discussion guidelines:
        - Speak naturally, like a real classmate
        - Respond to what others say before adding your own views
        - Share your opinions using examples from the material
        - Keep responses concise (20-30 seconds when spoken)
        - Adjust your language complexity according to your proficiency level
        - IMPORTANT: You are a DISTINCT individual. Do not say "thank you" on behalf of others.
        
        Remember: You are having a GROUP DISCUSSION, not giving a presentation or interview.
        """
    }
}

// MARK: - PCM Audio Player
class PCMAudioPlayer {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var pendingBuffers = 0
    var onPlaybackFinished: (() -> Void)?
    var currentPlayingVoice: String?
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine, let playerNode = playerNode else { return }
        
        audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 24000,
            channels: 1,
            interleaved: false
        )
        
        guard let format = audioFormat else { return }
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.prepare()
        
        do { try audioEngine.start() } catch { print("Failed to start audio engine: \(error)") }
    }
    
    func playPCMData(_ pcmData: Data, voice: String) {
        guard let playerNode = playerNode, let format = audioFormat else { return }
        
        currentPlayingVoice = voice
        pendingBuffers += 1
        
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            do { try audioEngine.start() } catch { return }
        }
        
        let frameCount = UInt32(pcmData.count / 2)
        if frameCount == 0 { return }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount
        
        let audioBuffer = buffer.audioBufferList.pointee.mBuffers
        pcmData.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            audioBuffer.mData?.copyMemory(from: baseAddress, byteCount: pcmData.count)
        }
        
        playerNode.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async {
                self?.pendingBuffers -= 1
                if self?.pendingBuffers == 0 {
                    self?.onPlaybackFinished?()
                }
            }
        }
        
        if !playerNode.isPlaying { playerNode.play() }
    }
    
    func stop() {
        playerNode?.stop()
        playerNode?.reset()
        pendingBuffers = 0
        currentPlayingVoice = nil
    }
}

// MARK: - WebSocket Manager
// MARK: - WebSocket Manager
@MainActor
class WebSocketManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var isAITalking = false
    @Published var remainingTime: Int = 480
    @Published var isDiscussionActive = false
    @Published var chatMessages: [ChatMessage] = []
    @Published var currentStreamingText = ""
    @Published var currentTranscription = ""
    @Published var canUserSpeak = true
    @Published var currentVoiceDisplay: String = "Jennifer"
    @Published var currentSpeakerName: String? = "Candidate A"
    @Published var currentExamText: String = ""
    @Published var userSpeakingTurns: Int = 0
    @Published var totalSpeakingDuringSec: Int = 0
    @Published var isWaitingForUser = false
    @Published var isPartBActive = false
    @Published var partBQuestion: String?
    @Published var partBUserResponses: [String] = []
    
    // Initial DSE collector wiring for handoff.
    private(set) var dseDataCollector = DSEDataCollector()
    private let volumeAnalyzer = VolumeAnalyzer()
    
    var onUserStartSpeaking: (() -> Void)?
    var onUserStopSpeaking: (() -> Void)?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var webSocketSession: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }()
    private var audioEngine: AVAudioEngine?
    private let audioPlayer = PCMAudioPlayer()
    private var recordingData = Data()
    private var timer: Timer?
    private var waitForUserTimer: Timer?
    private var isProcessingResponse = false
    private var currentVoice: Voice = .jennifer
    private var hasSentAudio = false
    private var isWaitingForVoiceUpdate = false
    private var currentResponseVoice: Voice = .jennifer
    private var voiceUpdateCompletion: (() -> Void)?
    private var currentRecordingStartTime: Date?
    private var keepAliveTimer: Timer?
    private var instructionPlayer: AVAudioPlayer?
    private var partBQuestions: [String] = []
    private var isTransitioningToPartB = false
    private var isFinishingPartBExam = false
    private var hasAnnouncedPartBEnd = false
    private var partBFinalizeWorkItem: DispatchWorkItem?
    private var partATransitionWorkItem: DispatchWorkItem?
    private var isPendingPartBTransition = false
    private var pendingInstructionPhase: InstructionPhase?
    
    // 新增：用于自动开始的标志
    private var isAutoStarting = false
    private var teacherVoiceCompletion: (() -> Void)?

    // MARK: - Discussion State
    private var currentBulletPointIndex: Int = 0
    private var turnsOnCurrentBulletPoint: Int = 0
    private let minTurnsBeforeTaskTransition: Int = 5
    private var examBulletPoints: [String] = []
    
    private enum InstructionPhase {
        case discussionIntro
        case partBIntro
        case partBEnd
        case autoStartVoiceOnly  // 新增：仅播放语音模式
    }
    
    private var currentTopic: DiscussionTopic?
    private var conversationHistory: [String] = []
    private var participants: [Participant] = []
    private var currentParticipantIndex = 0
    private var currentParticipant: Participant?
    private var pendingTurnDurationSeconds: Double?
    
    override init() {
        super.init()
        volumeAnalyzer.discussionElapsedProvider = { [weak self] in
            self?.dseDataCollector.getDiscussionSeconds() ?? 0
        }
        volumeAnalyzer.onPeriodicAverage = { [weak self] averageDb, discussionTimestamp in
            self?.dseDataCollector.appendVolumeSample(averageDb, timestamp: discussionTimestamp)
            print("Volume: \(averageDb) at \(discussionTimestamp) seconds")
        }
        setupAudioSession()
        setupAudioPlayerCallback()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true)
        } catch { print("Failed to setup audio session: \(error)") }
    }
    
    private func setupAudioPlayerCallback() {
        audioPlayer.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                self?.handleAIFinishedSpeaking()
            }
        }
    }
    
    // MARK: - 自动开始：仅播放老师语音，不添加消息（避免重复）
    func playTeacherVoiceOnlyForAutoStart(completion: @escaping () -> Void) {
        print("=== PLAY TEACHER VOICE ONLY FOR AUTO START ===")
        
        teacherVoiceCompletion = completion
        isAutoStarting = true
        pendingInstructionPhase = .autoStartVoiceOnly
        
        guard let url = Bundle.main.url(forResource: "teachersound", withExtension: "mp3") else {
            isAutoStarting = false
            pendingInstructionPhase = nil
            completion()
            return
        }
        
        do {
            instructionPlayer = try AVAudioPlayer(contentsOf: url)
            instructionPlayer?.delegate = self
            instructionPlayer?.prepareToPlay()
            instructionPlayer?.play()
            print("Teacher voice playing...")
        } catch {
            print("Failed to play teacher voice: \(error)")
            isAutoStarting = false
            pendingInstructionPhase = nil
            completion()
        }
    }
    
    // MARK: - 开始讨论（不播放语音，直接开始）
    func startDiscussionDirectly() {
        print("=== STARTING DISCUSSION DIRECTLY ===")
        
        // 开始收集數據
        dseDataCollector.startSession()

        remainingTime = 480
        isDiscussionActive = true
        canUserSpeak = false
        isWaitingForUser = false
        currentParticipantIndex = 0
        userSpeakingTurns = 0
        totalSpeakingDuringSec = 0
        conversationHistory.removeAll()
        pendingTurnDurationSeconds = nil
        
        // 添加 examiner 的初始消息
        chatMessages.append(
            ChatMessage(
                role: .ai,
                content: "Please sit according to the colour of your labels. You have 8 minutes for your discussion. You can look at the question paper and your notecard but please do not make notes during the discussion. Turn over the question paper. You may start now.",
                timestamp: Date(),
                voice: nil,
                speakerName: "Examiner"
            )
        )
        
        startTimer()
        
        let participant = getNextParticipant()
        currentParticipant = participant
        currentSpeakerName = participant.name
        currentVoice = participant.voice
        currentVoiceDisplay = participant.voice.displayName
        currentResponseVoice = participant.voice
        
        createResponseWithVoice()
    }
    
    // 保留原有方法（如果需要手动点击开始）
    func startDiscussion() {
        print("=== STARTING DSE GROUP DISCUSSION (with voice) ===")
        dseDataCollector.startSession()

        remainingTime = 480
        isDiscussionActive = true
        canUserSpeak = false
        isWaitingForUser = false
        currentParticipantIndex = 0
        userSpeakingTurns = 0
        totalSpeakingDuringSec = 0
        conversationHistory.removeAll()
        pendingTurnDurationSeconds = nil
        
        chatMessages.append(
            ChatMessage(
                role: .ai,
                content: "Please sit according to the colour of your labels. You have 8 minutes for your discussion. You can look at the question paper and your notecard but please do not make notes during the discussion. Turn over the question paper. You may start now.",
                timestamp: Date(),
                voice: nil,
                speakerName: "Examiner"
            )
        )
        
        playInstructionAudioAndBeginDiscussion()
    }
    
    private func playInstructionAudioAndBeginDiscussion() {
        pendingInstructionPhase = .discussionIntro
        guard let url = Bundle.main.url(forResource: "teachersound", withExtension: "mp3") else {
            beginDiscussionAfterInstruction()
            return
        }
        
        do {
            instructionPlayer = try AVAudioPlayer(contentsOf: url)
            instructionPlayer?.delegate = self
            instructionPlayer?.prepareToPlay()
            if instructionPlayer?.play() != true {
                pendingInstructionPhase = nil
                beginDiscussionAfterInstruction()
            }
        } catch {
            pendingInstructionPhase = nil
            beginDiscussionAfterInstruction()
        }
    }
    
    private func beginDiscussionAfterInstruction() {
        pendingInstructionPhase = nil
        instructionPlayer?.stop()
        instructionPlayer = nil
        startTimer()
        
        let participant = getNextParticipant()
        currentParticipant = participant
        currentSpeakerName = participant.name
        currentVoice = participant.voice
        currentVoiceDisplay = participant.voice.displayName
        currentResponseVoice = participant.voice
        
        createResponseWithVoice()
    }
    
    private func handleAIFinishedSpeaking() {
        isSpeaking = false
        isAITalking = false
        isProcessingResponse = false
        currentStreamingText = ""
        hasSentAudio = false
        isWaitingForVoiceUpdate = false
        
        if isDiscussionActive && remainingTime > 0 {
            isWaitingForUser = true
            canUserSpeak = true
            startWaitForUserTimer()
        }
    }
    
    private func startWaitForUserTimer() {
        waitForUserTimer?.invalidate()
        waitForUserTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.handleUserNoResponse()
            }
        }
    }
    
    private func cancelWaitForUserTimer() {
        waitForUserTimer?.invalidate()
        waitForUserTimer = nil
        isWaitingForUser = false
    }
    
    private func getNextParticipant() -> Participant {
        guard !participants.isEmpty else {
            return Participant(name: "Candidate A", voice: .jennifer, personality: "thoughtful", proficiency: .advanced)
        }
        let participant = participants[currentParticipantIndex % participants.count]
        currentParticipantIndex += 1
        currentSpeakerName = participant.name
        return participant
    }
    
    func setTopic(_ fullText: String, participants: [Participant]) {
        self.participants = participants
        self.currentTopic = DiscussionTopic(fullText: fullText, participants: participants)
        self.currentExamText = fullText

        self.examBulletPoints = extractTasks(from: fullText)
        self.currentBulletPointIndex = 0
        self.turnsOnCurrentBulletPoint = 0
    }
    
    func setTopicWithDefaultParticipants(_ fullText: String) {
        let defaultParticipants = [
            Participant(name: "Candidate A", voice: .cherry, personality: "thoughtful and analytical", proficiency: .advanced),
            Participant(name: "Candidate B", voice: .kai, personality: "energetic and opinionated", proficiency: .advanced),
            Participant(name: "Candidate C", voice: .jennifer, personality: "empathetic and community-focused", proficiency: .advanced)
        ]
        setTopic(fullText, participants: defaultParticipants)
    }

    private func extractTasks(from text: String) -> [String] {
        var tasks: [String] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") || (trimmed.first?.isNumber == true && trimmed.dropFirst().hasPrefix(". ")) {
                var task = trimmed
                if trimmed.hasPrefix("•") || trimmed.hasPrefix("-") {
                    task = String(trimmed.dropFirst()).trimmingCharacters(in: .whitespaces)
                } else if let spaceIndex = trimmed.firstIndex(of: " ") {
                    task = String(trimmed[spaceIndex...]).trimmingCharacters(in: .whitespaces)
                }
                
                if !task.isEmpty {
                    tasks.append(task)
                }
            }
        }
        return tasks
    }
    
    func setPartBQuestions(_ questions: [String]) {
        partBQuestions = questions.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    
    func buildCurrentDSEScoringInput() -> DSEScoringInput {
        return dseDataCollector.buildInputForScoring()
    }
    
    func resetToInitialState() {
        stopDiscussion()
        
        isConnected = false
        isRecording = false
        isSpeaking = false
        isAITalking = false
        isDiscussionActive = false
        canUserSpeak = false
        isWaitingForUser = false
        isProcessingResponse = false
        hasSentAudio = false
        isWaitingForVoiceUpdate = false
        isPartBActive = false
        isTransitioningToPartB = false
        isFinishingPartBExam = false
        hasAnnouncedPartBEnd = false
        partBQuestion = nil
        partBUserResponses = []
        pendingTurnDurationSeconds = nil
        pendingInstructionPhase = nil
        partBFinalizeWorkItem?.cancel()
        partBFinalizeWorkItem = nil
        
        chatMessages.removeAll()
        currentStreamingText = ""
        currentTranscription = ""
        currentSpeakerName = nil
        conversationHistory.removeAll()
        
        remainingTime = 480
        
        audioPlayer.stop()
        
        disconnect()
        
        currentParticipantIndex = 0
        
        recordingData = Data()
        dseDataCollector.resetSessionData()
    }
    
    private func buildDynamicInstructions(with participant: Participant) -> String {
        guard let topic = currentTopic else {
            return "You are a discussion partner. Speak naturally."
        }
        
        let extractedTasks = extractTasks(from: topic.fullText)
        let tasksList = extractedTasks.enumerated().map { index, task in
            "Task \(index + 1): \(task)"
        }.joined(separator: "\n")

        var instructions = """
        You are now role-playing as \(participant.name), a participant in a DSE English group discussion.
        
        Your personality: \(participant.personality)
        Your English proficiency: \(participant.proficiencyLevel.rawValue)
        
        --- COMPLETE EXAM MATERIAL ---
        \(topic.fullText)
        --- END OF EXAM MATERIAL ---

        --- TASKS TO DISCUSS ---
        \(tasksList.isEmpty ? "Read the exam material to identify the tasks." : tasksList)
        --- END OF TASKS ---

        
        Based on this material, you are having a group discussion.
        
        CONVERSATION SO FAR:
        """
        
        if !conversationHistory.isEmpty {
            instructions += "\n\(conversationHistory.suffix(6).joined(separator: "\n"))"
        } else {
            let firstTaskText = extractedTasks.first ?? "Identify the first meaningful discussion point from the exam material."
            instructions += "\n(No previous conversation - you are starting the discussion)"
            instructions += """
            You are the FIRST speaker to start the discussion:
            - Start without self-introduction.
            - Explicitly describe the main topic and tasks we need to discuss today.
            - Mention to discuss the current focus task first: Task 1 - \(firstTaskText)
            - Immediately share your initial thought on Task 1 - \(firstTaskText).
            - End by inviting others to share their views on Task 1 - \(firstTaskText).
            """
        }
        
        instructions += """
        
        YOUR BEHAVIOR AS \(participant.name.uppercased()):
        
        1. Be a NATURAL discussion partner:
           - Start and respond directly with content.
           - Respond to what others have said before adding your own views
           - Use varied openings and closings.
           
        
        2. When speaking:
           - Acknowledge the other participant's point and avoid keep repeating it
           - Share YOUR perspective based on your personality
           - You may use examples from the exam material to support your point
           - You MUST add at least one original idea, inference, or suggestion beyond the material content.
        
        3. Language level: \(participant.proficiencyLevel.rawValue)
           - Adjust your vocabulary and sentence complexity accordingly
           - \(participant.proficiencyLevel.style)


        4. Keep your response CONCISE (30 seconds when spoken)
        5. Use clear conversational English
        6. Be encouraging and collaborative
        
        Remember: You are having a real discussion, not giving a speech.
        """
        return instructions
    }
    
    private func updateDiscussionHistory(role: String, name: String, content: String) {
        let entry = "\(name): \(content.prefix(100))"
        conversationHistory.append(entry)
        if conversationHistory.count > 20 { conversationHistory.removeFirst() }
    }
    
    private func sendTextMessage(_ message: String) {
        guard !isProcessingResponse else { return }
        
        isProcessingResponse = true
        isAITalking = true
        isWaitingForUser = false
        canUserSpeak = false
        
        let textMessage: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "conversation.item.create",
            "item": [
                "type": "message",
                "role": "user",
                "content": [["type": "input_text", "text": message]]
            ]
        ]
        sendMessage(textMessage)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.createResponseWithVoice()
        }
    }
    
    private func generateAIResponse(userResponse: String? = nil, lastAIResponse: String? = nil) {
        let previousTaskIndex = currentBulletPointIndex
        if !examBulletPoints.isEmpty &&
            turnsOnCurrentBulletPoint >= minTurnsBeforeTaskTransition &&
            currentBulletPointIndex < examBulletPoints.count - 1 {
            currentBulletPointIndex += 1
            turnsOnCurrentBulletPoint = 0
        }
        let didTransitionTask = currentBulletPointIndex != previousTaskIndex
        let focusTaskNumber = examBulletPoints.isEmpty ? 1 : min(currentBulletPointIndex + 1, examBulletPoints.count)
        let focusTaskText = examBulletPoints.indices.contains(currentBulletPointIndex)
            ? examBulletPoints[currentBulletPointIndex]
            : "Identify and discuss the most relevant current point from the exam material."
        let previousTaskNumber = examBulletPoints.isEmpty ? 1 : min(previousTaskIndex + 1, examBulletPoints.count)
        let taskFlowInstruction = didTransitionTask
            ? "The previous focus was Task \(previousTaskNumber), but the current focus is now Task \(focusTaskNumber). Briefly respond to the previous point, then clearly switch to Task \(focusTaskNumber) and share your view on it."
            : "You MUST only continue or focus on Task \(focusTaskNumber). Do NOT move to another task."

        
        let participant = getNextParticipant()
        currentParticipant = participant
        currentSpeakerName = participant.name
        currentVoice = participant.voice
        currentVoiceDisplay = participant.voice.displayName
        currentResponseVoice = participant.voice
        
        var prompt = ""
        
        if let response = userResponse, !response.isEmpty {
            prompt = """
            You are \(participant.name) (proficiency: \(participant.proficiencyLevel.rawValue)).
            Keep language consistent with your assigned proficiency level.
            Remaining time: \(remainingTime) seconds.
            If remaining time is about 50 seconds or less, your MUST help the group reach consensus and give a closing summary to conclude the discussion.

            The other participant just said: "\(response)"
            Current focus task: Task \(focusTaskNumber) - \(focusTaskText)
            Task transition status: \(didTransitionTask ? "You have just moved to a new task. Explicitly say you are moving to Task \(focusTaskNumber)." : "Stay focused on task \(focusTaskNumber).")
            Task flow rule: \(taskFlowInstruction)
            
            1. Respond to the previous reply.
            2. State the current focus task (\(focusTaskText)) before your response.
            3. Focus on Task \(focusTaskNumber) - (\(focusTaskText)) and add one NEW perspective/reason/example beyond the material.
            4. NO greetings. Use varied openings and closings. It is STRICTLY FORBIDDEN to include "Hello" as your opener.

            """
        } else {
            prompt = """
            You are \(participant.name) (proficiency: \(participant.proficiencyLevel.rawValue)).
            Keep language consistent with your assigned proficiency level.
            Remaining time: \(remainingTime) seconds.
            If remaining time is about 50 seconds or less, your MUST help the group reach consensus and give a closing summary to conclude the discussion.

            Current focus task: You are now starting or responding to Task \(focusTaskNumber) - \(focusTaskText)
            Task transition status: \(didTransitionTask ? "You have just moved to a new task. Explicitly say you are moving to Task \(focusTaskNumber)." :
            "Stay focused on task \(focusTaskNumber).")
            Task flow rule: \(taskFlowInstruction)
            Previous candidate response: "\(lastAIResponse ?? "")"

            The group is silent. It is your turn to keep the discussion moving.
            1. Briefly respond to the previous candidate after agree or disagree.
            2. State the current focus task (\(focusTaskText)) after your response.
            3. Focus on Task \(focusTaskNumber) - (\(focusTaskText)) and add a NEW perspective/reason/example beyond the material.
            
            """
        }
        
        sendTextMessage(prompt)
    }
    
    func stopDiscussion() {
        print("=== STOPPING DISCUSSION ===")
        isDiscussionActive = false
        canUserSpeak = false
        isWaitingForUser = false
        timer?.invalidate()
        waitForUserTimer?.invalidate()
        timer = nil
        waitForUserTimer = nil
        isProcessingResponse = false
        isPartBActive = false
        isTransitioningToPartB = false
        pendingInstructionPhase = nil
        instructionPlayer?.stop()
        instructionPlayer = nil
        stopVolumeCollection()
        dseDataCollector.endSession()
        disconnect()
    }
    
    private func playPartBInstructionAudioAndBegin() {
        pendingInstructionPhase = .partBIntro
        
        let candidateURLs: [URL?] = [
            Bundle.main.url(forResource: "partb_transition", withExtension: "mp3")
        ]
        
        guard let playableURL = candidateURLs.compactMap({ $0 }).first else {
            beginPartBAfterInstruction()
            return
        }
        
        do {
            instructionPlayer = try AVAudioPlayer(contentsOf: playableURL)
            instructionPlayer?.delegate = self
            instructionPlayer?.prepareToPlay()
            if instructionPlayer?.play() != true {
                pendingInstructionPhase = nil
                beginPartBAfterInstruction()
            }
        } catch {
            pendingInstructionPhase = nil
            beginPartBAfterInstruction()
        }
    }
    
    //先commit part A then transit to part B
    private func finalizePartAAndTransitionToPartB() {
        guard !isTransitioningToPartB, !isPendingPartBTransition else { return }
        
        timer?.invalidate()
        waitForUserTimer?.invalidate()
        timer = nil
        waitForUserTimer = nil
        canUserSpeak = false
        isWaitingForUser = false
        isProcessingResponse = false
        
        if isRecording {
            isPendingPartBTransition = true
            stopMicRecording()
            schedulePartATransitionFallback()
            return
        }
        
        transitionToPartB()
    }
    
    private func schedulePartATransitionFallback() {
        partATransitionWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.completePendingPartBTransition()
        }
        partATransitionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: workItem)
    }
    
    private func completePendingPartBTransition() {
        guard isPendingPartBTransition else { return }
        isPendingPartBTransition = false
        partATransitionWorkItem?.cancel()
        partATransitionWorkItem = nil
        transitionToPartB()
    }
    
    private func transitionToPartB() {
        guard !isTransitioningToPartB else { return }
        isTransitioningToPartB = true
        isPendingPartBTransition = false
        partATransitionWorkItem?.cancel()
        partATransitionWorkItem = nil
        
        isAITalking = false
        isSpeaking = false
        isWaitingForUser = false
        canUserSpeak = false
        isProcessingResponse = false
        hasSentAudio = false
        currentStreamingText = ""
        
        timer?.invalidate()
        waitForUserTimer?.invalidate()
        timer = nil
        waitForUserTimer = nil
        
        audioPlayer.stop()
        instructionPlayer?.stop()
        instructionPlayer = nil
        
        if isRecording {
            stopMicRecording()
        }
        
        let selectedQuestion = partBQuestions.randomElement() ?? "Please present your personal response to the topic."
        partBQuestion = selectedQuestion
        
        chatMessages.append(
            ChatMessage(
                role: .ai,
                content: "Part B Individual Response starts now. Candidate D, you have 1 minute to answer the following question.",
                timestamp: Date(),
                voice: nil,
                speakerName: "Examiner"
            )
        )
        
        playPartBInstructionAudioAndBegin()
    }
    
    private func beginPartBAfterInstruction() {
        pendingInstructionPhase = nil
        instructionPlayer?.stop()
        instructionPlayer = nil
        
        isPartBActive = true
        isTransitioningToPartB = false
        remainingTime = 60
        canUserSpeak = true
        isWaitingForUser = false
        
        if let selectedQuestion = partBQuestion, !selectedQuestion.isEmpty {
            chatMessages.append(
                ChatMessage(
                    role: .ai,
                    content: selectedQuestion,
                    timestamp: Date(),
                    voice: nil,
                    speakerName: "Examiner"
                )
            )
        }
        
        startTimer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard let self = self else { return }
            if self.isConnected && !self.isRecording {
                self.startRecording()
            }
        }
    }
    
    private func finishExamAfterPartB() {
        guard !isFinishingPartBExam else { return }
        isFinishingPartBExam = true
        hasAnnouncedPartBEnd = false
        
        canUserSpeak = false
        isWaitingForUser = false
        isProcessingResponse = false
        
        timer?.invalidate()
        waitForUserTimer?.invalidate()
        timer = nil
        waitForUserTimer = nil

        if isRecording {
            stopMicRecording()
        }
        
        schedulePartBFinalizationFallback()
    }
    
    private func schedulePartBFinalizationFallback() {
        partBFinalizeWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.showPartBEndAndFinalize()
        }
        partBFinalizeWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: workItem)
    }
    
    private func showPartBEndAndFinalize() {
        guard isFinishingPartBExam, !hasAnnouncedPartBEnd else { return }
        hasAnnouncedPartBEnd = true
        partBFinalizeWorkItem?.cancel()
        partBFinalizeWorkItem = nil
        
        chatMessages.append(
            ChatMessage(
                role: .ai,
                content: "Time is up. That's the end of the examination.",
                timestamp: Date(),
                voice: nil,
                speakerName: "Examiner"
            )
        )
        
        playPartBEndInstructionAndComplete()
    }
    
    private func playPartBEndInstructionAndComplete() {
        pendingInstructionPhase = .partBEnd
        
        guard let url = Bundle.main.url(forResource: "partb_end", withExtension: "mp3") else {
            completePartBExamFinalStep()
            return
        }
        
        do {
            instructionPlayer = try AVAudioPlayer(contentsOf: url)
            instructionPlayer?.delegate = self
            instructionPlayer?.prepareToPlay()
            if instructionPlayer?.play() != true {
                completePartBExamFinalStep()
            }
        } catch {
            completePartBExamFinalStep()
        }
    }
    
    private func completePartBExamFinalStep() {
        isDiscussionActive = false
        isPartBActive = false
        isFinishingPartBExam = false
        hasAnnouncedPartBEnd = false
        partBFinalizeWorkItem?.cancel()
        partBFinalizeWorkItem = nil
        pendingInstructionPhase = nil
        instructionPlayer?.stop()
        instructionPlayer = nil
        
        dseDataCollector.printCollectedDataSummary()
        dseDataCollector.endSession()
        disconnect()
        NotificationCenter.default.post(name: NSNotification.Name("DiscussionEnded"), object: nil)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                    if self.remainingTime == 0 {
                        if self.isPartBActive {
                            self.finishExamAfterPartB()
                        } else {
                            self.finalizePartAAndTransitionToPartB()
                        }
                    }
                }
            }
        }
    }
    
    private func endDiscussion() {
        isDiscussionActive = false
        canUserSpeak = false
        isWaitingForUser = false
        timer?.invalidate()
        waitForUserTimer?.invalidate()
        dseDataCollector.endSession()
        disconnect()
        NotificationCenter.default.post(name: NSNotification.Name("DiscussionEnded"), object: nil)
    }
    
    private func handleUserNoResponse() {
        guard isDiscussionActive && !isRecording && !isAITalking && !isProcessingResponse && remainingTime > 0 else { return }
        isWaitingForUser = false
        print("User did not respond - another group member speaks")
        let lastAIContent = chatMessages.last(where: { $0.role == .ai })?.content
        generateAIResponse(userResponse: nil, lastAIResponse: lastAIContent)
    }
    
    func connect() {
        var components = URLComponents(string: AliyunConfig.endpoint)
        components?.queryItems = [URLQueryItem(name: "model", value: AliyunConfig.model)]
        
        guard let url = components?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(AliyunConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        if webSocketTask != nil {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
        }
        
        webSocketTask = webSocketSession.webSocketTask(with: request)
        webSocketTask?.resume()
        startKeepAlive()
        receiveMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.sendSessionConfig()
        }
    }
    
    func disconnect() {
        stopKeepAlive()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        stopMicRecording()
        instructionPlayer?.stop()
        instructionPlayer = nil
        pendingInstructionPhase = nil
        audioPlayer.stop()
        dseDataCollector.endSession()
    }
    

    private func startVolumeCollection() {
        volumeAnalyzer.start()
    }
    
    private func stopVolumeCollection() {
        volumeAnalyzer.stop()
    }
    
    private func startKeepAlive() {
        stopKeepAlive()
        keepAliveTimer = Timer.scheduledTimer(withTimeInterval: 40.0, repeats: true) { [weak self] _ in
            self?.sendKeepAlivePing()
        }
    }
    
    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
    }
    
    private func sendKeepAlivePing() {
        webSocketTask?.sendPing { error in
            if let error = error { print("Ping failed: \(error)") }
        }
    }
    
    private func sendSessionConfig() {
        guard let participant = currentParticipant else { return }
        let instructions = buildDynamicInstructions(with: participant)
        
        let config: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "voice": participant.voice.rawValue,
                "input_audio_format": "pcm",
                "output_audio_format": "pcm",
                "input_audio_transcription": ["enabled": true],
                "instructions": instructions,
                "turn_detection": NSNull()
            ] as [String : Any]
        ]
        sendMessage(config)
    }
    
    private func updateVoiceAndThen(completion: @escaping () -> Void) {
        if isWaitingForVoiceUpdate {
            voiceUpdateCompletion = completion
            return
        }
        
        isWaitingForVoiceUpdate = true
        
        guard let participant = currentParticipant else {
            isWaitingForVoiceUpdate = false
            completion()
            return
        }
        
        let instructions = buildDynamicInstructions(with: participant)
        let config: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "voice": currentVoice.rawValue,
                "input_audio_format": "pcm",
                "output_audio_format": "pcm",
                "input_audio_transcription": ["enabled": true],
                "instructions": instructions,
                "turn_detection": NSNull()
            ] as [String : Any]
        ]
        sendMessage(config)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            guard let self = self else { return }
            self.isWaitingForVoiceUpdate = false
            completion()
            if let queuedCompletion = self.voiceUpdateCompletion {
                self.voiceUpdateCompletion = nil
                self.updateVoiceAndThen(completion: queuedCompletion)
            }
        }
    }
    
    private func createResponseWithVoice() {
        updateVoiceAndThen { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let responseMessage: [String: Any] = [
                    "event_id": UUID().uuidString,
                    "type": "response.create",
                    "response": [
                        "modalities": ["text", "audio"],
                        "voice": self.currentResponseVoice.rawValue,
                        "output_audio_format": "pcm"
                    ]
                ]
                self.sendMessage(responseMessage)
            }
        }
    }
    
    func startRecording() {
        guard !isRecording, isConnected, !isAITalking, isDiscussionActive, canUserSpeak else { return }
        
        onUserStartSpeaking?()
        
        cancelWaitForUserTimer()
        sendMessage(["type": "input_audio_buffer.clear"])
        recordingData = Data()
        currentTranscription = ""
        currentRecordingStartTime = Date()
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: AliyunConfig.sampleRate,
            channels: 1,
            interleaved: false
        )
        
        guard let targetFormat = targetFormat else { return }
        
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, targetFormat: targetFormat)
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            startVolumeCollection()
        } catch { print("Failed to start audio engine: \(error)") }
    }
    
    func stopMicRecording(discardCurrentBuffer: Bool = false) {
        guard isRecording else { return }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        isRecording = false
        stopVolumeCollection()
        
        if discardCurrentBuffer {
            recordingData = Data()
            currentRecordingStartTime = nil
            pendingTurnDurationSeconds = nil
            isProcessingResponse = false
            canUserSpeak = false
            onUserStopSpeaking?()
            return
        }
        
        if recordingData.count > 0 {
            userSpeakingTurns += 1
            if let startTime = currentRecordingStartTime {
                let turnDuration = max(1, Int(Date().timeIntervalSince(startTime).rounded()))
                totalSpeakingDuringSec += turnDuration
                pendingTurnDurationSeconds = Double(turnDuration)
                dseDataCollector.addSpeakingDuration(seconds: Double(turnDuration))
            }
            currentRecordingStartTime = nil
            commitAudio()
        } else {
            currentRecordingStartTime = nil
            pendingTurnDurationSeconds = nil
            isProcessingResponse = false
            canUserSpeak = true
        }
        
        onUserStopSpeaking?()
    }
    
    private func commitAudio() {
        let commitMessage: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "input_audio_buffer.commit"
        ]
        sendMessage(commitMessage)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
        volumeAnalyzer.ingest(buffer: buffer)
        
        guard let converter = AVAudioConverter(from: buffer.format, to: targetFormat) else { return }
        
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(targetFormat.sampleRate * 0.1))
        var error: NSError?
        converter.convert(to: outputBuffer!, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard let pcmBuffer = outputBuffer,
              let audioData = pcmBuffer.int16ChannelData else { return }
        
        let frameLength = Int(pcmBuffer.frameLength)
        let data = Data(bytes: audioData[0], count: frameLength * 2)
        
        let amplitude = calculateAmplitude(data)
        if amplitude > 0.02 {
            recordingData.append(data)
            hasSentAudio = true
            let base64Audio = data.base64EncodedString()
            let appendMessage: [String: Any] = [
                "type": "input_audio_buffer.append",
                "event_id": UUID().uuidString,
                "audio": base64Audio
            ]
            sendMessage(appendMessage)
        }
    }
    
    private func calculateAmplitude(_ data: Data) -> Double {
        guard data.count > 0 else { return 0 }
        var maxValue: Int16 = 0
        data.withUnsafeBytes { bytes in
            let int16Ptr = bytes.bindMemory(to: Int16.self)
            for i in 0..<(data.count / 2) {
                maxValue = max(maxValue, abs(int16Ptr[i]))
            }
        }
        return Double(maxValue) / 32767.0
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text): self?.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) { self?.handleMessage(text) }
                    @unknown default: break
                    }
                    self?.receiveMessage()
                case .failure(let error):
                    print("Receive error: \(error)")
                    self?.isConnected = false
                    self?.stopKeepAlive()
                }
            }
        }
    }
    
    // 在 WebSocketManager 中找到 addMessage 方法，修改如下：
    private func addMessage(role: ChatMessage.MessageRole, content: String, voice: String? = nil, speakerName: String? = nil) {
        let message = ChatMessage(role: role, content: content, timestamp: Date(), voice: voice, speakerName: speakerName)
        chatMessages.append(message)
        chatMessages.sort { $0.timestamp < $1.timestamp }
        
        let name = role == .user ? "You" : (speakerName ?? "Candidate")
        updateDiscussionHistory(role: role == .user ? "You" : name, name: name, content: content)
        
        if role == .user {
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            let wordCount = trimmed
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
                .count
            
            dseDataCollector.incrementSpeakingTurns(by: 1)
            dseDataCollector.appendTranscriptSegment(trimmed)  // ✅ 确保这行代码执行
            dseDataCollector.appendSpeakingTurnData(
                wordCount: wordCount,
                durationSeconds: pendingTurnDurationSeconds
            )
            pendingTurnDurationSeconds = nil
            
            if isPartBActive {
                partBUserResponses.append(content)
                return
            }
            
            if isPendingPartBTransition {
                completePendingPartBTransition()
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.generateAIResponse(userResponse: content, lastAIResponse: nil)
            }
        } else {
            // 添加 AI 消息到 transcript
            dseDataCollector.appendTranscriptSegment("\(speakerName ?? "Candidate"): \(content)")
        }
    }
    
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        switch type {
        case "session.created", "session.updated":
            isConnected = true
        case "input_audio_buffer.committed":
            print("Audio committed")
        case "response.created":
            currentStreamingText = ""
        case "response.audio.delta":
            if isTransitioningToPartB || isPartBActive { return }
            if let audioBase64 = json["delta"] as? String,
               let audioData = Data(base64Encoded: audioBase64) {
                audioPlayer.playPCMData(audioData, voice: currentResponseVoice.displayName)
                isSpeaking = true
                isAITalking = true
            }
        case "response.audio_transcript.delta":
            if let transcript = json["transcript"] as? String {
                currentStreamingText += transcript
            } else if let delta = json["delta"] as? String {
                currentStreamingText += delta
            }
        case "response.audio_transcript.done":
            if isTransitioningToPartB || isPartBActive {
                currentStreamingText = ""
                return
            }
            if let transcript = json["transcript"] as? String {
                addMessage(role: .ai, content: transcript, voice: currentVoiceDisplay, speakerName: currentSpeakerName)
            }
            currentStreamingText = ""
        case "response.done":
            print("Response done")
        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String, hasSentAudio {
                let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if isPendingPartBTransition {
                    if !trimmed.isEmpty {
                        addMessage(role: .user, content: transcript)
                    } else {
                        completePendingPartBTransition()
                    }
                    hasSentAudio = false
                    return
                }
                
                let isValidPartB = isPartBActive && !trimmed.isEmpty
                let isValidPartA = !isPartBActive && trimmed.count > 5
                
                if isValidPartA || isValidPartB {
                    addMessage(role: .user, content: transcript)
                    if isValidPartB && isFinishingPartBExam {
                        showPartBEndAndFinalize()
                    }
                }
                hasSentAudio = false
            }
        default: break
        }
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard webSocketTask != nil else { return }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error { print("Send error: \(error)") }
        }
    }
}

extension WebSocketManager: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            print("WebSocket didOpen")
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            print("WebSocket didClose")
            self.isConnected = false
            self.stopKeepAlive()
            if self.webSocketTask === webSocketTask { self.webSocketTask = nil }
        }
    }
}

extension WebSocketManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("Audio player finished playing")
            
            let phase = self.pendingInstructionPhase
            self.pendingInstructionPhase = nil
            
            switch phase {
            case .discussionIntro:
                self.beginDiscussionAfterInstruction()
            case .partBIntro:
                self.beginPartBAfterInstruction()
            case .partBEnd:
                self.completePartBExamFinalStep()
            case .autoStartVoiceOnly:
                // 仅播放语音模式，不添加消息，只回调
                self.teacherVoiceCompletion?()
                self.teacherVoiceCompletion = nil
                self.isAutoStarting = false
            case .none:
                break
            }
        }
    }
}




// MARK: - 颜色扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}


// 修改后的 PreviewWaveformView - 与 SoundChartView 排版完全相同
struct PreviewWaveformView: View {
    let isAnimating: Bool
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 5) {
                let barCount = max(Int(geometry.size.width / 12), 6)
                
                ForEach(0..<barCount, id: \.self) { index in
                    let height = isAnimating ? getAnimatedBarHeight(index: index) : 6
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "#63BEF3"), Color(hex: "#5C43A9")]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 6, height: height)
                        .animation(.easeInOut(duration: 0.15), value: height)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 60)
        .clipped()
        .onAppear {
            if isAnimating {
                startAnimation()
            }
        }
        .onChange(of: isAnimating) { newValue in
            if newValue {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func getAnimatedBarHeight(index: Int) -> CGFloat {
        // 使用正弦波模拟动画效果
        let timeFactor = Date().timeIntervalSince1970 * 8
        let phase = Double(index) * 0.3
        let sinValue = sin(timeFactor + phase)
        // 将 sin 值 (-1 到 1) 映射到高度范围 (6 到 40)
        let normalized = (sinValue + 1) / 2
        return 6 + normalized * 34
    }
    
    private func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            // 触发视图更新
        }
    }
    
    private func stopAnimation() {
        timer?.invalidate()
        timer = nil
    }
}


// MARK: - 主视图 VideoCallView
// MARK: - 主视图 VideoCallView
@MainActor
struct VideoCallView: View {
    let paper: Paper?
    let dseCandidates: [DSECandidate]
    let onDismiss: (() -> Void)?
    
    // 改为可选类型，延迟初始化
    @State private var recorderVM: VideoRecorderViewModel?
    @State private var webSocketManager: WebSocketManager?
    @State private var micMonitor: MicrophoneMonitor?
    
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showFuzhuView = false
    @State private var fuzhuViewType: FuzhuViewType = .test
    @State private var showVideoPlayer = false
    @State private var showCannotSpeakAlert = false
    @State private var showDSEReport = false
    @State private var isGeneratingDSEReport = false
    @State private var dsePerformance: DSEPerformance?
    @State private var reportErrorMessage: String?
    @State private var noteText: String
    @State private var hasInitializedResources = false
    @State private var remainingTime: Int = 480
    @State var Startdisucussion: Bool = true
    @State private var hasAutoStarted = false
    @State private var isTeacherSpeaking = false
    @State private var discussionHasEnded = false
    @State private var showDiscussionNotEndedAlert = false  // 成绩按钮 alert

    // MARK: - 测试专用状态
    @State private var longPressCount = 0
    @State private var showTestToast = false
    @State private var toastMessage = ""
    
    @Environment(\.dismiss) private var dismiss
    
    init(paper: Paper? = nil, dseCandidates: [DSECandidate] = [], preparationNote: String = "", onDismiss: (() -> Void)? = nil) {
        self.paper = paper
        self.dseCandidates = dseCandidates
        self.onDismiss = onDismiss
        _noteText = State(initialValue: preparationNote)
    }
    
    // A: Cherry, B: Kai, C: Jennifer
    let uiCandidates: [Candidate] = [
        Candidate(id: "A", name: "Candidate A(Parrot)", icon: "user1icon", bgColor: Color(red: 0.39, green: 0.75, blue: 0.95), voice: .cherry),
        Candidate(id: "B", name: "Candidate B(Puppy)", icon: "user2icon", bgColor: Color(red: 0.98, green: 0.75, blue: 0.24), voice: .kai),
        Candidate(id: "C", name: "Candidate C(Monkey)", icon: "user3icon", bgColor: Color(red: 0.27, green: 0.36, blue: 0.71), voice: .jennifer),
        Candidate(id: "D", name: "Candidate D(You)", icon: "", bgColor: Color.clear, isMe: true)
    ]
    
    // 辅助属性，从 manager 获取值
    private var isDiscussionActive: Bool { webSocketManager?.isDiscussionActive ?? false }
    private var isAITalking: Bool { webSocketManager?.isAITalking ?? false }
    private var isRecording: Bool { webSocketManager?.isRecording ?? false }
    private var canUserSpeak: Bool { webSocketManager?.canUserSpeak ?? false }
    private var currentSpeakerName: String? { webSocketManager?.currentSpeakerName }
    private var hasEnded: Bool { discussionHasEnded }
    private var segmentsCount: Int { recorderVM?.segments.count ?? 0 }
    private var mergedVideoURL: URL? { recorderVM?.mergedVideoURL }
    
    // 波形图应该显示说话的状态
    private var isAnySpeaking: Bool {
        return isTeacherSpeaking || isAITalking || isRecording
    }
    
    private func getSpeakingCandidateId() -> String? {
        guard let speakingName = currentSpeakerName else { return nil }
        if speakingName.contains("A") { return "A" }
        if speakingName.contains("B") { return "B" }
        if speakingName.contains("C") { return "C" }
        return nil
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private var discussionExamText: String {
        guard let paper = paper else { return defaultExamText }
        
        let discussionPoints = paper.partA.discussionPoints.map { "• \($0)" }.joined(separator: "\n")
        return """
        \(paper.topic)
        
        \(paper.partA.content)
        
        Task:
        \(paper.partA.task)
        
        Discussion points:
        \(discussionPoints)
        """
    }
    
    private var discussionParticipants: [Participant] {
        guard !dseCandidates.isEmpty else {
            return [
                Participant(name: "Candidate A", voice: .cherry, personality: "thoughtful and analytical", proficiency: .advanced),
                Participant(name: "Candidate B", voice: .kai, personality: "energetic and opinionated", proficiency: .advanced),
                Participant(name: "Candidate C", voice: .jennifer, personality: "empathetic and community-focused", proficiency: .advanced)
            ]
        }
        
        return dseCandidates.map { candidate in
            let voice: Voice
            switch candidate.letter.uppercased() {
            case "A":
                voice = .cherry
            case "B":
                voice = .kai
            case "C":
                voice = .jennifer
            default:
                voice = .jennifer
            }
            
            let proficiency: Participant.ProficiencyLevel
            switch candidate.level {
            case ...1:
                proficiency = .beginner
            case 2...3:
                proficiency = .intermediate
            case 4:
                proficiency = .advanced
            default:
                proficiency = .native
            }
            
            return Participant(
                name: "Candidate \(candidate.letter)",
                voice: voice,
                personality: candidate.description,
                proficiency: proficiency
            )
        }
    }
    
    // 延迟初始化所有资源
    private func initializeResourcesIfNeeded() {
        guard !hasInitializedResources else { return }
        hasInitializedResources = true
        
        print("开始初始化所有资源...")
        
        DispatchQueue.main.async {
            self.recorderVM = VideoRecorderViewModel()
            self.webSocketManager = WebSocketManager()
            self.micMonitor = MicrophoneMonitor()
            
            self.webSocketManager?.onUserStartSpeaking = {
                DispatchQueue.main.async {
                    if let recorder = self.recorderVM, !recorder.recording {
                        recorder.recording = true
                    }
                }
            }
            
            self.recorderVM?.onDominantEmotion = { [weak webSocketManager = self.webSocketManager] label in
                webSocketManager?.dseDataCollector.appendEmotionCount(label)
                print("Emotion: \(label)")
            }
            
            self.recorderVM?.configureEyeContactDiscussionTiming { [weak webSocketManager = self.webSocketManager] in
                webSocketManager?.dseDataCollector.getDiscussionSeconds() ?? 0
            }
            self.recorderVM?.onEyeContactGaze = { [weak webSocketManager = self.webSocketManager] result in
                webSocketManager?.dseDataCollector.appendEyeContactCount(result.label)
                print("Eye contact: \(result.label)")
            }
            self.recorderVM?.onEyeContactLookAway = { [weak webSocketManager = self.webSocketManager] second in
                webSocketManager?.dseDataCollector.appendEyeContactLookAwaySecond(second)
                print("Eye contact look away: \(second)")
            }
            
            self.webSocketManager?.onUserStopSpeaking = {
                DispatchQueue.main.async {
                    if let recorder = self.recorderVM, recorder.recording {
                        recorder.recording = false
                    }
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.recorderVM?.requestMicrophonePermission()
                self.recorderVM?.prePrepareRecording()
            }
        }
    }
    
    // 自动开始：播放老师语音，然后开始讨论
    private func autoStartDiscussion() {
        guard !hasAutoStarted else { return }
        hasAutoStarted = true
        
        initializeResourcesIfNeeded()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let manager = webSocketManager,
                  let recorder = recorderVM else { return }
            
            discussionHasEnded = false
            recorder.hasEnded = false
            manager.setPartBQuestions(paper?.partB ?? [])
            manager.setTopic(discussionExamText, participants: discussionParticipants)
            
            // 连接 WebSocket
            manager.connect()
            
            // 播放老师语音
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isTeacherSpeaking = true
                
                manager.playTeacherVoiceOnlyForAutoStart {
                    DispatchQueue.main.async {
                        isTeacherSpeaking = false
                        
                        withAnimation(.easeInOut(duration: 0.3)) {
                            Startdisucussion = false
                        }
                        manager.startDiscussionDirectly()
                        print("Teacher voice finished, discussion started directly")
                    }
                }
            }
        }
    }
    
    @MainActor
    private func generateDSEReportAndPresent() {
        guard let webSocketManager = webSocketManager else { return }
        
        isGeneratingDSEReport = true
        reportErrorMessage = nil
        
        let scoringInput = webSocketManager.buildCurrentDSEScoringInput()
        let messages = webSocketManager.chatMessages
        let partBResponses = webSocketManager.partBUserResponses
        let examText = discussionExamText
        
        DSEScoreCalculator().calculatePerformanceWithLLM(
            from: scoringInput,
            messages: messages,
            examText: examText,
            partBResponses: partBResponses
        ) { result in
            Task { @MainActor in
                switch result {
                case .success(let performance):
                    self.dsePerformance = performance
                    self.isGeneratingDSEReport = false
                    self.showDSEReport = true
                case .failure(let error):
                    self.dsePerformance = DSEScoreCalculator().calculatePerformance(from: scoringInput)
                    self.reportErrorMessage = error.localizedDescription
                    self.isGeneratingDSEReport = false
                    self.showDSEReport = true
                }
            }
        }
    }

    // MARK: - 测试专用方法：强制结束讨论
   /* private func forceEndDiscussionForTesting() {
        print("⚠️⚠️⚠️ 测试模式：强制结束讨论 ⚠️⚠️⚠️")
        
        // 震动反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 显示提示
        toastMessage = "测试模式：已强制结束讨论"
        showTestToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showTestToast = false
        }
        
        // 强制结束讨论
        discussionHasEnded = true
        webSocketManager?.stopDiscussion()
        recorderVM?.hasEnded = true
        
        // 发送结束通知
        NotificationCenter.default.post(name: NSNotification.Name("DiscussionEnded"), object: nil)
        
        // 自动弹出成绩报告
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if let recorder = recorderVM, recorder.mergedVideoURL == nil && recorder.segments.count > 0 {
                DispatchQueue.global(qos: .userInitiated).async {
                    _ = recorder.mergeAllSegments()
                }
            }
            generateDSEReportAndPresent()
        }
    }*/
    // MARK: - 测试专用方法：强制结束讨论（不自动弹出报告）
    private func forceEndDiscussionForTesting() {
        print("⚠️⚠️⚠️ 测试模式：强制结束讨论 ⚠️⚠️⚠️")
        
        // 震动反馈
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // 显示提示
        toastMessage = "讨论已强制结束，点击「成绩」查看报告"
        showTestToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showTestToast = false
        }
        
        // 强制结束讨论
        discussionHasEnded = true
        webSocketManager?.stopDiscussion()
        recorderVM?.hasEnded = true
        
        // 发送结束通知
        NotificationCenter.default.post(name: NSNotification.Name("DiscussionEnded"), object: nil)
        
        // 注意：这里不再自动弹出成绩报告，让用户手动点击成绩按钮
        // 只合成视频，但不弹出报告
        if let recorder = recorderVM, recorder.mergedVideoURL == nil && recorder.segments.count > 0 {
            DispatchQueue.global(qos: .userInitiated).async {
                _ = recorder.mergeAllSegments()
            }
        }
    }
    
    @State private var loadingAnimationOffset = 0
    private func startLoadingAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { _ in
            withAnimation {
                loadingAnimationOffset = (loadingAnimationOffset + 1) % 3
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let topBarHeight: CGFloat = 90
            let bottomBarHeight: CGFloat = 90
            let gridHeight = geometry.size.height - topBarHeight - bottomBarHeight - 10
            let itemWidth = geometry.size.width / 2
            let itemHeight = gridHeight / 2
            
            ZStack {
                VStack(spacing: 0) {
                    // MARK: - 顶部栏（倒计时区域 - 添加长按手势）
                    HStack(spacing: 0) {
                        // 返回按钮
                        Button(action: {
                            if let manager = webSocketManager, manager.isDiscussionActive {
                                manager.stopDiscussion()
                            }
                            dismiss()
                            onDismiss?()
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 20, weight: .semibold))
                        }
                        .frame(width: 50)
                        
                        // 波形图
                        if let micMonitor = micMonitor {
                            SoundChartView(micMonitor: micMonitor, isUserSpeaking: isAnySpeaking)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 4)
                        } else {
                            PreviewWaveformView(isAnimating: isAnySpeaking)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 4)
                        }
                        
                        // 倒计时 - ⚠️ 测试专用：长按3秒强制结束
                        Text(timeString(from: webSocketManager?.remainingTime ?? 480))
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor((webSocketManager?.remainingTime ?? 480) < 60 ? .red : Color("blackorwhitecolor"))
                            .monospacedDigit()
                            .frame(width: 70)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(longPressCount > 0 ? Color.red.opacity(0.2) : Color.clear)
                            )
                            .onTapGesture {
                                forceEndDiscussionForTesting()
                            }
                          
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 60)
                    .padding(.bottom, 20)
                    .frame(height: topBarHeight)
                    .background(Color("baiseanniucolor"))
                    
                    // MARK: - 网格区域
                    ZStack {
                        VStack(spacing: 0) {
                            HStack(spacing: 0) {
                                CandidateView(candidate: uiCandidates[0], isAISpeaking: isAITalking && getSpeakingCandidateId() == "A")
                                    .frame(width: itemWidth, height: itemHeight)
                                CandidateView(candidate: uiCandidates[1], isAISpeaking: isAITalking && getSpeakingCandidateId() == "B")
                                    .frame(width: itemWidth, height: itemHeight)
                            }
                            HStack(spacing: 0) {
                                CandidateView(candidate: uiCandidates[2], isAISpeaking: isAITalking && getSpeakingCandidateId() == "C")
                                    .frame(width: itemWidth, height: itemHeight)
                                CandidateView(candidate: uiCandidates[3], isAISpeaking: false)
                                    .frame(width: itemWidth, height: itemHeight)
                                    .background(Color.black)
                            }
                        }
                        .frame(height: gridHeight)
                        .blur(radius: showFuzhuView ? 5 : 0)
                        
                        // Teacher Icon 覆盖层
                        if Startdisucussion {
                            ZStack {
                                Rectangle()
                                    .fill(Color("UnSelectionColor"))
                                    .frame(height: gridHeight)
                                
                                VStack(spacing: 20) {
                                    Image("teachericon")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 120, height: 120)
                                        .background(
                                            Circle()
                                                .fill(Color.white)
                                                .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 5)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                        )
                                    
                                    HStack(spacing: 12) {
                                        ForEach(0..<3) { index in
                                            Circle()
                                                .frame(width: 10, height: 10)
                                                .foregroundColor(.gray)
                                                .scaleEffect(loadingAnimationOffset == index ? 1.4 : 0.7)
                                                .animation(
                                                    Animation.easeInOut(duration: 0.5)
                                                        .repeatForever()
                                                        .delay(Double(index) * 0.2),
                                                    value: loadingAnimationOffset
                                                )
                                        }
                                    }
                                    .padding(.top, 20)
                                    .onAppear {
                                        startLoadingAnimation()
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                VStack {
                                    Spacer()
                                    HStack {
                                        Text("Examiner")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gray)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.9))
                                                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            )
                                            .overlay(
                                                Capsule()
                                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                        Spacer()
                                    }
                                    .padding(.bottom, 20)
                                    .padding(.leading, 20)
                                }
                            }
                        }
                        
                        if showFuzhuView, let webSocketManager = webSocketManager {
                            FuzhuContentView(type: fuzhuViewType, onClose: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showFuzhuView = false
                                }
                            }, paper: paper, webSocketManager: webSocketManager, noteText: $noteText)
                            .frame(width: itemWidth * 2, height: gridHeight)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .zIndex(10)
                        }
                    }
                    .frame(height: gridHeight)
                    
                    // MARK: - 底部栏（2+1+2 对称布局）
                    HStack(spacing: 0) {
                        // 左侧两个按钮（字幕 + 卷子）
                        HStack(spacing: 28) {
                            // 1. 字幕
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    fuzhuViewType = .subtitle
                                    showFuzhuView = true
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "captions.bubble.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color("blackorwhitecolor"))
                                    Text("字幕")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("blackorwhitecolor"))
                                }
                                .frame(width: 50)
                            }
                            .buttonStyle(.plain)
                            
                            // 2. 试卷
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    fuzhuViewType = .test
                                    showFuzhuView = true
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "doc.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color("blackorwhitecolor"))
                                    Text("试题")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("blackorwhitecolor"))
                                }
                                .frame(width: 50)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 中间：圆形发言按钮
                        Button(action: {
                            guard let manager = webSocketManager else { return }
                            
                            if !manager.isDiscussionActive {
                                showCannotSpeakAlert = true
                            } else if manager.isAITalking {
                                showCannotSpeakAlert = true
                            } else if manager.isRecording {
                                manager.stopMicRecording()
                            } else if manager.canUserSpeak {
                                manager.startRecording()
                            } else {
                                showCannotSpeakAlert = true
                            }
                        }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(
                                            isRecording ?
                                            LinearGradient(
                                                colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.1)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ) :
                                            LinearGradient(
                                                colors: [Color(hex: "#667eea"), Color(hex: "#764ba2")],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: 60, height: 60)
                                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
                                    
                                    if isRecording {
                                        Image(systemName: "stop.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    } else if isAITalking {
                                        Image(systemName: "person.wave.2.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    } else {
                                        Image(systemName: "mic.fill")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Text(isRecording ? "停止说话" : (isAITalking ? (currentSpeakerName ?? "对方") + "讲话中..." : "开始发言"))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                        }
                        .buttonStyle(.plain)
                        
                        // 右侧两个按钮（笔记 + 成绩）
                        HStack(spacing: 28) {
                            // 3. 笔记
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    fuzhuViewType = .note
                                    showFuzhuView = true
                                }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color("blackorwhitecolor"))
                                    Text("稿纸")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("blackorwhitecolor"))
                                }
                                .frame(width: 50)
                            }
                            .buttonStyle(.plain)
                            
                            // 4. 成绩
                            Button(action: {
                                print("成绩按钮被点击，hasEnded = \(hasEnded)")
                                
                                guard hasEnded else {
                                    print("讨论未结束，显示提示")
                                    let generator = UINotificationFeedbackGenerator()
                                    generator.notificationOccurred(.warning)
                                    showDiscussionNotEndedAlert = true
                                    return
                                }
                                
                                print("讨论已结束，开始生成报告")
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                
                                if let recorder = recorderVM, recorder.mergedVideoURL == nil && recorder.segments.count > 0 {
                                    DispatchQueue.global(qos: .userInitiated).async {
                                        _ = recorder.mergeAllSegments()
                                    }
                                }
                                generateDSEReportAndPresent()
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 22, weight: .medium))
                                        .foregroundColor(Color("blackorwhitecolor"))
                                    Text("成绩")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(Color("blackorwhitecolor"))
                                }
                                .frame(width: 50)
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .frame(height: 88)
                    .background(Color("systemBackgroundColor"))
                    .overlay(
                        Rectangle()
                            .frame(height: 0.5)
                            .foregroundColor(Color(.separator)),
                        alignment: .top
                    )
                }
                
                // 录制指示器
              /* if isRecording {
                    VStack {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            Text("录制中...")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding(6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(12)
                        .padding(.top, 55)
                        .padding(.leading, 20)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }*/
                
                if isGeneratingDSEReport {
                    LoadingView()
                        .ignoresSafeArea()
                }
                // 测试提示 Toast
                if showTestToast {
                    VStack {
                        Spacer()
                        Text(toastMessage)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.8))
                            .cornerRadius(25)
                            .padding(.bottom, 120)
                        Spacer()
                    }
                    .transition(.opacity)
                    .zIndex(100)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarHidden(true)
        .ignoresSafeArea(.all)
        .onAppear {
            print("VideoCallView appeared")
            autoStartDiscussion()
        }
        .onDisappear {
            webSocketManager?.stopDiscussion()
            micMonitor?.stopMonitoring()
        }
        .alert("提示", isPresented: $showCannotSpeakAlert) {
            Button("确定", role: .cancel) { }
        } message: {
            if let manager = webSocketManager, !manager.isDiscussionActive {
                Text("讨论未开始，请稍候")
            } else if isAITalking {
                Text("其他人正在发言中，请稍后再试")
            } else {
                Text("当前无法发言，请稍后再试")
            }
        }
        .alert("提示", isPresented: $showDiscussionNotEndedAlert) {
            Button("好的", role: .cancel) { }
        } message: {
            Text("讨论尚未结束，请完成讨论后再查看成绩")
        }
        .fullScreenCover(isPresented: $showDSEReport) {
            if let videoURL = mergedVideoURL {
                DSEReportPage(
                    videoURL: videoURL,
                    performance: dsePerformance,
                    chatMessages: webSocketManager?.chatMessages ?? [],
                    preparationNote: noteText
                )
            } else {
                DSEReportPage(
                    videoURL: nil,
                    performance: dsePerformance,
                    chatMessages: webSocketManager?.chatMessages ?? [],
                    preparationNote: noteText
                )
            }
        }
        .fullScreenCover(isPresented: $showVideoPlayer) {
            if let url = mergedVideoURL {
                VideoPlayerView(url: url, title: "合成视频")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DiscussionEnded"))) { _ in
            print("收到 DiscussionEnded 通知")
            discussionHasEnded = true
            if let recorder = recorderVM {
                recorder.hasEnded = true
            }
        }
    }
}


/*
// MARK: - 预览
struct VideoCallView_Previews: PreviewProvider {
    static var previews: some View {
        VideoCallView().preferredColorScheme(.dark)
    }
}
*/


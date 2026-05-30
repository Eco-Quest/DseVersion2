//
//  TSAEnglishPracticeView.swift
//  dse_test
//
//  Created by Matt on 2026/5/25.
//

import SwiftUI
import Speech
import AVFoundation
import Combine

// 年级
enum TSAEnglishGrade: String, CaseIterable {
    case p3 = "小学三年级"
    case p6 = "小学六年级"
    
    var displayName: String { self.rawValue }
    var jsonKey: String {
        switch self {
        case .p3: return "小三"
        case .p6: return "小六"
        }
    }
}

// MARK: - 英文题型枚举（统一放在这里）
enum EnglishQuestionType: String, CaseIterable {
    case readAloud = "朗读与答问"
    case pictureAnswer = "看图答问"
    case readingInteraction = "朗读 + 师生互动"
    case presentation = "口头报告"
    
    var displayName: String { self.rawValue }
    
    var description: String {
        switch self {
        case .readAloud:
            return "朗读一篇短文，然后回答问题"
        case .pictureAnswer:
            return "观察图片，描述图片内容并回答问题"
        case .readingInteraction:
            return "朗读短文 + 师生互动问答"
        case .presentation:
            return "根据题目进行口头报告"
        }
    }
    
    var icon: String {
        switch self {
        case .readAloud: return "book.fill"
        case .pictureAnswer: return "photo.stack.fill"
        case .readingInteraction: return "bubble.left.and.bubble.right.fill"
        case .presentation: return "mic.fill"
        }
    }
    
    var preparationTime: Int {
        switch self {
        case .readAloud: return 120
        case .pictureAnswer: return 180
        case .readingInteraction: return 120
        case .presentation: return 180
        }
    }
    
    var speakingTime: Int {
        switch self {
        case .readAloud: return 180
        case .pictureAnswer: return 120
        case .readingInteraction: return 180
        case .presentation: return 120
        }
    }
    
    var timeDescription: String {
        switch self {
        case .readAloud:
            return "⏱️ 2分钟准备 + 3分钟作答"
        case .pictureAnswer:
            return "⏱️ 3分钟准备 + 2分钟作答"
        case .readingInteraction:
            return "⏱️ 2分钟准备 + 3分钟互动"
        case .presentation:
            return "⏱️ 3分钟准备 + 2分钟作答"
        }
    }
    
    var fullDescription: String {
        switch self {
        case .readAloud:
            return "全港性评估（TSA）英文口试（小三）朗读与答问部分共设2分钟准备时间及3分钟作答时间。学生需清晰朗读指定文章，并根据文章内容回答老师提问，以完整句子表达。"
        case .pictureAnswer:
            return "全港性评估（TSA）英文口试（小三）看图答问部分共设3分钟准备时间及2分钟作答时间。学生需仔细观察图片，描述图片内容，并回答老师提问。"
        case .readingInteraction:
            return "全港性评估（TSA）英文口试（小六）朗读与师生互动部分共设2分钟准备时间及3分钟互动时间。学生需清晰朗读文章，并与老师进行实时互动问答，表达个人观点。"
        case .presentation:
            return "全港性评估（TSA）英文口试（小六）口头报告部分共设3分钟准备时间及2分钟报告时间。学生需根据指定题目进行口头报告，清晰流畅地表达观点和想法。"
        }
    }
}

// 小三题型
enum TSAEnglishP3Type: String, CaseIterable {
    case readAloud = "朗读与答问"
    case pictureAnswer = "看图答问"
    
    var displayName: String { self.rawValue }
    
    var description: String {
        switch self {
        case .readAloud:
            return "朗读一篇短文，然后回答问题"
        case .pictureAnswer:
            return "观察图片，描述图片内容并回答问题"
        }
    }
    
    var icon: String {
        switch self {
        case .readAloud: return "book.fill"
        case .pictureAnswer: return "photo.stack.fill"
        }
    }
    
    var questionType: EnglishQuestionType {
        switch self {
        case .readAloud: return .readAloud
        case .pictureAnswer: return .pictureAnswer
        }
    }
}

// 小六题型
enum TSAEnglishP6Type: String, CaseIterable {
    case readingInteraction = "朗读 + 师生互动"
    case presentation = "口头报告"
    
    var displayName: String { self.rawValue }
    
    var description: String {
        switch self {
        case .readingInteraction:
            return "朗读短文 + 实时师生互动问答"
        case .presentation:
            return "根据题目进行口头报告"
        }
    }
    
    var icon: String {
        switch self {
        case .readingInteraction: return "bubble.left.and.bubble.right.fill"
        case .presentation: return "mic.fill"
        }
    }
    
    var questionType: EnglishQuestionType {
        switch self {
        case .readingInteraction: return .readingInteraction
        case .presentation: return .presentation
        }
    }
}

// MARK: - 英文 TSA 数据模型
struct EnglishTSAData: Codable {
    let 小三: Grade3Data
    let 小六: Grade6Data
}

struct Grade3Data: Codable {
    let read_aloud: ReadAloudItem
    let picture_answer: PictureAnswerItem
}

struct ReadAloudItem: Codable {
    let id: String
    let title: String
    let passage: String
    let questions: [String]
}

struct PictureAnswerItem: Codable {
    let id: String
    let title: String
    let image: String
    let instruction: String
    let questions: [PictureQuestion]
}

struct PictureQuestion: Codable {
    let question: String
    let pointTo: String
}

struct Grade6Data: Codable {
    let reading_interaction: ReadingInteractionItem
    let presentation: PresentationItem
}

struct ReadingInteractionItem: Codable {
    let id: String
    let title: String
    let passage: String
    let interaction_questions: [String]
}

struct PresentationItem: Codable {
    let id: String
    let title: String
    let instruction: String
    let helping_questions: [String]
}

// MARK: - 统一配置
struct EnglishStoryConfig {
    let grade: String
    let type: EnglishQuestionType
    let title: String
    let passage: String?
    let questions: [String]
    let pictureQuestions: [PictureQuestion]?
    let imageName: String?
    let pictureInstruction: String?
    let instruction: String?
    let id: String
}

// MARK: - 朗读与答问的阶段
enum ReadAloudStage {
    case reading
    case questioning
    
    var title: String {
        switch self {
        case .reading:
            return "Part 1: Reading Aloud"
        case .questioning:
            return "Part 2: Interactive Discussion"
        }
    }
    
    var instruction: String {
        switch self {
        case .reading:
            return "请清晰朗读下面的文章"
        case .questioning:
            return "与 AI 老师进行实时对话讨论"
        }
    }
}

// MARK: - 等级枚举
enum PerformanceLevel: String, Codable {
    case excellent = "优秀"
    case good = "良好"
    case average = "一般"
    case needsWork = "需加强"
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .average: return .orange
        case .needsWork: return .red
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .excellent: return .green.opacity(0.15)
        case .good: return .blue.opacity(0.15)
        case .average: return .orange.opacity(0.15)
        case .needsWork: return .red.opacity(0.15)
        }
    }
}

// MARK: - 英文 AI 报告数据模型
struct EnglishAIReportData: Codable {
    var score: Int
    let scoreReason: String
    let suggestions: [String]
    let encouragement: String
    let questionAnalysis: [EnglishQuestionAnalysis]
    let missingWords: [String]
    
    // 口头报告 & 朗读+互动 的分维度评分
    var contentLevel: PerformanceLevel?
    var languageLevel: PerformanceLevel?
    var organizationLevel: PerformanceLevel?
    var deliveryLevel: PerformanceLevel?
    var contentFeedback: String?
    var languageFeedback: String?
    var organizationFeedback: String?
    var deliveryFeedback: String?
    
    // 小六朗读+互动的互动分析
    var interactionAnalysis: [InteractionAnalysis]?
    
    // LLM 生成的参考范例（仅口头报告）
    var sampleScript: String?
    
    struct EnglishQuestionAnalysis: Codable {
        let questionNumber: Int
        let question: String
        let pointTo: String?
        let evaluation: String
        let sampleAnswer: String
        let hasPointTo: Bool?
    }
    
    struct InteractionAnalysis: Codable {
        let questionNumber: Int
        let question: String
        let studentAnswer: String
        let evaluation: String
        let sampleAnswer: String
    }
}

// MARK: - 互动消息模型
struct InteractiveMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    
    enum MessageRole {
        case teacher
        case student
        
        var displayName: String {
            switch self {
            case .teacher: return "老师"
            case .student: return "你"
            }
        }
    }
}

// MARK: - 互动聊天气泡
struct InteractiveChatBubble: View {
    let message: InteractiveMessage
    
    var body: some View {
        HStack {
            if message.role == .teacher {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "5C43A8"))
                        Text("老师")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .padding(12)
                        .background(Color(hex: "5C43A8").opacity(0.1))
                        .cornerRadius(16)
                }
                Spacer()
            } else {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(message.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        Text("你")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Image(systemName: "person.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(hex: "63BEF3"))
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .padding(12)
                        .background(Color(hex: "63BEF3").opacity(0.15))
                        .cornerRadius(16)
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - PCM 音频播放器
class PCMAudioPlayer1 {
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var pendingBuffers = 0
    var onPlaybackFinished: (() -> Void)?
    var currentPlayingVoice: String?
    
    private let remoteSampleRate: Double = 24000
    
    init() {
        setupAudioEngine()
    }
    
    private func setupAudioEngine() {
        DispatchQueue.main.async { [weak self] in
            self?.initializeAudioEngine()
        }
    }
    
    private func initializeAudioEngine() {
        if audioEngine != nil {
            cleanupAudioEngine()
        }
        
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        
        guard let audioEngine = audioEngine, let playerNode = playerNode else { return }
        
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: remoteSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            print("❌ PCM播放器：无法创建音频格式")
            return
        }
        
        audioFormat = format
        
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        
        configureAudioSessionForPlayback()
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            print("✅ PCM播放器：音频引擎启动成功")
        } catch {
            print("❌ PCM播放器：启动音频引擎失败: \(error)")
        }
    }
    
    private func configureAudioSessionForPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            print("❌ PCM播放器：音频会话配置失败: \(error)")
        }
    }
    
    private func cleanupAudioEngine() {
        playerNode?.stop()
        playerNode?.reset()
        audioEngine?.stop()
        audioEngine = nil
        playerNode = nil
        audioFormat = nil
        pendingBuffers = 0
    }
    
    func playPCMData(_ pcmData: Data, voice: String) {
        DispatchQueue.main.async { [weak self] in
            self?.performPlayPCMData(pcmData, voice: voice)
        }
    }
    
    private func performPlayPCMData(_ pcmData: Data, voice: String) {
        guard pcmData.count > 0 else { return }
        
        if playerNode == nil || audioFormat == nil {
            initializeAudioEngine()
            guard let playerNode = playerNode, let format = audioFormat else { return }
        }
        
        guard let playerNode = playerNode, let format = audioFormat else { return }
        
        currentPlayingVoice = voice
        pendingBuffers += 1
        
        if let audioEngine = audioEngine, !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                pendingBuffers -= 1
                return
            }
        }
        
        let frameCount = UInt32(pcmData.count / 2)
        if frameCount == 0 {
            pendingBuffers -= 1
            return
        }
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            pendingBuffers -= 1
            return
        }
        buffer.frameLength = frameCount
        
        pcmData.withUnsafeBytes { rawBufferPointer in
            guard let baseAddress = rawBufferPointer.baseAddress else { return }
            let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
            guard let floatChannelData = buffer.floatChannelData else { return }
            
            for i in 0..<Int(frameCount) {
                floatChannelData[0][i] = Float(int16Pointer[i]) / Float(Int16.max)
            }
        }
        
        playerNode.scheduleBuffer(buffer) { [weak self] in
            DispatchQueue.main.async {
                self?.pendingBuffers -= 1
                if self?.pendingBuffers == 0 {
                    self?.onPlaybackFinished?()
                }
            }
        }
        
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }
    
    func stop() {
        DispatchQueue.main.async { [weak self] in
            self?.performStop()
        }
    }
    
    private func performStop() {
        playerNode?.stop()
        playerNode?.reset()
        pendingBuffers = 0
        currentPlayingVoice = nil
    }
    
    deinit {
        cleanupAudioEngine()
    }
}

// MARK: - 实时互动管理器
class RealTimeInteractionManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var isAITalking = false
    @Published var isWaitingForResponse = false
    @Published var messages: [InteractiveMessage] = []
    @Published var currentTranscript = ""
    @Published var currentTeacherText = ""
    @Published var remainingTime: Int = 120
    @Published var isActive = false
    @Published var currentQuestionIndex = 0
    @Published var totalQuestions = 0
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var audioEngine: AVAudioEngine?
    private let audioPlayer = PCMAudioPlayer1()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var timer: Timer?
    private var responseTimeoutTimer: Timer?
    
    private let apiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    private let endpoint = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime"
    private let model = "qwen3-omni-flash-realtime"
    
    private var savedPassage: String = ""
    private var savedQuestions: [String] = []
    var waitingForAnswer = false
    private var isFirstMessage = true
    private var hasSentIntro = false
    private var processedMessageIds = Set<String>()
    private var lastMessageTime: Date?
    
    var onTeacherMessage: ((String) -> Void)?
    var onInteractionComplete: (() -> Void)?
    var onTimeUpdate: ((Int) -> Void)?
    var onQuestionProgress: ((Int, Int) -> Void)?
    
    override init() {
        super.init()
        setupAudioPlayerCallback()
        requestSpeechPermission()
    }
    
    private func setupAudioPlayerCallback() {
        audioPlayer.onPlaybackFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.handleTeacherFinishedSpeaking()
            }
        }
    }
    
    private func handleTeacherFinishedSpeaking() {
        DispatchQueue.main.async { [weak self] in
            self?.isAITalking = false
            if let self = self, self.isActive && self.remainingTime > 0 && self.waitingForAnswer {
                self.isWaitingForResponse = true
                self.startResponseTimeout()
            }
            self?.currentTeacherText = ""
        }
    }
    
    private func startResponseTimeout() {
        responseTimeoutTimer?.invalidate()
        responseTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                guard let self = self, self.isActive, self.waitingForAnswer, self.isWaitingForResponse else { return }
                self.isWaitingForResponse = false
                self.waitingForAnswer = false
                self.sendTeacherMessage("Do you have any thoughts about what we just discussed?")
            }
        }
    }
    
    private func cancelResponseTimeout() {
        responseTimeoutTimer?.invalidate()
        responseTimeoutTimer = nil
    }
    
    func startInteraction(passage: String, questions: [String]) {
        savedPassage = passage
        savedQuestions = questions
        totalQuestions = questions.count
        waitingForAnswer = false
        isFirstMessage = true
        hasSentIntro = false
        isActive = true
        remainingTime = 120
        messages.removeAll()
        currentTranscript = ""
        currentTeacherText = ""
        processedMessageIds.removeAll()
        lastMessageTime = nil
        
        connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            self.startTimer()
            self.isWaitingForResponse = false
            self.isAITalking = false
            self.waitingForAnswer = false
        }
    }
    
    func startDiscussion() {
        guard isActive, isConnected else { return }
        if hasSentIntro { return }
        hasSentIntro = true
        
        if !savedQuestions.isEmpty {
            let firstQuestion = savedQuestions[0]
            sendTeacherMessage(firstQuestion)
            currentQuestionIndex = 1
        }
    }
    
    func stopInteraction() {
        isActive = false
        waitingForAnswer = false
        isWaitingForResponse = false
        timer?.invalidate()
        timer = nil
        cancelResponseTimeout()
        stopListening()
        disconnect()
        onInteractionComplete?()
    }
    
    func reset() {
        processedMessageIds.removeAll()
        lastMessageTime = nil
        isConnected = false
        isRecording = false
        isAITalking = false
        isWaitingForResponse = false
        waitingForAnswer = false
        isActive = false
        hasSentIntro = false
    }
    
    private func endInteraction() {
        isActive = false
        isAITalking = false
        isWaitingForResponse = false
        waitingForAnswer = false
        cancelResponseTimeout()
        stopListening()
        stopInteraction()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.remainingTime > 0 {
                    self.remainingTime -= 1
                    self.onTimeUpdate?(self.remainingTime)
                    if self.remainingTime == 0 {
                        self.endInteraction()
                    }
                }
            }
        }
    }
    
    func connect() {
        var components = URLComponents(string: endpoint)
        components?.queryItems = [URLQueryItem(name: "model", value: model)]
        
        guard let url = components?.url else { return }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.sendSessionConfig()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
    }
    
    private func sendSessionConfig() {
        let instructions = """
        You are a professional English teacher for Hong Kong TSA oral practice.
        
        IMPORTANT RULES YOU MUST FOLLOW:
        1. ONLY ask the prepared questions I give you - DO NOT greet, DO NOT say hello
        2. DO NOT start conversation by yourself
        3. Keep responses SHORT (1 sentence only)
        4. Only speak about the passage content
        5. Wait for student answer before asking next question
        6. No extra comments, no encouragement during questions
        
        Passage for discussion: \(savedPassage)
        """
        
        let config: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "session.update",
            "session": [
                "modalities": ["text", "audio"],
                "voice": "Jennifer",
                "input_audio_format": "pcm",
                "output_audio_format": "pcm",
                "input_audio_transcription": ["enabled": true],
                "instructions": instructions,
                "turn_detection": [
                    "type": "server_vad",
                    "threshold": 0.5,
                    "prefix_padding_ms": 300,
                    "silence_duration_ms": 600
                ]
            ] as [String : Any]
        ]
        sendMessage(config)
    }
    
    func sendTeacherMessage(_ text: String) {
        let message = InteractiveMessage(
            role: .teacher,
            content: text,
            timestamp: Date()
        )
        
        DispatchQueue.main.async {
            self.messages.append(message)
            self.onTeacherMessage?(text)
        }
        
        sendTextMessage(text)
    }
    
    private func sendTextMessage(_ message: String) {
        isAITalking = true
        isWaitingForResponse = false
        currentTeacherText = message
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.createResponse()
        }
    }
    
    private func createResponse() {
        let responseMessage: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "response.create",
            "response": [
                "modalities": ["text", "audio"],
                "voice": "Jennifer",
                "output_audio_format": "pcm"
            ]
        ]
        sendMessage(responseMessage)
    }
    
    func startListening() {
        guard !isRecording && !isAITalking && isActive && remainingTime > 0 && isWaitingForResponse && waitingForAnswer else { return }
        
        #if targetEnvironment(simulator)
        return
        #endif
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        if audioEngine != nil {
            audioEngine?.stop()
            audioEngine?.inputNode.removeTap(onBus: 0)
            audioEngine = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
            isWaitingForResponse = false
        } catch {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                if let result = result {
                    self?.currentTranscript = result.bestTranscription.formattedString
                }
            }
        }
    }
    
    func forceStopListeningAndSend() {
        guard isRecording else { return }
        
        if let engine = audioEngine {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionTask?.cancel()
        
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        let studentResponse = currentTranscript.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !studentResponse.isEmpty {
            let message = InteractiveMessage(
                role: .student,
                content: studentResponse,
                timestamp: Date()
            )
            DispatchQueue.main.async {
                self.messages.append(message)
                self.onTeacherMessage?(studentResponse)
            }
            sendTextMessage(studentResponse)
            cancelResponseTimeout()
        } else if isActive && remainingTime > 0 && !isAITalking {
            isWaitingForResponse = true
        }
        
        currentTranscript = ""
    }
    
    func stopListening() {
        if isRecording {
            if let engine = audioEngine {
                engine.stop()
                engine.inputNode.removeTap(onBus: 0)
            }
            recognitionRequest?.endAudio()
            recognitionTask?.cancel()
            audioEngine = nil
            recognitionRequest = nil
            recognitionTask = nil
            isRecording = false
        }
    }
    
    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                print("语音识别授权状态: \(status.rawValue)")
            }
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        self?.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.handleMessage(text)
                        }
                    @unknown default:
                        break
                    }
                    self?.receiveMessage()
                case .failure(let error):
                    print("接收错误: \(error)")
                    self?.isConnected = false
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }
        
        switch type {
        case "session.created", "session.updated":
            isConnected = true
            
        case "response.audio.delta":
            if let audioBase64 = json["delta"] as? String,
               let audioData = Data(base64Encoded: audioBase64) {
                audioPlayer.playPCMData(audioData, voice: "Teacher")
            }
            
        case "response.audio_transcript.delta":
            if let transcript = json["transcript"] as? String {
                currentTeacherText += transcript
            } else if let delta = json["delta"] as? String {
                currentTeacherText += delta
            }
            
        case "response.audio_transcript.done":
            if let transcript = json["transcript"] as? String {
                let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    let now = Date()
                    
                    DispatchQueue.main.async {
                        let duplicate = self.messages.contains { msg in
                            msg.content == trimmed &&
                            msg.role == .teacher &&
                            now.timeIntervalSince(msg.timestamp) < 2.5
                        }
                        
                        if !duplicate {
                            let message = InteractiveMessage(
                                role: .teacher,
                                content: trimmed,
                                timestamp: now
                            )
                            self.messages.append(message)
                            self.onTeacherMessage?(trimmed)
                        }
                    }
                }
            }
            currentTeacherText = ""
            
        case "response.done":
            DispatchQueue.main.async {
                self.waitingForAnswer = true
            }
            
        default:
            break
        }
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("发送错误: \(error)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

extension RealTimeInteractionManager: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}

// MARK: - 互动对话视图
struct InteractionDiscussionView: View {
    let passage: String
    let questions: [String]
    let onComplete: (() -> Void)?
    
    @StateObject private var manager = RealTimeInteractionManager()
    @State private var scrollToBottom = false
    @State private var messages: [InteractiveMessage] = []
    @State private var hasStartedDiscussion = false
    @Environment(\.dismiss) private var dismiss
    
    private let themeLightColor = Color("ziselansecolor")
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: {
                    manager.stopInteraction()
                    manager.reset()
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                }
                .frame(width: 44)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("师生互动讨论")
                        .font(.system(size: 18, weight: .semibold))
                    
                    if manager.totalQuestions > 0 {
                        Text("对话进行中")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14))
                        .foregroundColor(manager.remainingTime < 60 ? .red : themeLightColor)
                    Text(timeString(from: manager.remainingTime))
                        .font(.system(size: 20, weight: .semibold, design: .monospaced))
                        .foregroundColor(manager.remainingTime < 60 ? .red : .primary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color("baiseanniucolor"))
                .cornerRadius(20)
            }
            .padding(.horizontal, 16)
            .padding(.top, 60)
            .padding(.bottom, 12)
            .background(Color("baiseanniucolor"))
            
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        if messages.isEmpty {
                            startPromptView
                        }
                        
                        ForEach(messages) { message in
                            InteractiveChatBubble(message: message)
                                .id(message.id)
                        }
                        
                        if manager.isAITalking && !manager.currentTeacherText.isEmpty {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "person.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(themeLightColor)
                                        Text("老师")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                        Text("正在输入...")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(manager.currentTeacherText)
                                        .font(.body)
                                        .padding(12)
                                        .background(themeLightColor.opacity(0.1))
                                        .cornerRadius(16)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .id("typing")
                        }
                        
                        if manager.isRecording {
                            HStack {
                                Spacer()
                                HStack(spacing: 8) {
                                    Image(systemName: "mic.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                    Text("录音中... 点击停止")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(20)
                            }
                            .padding(.horizontal, 16)
                            .id("recording")
                        }
                        
                        if manager.isRecording && !manager.currentTranscript.isEmpty {
                            HStack {
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    HStack(spacing: 6) {
                                        Text("识别中...")
                                            .font(.caption2)
                                            .foregroundColor(.gray)
                                        Text("你")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                    }
                                    Text(manager.currentTranscript)
                                        .font(.body)
                                        .padding(12)
                                        .background(Color(hex: "63BEF3").opacity(0.15))
                                        .cornerRadius(16)
                                }
                            }
                            .padding(.horizontal, 16)
                            .id("transcript")
                        }
                    }
                    .padding(.vertical, 16)
                }
                .onReceive(manager.$messages) { newMessages in
                    for msg in newMessages {
                        if !messages.contains(where: { $0.id == msg.id }) {
                            messages.append(msg)
                            scrollToBottom = true
                        }
                    }
                }
                .onChange(of: manager.isAITalking) { newValue in
                    if !newValue {
                        scrollToBottom = true
                    }
                }
                .onChange(of: scrollToBottom) { shouldScroll in
                    if shouldScroll, let lastId = messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                        DispatchQueue.main.async {
                            scrollToBottom = false
                        }
                    }
                }
            }
            
            HStack(spacing: 20) {
                Button(action: {
                    if manager.isRecording {
                        manager.forceStopListeningAndSend()
                    } else if !manager.isAITalking && manager.remainingTime > 0 && manager.isWaitingForResponse {
                        manager.startListening()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(manager.isRecording ? Color.red : (manager.isWaitingForResponse && !manager.isAITalking ? themeLightColor : Color.gray.opacity(0.5)))
                            .frame(width: 60, height: 60)
                            .shadow(color: .black.opacity(0.2), radius: 5)
                        
                        if manager.isRecording {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        } else if manager.isAITalking {
                            Image(systemName: "person.wave.2.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(!manager.isRecording && (manager.isAITalking || !manager.isWaitingForResponse))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if manager.isRecording && !manager.currentTranscript.isEmpty {
                        Text("当前: \(manager.currentTranscript)")
                            .font(.caption2)
                            .foregroundColor(.blue)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color("baiseanniucolor"))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator)),
                alignment: .top
            )
        }
        .background(Color("systemBackgroundColor"))
        .navigationBarHidden(true)
        .onAppear {
            manager.onTeacherMessage = { message in
                DispatchQueue.main.async {
                    let exists = messages.contains { $0.content == message && $0.role == .teacher }
                    if !exists {
                        let msg = InteractiveMessage(role: .teacher, content: message, timestamp: Date())
                        messages.append(msg)
                        scrollToBottom = true
                    }
                }
            }
            
            manager.onInteractionComplete = {
                DispatchQueue.main.async {
                    onComplete?()
                }
            }
            
            manager.startInteraction(passage: passage, questions: questions)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                if !hasStartedDiscussion && manager.isConnected {
                    hasStartedDiscussion = true
                    manager.startDiscussion()
                }
            }
        }
        .onDisappear {
            if manager.isActive {
                manager.stopInteraction()
            }
            manager.reset()
        }
    }
    
    private var startPromptView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(themeLightColor.opacity(0.6))
            
            Text("AI 老师准备就绪...")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("请稍后，讨论即将开始")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var statusText: String {
        if manager.isRecording {
            return "🎙️ 录音中... 点击红色按钮停止并发送"
        } else if manager.isAITalking {
            return "🤖 老师正在说话，请稍候..."
        } else if manager.isWaitingForResponse {
            return "🎤 轮到你了！点击麦克风开始回答"
        } else {
            return "📝 等待老师提问..."
        }
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - 音频播放组件
struct EnglishAudioPlaybackView: View {
    let audioURL: URL?
    let title: String
    
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    @State private var loadError = false
    @State private var isLoading = true
    @State private var errorMessage = ""
    
    private let themeColor = Color("SelectionColor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 8)
                    Text("加载音频中...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .onAppear {
                    setupAudioPlayer()
                }
            } else if loadError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else if let player = audioPlayer {
                HStack(spacing: 16) {
                    Button(action: {
                        HapticFeedbackManager.medium()
                        togglePlayback()
                    }) {
                        ZStack {
                            Circle()
                                .fill(themeColor.opacity(0.1))
                                .frame(width: 48, height: 48)
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 22))
                                .foregroundColor(themeColor)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 4)
                                    .cornerRadius(2)
                                
                                Rectangle()
                                    .fill(themeColor)
                                    .frame(width: geometry.size.width * CGFloat(currentTime / (duration > 0 ? duration : 1)), height: 4)
                                    .cornerRadius(2)
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                                        let newTime = duration * Double(percentage)
                                        currentTime = newTime
                                        audioPlayer?.currentTime = newTime
                                    }
                            )
                        }
                        .frame(height: 4)
                        
                        HStack {
                            Text(formatTime(currentTime))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(formatTime(duration))
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
                .onDisappear {
                    timer?.invalidate()
                    audioPlayer?.stop()
                    isPlaying = false
                }
            }
        }
        .onAppear {
            configureAudioSessionForPlayback()
        }
    }
    
    private func configureAudioSessionForPlayback() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("🎵 配置音频会话失败: \(error)")
        }
    }
    
    private func setupAudioPlayer() {
        guard let url = audioURL else {
            loadError = true
            errorMessage = "音频文件不存在"
            isLoading = false
            return
        }
        
        let fileManager = FileManager.default
        let fileExists = fileManager.fileExists(atPath: url.path)
        
        if !fileExists {
            loadError = true
            errorMessage = "找不到音频文件"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = nil
            duration = audioPlayer?.duration ?? 0
            loadError = false
            isLoading = false
        } catch {
            loadError = true
            errorMessage = "音频加载失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    private func togglePlayback() {
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
            isPlaying = false
        } else {
            if currentTime >= duration - 0.1 {
                audioPlayer?.currentTime = 0
                currentTime = 0
            }
            audioPlayer?.play()
            startTimer()
            isPlaying = true
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let player = audioPlayer else { return }
            currentTime = player.currentTime
            if !player.isPlaying && isPlaying {
                isPlaying = false
                timer?.invalidate()
            }
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - 等级标签视图
struct LevelBadge: View {
    let level: PerformanceLevel
    
    var body: some View {
        Text(level.rawValue)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(level.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(level.backgroundColor)
            .cornerRadius(12)
    }
}

// MARK: - 分维度评分卡片视图
struct DimensionScoreCard: View {
    let title: String
    let level: PerformanceLevel
    let feedback: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
                Spacer()
                LevelBadge(level: level)
            }
            
            Text(feedback)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color("baiseanniucolor"))
        .cornerRadius(12)
    }
}

// MARK: - 参考范例视图
struct SampleScriptView: View {
    let script: String
    @State private var isExpanded = false
    @State private var isCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 18))
                    Text("📖 参考范例（点击展开）")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.blue)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(script)
                        .font(.system(size: 14))
                        .lineSpacing(6)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    
                    Button(action: {
                        UIPasteboard.general.string = script
                        isCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            isCopied = false
                        }
                    }) {
                        HStack {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 14))
                            Text(isCopied ? "已复制" : "复制文本")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - 英文报告内容视图
struct EnglishReportContentView: View {
    let report: EnglishAIReportData
    let readingTranscript: String
    let originalPassage: String
    let questions: [String]
    let pictureQuestions: [PictureQuestion]?
    let passageTitle: String
    let userAudioURL: URL?
    let referenceAudioURL: URL?
    let onRestart: () -> Void
    let isPictureAnswer: Bool
    let isPresentation: Bool
    let isReadingInteraction: Bool  // 新增：是否为朗读+互动
    
    private let themeColor = Color("SelectionColor")
    private let themeLightColor = Color("ziselansecolor")
    
    private func highlightedPassage() -> AttributedString {
        var attributedString = AttributedString(originalPassage)
        let lowercasedTranscript = readingTranscript.lowercased()
        
        let words = originalPassage.split(separator: " ")
        
        for word in words {
            let wordString = String(word)
            let cleanWord = wordString.trimmingCharacters(in: .punctuationCharacters).lowercased()
            
            let isRead = lowercasedTranscript.contains(cleanWord)
            
            if !isRead && cleanWord.count > 2 {
                if let range = attributedString.range(of: wordString) {
                    attributedString[range].foregroundColor = .red
                    attributedString[range].font = .system(size: 17, weight: .bold)
                }
            }
        }
        
        return attributedString
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                scoreSection
                
                // 朗读+互动 和 口头报告 显示分维度评分
                if isReadingInteraction || isPresentation {
                    dimensionScoresSection
                }
                
                // 朗读原文区域（朗读与答问、朗读+互动需要显示）
                if !isPictureAnswer && !isPresentation {
                    readingPassageSection
                    referenceAudioSection
                    userAudioSection
                }
                
                // 问答分析（朗读与答问、看图答问需要显示）
                if !isPresentation && !report.questionAnalysis.isEmpty {
                    questionsAnalysisSection
                }
                
                // 互动分析（朗读+互动专用）
                if isReadingInteraction, let interactionAnalysis = report.interactionAnalysis, !interactionAnalysis.isEmpty {
                    interactionAnalysisSection(analysis: interactionAnalysis)
                }
                
                // 参考范例（口头报告专用）
                if isPresentation, let sampleScript = report.sampleScript, !sampleScript.isEmpty {
                    SampleScriptView(script: sampleScript)
                }
                
                suggestionsSection
                restartButton
            }
            .padding(20)
        }
        .background(Color("systemBackgroundColor"))
    }
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 6) {
            if isPresentation {
                Text("口头报告评估报告")
                    .font(.system(size: 26, weight: .bold))
            } else if isPictureAnswer {
                Text("看图答问评估报告")
                    .font(.system(size: 26, weight: .bold))
            } else if isReadingInteraction {
                Text("朗读与互动评估报告")
                    .font(.system(size: 26, weight: .bold))
            } else {
                Text("英文口试评估报告")
                    .font(.system(size: 26, weight: .bold))
            }
            Text(passageTitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var scoreSection: some View {
        VStack(spacing: 16) {
            ScoreRingView1(score: report.score)
            Text(report.scoreReason)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(Color("baiseanniucolor"))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private var dimensionScoresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text(isReadingInteraction ? "朗读表现评分" : "分维度评分")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            // 口头报告显示4个维度
            if isPresentation {
                if let contentLevel = report.contentLevel, let contentFeedback = report.contentFeedback {
                    DimensionScoreCard(
                        title: "内容 (Content)",
                        level: contentLevel,
                        feedback: contentFeedback,
                        icon: "doc.text.fill",
                        color: .blue
                    )
                }
                
                if let languageLevel = report.languageLevel, let languageFeedback = report.languageFeedback {
                    DimensionScoreCard(
                        title: "语言 (Language)",
                        level: languageLevel,
                        feedback: languageFeedback,
                        icon: "waveform.circle.fill",
                        color: .green
                    )
                }
                
                if let organizationLevel = report.organizationLevel, let organizationFeedback = report.organizationFeedback {
                    DimensionScoreCard(
                        title: "组织 (Organization)",
                        level: organizationLevel,
                        feedback: organizationFeedback,
                        icon: "list.bullet.rectangle.fill",
                        color: .orange
                    )
                }
                
                if let deliveryLevel = report.deliveryLevel, let deliveryFeedback = report.deliveryFeedback {
                    DimensionScoreCard(
                        title: "表达 (Delivery)",
                        level: deliveryLevel,
                        feedback: deliveryFeedback,
                        icon: "mic.circle.fill",
                        color: .purple
                    )
                }
            }
            // 朗读+互动显示2个维度（朗读表现 + 互动表现）
            else if isReadingInteraction {
                if let languageLevel = report.languageLevel, let languageFeedback = report.languageFeedback {
                    DimensionScoreCard(
                        title: "朗读表现 (Reading)",
                        level: languageLevel,
                        feedback: languageFeedback,
                        icon: "book.fill",
                        color: .green
                    )
                }
                
                if let deliveryLevel = report.deliveryLevel, let deliveryFeedback = report.deliveryFeedback {
                    DimensionScoreCard(
                        title: "互动表现 (Interaction)",
                        level: deliveryLevel,
                        feedback: deliveryFeedback,
                        icon: "bubble.left.and.bubble.right.fill",
                        color: .purple
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private var readingPassageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("朗读原文（红色标注为未读到的单词）")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            Text(highlightedPassage())
                .font(.system(size: 16))
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var referenceAudioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("参考朗读（标准发音）")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            EnglishAudioPlaybackView(audioURL: referenceAudioURL, title: "标准示范读音")
        }
    }
    
    @ViewBuilder
    private var userAudioSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "mic.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("你的录音")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            EnglishAudioPlaybackView(audioURL: userAudioURL, title: "你的朗读录音")
        }
    }
    
    @ViewBuilder
    private var questionsAnalysisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("问答分析")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            ForEach(report.questionAnalysis, id: \.questionNumber) { analysis in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("问题 \(analysis.questionNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeLightColor)
                        Spacer()
                    }
                    
                    Text(analysis.question)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.vertical, 4)
                    
                    Divider()
                    
                    Text("📝 评语：\(analysis.evaluation)")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                    
                    Text("💡 参考答案：\(analysis.sampleAnswer)")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
            }
        }
    }
    
    @ViewBuilder
    private func interactionAnalysisSection(analysis: [EnglishAIReportData.InteractionAnalysis]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("互动问答分析")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            ForEach(analysis, id: \.questionNumber) { item in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("问题 \(item.questionNumber)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(themeLightColor)
                        Spacer()
                    }
                    
                    Text(item.question)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .padding(.vertical, 4)
                    
                    Divider()
                    
                    Text("🗣️ 你的回答：\(item.studentAnswer)")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                    
                    Text("📝 评语：\(item.evaluation)")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    
                    Text("💡 参考回答：\(item.sampleAnswer)")
                        .font(.system(size: 13))
                        .foregroundColor(.orange)
                }
                .padding()
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
            }
        }
    }
    
    @ViewBuilder
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
                Text("改进建议")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                ForEach(report.suggestions.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(themeColor)
                            .clipShape(Circle())
                        Text(report.suggestions[index])
                            .font(.system(size: 14))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color("baiseanniucolor"))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var restartButton: some View {
        Button(action: {
            HapticFeedbackManager.medium()
            onRestart()
        }) {
            HStack {
                Image(systemName: "arrow.counterclockwise")
                Text("重新开始")
            }
            .font(.system(size: 17, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(themeColor)
            .cornerRadius(12)
        }
        .padding(.top, 5)
    }
}

// MARK: - 环形分数视图
struct ScoreRingView1: View {
    let score: Int
    private let themeColor = Color("SelectionColor")
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(themeColor, lineWidth: 12)
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: score)
            
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(themeColor)
                Text("分")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - 数据管理器
class EnglishStoryManager: ObservableObject {
    @Published var allData: EnglishTSAData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "english_tsa_data", withExtension: "json") else {
            errorMessage = "找不到 english_tsa_data.json 文件"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allData = try decoder.decode(EnglishTSAData.self, from: data)
            isLoading = false
        } catch {
            errorMessage = "JSON 解析失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func getP3ReadAloud() -> ReadAloudItem? {
        return allData?.小三.read_aloud
    }
    
    func getP3PictureAnswer() -> PictureAnswerItem? {
        return allData?.小三.picture_answer
    }
    
    func getP6ReadingInteraction() -> ReadingInteractionItem? {
        return allData?.小六.reading_interaction
    }
    
    func getP6Presentation() -> PresentationItem? {
        return allData?.小六.presentation
    }
}

// MARK: - 主视图
struct TSAEnglishPracticeView: View {
    let grade: String
    let questionType: EnglishQuestionType
    
    @State private var currentStage: Stage = .preparing
    @State private var readAloudStage: ReadAloudStage = .reading
    @State private var pictureQuestionStage: Bool = false
    @State private var timeRemaining = 180
    @State private var timer: Timer?
    
    @State private var isRecording = false
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    
    @State private var fullTranscript = ""
    @State private var readingTranscript = ""
    
    @State private var currentQuestionIndex = 0
    @State private var allQuestions: [String] = []
    @State private var allPictureQuestions: [PictureQuestion] = []
    @State private var userAnswers: [String] = []
    
    @State private var showReport = false
    @State private var isLoadingReport = false
    @State private var englishReport: EnglishAIReportData?
    @State private var referenceAudioURL: URL?
    
    // 互动模式专用
    @State private var showInteractionView = false
    @State private var savedPassage = ""
    @State private var savedQuestions: [String] = []
    @State private var interactionMessages: [InteractiveMessage] = []  // 保存互动对话
    
    @StateObject private var manager = EnglishStoryManager()
    @State private var storyConfig: EnglishStoryConfig?
    @State private var isLoadingStory = true
    
    private let themeColor = Color("SelectionColor")
    private let themeLightColor = Color("ziselansecolor")
    
    private let aliyunEndpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    private let aliyunApiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    
    enum Stage {
        case preparing, speaking, finished
    }
    
    init(grade: String, questionType: EnglishQuestionType) {
        self.grade = grade
        self.questionType = questionType
    }
    
    var body: some View {
        ZStack {
            if showInteractionView {
                InteractionDiscussionView(
                    passage: savedPassage,
                    questions: savedQuestions
                ) {
                    showInteractionView = false
                    finishPractice()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("InteractionMessages"))) { notification in
                    if let messages = notification.userInfo?["messages"] as? [InteractiveMessage] {
                        self.interactionMessages = messages
                    }
                }
            } else if showReport {
                if isLoadingReport {
                    loadingReportView
                } else if let report = englishReport {
                    EnglishReportContentView(
                        report: report,
                        readingTranscript: readingTranscript,
                        originalPassage: storyConfig?.passage ?? "",
                        questions: allQuestions,
                        pictureQuestions: allPictureQuestions.isEmpty ? nil : allPictureQuestions,
                        passageTitle: storyConfig?.title ?? "英文口试",
                        userAudioURL: recordingURL,
                        referenceAudioURL: referenceAudioURL,
                        onRestart: resetAll,
                        isPictureAnswer: questionType == .pictureAnswer,
                        isPresentation: questionType == .presentation,
                        isReadingInteraction: questionType == .readingInteraction
                    )
                }
            } else if manager.isLoading || isLoadingStory {
                loadingView
            } else if let error = manager.errorMessage {
                errorView(error: error)
            } else if let config = storyConfig {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        stageStatusView
                        Divider()
                        studentNoticeView(config: config)
                        
                        if let passage = config.passage,
                           (config.type == .readAloud || config.type == .readingInteraction),
                           readAloudStage == .reading {
                            passageView(passage: passage)
                        }
                        
                        if config.type == .readAloud && readAloudStage == .questioning && currentQuestionIndex < allQuestions.count {
                            questionsView
                        }
                        
                        if let imageName = config.imageName, config.type == .pictureAnswer {
                            pictureInstructionView(imageName: imageName, instruction: config.pictureInstruction)
                        }
                        
                        if config.type == .pictureAnswer && pictureQuestionStage && currentQuestionIndex < allPictureQuestions.count {
                            pictureQuestionsView
                        }
                        
                        if config.type == .presentation {
                            instructionView(instruction: config.instruction ?? "")
                            
                            if !config.questions.isEmpty {
                                helpingQuestionsView(questions: config.questions)
                            }
                        }
                        
                        Divider()
                        actionButton
                        Spacer(minLength: 20)
                    }
                    .padding(20)
                }
                .background(Color("systemBackgroundColor"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    HapticFeedbackManager.medium()
                    if showReport {
                        resetAll()
                    } else {
                        dismiss()
                    }
                }) {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "chevron.left")
                    } else {
                        ZStack {
                            Circle()
                                .fill(Color("baiseanniucolor"))
                                .frame(width: 30, height: 30)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            Image(systemName: "chevron.left")
                                .font(.body.weight(.medium))
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            
            if !showReport && !showInteractionView && (currentStage == .preparing || currentStage == .speaking) {
                ToolbarItem(placement: .principal) {
                    Text(grade == "小三" ? "小三 TSA 英文口试" : "小六 TSA 英文口试")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Image(systemName: currentStage == .preparing ? "clock" : "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeLightColor)
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(themeLightColor)
                    }
                }
            } else if !showReport && !showInteractionView {
                ToolbarItem(placement: .principal) {
                    Text(grade == "小三" ? "小三 TSA 英文口试" : "小六 TSA 英文口试")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
        }
        .onAppear {
            requestSpeechPermission()
            setupAudioSession()
            loadConfig()
        }
        .onDisappear {
            stopRecording()
            timer?.invalidate()
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - 视图组件
    @ViewBuilder
    var questionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Question \(currentQuestionIndex + 1) of \(allQuestions.count)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeLightColor)
            
            Text(allQuestions[currentQuestionIndex])
                .font(.system(size: 20, weight: .medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 30)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("baiseanniucolor"))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(themeLightColor.opacity(0.3), lineWidth: 1)
                )
        }
    }
    
    @ViewBuilder
    var pictureQuestionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Question \(currentQuestionIndex + 1) of \(allPictureQuestions.count)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(themeLightColor)
            
            VStack(alignment: .leading, spacing: 12) {
                Text(allPictureQuestions[currentQuestionIndex].question)
                    .font(.system(size: 20, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color("baiseanniucolor"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(themeLightColor.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    @ViewBuilder
    func pictureInstructionView(imageName: String, instruction: String?) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let instruction = instruction, !instruction.isEmpty {
                Text(instruction)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.clear)
            }
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(height: 250)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .overlay(
                    Group {
                        if let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 250)
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray)
                                Text("图片示例")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                )
        }
    }
    
    @ViewBuilder
    func instructionView(instruction: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 20))
                Text("题目说明")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            Text(instruction)
                .font(.system(size: 15))
                .lineSpacing(5)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    func helpingQuestionsView(questions: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 20))
                Text("提示问题")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(questions.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(index + 1).")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(themeLightColor)
                        Text(questions[index])
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color("baiseanniucolor"))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    func passageView(passage: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 20))
                Text("朗读文章")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            Text(passage)
                .font(.system(size: 17))
                .lineSpacing(6)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    func studentNoticeView(config: EnglishStoryConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("📋 学生须知：")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            switch config.type {
            case .readAloud:
                Text("Part 1: 请清晰朗读下面的文章。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("Part 2: 老师会提问，请用完整句子回答问题。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
                
            case .readingInteraction:
                Text("Part 1: 请清晰朗读下面的文章（1分钟）。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("Part 2: 与 AI 老师进行实时互动讨论（2分钟），回答老师的问题并表达个人观点。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
                
            case .pictureAnswer:
                Text("Part 1: 请仔细观察图片（3分钟）。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("Part 2: 老师会提问，请用完整句子回答问题（2分钟）。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
                
            case .presentation:
                Text("1. 你有 2 分钟时间进行口头报告。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("2. 使用下面的提示问题来组织你的报告内容。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("3. 准备时间结束后，点击「开始作答」并对着麦克风说话。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    var stageStatusView: some View {
        VStack(spacing: 12) {
            let title: String = {
                switch currentStage {
                case .preparing: return "准备阶段"
                case .speaking:
                    if config?.type == .readAloud {
                        return readAloudStage.title
                    } else if config?.type == .pictureAnswer {
                        if pictureQuestionStage {
                            return "Part 2: Answering Questions"
                        } else {
                            return "Part 1: Study the Picture"
                        }
                    } else if config?.type == .readingInteraction {
                        return readAloudStage.title
                    }
                    return "作答阶段"
                case .finished: return "报告"
                }
            }()
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeLightColor)
            
            if currentStage == .preparing {
                if questionType == .pictureAnswer {
                    Text("你有 3 分钟时间观察图片")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else {
                    Text("你有 \(questionType.preparationTime / 60) 分钟时间准备")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            } else if currentStage == .speaking {
                if config?.type == .readAloud && readAloudStage == .reading {
                    Text("请清晰朗读文章")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else if config?.type == .readingInteraction && readAloudStage == .reading {
                    Text("请清晰朗读文章（1分钟）")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else if config?.type == .readAloud && readAloudStage == .questioning {
                    Text("请回答老师的问题")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else if config?.type == .readingInteraction && readAloudStage == .questioning {
                    Text("与 AI 老师进行实时互动讨论（2分钟）")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else if config?.type == .pictureAnswer && !pictureQuestionStage {
                    Text("请仔细观察图片")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else if config?.type == .pictureAnswer && pictureQuestionStage {
                    Text("请回答老师的问题（2分钟）")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                } else {
                    let timeText = (questionType == .presentation) ? "2分钟" : "1分钟"
                    Text("你有 \(timeText) 时间完成作答")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color("baiseanniucolor"))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    var actionButton: some View {
        if questionType == .presentation && currentStage == .speaking {
            VStack(spacing: 16) {
                Text(actionButtonText)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(themeLightColor)
                    .cornerRadius(14)
                    .onTapGesture {
                        HapticFeedbackManager.medium()
                        handleNextAction()
                    }
                
                Text("提前结束发言")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                   
                   
                    .onTapGesture {
                        HapticFeedbackManager.medium()
                        finishPractice()
                    }
            }
            .padding(.horizontal, 5)
        } else {
            Text(actionButtonText)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(themeLightColor)
                .cornerRadius(14)
                .onTapGesture {
                    HapticFeedbackManager.medium()
                    if currentStage == .preparing {
                        skipToSpeaking()
                    } else if currentStage == .speaking {
                        handleNextAction()
                    }
                }
                .padding(.horizontal, 5)
        }
    }
    
    var actionButtonText: String {
        if currentStage == .preparing {
            return "跳过准备阶段"
        } else if currentStage == .speaking {
            if config?.type == .readAloud {
                if readAloudStage == .reading {
                    return "进入问答环节"
                } else if readAloudStage == .questioning {
                    if currentQuestionIndex < allQuestions.count - 1 {
                        return "下一题"
                    } else {
                        return "完成考试"
                    }
                }
            } else if config?.type == .readingInteraction {
                if readAloudStage == .reading {
                    return "进入互动讨论"
                } else if readAloudStage == .questioning {
                    return "进行中..."
                }
            } else if config?.type == .pictureAnswer {
                if currentQuestionIndex < allPictureQuestions.count - 1 {
                    return "下一题"
                } else {
                    return "完成考试"
                }
            }
            return isRecording ? "正在讲话..." : "开始作答"
        }
        return "完成"
    }
    
    // MARK: - 核心逻辑
    private func loadReferenceAudio(for id: String) {
        let formats = ["mp3", "m4a", "wav", "caf"]
        for format in formats {
            if let audioPath = Bundle.main.path(forResource: id, ofType: format) {
                referenceAudioURL = URL(fileURLWithPath: audioPath)
                return
            }
        }
    }
    
    private func loadConfig() {
        isLoadingStory = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            switch questionType {
            case .readAloud:
                if let item = manager.getP3ReadAloud() {
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .readAloud,
                        title: item.title,
                        passage: item.passage,
                        questions: item.questions,
                        pictureQuestions: nil,
                        imageName: nil,
                        pictureInstruction: nil,
                        instruction: nil,
                        id: item.id
                    )
                    allQuestions = item.questions
                    loadReferenceAudio(for: item.id)
                }
                
            case .pictureAnswer:
                if let item = manager.getP3PictureAnswer() {
                    let questionStrings = item.questions.map { $0.question }
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .pictureAnswer,
                        title: item.title,
                        passage: nil,
                        questions: questionStrings,
                        pictureQuestions: item.questions,
                        imageName: item.image,
                        pictureInstruction: item.instruction,
                        instruction: nil,
                        id: item.id
                    )
                    allPictureQuestions = item.questions
                    allQuestions = questionStrings
                }
                
            case .readingInteraction:
                if let item = manager.getP6ReadingInteraction() {
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .readingInteraction,
                        title: item.title,
                        passage: item.passage,
                        questions: item.interaction_questions,
                        pictureQuestions: nil,
                        imageName: nil,
                        pictureInstruction: nil,
                        instruction: nil,
                        id: item.id
                    )
                    allQuestions = item.interaction_questions
                    savedPassage = item.passage
                    savedQuestions = item.interaction_questions
                    loadReferenceAudio(for: item.id)
                }
                
            case .presentation:
                if let item = manager.getP6Presentation() {
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .presentation,
                        title: item.title,
                        passage: nil,
                        questions: item.helping_questions,
                        pictureQuestions: nil,
                        imageName: nil,
                        pictureInstruction: nil,
                        instruction: item.instruction,
                        id: item.id
                    )
                    allQuestions = item.helping_questions
                }
            }
            
            isLoadingStory = false
            startPreparing()
        }
    }
    
    private func handleNextAction() {
        if config?.type == .readAloud {
            if readAloudStage == .reading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.readingTranscript = self.fullTranscript
                    self.stopRecording()
                    self.readAloudStage = .questioning
                    self.currentQuestionIndex = 0
                    self.userAnswers = []
                    self.fullTranscript = ""
                    self.startTimerForQuestioning()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.startRecording()
                        self.startRecordingToFile()
                    }
                }
            } else if readAloudStage == .questioning {
                handleQuestionNext()
            }
        } else if config?.type == .readingInteraction {
            if readAloudStage == .reading {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.readingTranscript = self.fullTranscript
                    self.stopRecording()
                    self.stopRecordingToFile()
                    self.readAloudStage = .questioning
                    self.showInteractionView = true
                }
            }
        } else if config?.type == .pictureAnswer {
            handlePictureQuestionNext()
        } else {
            if !isRecording {
                startRecording()
                startRecordingToFile()
            }
        }
    }
    
    private func handleQuestionNext() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let currentAnswer = self.fullTranscript
            self.userAnswers.append(currentAnswer)
            self.stopRecording()
            self.stopRecordingToFile()
            self.fullTranscript = ""
            
            if self.currentQuestionIndex + 1 < self.allQuestions.count {
                self.currentQuestionIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startRecording()
                    self.startRecordingToFile()
                }
            } else {
                self.finishPractice()
            }
        }
    }
    
    private func handlePictureQuestionNext() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let currentAnswer = self.fullTranscript
            self.userAnswers.append(currentAnswer)
            self.stopRecording()
            self.stopRecordingToFile()
            self.fullTranscript = ""
            
            if self.currentQuestionIndex + 1 < self.allPictureQuestions.count {
                self.currentQuestionIndex += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.startRecording()
                    self.startRecordingToFile()
                }
            } else {
                self.finishPractice()
            }
        }
    }
    
    private func startTimerForQuestioning() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                if self.readAloudStage == .questioning {
                    let currentAnswer = self.fullTranscript
                    if !currentAnswer.isEmpty {
                        self.userAnswers.append(currentAnswer)
                    }
                    self.finishPractice()
                } else {
                    self.finishPractice()
                }
            }
        }
    }
    
    private func performAIAnalysis() {
        isLoadingReport = true
        
        let missingWords = findMissingWords()
        
        // 构建互动对话记录（用于朗读+互动）
        var interactionQA: [(question: String, answer: String)] = []
        if questionType == .readingInteraction && !interactionMessages.isEmpty {
            var currentQuestion = ""
            for msg in interactionMessages {
                if msg.role == .teacher {
                    currentQuestion = msg.content
                } else if msg.role == .student && !currentQuestion.isEmpty {
                    interactionQA.append((question: currentQuestion, answer: msg.content))
                    currentQuestion = ""
                }
            }
        }
        
        let qaRecords: String
        if questionType == .presentation {
            qaRecords = "【学生报告内容】\n\(fullTranscript)"
        } else if questionType == .readingInteraction && !interactionQA.isEmpty {
            qaRecords = interactionQA.enumerated().map {
                "Q\($0.offset + 1): \($0.element.question)\nA: \($0.element.answer)"
            }.joined(separator: "\n\n")
        } else if questionType == .pictureAnswer && !allPictureQuestions.isEmpty {
            qaRecords = zip(allPictureQuestions, userAnswers).map {
                "Q: \($0.0.question)\nPoint to: \($0.0.pointTo)\nA: \($0.1)"
            }.joined(separator: "\n\n")
        } else {
            qaRecords = zip(allQuestions, userAnswers).map { "Q: \($0.0)\nA: \($0.1)" }.joined(separator: "\n\n")
        }
        
        let pictureSpecificPrompt = questionType == .pictureAnswer ? """
        
        【特别说明 - TSA看图答问评分标准】
        每个问题都包含一个"Point to"指向说明，用于评估学生是否理解问题并指向正确的人物/物体。
        请在评估时注意学生是否准确回答了问题，评语中可以提及指向是否正确。
        """ : ""
        
        let readingInteractionPrompt = questionType == .readingInteraction ? """
        
        【特别说明 - TSA小六朗读+互动评分标准】
        请分析学生的朗读和互动表现：
        
        1. 朗读表现 (Reading) - 评估发音、流畅度、准确度
           - 优秀：发音标准，朗读流畅，准确度高
           - 良好：发音基本标准，较流畅
           - 一般：有较多发音错误，不够流畅
           - 需加强：发音混乱，无法流畅朗读
        
        2. 互动表现 (Interaction) - 评估理解能力、回应质量、表达清晰度
           - 优秀：完全理解问题，回应恰当，表达清晰
           - 良好：基本理解问题，回应相关
           - 一般：部分理解问题，回应不完整
           - 需加强：不理解问题，无法回应
        
        请为两个维度评级，并给出简短的评语。
        
        同时，为每个互动问题给出详细分析（问题内容、学生回答、评语、参考回答）。
        """ : ""
        
        let presentationPrompt = questionType == .presentation ? """
        
        【特别说明 - TSA小六口头报告评分标准】
        请按照以下标准对学生的报告进行分维度评级（等级：优秀/良好/一般/需加强）：
        
        1. 内容 (Content) - 满分40分
           - 优秀(32-40分)：围绕题目展开，有地点、交通、人物、商店，有个人观点
           - 良好(24-31分)：围绕题目，有部分细节
           - 一般(16-23分)：部分离题，细节不足
           - 需加强(0-15分)：严重离题或无观点
        
        2. 语言 (Language) - 满分30分
           - 优秀(24-30分)：语法正确，词汇丰富，句子完整
           - 良好(18-23分)：少量语法错误，词汇恰当
           - 一般(12-17分)：较多语法错误，词汇有限
           - 需加强(0-11分)：语法混乱，词汇匮乏
        
        3. 组织 (Organization) - 满分20分
           - 优秀(16-20分)：有清晰开头、主体、结尾
           - 良好(12-15分)：结构基本完整
           - 一般(8-11分)：结构松散
           - 需加强(0-7分)：没有结构
        
        4. 表达 (Delivery) - 满分10分
           - 优秀(8-10分)：发音清晰，语速适中，有自信
           - 良好(6-7分)：发音基本清晰
           - 一般(4-5分)：发音不清，语速过快或过慢
           - 需加强(0-3分)：无法听清
        
        请为每个维度评级，并给出简短的评语。
        
        同时，请根据学生的报告内容，生成一个「改进范例」（sampleScript），展示如何更好地完成这个口头报告。
        范例应该包含完整的报告内容（约200-300词），结构清晰（开头-主体-结尾），语法正确。
        """ : ""
        
        let prompt = """
        你是一个专业的英文老师，熟悉香港TSA英文口试评估标准。
        
        请分析学生的表现，并以JSON格式返回结果。
        
        \(questionType == .presentation ? "【报告题目】\n\(storyConfig?.instruction ?? "")" : "【朗读内容】\n\(readingTranscript)")
        
        【问答记录】
        \(qaRecords)
        \(pictureSpecificPrompt)
        \(readingInteractionPrompt)
        \(presentationPrompt)
        
        【返回格式要求】
        必须严格按照以下JSON格式返回：
        {
            "score": 85,
            "scoreReason": "能够围绕题目进行报告，表达清晰流畅",
            "suggestions": ["建议1", "建议2", "建议3"],
            "encouragement": "鼓励的话（用中文）",
            "missingWords": [],
            \(questionType == .presentation ? """
            "contentLevel": "优秀",
            "languageLevel": "良好",
            "organizationLevel": "良好",
            "deliveryLevel": "优秀",
            "contentFeedback": "内容相关性强，提到了多个地点和交通工具，有个人观点",
            "languageFeedback": "语法基本正确，词汇丰富，句子完整",
            "organizationFeedback": "结构清晰，有明确的开头、主体和结尾",
            "deliveryFeedback": "发音清晰，语速适中，表现自信",
            "sampleScript": "这是一个完整的2分钟报告范例...",
            """ : (questionType == .readingInteraction ? """
            "languageLevel": "良好",
            "deliveryLevel": "良好",
            "languageFeedback": "朗读流畅，发音基本标准",
            "deliveryFeedback": "能够理解问题并做出回应",
            "interactionAnalysis": [
                {
                    "questionNumber": 1,
                    "question": "老师问的问题",
                    "studentAnswer": "学生的回答",
                    "evaluation": "对回答的评语",
                    "sampleAnswer": "参考回答"
                }
            ],
            """ : """
            "questionAnalysis": [
                {
                    "questionNumber": 1,
                    "question": "问题内容",
                    "pointTo": "指向说明（如果有）",
                    "evaluation": "对回答的评价（用中文）",
                    "sampleAnswer": "参考答案（完整句子的英文）",
                    "hasPointTo": true/false
                }
            ]
            """))
            \(questionType == .presentation ? "" : "")
        }
        
        注意：
        1. 等级必须是以下之一：优秀、良好、一般、需加强
        2. \(questionType == .presentation ? "sampleScript 必须是英文，约200-300词" : "")
        """
        
        callAIAPI(with: prompt)
    }
    
    private func findMissingWords() -> [String] {
        guard let passage = storyConfig?.passage else { return [] }
        let originalWords = passage.lowercased().split(separator: " ").map(String.init)
        let transcriptWords = readingTranscript.lowercased().split(separator: " ").map(String.init)
        
        var missing: [String] = []
        for word in originalWords {
            let cleanWord = word.trimmingCharacters(in: .punctuationCharacters)
            if cleanWord.count > 2 && !transcriptWords.contains(where: { $0.contains(cleanWord) }) {
                if !missing.contains(cleanWord) {
                    missing.append(cleanWord)
                }
            }
        }
        return missing
    }
    
    private func callAIAPI(with prompt: String) {
        guard let url = URL(string: aliyunEndpoint) else {
            useFallbackReport()
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(aliyunApiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let requestBody: [String: Any] = [
            "model": "qwen-plus",
            "messages": [
                ["role": "system", "content": "你是一个专业的英文老师，熟悉香港TSA评估标准。只返回纯JSON格式，不要有任何其他解释文字。"],
                ["role": "user", "content": prompt]
            ],
            "stream": false,
            "temperature": 0.5,
            "max_tokens": 3000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            useFallbackReport()
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("网络错误：\(error)")
                    self.useFallbackReport()
                    return
                }
                
                guard let data = data else {
                    self.useFallbackReport()
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let choices = json["choices"] as? [[String: Any]],
                       let message = choices.first?["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        
                        let cleanContent = content
                            .replacingOccurrences(of: "```json", with: "")
                            .replacingOccurrences(of: "```", with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if let jsonStart = cleanContent.firstIndex(of: "{"),
                           let jsonEnd = cleanContent.lastIndex(of: "}") {
                            let jsonString = String(cleanContent[jsonStart...jsonEnd])
                            
                            if let jsonData = jsonString.data(using: .utf8) {
                                var report = try JSONDecoder().decode(EnglishAIReportData.self, from: jsonData)
                                report.score = min(max(report.score, 0), 100)
                                
                                // 转换等级字符串为枚举
                                if let contentLevelStr = report.contentLevel?.rawValue {
                                    report.contentLevel = PerformanceLevel(rawValue: contentLevelStr)
                                }
                                if let languageLevelStr = report.languageLevel?.rawValue {
                                    report.languageLevel = PerformanceLevel(rawValue: languageLevelStr)
                                }
                                if let organizationLevelStr = report.organizationLevel?.rawValue {
                                    report.organizationLevel = PerformanceLevel(rawValue: organizationLevelStr)
                                }
                                if let deliveryLevelStr = report.deliveryLevel?.rawValue {
                                    report.deliveryLevel = PerformanceLevel(rawValue: deliveryLevelStr)
                                }
                                
                                self.englishReport = report
                                self.isLoadingReport = false
                                return
                            }
                        }
                    }
                    self.useFallbackReport()
                } catch {
                    print("解析错误：\(error)")
                    self.useFallbackReport()
                }
            }
        }.resume()
    }
    
    // MARK: - 辅助函数（放在 useFallbackReport 之前）

    private func getSampleAnswer(for question: String, pointTo: String) -> String {
        let lowerQuestion = question.lowercased()
        
        if lowerQuestion.contains("what does the woman want to bring") {
            return "The woman wants to bring a dog onto the bus."
        } else if lowerQuestion.contains("what does the driver say") {
            return "The driver says that dogs are not allowed on the bus."
        } else if lowerQuestion.contains("why is this girl so happy") {
            return "The girl is happy because she is listening to her favourite music."
        } else if lowerQuestion.contains("how does this man feel") {
            return "The man feels annoyed because the music is too loud."
        } else if lowerQuestion.contains("what is this boy doing") {
            return "The boy is reading a book."
        } else if lowerQuestion.contains("what is this girl doing") {
            return "The girl is offering her seat to the old man."
        } else if lowerQuestion.contains("is it good to do that") {
            return "Yes, it is good because helping others is important."
        } else if lowerQuestion.contains("what does this man say to the girl") {
            return "The old man says thank you to the girl."
        } else if lowerQuestion.contains("do you love") {
            return "Yes, I love my summer holidays very much because I can do many interesting things."
        } else if lowerQuestion.contains("what do you do") {
            return "I go swimming and go to the library with my brother."
        } else if lowerQuestion.contains("what transport") || lowerQuestion.contains("take") {
            return "I usually take the MTR because it is fast and convenient."
        } else if lowerQuestion.contains("where do you see") {
            return "I see busy roads in Mong Kok, Causeway Bay, and Central."
        } else if lowerQuestion.contains("who do you see") {
            return "I see office workers, students, and elderly people."
        } else if lowerQuestion.contains("how do you cross") {
            return "I use the zebra crossing and look left, right, then left again."
        } else if lowerQuestion.contains("do you like walking") {
            return "I don't really like walking along a busy road because it is too noisy and crowded."
        }
        return "That's a good question. I think you should answer it with a complete sentence."
    }

    private func useFallbackReport() {
        let missingWords = findMissingWords()
        var score = 0
        let answeredCount = userAnswers.filter { !$0.isEmpty }.count
        
        // 检测是否有任何有效回答（包括朗读和问答）
        let hasAnyRecording = readingTranscript.count > 0 || fullTranscript.count > 0 || answeredCount > 0 || !interactionMessages.isEmpty
        
        // 如果是口头报告但没有录音内容
        if questionType == .presentation && fullTranscript.isEmpty {
            score = 0
        }
        // 如果是朗读+互动但没有朗读内容也没有互动消息
        else if questionType == .readingInteraction && readingTranscript.isEmpty && interactionMessages.isEmpty {
            score = 0
        }
        // 如果是看图答问或朗读答问但没有回答
        else if (questionType == .pictureAnswer || questionType == .readAloud) && answeredCount == 0 && readingTranscript.isEmpty {
            score = 0
        }
        else if questionType == .presentation {
            if fullTranscript.count > 100 {
                score = 85
            } else if fullTranscript.count > 50 {
                score = 70
            } else if fullTranscript.count > 0 {
                score = 50
            }
        } else if questionType == .readingInteraction {
            if readingTranscript.count > 50 {
                score = 75
            } else if readingTranscript.count > 0 {
                score = 60
            }
            if !interactionMessages.isEmpty {
                score = min(score + 10, 85)
            }
        } else {
            let totalQuestions = questionType == .pictureAnswer ? allPictureQuestions.count : allQuestions.count
            if answeredCount == totalQuestions && totalQuestions > 0 {
                score = 80
            } else if answeredCount > 0 {
                score = 65
            } else if readingTranscript.count > 50 {
                score = 70
            } else if readingTranscript.count > 0 {
                score = 55
            }
        }
        
        // 构建问题分析
        let questionList: [String]
        let pointToList: [String]
        if questionType == .pictureAnswer && !allPictureQuestions.isEmpty {
            questionList = allPictureQuestions.map { $0.question }
            pointToList = allPictureQuestions.map { $0.pointTo }
        } else {
            questionList = allQuestions
            pointToList = []
        }
        
        var questionAnalysis: [EnglishAIReportData.EnglishQuestionAnalysis] = []
        if questionType != .presentation && questionType != .readingInteraction {
            for (index, question) in questionList.enumerated() {
                let answer = index < userAnswers.count ? userAnswers[index] : ""
                let pointTo = index < pointToList.count ? pointToList[index] : ""
                let hasPointTo = !pointTo.isEmpty
                
                let evaluation: String
                if answer.isEmpty {
                    if !hasAnyRecording {
                        evaluation = "未侦测到麦克风声音，请检查麦克风权限"
                    } else {
                        evaluation = "未侦测到回答内容"
                    }
                } else if hasPointTo {
                    evaluation = "能够回答问题\(answer.lowercased().contains(pointTo.lowercased()) ? "，并正确指向了相关内容" : "，但未按指示指向正确位置")"
                } else {
                    evaluation = "能够回答问题，表达清晰"
                }
                
                questionAnalysis.append(
                    EnglishAIReportData.EnglishQuestionAnalysis(
                        questionNumber: index + 1,
                        question: question,
                        pointTo: pointTo.isEmpty ? nil : pointTo,
                        evaluation: evaluation,
                        sampleAnswer: getSampleAnswer(for: question, pointTo: pointTo),
                        hasPointTo: hasPointTo
                    )
                )
            }
        }
        
        // 构建互动分析
        var interactionAnalysis: [EnglishAIReportData.InteractionAnalysis]? = nil
        if questionType == .readingInteraction && !interactionMessages.isEmpty {
            var qaList: [(question: String, answer: String)] = []
            var currentQuestion = ""
            for msg in interactionMessages {
                if msg.role == .teacher {
                    currentQuestion = msg.content
                } else if msg.role == .student && !currentQuestion.isEmpty {
                    qaList.append((question: currentQuestion, answer: msg.content))
                    currentQuestion = ""
                }
            }
            interactionAnalysis = qaList.enumerated().map { index, item in
                EnglishAIReportData.InteractionAnalysis(
                    questionNumber: index + 1,
                    question: item.question,
                    studentAnswer: item.answer,
                    evaluation: item.answer.isEmpty ? (hasAnyRecording ? "未侦测到回答内容" : "未侦测到麦克风声音") : "能够理解问题并做出回应",
                    sampleAnswer: getSampleAnswer(for: item.question, pointTo: "")
                )
            }
        }
        
        // 根据是否有回答内容决定等级
        let hasValidContent: Bool
        if questionType == .presentation {
            hasValidContent = fullTranscript.count > 20
        } else if questionType == .readingInteraction {
            hasValidContent = readingTranscript.count > 20 || !interactionMessages.isEmpty
        } else {
            hasValidContent = answeredCount > 0 || readingTranscript.count > 20
        }
        
        let contentLevel: PerformanceLevel = hasValidContent ? .average : .needsWork
        let languageLevel: PerformanceLevel = hasValidContent ? .average : .needsWork
        let organizationLevel: PerformanceLevel = hasValidContent ? .average : .needsWork
        let deliveryLevel: PerformanceLevel = hasValidContent ? .average : .needsWork
        
        // 根据是否有录音内容生成不同的建议
        let suggestions: [String]
        if !hasAnyRecording {
            suggestions = [
                "未侦测到麦克风声音，请检查麦克风权限",
                "请确保在作答时间内对着麦克风说话",
                "你可以点击「重新开始」再次尝试"
            ]
        } else if questionType == .presentation {
            if fullTranscript.isEmpty {
                suggestions = [
                    "未侦测到报告内容，请检查麦克风是否正常工作",
                    "点击麦克风按钮开始录音，说完后再次点击结束",
                    "你可以点击「重新开始」再次尝试"
                ]
            } else {
                suggestions = [
                    "报告前先想清楚开头、主体、结尾的结构",
                    "使用连接词让表达更连贯，如：First, Second, Finally",
                    "尝试用完整的句子表达观点，不要只说关键词",
                    "多练习即兴发言，提高表达的流畅度",
                    "注意发音清晰，语速适中"
                ]
            }
        } else if questionType == .readingInteraction {
            if readingTranscript.isEmpty && interactionMessages.isEmpty {
                suggestions = [
                    "未侦测到朗读和互动内容，请检查麦克风权限",
                    "Part 1: 点击麦克风按钮开始朗读文章",
                    "Part 2: 与 AI 老师进行互动问答",
                    "你可以点击「重新开始」再次尝试"
                ]
            } else {
                suggestions = [
                    "多听英文录音，模仿标准发音",
                    "朗读时注意语调和停顿",
                    "互动时仔细听老师的问题，用完整句子回答",
                    "尝试表达个人观点，不要只回答 Yes/No"
                ]
            }
        } else if questionType == .pictureAnswer {
            if answeredCount == 0 && readingTranscript.isEmpty {
                suggestions = [
                    "未侦测到回答内容，请检查麦克风权限",
                    "仔细观察图片后，点击麦克风按钮回答问题",
                    "你可以点击「重新开始」再次尝试"
                ]
            } else {
                suggestions = [
                    "回答问题前，先仔细观察图片中的人物和物品",
                    "使用完整句子回答问题，例如：'The woman is carrying a dog.'",
                    "多练习描述图片中的人物动作和位置"
                ]
            }
        } else {
            if answeredCount == 0 && readingTranscript.isEmpty {
                suggestions = [
                    "未侦测到朗读和回答内容，请检查麦克风权限",
                    "点击麦克风按钮开始朗读文章和回答问题",
                    "你可以点击「重新开始」再次尝试"
                ]
            } else {
                suggestions = [
                    "多听英文录音，模仿标准发音",
                    "练习用完整句子回答问题",
                    "尝试使用更多连接词使表达更连贯"
                ]
            }
        }
        
        let scoreReason: String
        if !hasAnyRecording {
            scoreReason = "未侦测到麦克风声音，请检查麦克风权限后重试"
        } else if score == 0 {
            scoreReason = "未侦测到有效的回答内容"
        } else {
            scoreReason = questionType == .presentation ? "根据口头报告表现综合评估" : (questionType == .readingInteraction ? "根据朗读和互动表现综合评估" : (questionType == .pictureAnswer ? "根据看图问答表现综合评估" : "根据朗读和问答表现综合评估"))
        }
        
        let encouragement: String
        if !hasAnyRecording {
            encouragement = "未侦测到麦克风声音。请检查麦克风权限，确保允许App使用麦克风后重新尝试。"
        } else if score == 0 {
            encouragement = "未侦测到有效的回答内容。请确保在作答时间内对着麦克风说话。"
        } else {
            encouragement = "做得不错！继续努力，你的英文会越来越棒！"
        }
        
        let fallbackReport = EnglishAIReportData(
            score: score,
            scoreReason: scoreReason,
            suggestions: suggestions,
            encouragement: encouragement,
            questionAnalysis: questionAnalysis,
            missingWords: missingWords,
            contentLevel: contentLevel,
            languageLevel: languageLevel,
            organizationLevel: organizationLevel,
            deliveryLevel: deliveryLevel,
            contentFeedback: hasAnyRecording ? (questionType == .presentation ? "内容已侦测" : "回答已侦测") : "未侦测到内容",
            languageFeedback: hasAnyRecording ? (questionType == .presentation ? "语言已侦测" : "回答已侦测") : "未侦测到内容",
            organizationFeedback: hasAnyRecording ? (questionType == .presentation ? "结构已侦测" : "回答已侦测") : "未侦测到内容",
            deliveryFeedback: hasAnyRecording ? (questionType == .presentation ? "表达已侦测" : "回答已侦测") : "未侦测到内容",
            interactionAnalysis: interactionAnalysis,
            sampleScript: nil
        )
        
        self.englishReport = fallbackReport
        self.isLoadingReport = false
    }
    
    
    @ViewBuilder
    var loadingReportView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("正在评估你的表现...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            Text("正在分析你的回答")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("systemBackgroundColor"))
    }
    
    @ViewBuilder
    var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("加载中...")
                .font(.system(size: 18, weight: .medium))
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("systemBackgroundColor"))
    }
    
    @ViewBuilder
    func errorView(error: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(error)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                HapticFeedbackManager.medium()
                manager.loadData()
                loadConfig()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .background(Color("systemBackgroundColor"))
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    var config: EnglishStoryConfig? {
        return storyConfig
    }
    
    func startPreparing() {
        currentStage = .preparing
        
        if questionType == .pictureAnswer {
            timeRemaining = 180
        } else {
            timeRemaining = questionType.preparationTime
        }
        
        fullTranscript = ""
        readingTranscript = ""
        pictureQuestionStage = false
        currentQuestionIndex = 0
        userAnswers = []
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                startSpeaking()
            }
        }
    }
    
    func startSpeaking() {
        timer?.invalidate()
        currentStage = .speaking
        
        if questionType == .readAloud {
            readAloudStage = .reading
            timeRemaining = questionType.speakingTime
            startRecording()
            startRecordingToFile()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.stopRecording()
                        self.stopRecordingToFile()
                        self.readingTranscript = self.fullTranscript
                        self.readAloudStage = .questioning
                        self.currentQuestionIndex = 0
                        self.userAnswers = []
                        self.fullTranscript = ""
                        
                        if self.questionType == .readAloud {
                            self.timeRemaining = 180
                            self.startTimerForQuestioning()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                self.startRecording()
                                self.startRecordingToFile()
                            }
                        }
                    }
                }
            }
        } else if questionType == .readingInteraction {
            readAloudStage = .reading
            timeRemaining = 60
            startRecording()
            startRecordingToFile()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.timer?.invalidate()
                    self.timer = nil
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.stopRecording()
                        self.stopRecordingToFile()
                        self.readingTranscript = self.fullTranscript
                        self.readAloudStage = .questioning
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            self.showInteractionView = true
                        }
                    }
                }
            }
        } else if questionType == .presentation {
            timeRemaining = 120
            startRecording()
            startRecordingToFile()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.finishPractice()
                }
            }
        } else if questionType == .pictureAnswer {
            pictureQuestionStage = true
            timeRemaining = 120
            startRecording()
            startRecordingToFile()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.finishPractice()
                }
            }
        }
    }
    
    func finishPractice() {
        timer?.invalidate()
        timer = nil
        
        stopRecording()
        stopRecordingToFile()
        
        currentStage = .finished
        
        showReport = true
        performAIAnalysis()
    }
    
    func skipToSpeaking() {
        timer?.invalidate()
        startSpeaking()
    }
    
    func resetAll() {
        timer?.invalidate()
        stopRecording()
        stopRecordingToFile()
        fullTranscript = ""
        readingTranscript = ""
        userAnswers = []
        currentQuestionIndex = 0
        readAloudStage = .reading
        pictureQuestionStage = false
        showReport = false
        isLoadingReport = false
        englishReport = nil
        showInteractionView = false
        interactionMessages = []
        startPreparing()
    }
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
    func startRecordingToFile() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filename = "english_recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = documentsPath.appendingPathComponent(filename)
        
        guard let url = recordingURL else { return }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
        } catch {
            print("开始录音失败: \(error)")
        }
    }
    
    func stopRecordingToFile() {
        audioRecorder?.stop()
        audioRecorder = nil
    }
    
    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                print("语音识别授权状态：\(status.rawValue)")
            }
        }
    }
    
    func startRecording() {
        #if targetEnvironment(simulator)
        return
        #endif
        
        if isRecording {
            stopRecording()
        }
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.addsPunctuation = true
        recognitionRequest.taskHint = .dictation
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
            isRecording = true
        } catch {
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.fullTranscript = transcribedText
                }
            }
        }
    }
    
    func stopRecording() {
        if !isRecording && !audioEngine.isRunning {
            return
        }
        
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("停止音频会话失败: \(error)")
        }
    }
}

// MARK: - 预览
#Preview {
    TSAEnglishPracticeView(grade: "小六", questionType: .presentation)
}

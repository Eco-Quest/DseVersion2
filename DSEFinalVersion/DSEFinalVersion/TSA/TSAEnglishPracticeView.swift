
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
    let imageDescription: String
    let questions: [String]
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
    let passage: String?           // 朗读用
    let questions: [String]        // 问题列表
    let imageName: String?         // 看图用
    let imageDescription: String?  // 图片描述
    let instruction: String?       // 口头报告说明
}

enum EnglishQuestionType {
    case readAloud          // 小三：朗读
    case pictureAnswer      // 小三：看图答问
    case readingInteraction // 小六：朗读互动
    case presentation       // 小六：口头报告
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
            print("❌ 找不到 english_tsa_data.json 文件")
            errorMessage = "找不到 english_tsa_data.json 文件"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allData = try decoder.decode(EnglishTSAData.self, from: data)
            print("✅ 成功加载英文 TSA 数据")
            isLoading = false
        } catch {
            print("❌ JSON 解析失败: \(error)")
            errorMessage = "JSON 解析失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    // 获取小三朗读题型
    func getP3ReadAloud() -> ReadAloudItem? {
        return allData?.小三.read_aloud
    }
    
    // 获取小三看图答问题型
    func getP3PictureAnswer() -> PictureAnswerItem? {
        return allData?.小三.picture_answer
    }
    
    // 获取小六朗读互动题型
    func getP6ReadingInteraction() -> ReadingInteractionItem? {
        return allData?.小六.reading_interaction
    }
    
    // 获取小六口头报告题型
    func getP6Presentation() -> PresentationItem? {
        return allData?.小六.presentation
    }
}

// MARK: - 主视图
struct TSAEnglishPracticeView: View {
    let grade: String      // "小三" 或 "小六"
    let questionType: EnglishQuestionType
    
    // 计时相关
    @State private var currentStage: Stage = .preparing
    @State private var timeRemaining = 180  // 准备3分钟
    @State private var timer: Timer?
    
    // 语音识别相关
    @State private var isRecording = false
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    // 录音回放
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    
    // 识别文字
    @State private var fullTranscript = ""
    
    // 数据
    @StateObject private var manager = EnglishStoryManager()
    @State private var storyConfig: EnglishStoryConfig?
    @State private var isLoadingStory = true
    
    // 主题色
    private let themeColor = Color("SelectionColor")
    private let themeLightColor = Color("ziselansecolor")
    
    enum Stage {
        case preparing, speaking, finished
    }
    
    init(grade: String, questionType: EnglishQuestionType) {
        self.grade = grade
        self.questionType = questionType
    }
    
    var body: some View {
        ZStack {
            if manager.isLoading || isLoadingStory {
                loadingView
            } else if let error = manager.errorMessage {
                errorView(error: error)
            } else if let config = storyConfig {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        // 标题
                        headerView(config: config)
                        
                        // 阶段状态
                        stageStatusView
                        
                        Divider()
                        
                        // 学生须知
                        studentNoticeView(config: config)
                        
                        // 朗读文章（朗读题型）
                        if let passage = config.passage, config.type == .readAloud || config.type == .readingInteraction {
                            passageView(passage: passage)
                        }
                        
                        // 图片（看图题型）
                        if let imageName = config.imageName, config.type == .pictureAnswer {
                            pictureView(imageName: imageName, description: config.imageDescription)
                        }
                        
                        // 口头报告说明
                        if let instruction = config.instruction, config.type == .presentation {
                            instructionView(instruction: instruction)
                        }
                        
                        // 帮助问题（口头报告用）
                        if config.type == .presentation && !config.questions.isEmpty {
                            helpingQuestionsView(questions: config.questions)
                        }
                        
                        Divider()
                        
                        // 开始/跳过按钮
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
                   
                    dismiss()
                }) {
                    if #available(iOS 26.0, *) {
                        Image(systemName: "chevron.left")
                            //.foregroundColor(Color("anniucolor"))
                    }else{
                        ZStack {
                            // 圓形白色背景
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
            
            if currentStage == .preparing || currentStage == .speaking {
                ToolbarItem(placement: .principal) {
                    Text(grade == "小三" ? "小三英文口试" : "小六英文口试")
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
            } else {
                ToolbarItem(placement: .principal) {
                    Text(grade == "小三" ? "小三英文口试" : "小六英文口试")
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
    // MARK: - 加载配置
    func loadConfig() {
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
                        imageName: nil,
                        imageDescription: nil,
                        instruction: nil
                    )
                }
                
            case .pictureAnswer:
                if let item = manager.getP3PictureAnswer() {
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .pictureAnswer,
                        title: item.title,
                        passage: nil,
                        questions: item.questions,
                        imageName: item.image,
                        imageDescription: item.imageDescription,
                        instruction: nil
                    )
                }
                
            case .readingInteraction:
                if let item = manager.getP6ReadingInteraction() {
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .readingInteraction,
                        title: item.title,
                        passage: item.passage,
                        questions: item.interaction_questions,
                        imageName: nil,
                        imageDescription: nil,
                        instruction: nil
                    )
                }
                
            case .presentation:
                if let item = manager.getP6Presentation() {
                    storyConfig = EnglishStoryConfig(
                        grade: grade,
                        type: .presentation,
                        title: item.title,
                        passage: nil,
                        questions: item.helping_questions,
                        imageName: nil,
                        imageDescription: nil,
                        instruction: item.instruction
                    )
                }
            }
            
            isLoadingStory = false
            startPreparing()
        }
    }
    
    // MARK: - 视图组件
    @ViewBuilder
    func headerView(config: EnglishStoryConfig) -> some View {
        VStack(spacing: 6) {
            Text(grade == "小三" ? "小三 TSA 英文口试" : "小六 TSA 英文口试")
                .font(.system(size: 26, weight: .bold))
            Text(config.title)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    var stageStatusView: some View {
        VStack(spacing: 12) {
            let title: String = {
                switch currentStage {
                case .preparing: return "准备阶段"
                case .speaking: return "作答阶段"
                case .finished: return "报告"
                }
            }()
            
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(themeLightColor)
            
            if currentStage == .preparing {
                Text("你有3分钟时间准备")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
            } else if currentStage == .speaking {
                let timeText = (questionType == .presentation) ? "2分钟" : "1分钟"
                Text("你有\(timeText)时间完成作答")
                    .font(.system(size: 18))
                    .foregroundColor(.secondary)
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
    func studentNoticeView(config: EnglishStoryConfig) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Text("📋 学生须知：")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            switch config.type {
            case .readAloud, .readingInteraction:
                Text("1. 请清晰朗读下面的文章。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("2. 老师会提问，请用完整句子回答问题。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
                
            case .pictureAnswer:
                Text("1. 请仔细观察图片。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("2. 回答老师关于图片的问题。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
                
            case .presentation:
                Text("1. 你有2分钟时间进行口头报告。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("2. 使用提示问题来组织你的想法。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                Text("3. 请清晰表达，并看着老师。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
            }
        }
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
    func pictureView(imageName: String, description: String?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 20))
                Text("图片")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .frame(height: 220)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .overlay(
                    Group {
                        if let uiImage = UIImage(named: imageName) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 220)
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
                            .frame(height: 220)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                )
            
            if let desc = description {
                Text(desc)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
            }
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
                    }
                }
            }
            .padding()
            .background(Color("baiseanniucolor"))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    var actionButton: some View {
        HStack {
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
                    }
                }
        }
        .padding(.horizontal, 5)
    }
    
    var actionButtonText: String {
        if !isRecording {
            return currentStage == .preparing ? "跳过准备阶段" : "开始作答"
        } else {
            return "录音中..."
        }
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
    
    // MARK: - 辅助函数
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    // MARK: - 计时逻辑
    func startPreparing() {
        currentStage = .preparing
        timeRemaining = 180
        fullTranscript = ""
        
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
        
        // 口头报告2分钟，其他1分钟
        if questionType == .presentation {
            timeRemaining = 120
        } else {
            timeRemaining = 60
        }
        
        startRecording()
        startRecordingToFile()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                finishPractice()
            }
        }
    }
    
    func finishPractice() {
        timer?.invalidate()
        timer = nil
        
        stopRecording()
        stopRecordingToFile()
        
        currentStage = .finished
        // TODO: 跳转到报告页面
    }
    
    func skipToSpeaking() {
        timer?.invalidate()
        startSpeaking()
    }
    
    // MARK: - 录音功能
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
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
        print("⚠️ 模拟器无法测试真实录音")
        return
        #endif
        
        recognitionTask?.cancel()
        recognitionTask = nil
        
        if isRecording {
            stopRecording()
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ 音频会话设置失败: \(error)")
            return
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ 无法创建识别请求")
            return
        }
        
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
            print("\n🎤 开始录音...\n")
        } catch {
            print("❌ 音频引擎启动失败: \(error)")
            return
        }
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                let transcribedText = result.bestTranscription.formattedString
                DispatchQueue.main.async {
                    self.fullTranscript = transcribedText
                }
                print("\r📝 \(transcribedText)", terminator: "")
            }
            
            if let error = error {
                if (error as NSError).code != 4 {
                    print("\n❌ 识别错误: \(error.localizedDescription)")
                }
                self.stopRecording()
            }
            
            if result?.isFinal == true {
                print("\n✅ 录音完成\n")
                self.stopRecording()
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
        
        if currentStage == .speaking {
            print("\n⏸️ 录音已停止\n")
        }
    }
}

// MARK: - 预览
#Preview {
    TSAEnglishPracticeView(grade: "小三", questionType: .readAloud)
}

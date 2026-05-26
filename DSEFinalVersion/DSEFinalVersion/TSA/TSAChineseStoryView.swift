//
//  TSAChineseStoryView.swift
//  dse_test
//
//  Created by Matt on 2026/5/23.
//

import SwiftUI
import Speech
import AVFoundation
import Combine

// MARK: - JSON 数据模型
struct StoryData: Codable {
    let categories: Categories
}

struct Categories: Codable {
    let 小三: GradeLevel
    let 小六: GradeLevel
    
    enum CodingKeys: String, CodingKey {
        case 小三 = "小三"
        case 小六 = "小六"
    }
}

// MARK: - 年级数据模型（支持两种题型结构）
struct GradeLevel: Codable {
    let name: String
    let stories: [StoryItem]?      // 小三使用
    let question_types: QuestionTypes?  // 小六使用
}

// MARK: - 小六题型结构
struct QuestionTypes: Codable {
    let picture_story: PictureStoryType
    let qa: QAType
    let discussion: DiscussionType
}

// MARK: - 看图说故事题型（小六）
struct PictureStoryType: Codable {
    let description: String
    let items: [PictureStoryItem]
}

struct PictureStoryItem: Codable, Identifiable {
    let id: String
    let topic: String
    let image: ImageInfo
}

// MARK: - 问答题型（口头报告）
struct QAType: Codable {
    let description: String
    let items: [QAItem]
}

struct QAItem: Codable, Identifiable {
    let id: String
    let topic: String
    let question: String
}

// MARK: - 讨论题型（小组讨论：1分钟准备 + 3分钟讨论）
struct DiscussionType: Codable {
    let description: String
    let items: [DiscussionItem]
}

struct DiscussionItem: Codable, Identifiable {
    let id: String
    let topic: String
    let discussion_question: String
}

// MARK: - 故事项（小三使用）
struct StoryItem: Codable, Identifiable {
    let id: String
    let topic: String
    let images: [ImageInfo]
}

// MARK: - 图片信息
struct ImageInfo: Codable {
    let name: String
    let filename: String
    let description: String
}

// MARK: - 统一的故事配置（用于 UI 展示）
struct StoryConfig {
    let topic: String
    let images: [String]
    let pictureDescriptions: [String]
    let type: StoryType
    
    enum StoryType {
        case pictureStory      // 小三/小六：看图说故事
        case oralReport       // 小六：口头报告
        case discussion        // 小六：小组讨论（1分钟准备 + 3分钟讨论）
    }
    
    init(topic: String, images: [String], pictureDescriptions: [String], type: StoryType = .pictureStory) {
        self.topic = topic
        self.images = images
        self.pictureDescriptions = pictureDescriptions
        self.type = type
    }
}

// MARK: - 故事管理器
class StoryManager: ObservableObject {
    @Published var currentStory: StoryItem?
    @Published var currentGrade: String = "小三"
    @Published var allStories: StoryData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // 小六题型切换
    @Published var currentQuestionType: QuestionType = .pictureStory
    
    enum QuestionType: String, CaseIterable {
        case pictureStory = "看图说故事"
        case oralReport = "口头报告"
        case discussion = "小组讨论"
    }
    
    init() {
        loadStoryData()
    }
    
    func loadStoryData() {
        isLoading = true
        errorMessage = nil
        
        guard let url = Bundle.main.url(forResource: "story_data", withExtension: "json") else {
            print("❌ 找不到 story_data.json 文件")
            errorMessage = "找不到 story_data.json 文件"
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            allStories = try decoder.decode(StoryData.self, from: data)
            
            if let stories = allStories {
                print("✅ 成功加载故事数据")
                print("  小三故事数量：\(stories.categories.小三.stories?.count ?? 0)")
                if let qTypes = stories.categories.小六.question_types {
                    print("  小六看图说故事数量：\(qTypes.picture_story.items.count)")
                    print("  小六口头报告数量：\(qTypes.qa.items.count)")
                    print("  小六小组讨论数量：\(qTypes.discussion.items.count)")
                }
            }
        } catch {
            print("❌ JSON 解析失败: \(error)")
            errorMessage = "JSON 解析失败: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - 随机抽取（小三）
    func randomStory() -> StoryItem? {
        guard let allStories = allStories else {
            print("❌ 没有加载到故事数据")
            return nil
        }
        
        let gradeData = allStories.categories.小三
        guard let stories = gradeData.stories, !stories.isEmpty else { return nil }
        
        let randomIndex = Int.random(in: 0..<stories.count)
        currentStory = stories[randomIndex]
        
        print("📖 随机抽取【小三】故事：\(currentStory?.topic ?? "未知")")
        return currentStory
    }
    
    // MARK: - 随机抽取小六题型
    func randomSixthGradeItem(for type: QuestionType) -> (id: String, topic: String, questionText: String, image: ImageInfo?)? {
        guard let allStories = allStories,
              let qTypes = allStories.categories.小六.question_types else {
            print("❌ 小六数据不存在")
            return nil
        }
        
        switch type {
        case .pictureStory:
            let items = qTypes.picture_story.items
            guard !items.isEmpty else { return nil }
            let randomIndex = Int.random(in: 0..<items.count)
            let item = items[randomIndex]
            print("📖 随机抽取【小六-看图说故事】：\(item.topic)")
            return (id: item.id, topic: item.topic, questionText: "", image: item.image)
            
        case .oralReport:
            let items = qTypes.qa.items
            guard !items.isEmpty else { return nil }
            let randomIndex = Int.random(in: 0..<items.count)
            let item = items[randomIndex]
            print("📖 随机抽取【小六-口头报告】：\(item.topic)")
            return (id: item.id, topic: item.topic, questionText: item.question, image: nil)
            
        case .discussion:
            let items = qTypes.discussion.items
            guard !items.isEmpty else { return nil }
            let randomIndex = Int.random(in: 0..<items.count)
            let item = items[randomIndex]
            print("📖 随机抽取【小六-小组讨论】：\(item.topic)")
            return (id: item.id, topic: item.topic, questionText: item.discussion_question, image: nil)
        }
    }
    
    // MARK: - 转换为 StoryConfig（小三）
    func convertToStoryConfig(from story: StoryItem) -> StoryConfig {
        let imageNames = story.images.map { $0.filename }
        let descriptions = story.images.map { $0.description }
        
        return StoryConfig(
            topic: story.topic,
            images: imageNames,
            pictureDescriptions: descriptions,
            type: .pictureStory
        )
    }
    
    // MARK: - 转换为 StoryConfig（小六）
    func convertSixthGradeToStoryConfig(for type: QuestionType) -> StoryConfig? {
        guard let item = randomSixthGradeItem(for: type) else { return nil }
        
        switch type {
        case .pictureStory:
            let imageNames = [item.image?.filename ?? ""]
            let descriptions = [item.image?.description ?? ""]
            return StoryConfig(
                topic: item.topic,
                images: imageNames,
                pictureDescriptions: descriptions,
                type: .pictureStory
            )
            
        case .oralReport:
            return StoryConfig(
                topic: item.topic,
                images: [],
                pictureDescriptions: [item.questionText],
                type: .oralReport
            )
            
        case .discussion:
            return StoryConfig(
                topic: item.topic,
                images: [],
                pictureDescriptions: [item.questionText],
                type: .discussion
            )
        }
    }
    
    // MARK: - 随机获取配置（根据年级）
    func randomStoryConfig(for grade: String) -> StoryConfig? {
        if grade == "小三" {
            guard let story = randomStory() else { return nil }
            return convertToStoryConfig(from: story)
        } else {
            // 小六：随机选择一种题型
            let allTypes: [QuestionType] = [.pictureStory, .oralReport, .discussion]
            let randomType = allTypes.randomElement() ?? .pictureStory
            currentQuestionType = randomType
            return convertSixthGradeToStoryConfig(for: randomType)
        }
    }
    
    // 指定题型获取配置
    func randomStoryConfig(for grade: String, type: QuestionType) -> StoryConfig? {
        if grade == "小三" {
            return randomStoryConfig(for: grade)
        } else {
            currentQuestionType = type
            return convertSixthGradeToStoryConfig(for: type)
        }
    }
    
    // 转换 StoryConfig.StoryType 到 QuestionType
    func convertToQuestionType(from storyType: StoryConfig.StoryType) -> QuestionType {
        switch storyType {
        case .pictureStory:
            return .pictureStory
        case .oralReport:
            return .oralReport
        case .discussion:
            return .discussion
        }
    }
}

// MARK: - AI 报告数据模型
struct AIReportData: Codable {
    var score: Int
    let scoreReason: String
    let standardStory: String
    let completeness: EvaluationItem
    let language: EvaluationItem
    let creativity: EvaluationItem
    let suggestions: [String]
    let encouragement: String
    
    struct EvaluationItem: Codable {
        let level: String
        let comment: String
    }
}

// MARK: - 录音回放组件
struct AudioPlaybackView: View {
    let audioURL: URL
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlaying = false
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var timer: Timer?
    
    private let themeColor = Color("SelectionColor")
    
    var body: some View {
        if #available(iOS 26, *) {
            HStack(spacing: 16) {
                Button(action: togglePlayback) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(themeColor)
                    }
                }
                
                Text(formatTime(currentTime))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .leading)
                
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
                
                Text(formatTime(duration))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
            .onAppear { setupAudioPlayer() }
            .onDisappear {
                timer?.invalidate()
                audioPlayer?.stop()
            }
        } else {
            HStack(spacing: 16) {
                Button(action: togglePlayback) {
                    ZStack {
                        Circle()
                            .fill(themeColor.opacity(0.1))
                            .frame(width: 48, height: 48)
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                            .foregroundColor(themeColor)
                    }
                }
                
                Text(formatTime(currentTime))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .leading)
                
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
                
                Text(formatTime(duration))
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(width: 45, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color("baiseanniucolor"))
            .cornerRadius(12)
            .onAppear { setupAudioPlayer() }
            .onDisappear {
                timer?.invalidate()
                audioPlayer?.stop()
            }
        }
    }
    
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("加载音频失败: \(error)")
        }
    }
    
    private func togglePlayback() {
        HapticFeedbackManager.medium()
        if isPlaying {
            audioPlayer?.pause()
            timer?.invalidate()
            isPlaying = false
        } else {
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
            if !player.isPlaying {
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

// MARK: - 评分环形进度条
struct ScoreRingView: View {
    let score: Int
    private let themeColor = Color(red: 71/255, green: 59/255, blue: 147/255)
    
    var scoreColor: Color {
        if score >= 80 { return .green }
        if score >= 60 { return .blue }
        if score >= 40 { return .orange }
        return .red
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: CGFloat(score) / 100)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.8), value: score)
            
            VStack(spacing: 4) {
                Text("\(score)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                Text("分")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 评估卡片组件
struct EvaluationCard: View {
    let title: String
    let level: String
    let comment: String
    
    private let themeColor = Color(red: 71/255, green: 59/255, blue: 147/255)
    
    var levelColor: Color {
        switch level {
        case "优秀": return .green
        case "良好": return .blue
        case "一般": return .orange
        default: return .gray
        }
    }
    
    var levelIcon: String {
        switch level {
        case "优秀": return "star.fill"
        case "良好": return "hand.thumbsup.fill"
        case "一般": return "flag.fill"
        default: return "circle.fill"
        }
    }
    
    var body: some View {
        if #available(iOS 26, *) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: levelIcon)
                        .foregroundColor(levelColor)
                        .font(.system(size: 18))
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(level)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(levelColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(levelColor.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Text(comment)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .glassEffect(.regular, in: .rect(cornerRadius: 12))
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: levelIcon)
                        .foregroundColor(levelColor)
                        .font(.system(size: 18))
                    
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text(level)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(levelColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(levelColor.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Text(comment)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
            .padding()
            .background(Color("baiseanniucolor"))
            .cornerRadius(12)
        }
    }
}

// MARK: - 图片组件（多图/单图通用）
struct PictureRow: View {
    let num: Int
    let imageName: String
    private let themeLightColor = Color("ziselansecolor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图\(num)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeLightColor)
                .padding(.leading, 4)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .frame(height: 250)
                .frame(maxWidth: .infinity)
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
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray)
                                Text("图画 \(num)")
                                    .font(.system(size: 16))
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - 图画回顾组件
struct PictureReviewCard: View {
    let index: Int
    let imageName: String
    let description: String
    private let themeColor = Color("ziselansecolor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("图\(index + 1)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(themeColor)
                .padding(.leading, 4)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                )
                .frame(height: 250)
                .frame(maxWidth: .infinity)
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
                                    .font(.system(size: 44))
                                    .foregroundColor(.gray)
                                Text("图画 \(index + 1)")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 250)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(12)
                        }
                    }
                )
            
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
                .padding(.top, 4)
        }
    }
}

// MARK: - 小组讨论专用的声音枚举（支持粤语）
enum DiscussionVoice: String, CaseIterable {
    case xiaoxiao = "Xiaoxiao"
    case kiki = "Kiki"
    case yunxi = "Yunxi"
    case yunjian = "Yunjian"
    case rocky = "Rocky"
    case cherry = "Cherry"
    case kai = "Kai"
    case jennifer = "Jennifer"
    
    var displayName: String {
        switch self {
        case .xiaoxiao: return "小晓 (粤语女声)"
        case .kiki: return "Kiki (粤语女声)"
        case .yunxi: return "云希 (粤语男声)"
        case .yunjian: return "云健 (粤语男声)"
        case .rocky: return "Rocky (粤语男声)"
        case .cherry: return "Cherry (普通话)"
        case .kai: return "Kai (普通话)"
        case .jennifer: return "Jennifer (普通话)"
        }
    }
}

// MARK: - 小组讨论专用的参与者模型
struct DiscussionParticipant {
    let name: String
    let voice: DiscussionVoice
    let personality: String
    let proficiencyLevel: ProficiencyLevel
    
    enum ProficiencyLevel: String {
        case beginner = "beginner"
        case intermediate = "intermediate"
        case advanced = "advanced"
        case native = "native"
        
        var style: String {
            switch self {
            case .beginner: return "使用基础词汇，简单句子"
            case .intermediate: return "使用常见词汇，能表达观点"
            case .advanced: return "使用精确词汇，复杂句式"
            case .native: return "自然流畅，丰富的表达"
            }
        }
    }
    
    init(name: String, voice: DiscussionVoice, personality: String, proficiency: ProficiencyLevel = .advanced) {
        self.name = name
        self.voice = voice
        self.personality = personality
        self.proficiencyLevel = proficiency
    }
}

// MARK: - 小组讨论专用的聊天消息模型
struct DiscussionChatMessage: Identifiable, Equatable {
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
            return "你"
        } else {
            if let name = speakerName {
                return name
            }
            return "同学"
        }
    }
}

// MARK: - 小组讨论主题模型
struct DiscussionTopic1 {
    let fullText: String
    let participants: [DiscussionParticipant]
    
    var article: String { return fullText }
}

// MARK: - 小组讨论专用的 PCM 音频播放器
class DiscussionPCMAudioPlayer {
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
        
        guard let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 24000,
            channels: 1,
            interleaved: false
        ) else {
            print("Failed to create audio format")
            return
        }
        audioFormat = format
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func playPCMData(_ pcmData: Data, voice: String) {
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
            if let baseAddress = rawBufferPointer.baseAddress {
                let int16Pointer = baseAddress.assumingMemoryBound(to: Int16.self)
                if let floatChannelData = buffer.floatChannelData {
                    for i in 0..<Int(frameCount) {
                        floatChannelData[0][i] = Float(int16Pointer[i]) / Float(Int16.max)
                    }
                }
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
        playerNode?.stop()
        playerNode?.reset()
        pendingBuffers = 0
        currentPlayingVoice = nil
    }
}

// MARK: - 小组讨论专用的 WebSocket 管理器
class DiscussionWebSocketManager: NSObject, ObservableObject {
    @Published var isConnected = false
    @Published var isRecording = false
    @Published var isSpeaking = false
    @Published var isAITalking = false
    @Published var isDiscussionActive = false
    @Published var chatMessages: [DiscussionChatMessage] = []
    @Published var currentStreamingText = ""
    @Published var canUserSpeak = true
    @Published var currentSpeakerName: String? = "同学 A"
    
    @Published var currentRemainingTime: Int = 180
    
    var selectedLanguage: String = "粤语"
    
    private var turnCounter = 0
    private let participantsList = ["同学 A", "同学 B"]
    private var consecutiveSilenceCount = 0
    var onDiscussionEnded: ((String) -> Void)?
    private var isGeneratingResponse = false
    private var hasGivenConclusion = false
    
    private var webSocketTask: URLSessionWebSocketTask?
    private lazy var webSocketSession: URLSession = {
        URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
    }()
    private var audioEngine: AVAudioEngine?
    private let audioPlayer = DiscussionPCMAudioPlayer()
    private var recordingData = Data()
    private var isProcessingResponse = false
    private var currentVoice: DiscussionVoice = .xiaoxiao
    private var hasSentAudio = false
    private var isWaitingForVoiceUpdate = false
    private var currentResponseVoice: DiscussionVoice = .xiaoxiao
    private var voiceUpdateCompletion: (() -> Void)?
    
    private var currentTopic: DiscussionTopic1?
    private var conversationHistory: [String] = []
    private var participants: [DiscussionParticipant] = []
    private var currentParticipant: DiscussionParticipant?
    private var waitForUserTimer: Timer?
    
    private let aliyunEndpoint = "wss://dashscope.aliyuncs.com/api-ws/v1/realtime"
    private let aliyunApiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    private let model = "qwen3-omni-flash-realtime"
    
    override init() {
        super.init()
        print("🎤 [DiscussionWebSocketManager] 初始化")
        setupAudioSession()
        setupAudioPlayerCallback()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
            try audioSession.setActive(true)
            print("✅ [音频] 音频会话设置成功")
        } catch {
            print("❌ [音频] 设置音频会话失败: \(error)")
        }
    }
    
    private func setupAudioPlayerCallback() {
        audioPlayer.onPlaybackFinished = { [weak self] in
            Task { @MainActor in
                print("🎵 [AI] 语音播放结束")
                self?.handleAIFinishedSpeaking()
            }
        }
    }
    
    private func handleAIFinishedSpeaking() {
        print("📢 [状态] handleAIFinishedSpeaking() 被调用")
        
        isSpeaking = false
        isAITalking = false
        isProcessingResponse = false
        currentStreamingText = ""
        hasSentAudio = false
        isWaitingForVoiceUpdate = false
        consecutiveSilenceCount = 0
        isGeneratingResponse = false
        
        if isDiscussionActive {
            if waitForUserTimer == nil {
                canUserSpeak = true
                print("✅ [状态] 允许用户发言，启动3秒等待计时器")
                startWaitForUserTimer()
            }
        }
    }
    
    private func startWaitForUserTimer() {
        waitForUserTimer?.invalidate()
        
        print("⏰ [计时器] 启动等待用户发言计时器（3秒）")
        
        waitForUserTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            guard self.isDiscussionActive, !self.isRecording, !self.isAITalking else {
                return
            }
            
            print("⏰ [计时器] 用户3秒内未发言")
            
            self.canUserSpeak = false
            self.waitForUserTimer = nil
            
            if self.consecutiveSilenceCount >= 1 {
                print("❌ [讨论] 用户连续两次没发言，结束讨论")
                let transcript = self.getDiscussionTranscript()
                self.onDiscussionEnded?(transcript)
                self.stopDiscussion()
                return
            }
            
            print("🔄 [发言] 用户第一次沉默，切换发言人")
            self.turnCounter += 1
            let nextSpeakerName = self.participantsList[self.turnCounter % 2]
            
            if let nextParticipant = self.participants.first(where: { $0.name == nextSpeakerName }) {
                self.currentParticipant = nextParticipant
                self.currentSpeakerName = nextParticipant.name
                self.currentVoice = nextParticipant.voice
                self.currentResponseVoice = nextParticipant.voice
                self.consecutiveSilenceCount += 1
                self.generateAIReply()
            } else {
                let voice = self.getVoiceForCurrentLanguage()
                let tempParticipant = DiscussionParticipant(name: nextSpeakerName, voice: voice, personality: "温和", proficiency: .advanced)
                self.currentParticipant = tempParticipant
                self.currentSpeakerName = nextSpeakerName
                self.currentVoice = voice
                self.currentResponseVoice = voice
                self.consecutiveSilenceCount += 1
                self.generateAIReply()
            }
        }
    }
    
    private func cancelWaitForUserTimer() {
        waitForUserTimer?.invalidate()
        waitForUserTimer = nil
    }
    
    private func getDiscussionTranscript() -> String {
        var transcript = ""
        for message in chatMessages {
            let speaker = message.displayName
            transcript += "\(speaker): \(message.content)\n"
        }
        return transcript
    }
    
    private func getVoiceForCurrentLanguage() -> DiscussionVoice {
        if selectedLanguage == "粤语" {
            let cantoneseVoices: [DiscussionVoice] = [.kiki, .rocky]
            let index = turnCounter % cantoneseVoices.count
            return cantoneseVoices[index]
        } else {
            let mandarinVoices: [DiscussionVoice] = [.cherry, .kai]
            let index = turnCounter % mandarinVoices.count
            return mandarinVoices[index]
        }
    }
    
    private func getNextParticipant() -> DiscussionParticipant {
        guard !participants.isEmpty else {
            let voice = getVoiceForCurrentLanguage()
            let name = participantsList[turnCounter % 2]
            return DiscussionParticipant(name: name, voice: voice, personality: "温和", proficiency: .advanced)
        }
        
        let nextName = participantsList[turnCounter % 2]
        if let participant = participants.first(where: { $0.name == nextName }) {
            currentSpeakerName = participant.name
            return participant
        } else {
            let voice = getVoiceForCurrentLanguage()
            let defaultParticipant = DiscussionParticipant(name: nextName, voice: voice, personality: "温和", proficiency: .advanced)
            currentSpeakerName = defaultParticipant.name
            return defaultParticipant
        }
    }
    
    func setTopic(_ fullText: String, participants: [DiscussionParticipant]) {
        self.participants = participants
        self.currentTopic = DiscussionTopic1(fullText: fullText, participants: participants)
        self.turnCounter = 0
        self.consecutiveSilenceCount = 0
        self.hasGivenConclusion = false
        self.isGeneratingResponse = false
    }
    
    func startDiscussionDirectly() {
        print("=== 🎯 [讨论] STARTING DISCUSSION DIRECTLY ===")
        isDiscussionActive = true
        canUserSpeak = false
        turnCounter = 0
        consecutiveSilenceCount = 0
        hasGivenConclusion = false
        isGeneratingResponse = false
        conversationHistory.removeAll()
        chatMessages.removeAll()
        
        connect()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let firstSpeakerName = self.participantsList[0]
            
            if let firstParticipant = self.participants.first(where: { $0.name == firstSpeakerName }) {
                self.currentParticipant = firstParticipant
                self.currentSpeakerName = firstParticipant.name
                self.currentVoice = firstParticipant.voice
                self.currentResponseVoice = firstParticipant.voice
            } else {
                let voice = self.getVoiceForCurrentLanguage()
                let defaultParticipant = DiscussionParticipant(name: firstSpeakerName, voice: voice, personality: "温和", proficiency: .advanced)
                self.currentParticipant = defaultParticipant
                self.currentSpeakerName = firstSpeakerName
                self.currentVoice = voice
                self.currentResponseVoice = voice
            }
            self.createResponseWithVoice()
        }
    }
    
    func stopDiscussion() {
        isDiscussionActive = false
        canUserSpeak = false
        isProcessingResponse = false
        isGeneratingResponse = false
        cancelWaitForUserTimer()
        disconnect()
    }
    
    func connect() {
        var components = URLComponents(string: aliyunEndpoint)
        components?.queryItems = [URLQueryItem(name: "model", value: model)]
        
        guard let url = components?.url else {
            print("❌ [连接] 无效的 URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(aliyunApiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        if webSocketTask != nil {
            webSocketTask?.cancel(with: .goingAway, reason: nil)
            webSocketTask = nil
        }
        
        webSocketTask = webSocketSession.webSocketTask(with: request)
        webSocketTask?.resume()
        receiveMessage()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.sendSessionConfig()
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        isConnected = false
        stopMicRecording()
        audioPlayer.stop()
    }
    
    private func sendSessionConfig() {
        guard let participant = currentParticipant else {
            return
        }
        
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
    
    private func buildDynamicInstructions(with participant: DiscussionParticipant) -> String {
        let isCantonese = selectedLanguage == "粤语"
        let needsConclusion = currentRemainingTime <= 50 && !hasGivenConclusion
        
        guard let topic = currentTopic else {
            if isCantonese {
                return "你係一個討論嘅同學，必須用粵語正常講嘢就得。"
            } else {
                return "你是一个讨论的同学，必须用普通话正常说话。严禁使用任何粤语词汇，必须全程使用普通话。"
            }
        }
        
        var instructions = ""
        
        if isCantonese {
            instructions = """
            
            --- 討論題目 ---
            \(topic.fullText)
            --- 題目完 ---
            
            你係香港小六學生，必須用粵語參加小組討論。
            
            說話要求：
            - 每句10-20個字，簡單直接
            - 用生活化嘅粵語詞語
            - 要回應前面同學講過嘅內容，唔好重覆自己講過嘅嘢
            
            \(needsConclusion ? "⚠️ 時間剩返 \(currentRemainingTime) 秒，你要幫大家達成共識，做總結結束討論。" : "時間剩返 \(currentRemainingTime) 秒。")
            
            """
        } else {
            instructions = """
            
            --- 討論題目 ---
            \(topic.fullText)
            --- 題目完 ---
            
            你是香港小六學生，必須用普通話參加小組討論。嚴禁使用粵語！
            
            說話要求：
            - 每句10-20個字，簡單直接
            - 用生活化的普通話詞語
            - 要回應前面同學說過的内容，不要重複自己說過的話
            - 禁止使用「嘅」、「咗」、「嚟」、「哋」、「係」、「冇」等粵語詞彙
            - 使用「的」、「了」、「来」、「们」、「是」、「没有」等普通話詞彙
            
            \(needsConclusion ? "⚠️ 時間剩下 \(currentRemainingTime) 秒，你要幫助大家達成共識，做總結結束討論。" : "時間剩下 \(currentRemainingTime) 秒。")
            
            """
        }
        
        if !conversationHistory.isEmpty {
            instructions += "\n--- 對話歷史 ---\n"
            instructions += conversationHistory.suffix(8).joined(separator: "\n")
            instructions += "\n--- 對話完 ---\n"
            if isCantonese {
                instructions += "\n請根據以上對話歷史，必須用粵語繼續討論。\n"
            } else {
                instructions += "\n請根據以上對話歷史，必須用普通話繼續討論。嚴禁使用粵語！\n"
            }
        } else {
            if isCantonese {
                instructions += "\n（未有對話，你係第一個發言）\n"
                instructions += "你係第一個發言：必須用粵語直接講你嘅初步想法，然後問另一位同學。\n"
            } else {
                instructions += "\n（沒有對話，你是第一個發言）\n"
                instructions += "你是第一個發言：必須用普通話直接說你的初步想法，然後問另一位同學。嚴禁使用粵語！\n"
            }
        }
        
        return instructions
    }
    
    private func generateAIResponse(userResponse: String) {
        guard !isGeneratingResponse else { return }
        isGeneratingResponse = true
        
        let participant = currentParticipant ?? getNextParticipant()
        currentParticipant = participant
        currentSpeakerName = participant.name
        currentVoice = participant.voice
        currentResponseVoice = participant.voice
        
        let remainingTime = currentRemainingTime
        let isCantonese = selectedLanguage == "粤语"
        let needsConclusion = remainingTime <= 50 && !hasGivenConclusion
        if needsConclusion {
            hasGivenConclusion = true
        }
        
        var recentHistory = ""
        let lastMessages = chatMessages.suffix(4)
        if !lastMessages.isEmpty {
            for msg in lastMessages {
                let speaker = msg.displayName
                recentHistory += "\(speaker): \(msg.content)\n"
            }
        }
        
        if isCantonese {
            let prompt = """
            你是香港小六學生，用粵語參加小組討論。
            
            \(needsConclusion ? "時間剩返 \(remainingTime) 秒，你要幫大家達成共識，做總結。" : "時間剩返 \(remainingTime) 秒。")
            
            討論題目：\(currentTopic?.fullText ?? "")
            
            最近的對話：
            \(recentHistory)
            
            剛才同學說：「\(userResponse.prefix(150))」
            
            請你用粵語回應同學的觀點。你可以：
            1. 表示同意或不同意
            2. 補充新的觀點
            3. 提問引導討論
            
            不要重複自己說過的話，每句話10-20個字。
            """
            sendTextMessage(prompt)
        } else {
            let prompt = """
            你是香港小六學生，用普通話參加小組討論。嚴禁使用粵語！
            
            \(needsConclusion ? "時間剩下 \(remainingTime) 秒，你要幫助大家達成共識，做總結。" : "時間剩下 \(remainingTime) 秒。")
            
            討論題目：\(currentTopic?.fullText ?? "")
            
            最近的對話：
            \(recentHistory)
            
            剛才同學說：「\(userResponse.prefix(150))」
            
            請你用普通話回應同學的觀點。你可以：
            1. 表示同意或不同意
            2. 補充新的觀點
            3. 提問引導討論
            
            不要重複自己說過的話，每句話10-20個字。
            禁止使用粵語詞彙：嘅、咗、嚟、哋、係、冇
            """
            sendTextMessage(prompt)
        }
    }
    
    private func generateAIReply() {
        guard !isGeneratingResponse else { return }
        isGeneratingResponse = true
        
        let participant = currentParticipant ?? getNextParticipant()
        currentParticipant = participant
        currentSpeakerName = participant.name
        currentVoice = participant.voice
        currentResponseVoice = participant.voice
        
        let remainingTime = currentRemainingTime
        let isCantonese = selectedLanguage == "粤语"
        let needsConclusion = remainingTime <= 50 && !hasGivenConclusion
        if needsConclusion {
            hasGivenConclusion = true
        }
        
        var recentHistory = ""
        let lastMessages = chatMessages.suffix(4)
        let filteredMessages = lastMessages.filter { msg in
            if msg.role == .ai {
                return msg.speakerName != currentSpeakerName
            }
            return true
        }
        
        for msg in filteredMessages {
            let speaker = msg.displayName
            recentHistory += "\(speaker): \(msg.content)\n"
        }
        
        let hasRecentUserMessage = chatMessages.last?.role == .user
        
        if isCantonese {
            let prompt: String
            if hasRecentUserMessage {
                prompt = """
                你是香港小六學生，用粵語參加小組討論。
                
                \(needsConclusion ? "時間剩返 \(remainingTime) 秒，你要幫大家達成共識，做總結。" : "時間剩返 \(remainingTime) 秒。")
                
                討論題目：\(currentTopic?.fullText ?? "")
                
                最近的對話：
                \(recentHistory)
                
                請用粵語繼續討論。你可以：
                1. 提出新的觀點
                2. 補充前面同學的想法
                3. 提問引導討論
                
                不要重複自己說過的話，每句話10-20個字。
                """
            } else {
                prompt = """
                你是香港小六學生，用粵語參加小組討論。
                
                \(needsConclusion ? "時間剩返 \(remainingTime) 秒，你要幫大家達成共識，做總結。" : "時間剩返 \(remainingTime) 秒。")
                
                討論題目：\(currentTopic?.fullText ?? "")
                
                現在請你提出一個**不同**的觀點或例子來豐富討論。
                不要重複自己說過的話，要說新的內容！
                """
            }
            sendTextMessage(prompt)
        } else {
            let prompt: String
            if hasRecentUserMessage {
                prompt = """
                你是香港小六學生，用普通話參加小組討論。嚴禁使用粵語！
                
                \(needsConclusion ? "時間剩下 \(remainingTime) 秒，你要幫助大家達成共識，做總結。" : "時間剩下 \(remainingTime) 秒。")
                
                討論題目：\(currentTopic?.fullText ?? "")
                
                最近的對話：
                \(recentHistory)
                
                請用普通話繼續討論。你可以：
                1. 提出新的觀點
                2. 補充前面同學的想法
                3. 提問引導討論
                
                不要重複自己說過的話，每句話10-20個字。
                禁止使用粵語詞彙：嘅、咗、嚟、哋、係、冇、乜、嘢
                """
            } else {
                prompt = """
                你是香港小六學生，用普通話參加小組討論。嚴禁使用粵語！
                
                \(needsConclusion ? "時間剩下 \(remainingTime) 秒，你要幫助大家達成共識，做總結。" : "時間剩下 \(remainingTime) 秒。")
                
                討論題目：\(currentTopic?.fullText ?? "")
                
                現在請你提出一個**不同**的觀點或例子來豐富討論。
                不要重複自己說過的話，要說新的內容！
                禁止使用粵語詞彙：嘅、咗、嚟、哋、係、冇、乜、嘢
                """
            }
            sendTextMessage(prompt)
        }
    }
    
    private func updateDiscussionHistory(role: String, name: String, content: String) {
        let entry = "\(name): \(content)"
        conversationHistory.append(entry)
        if conversationHistory.count > 16 { conversationHistory.removeFirst() }
    }
    
    private func sendTextMessage(_ message: String) {
        guard !isProcessingResponse else {
            return
        }
        
        isProcessingResponse = true
        isAITalking = true
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
    
    func startRecording() {
        guard !isRecording, isConnected, !isAITalking, isDiscussionActive, canUserSpeak else {
            return
        }
        
        consecutiveSilenceCount = 0
        cancelWaitForUserTimer()
        
        sendMessage(["type": "input_audio_buffer.clear"])
        recordingData = Data()
        
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatInt16,
            sampleRate: 16000,
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
        } catch {
            print("❌ [录音] 启动音频引擎失败: \(error)")
        }
    }
    
    func stopMicRecording() {
        guard isRecording else {
            return
        }
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        isRecording = false
        
        if recordingData.count > 0 {
            commitAudio()
        }
    }
    
    private func commitAudio() {
        let commitMessage: [String: Any] = [
            "event_id": UUID().uuidString,
            "type": "input_audio_buffer.commit"
        ]
        sendMessage(commitMessage)
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
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
                    case .string(let text):
                        self?.handleMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.handleMessage(text)
                        }
                    @unknown default: break
                    }
                    self?.receiveMessage()
                case .failure(let error):
                    print("❌ [WebSocket] 接收消息错误: \(error)")
                    self?.isConnected = false
                }
            }
        }
    }
    
    private func addMessage(role: DiscussionChatMessage.MessageRole, content: String, voice: String? = nil, speakerName: String? = nil) {
        let message = DiscussionChatMessage(role: role, content: content, timestamp: Date(), voice: voice, speakerName: speakerName)
        chatMessages.append(message)
        
        let name = role == .user ? "你" : (speakerName ?? "同学")
        updateDiscussionHistory(role: role == .user ? "你" : name, name: name, content: content)
        
        if role == .user {
            consecutiveSilenceCount = 0
            cancelWaitForUserTimer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self = self, self.isDiscussionActive else {
                    return
                }
                
                self.turnCounter += 1
                let nextSpeakerName = self.participantsList[self.turnCounter % 2]
                
                if let nextParticipant = self.participants.first(where: { $0.name == nextSpeakerName }) {
                    self.currentParticipant = nextParticipant
                    self.currentSpeakerName = nextParticipant.name
                    self.currentVoice = nextParticipant.voice
                    self.currentResponseVoice = nextParticipant.voice
                    self.generateAIResponse(userResponse: content)
                } else {
                    let voice = self.getVoiceForCurrentLanguage()
                    let tempParticipant = DiscussionParticipant(name: nextSpeakerName, voice: voice, personality: "温和", proficiency: .advanced)
                    self.currentParticipant = tempParticipant
                    self.currentSpeakerName = nextSpeakerName
                    self.currentVoice = voice
                    self.currentResponseVoice = voice
                    self.generateAIResponse(userResponse: content)
                }
            }
        }
    }
    
    private func handleMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }
        
        switch type {
        case "session.created", "session.updated":
            isConnected = true
        case "input_audio_buffer.committed":
            print("🎤 [音频] 音频已提交")
        case "response.created":
            currentStreamingText = ""
        case "response.audio.delta":
            if let audioBase64 = json["delta"] as? String,
               let audioData = Data(base64Encoded: audioBase64) {
                audioPlayer.playPCMData(audioData, voice: currentResponseVoice.displayName)
                isSpeaking = true
                isAITalking = true
            }
        case "response.audio_transcript.delta":
            if let delta = json["delta"] as? String {
                currentStreamingText += delta
            }
        case "response.audio_transcript.done":
            if let transcript = json["transcript"] as? String {
                addMessage(role: .ai, content: transcript, voice: currentVoice.displayName, speakerName: currentSpeakerName)
            }
            currentStreamingText = ""
        case "response.done":
            print("✅ [响应] 响应完成")
        case "conversation.item.input_audio_transcription.completed":
            if let transcript = json["transcript"] as? String, hasSentAudio {
                let trimmed = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty {
                    addMessage(role: .user, content: transcript)
                }
                hasSentAudio = false
            }
        default:
            break
        }
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard webSocketTask != nil else {
            return
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return
        }
        
        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                print("❌ [WebSocket] 发送消息错误: \(error)")
            }
        }
    }
}

extension DiscussionWebSocketManager: URLSessionWebSocketDelegate {
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        Task { @MainActor in
            print("✅ [WebSocket] 连接已打开")
        }
    }
    
    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        Task { @MainActor in
            print("🔌 [WebSocket] 连接已关闭: \(closeCode)")
            self.isConnected = false
            if self.webSocketTask === webSocketTask { self.webSocketTask = nil }
        }
    }
}

// MARK: - 小组讨论专用的音量监控器
class DiscussionMicMonitor: ObservableObject {
    @Published var averageDb: Float = 0.0
    var onVolumeUpdate: ((Float) -> Void)?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    
    init() {
        setupMicrophone()
    }
    
    private func setupMicrophone() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine?.inputNode
        
        let recordingFormat = inputNode?.outputFormat(forBus: 0)
        
        inputNode?.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
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
            self.onVolumeUpdate?(normalizedDb)
        }
    }
    
    func startMonitoring() {}
    
    func stopMonitoring() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
    }
}

// MARK: - 小组讨论专用视图
struct DiscussionGroupView: View {
    let topic: String
    let language: String
    let onFinish: (String) -> Void
    
    @StateObject private var webSocketManager = DiscussionWebSocketManager()
    @State private var remainingTime = 180
    @State private var timer: Timer?
    @State private var isUserSpeaking = false
    @StateObject private var micMonitor = DiscussionMicMonitor()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 头部计时器
            VStack(spacing: 8) {
                Text("小组讨论")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color("ziselansecolor"))
                
                Text("请与两位AI同学进行讨论（\(language)）")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                
                Text(timeString(from: remainingTime))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(remainingTime < 30 ? .red : Color("ziselansecolor"))
                    .padding(.top, 8)
            }
            .padding(.top, 20)
            
            // 讨论题目
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color("ziselansecolor"))
                    Text("讨论题目")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color("ziselansecolor"))
                }
                
                Text(topic)
                    .font(.system(size: 16))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("baiseanniucolor"))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            // 聊天记录区域
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(webSocketManager.chatMessages) { message in
                            DiscussionGroupBubble(message: message)
                                .id(message.id)
                        }
                        
                        if webSocketManager.isAITalking && !webSocketManager.currentStreamingText.isEmpty {
                            DiscussionGroupBubble(
                                message: DiscussionChatMessage(
                                    role: .ai,
                                    content: webSocketManager.currentStreamingText,
                                    timestamp: Date(),
                                    voice: nil,
                                    speakerName: webSocketManager.currentSpeakerName
                                ),
                                isStreaming: true
                            )
                            .id("streaming")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: webSocketManager.chatMessages.count) { _ in
                    if let lastMessage = webSocketManager.chatMessages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: webSocketManager.currentStreamingText) { _ in
                    withAnimation {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            .background(.clear)
            
            // 底部录音控制
            VStack(spacing: 8) {
             
                Button(action: {
                    if webSocketManager.isRecording {
                        webSocketManager.stopMicRecording()
                        isUserSpeaking = false
                    } else if webSocketManager.canUserSpeak && !webSocketManager.isAITalking {
                        webSocketManager.startRecording()
                        isUserSpeaking = true
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(webSocketManager.isRecording ? Color.red : Color("ziselansecolor"))
                            .frame(width: 56, height: 56)
                            .shadow(radius: 3)
                        
                        Image(systemName: webSocketManager.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                }
                .disabled(!webSocketManager.canUserSpeak && !webSocketManager.isRecording)
                
                if webSocketManager.isAITalking {
                    Text("\(webSocketManager.currentSpeakerName ?? "同学") 正在发言...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else if webSocketManager.isRecording {
                    Text("你正在发言...")
                        .font(.caption2)
                        .foregroundColor(.red)
                } else if webSocketManager.canUserSpeak {
                    Text("点击麦克风发言")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("请稍候...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 12)
            .background(.clear)
        }
        .background(Color("systemBackgroundColor"))
        .onAppear {
            startDiscussion()
        }
        .onDisappear {
            stopDiscussion()
        }
        .navigationBarBackButtonHidden(true)
      
    }
    
    private func startDiscussion() {
        let voice1: DiscussionVoice
        let voice2: DiscussionVoice
        
        if language == "粤语" {
            voice1 = .kiki
            voice2 = .rocky
        } else {
            voice1 = .cherry
            voice2 = .kai
        }
        
        let participants = [
            DiscussionParticipant(name: "同学 A", voice: voice1, personality: "友善", proficiency: .advanced),
            DiscussionParticipant(name: "同学 B", voice: voice2, personality: "友善", proficiency: .advanced)
        ]
        
        webSocketManager.selectedLanguage = language
        webSocketManager.setTopic(topic, participants: participants)
        
        webSocketManager.onDiscussionEnded = { transcript in
            DispatchQueue.main.async {
                self.onFinish(transcript)
            }
        }
        
        webSocketManager.startDiscussionDirectly()
        startTimer()
        micMonitor.startMonitoring()
    }
    
    private func stopDiscussion() {
        timer?.invalidate()
        timer = nil
        webSocketManager.stopDiscussion()
        micMonitor.stopMonitoring()
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if remainingTime > 0 {
                remainingTime -= 1
                webSocketManager.currentRemainingTime = remainingTime
            } else {
                let transcript = getDiscussionTranscript()
                webSocketManager.stopDiscussion()
                onFinish(transcript)
                timer?.invalidate()
                timer = nil
            }
        }
    }
    
    private func getDiscussionTranscript() -> String {
        var transcript = ""
        for message in webSocketManager.chatMessages {
            let speaker = message.displayName
            transcript += "\(speaker): \(message.content)\n"
        }
        return transcript
    }
    
    private func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}

// MARK: - 小组讨论专用气泡
struct DiscussionGroupBubble: View {
    let message: DiscussionChatMessage
    var isStreaming: Bool = false
    
    var body: some View {
        HStack {
            if message.role == .user {
                Spacer()
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                HStack {
                    if message.role == .user {
                        Text("你")
                            .font(.caption)
                            .fontWeight(.semibold)
                    } else {
                        Text(message.displayName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("ziselansecolor"))
                    }
                    
                    Text(message.formattedTime)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(
                        message.role == .user ?
                        Color("ziselansecolor").opacity(0.15) :
                        Color("baiseanniucolor")
                    )
                    .cornerRadius(16)
                
            
            }
            
            if message.role == .ai {
                Spacer()
            }
        }
        .id(message.id)
    }
}



// MARK: - 小组讨论记录分组模型
struct DiscussionTurn: Identifiable {
    let id = UUID()
    let turnNumber: Int
    let messages: [(speaker: String, content: String, isUser: Bool)]
    
    var summary: String {
        let speakers = Set(messages.map { $0.speaker })
        return "第\(turnNumber)轮"
    }
    
    var firstMessagePreview: String {
        if let first = messages.first {
            let preview = first.content.prefix(50)
            return "\(first.speaker): \(preview)\(first.content.count > 50 ? "..." : "")"
        }
        return ""
    }
}

// MARK: - 报告内容视图
struct ReportContentView: View {
    let report: AIReportData
    let storyConfig: StoryConfig?
    let discussionTranscript: String
    let language: String
    let onRestart: () -> Void
    
    @State private var showFullDiscussion = false
    @State private var expandedTurns: Set<UUID> = []
    
    private let themeColor = Color("SelectionColor")
    private let themeLightColor = Color("ziselansecolor")
    
    // 解析讨论记录为结构化数据
    private var discussionMessages: [(speaker: String, content: String, isUser: Bool)] {
        let lines = discussionTranscript.split(separator: "\n", omittingEmptySubsequences: false)
        var messages: [(speaker: String, content: String, isUser: Bool)] = []
        
        for line in lines {
            let stringLine = String(line)
            if let colonIndex = stringLine.firstIndex(of: ":") {
                let speaker = String(stringLine[stringLine.startIndex..<colonIndex]).trimmingCharacters(in: .whitespaces)
                let content = String(stringLine[stringLine.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
                if !content.isEmpty {
                    messages.append((speaker: speaker, content: content, isUser: speaker == "你"))
                }
            }
        }
        return messages
    }
    
    // 将讨论记录按轮次分组
    private var discussionTurns: [DiscussionTurn] {
        let messages = discussionMessages
        var turns: [DiscussionTurn] = []
        var currentTurnMessages: [(speaker: String, content: String, isUser: Bool)] = []
        var turnNumber = 1
        var lastSpeaker: String?
        
        for message in messages {
            if let last = lastSpeaker, last != message.speaker, !currentTurnMessages.isEmpty {
                if !currentTurnMessages.isEmpty {
                    turns.append(DiscussionTurn(
                        turnNumber: turnNumber,
                        messages: currentTurnMessages
                    ))
                    turnNumber += 1
                    currentTurnMessages = []
                }
            }
            currentTurnMessages.append(message)
            lastSpeaker = message.speaker
            
            if currentTurnMessages.count >= 4 {
                turns.append(DiscussionTurn(
                    turnNumber: turnNumber,
                    messages: currentTurnMessages
                ))
                turnNumber += 1
                currentTurnMessages = []
                lastSpeaker = nil
            }
        }
        
        if !currentTurnMessages.isEmpty {
            turns.append(DiscussionTurn(
                turnNumber: turnNumber,
                messages: currentTurnMessages
            ))
        }
        
        return turns
    }
    
    // 统计发言次数
    private var speakingStats: (userCount: Int, aiCount: Int, userPercentage: Int) {
        let messages = discussionMessages
        let userCount = messages.filter { $0.isUser }.count
        let aiCount = messages.filter { !$0.isUser }.count
        let total = max(userCount + aiCount, 1)
        let userPercentage = (userCount * 100) / total
        return (userCount, aiCount, userPercentage)
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                headerView
                
                // 评分区域
                scoreSection
                
                // 详细评估
                evaluationSection
                
                // 小组讨论专用：发言统计图表 + 讨论记录
                if storyConfig?.type == .discussion && !discussionMessages.isEmpty {
                    discussionStatsSection
                    discussionTranscriptSection
                }
                
                // 参考答案（仅看图说故事）
                if storyConfig?.type == .pictureStory {
                    referenceAnswerSection
                    pictureReviewSection
                }
                
                // 改进建议
                suggestionsSection
                
                // 鼓励
                encouragementSection
                
                // 重新开始按钮
                restartButton
            }
            .padding(20)
        }
        .background(Color("systemBackgroundColor"))
    }
    
    // MARK: - 子视图组件
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 6) {
            Text(storyConfig?.type == .discussion ? "小六TSA中国语文" : (storyConfig?.type == .oralReport ? "小六TSA中国语文" : "小三TSA中国语文"))
                .font(.system(size: 26, weight: .bold))
            Text(getSubtitle())
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    @ViewBuilder
    private var scoreSection: some View {
        if #available(iOS 26, *) {
            VStack(spacing: 16) {
                ScoreRingView(score: report.score)
                Text(report.scoreReason)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            VStack(spacing: 16) {
                ScoreRingView(score: report.score)
                Text(report.scoreReason)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 16)
            .background(Color("baiseanniucolor"))
            .cornerRadius(16)
        }
    }
    
    @ViewBuilder
    private var evaluationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("详细评估")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(themeColor)
            
            EvaluationCard(title: "内容完整性", level: report.completeness.level, comment: report.completeness.comment)
            EvaluationCard(title: "语言表达", level: report.language.level, comment: report.language.comment)
            EvaluationCard(title: "创意表现", level: report.creativity.level, comment: report.creativity.comment)
        }
    }
    
    @ViewBuilder
    private var discussionStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("发言统计")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
            }
            
            // 发言次数图表
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    // 用户发言
                    VStack {
                        Text("你的发言")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(speakingStats.userCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(themeLightColor)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // AI发言
                    VStack {
                        Text("AI发言")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(speakingStats.aiCount)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 进度条
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("你的发言占比")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(speakingStats.userPercentage)%")
                            .font(.caption)
                            .foregroundColor(themeLightColor)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 8)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(themeLightColor)
                                .frame(width: geometry.size.width * CGFloat(speakingStats.userPercentage) / 100, height: 8)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
            }
            .padding()
            .background(Color("baiseanniucolor"))
            .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var discussionTranscriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .foregroundColor(themeLightColor)
                    .font(.system(size: 18))
                Text("讨论记录")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeLightColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showFullDiscussion.toggle()
                    }
                }) {
                    Text(showFullDiscussion ? "收起" : "展开全部")
                        .font(.caption)
                        .foregroundColor(themeLightColor)
                }
            }
            
            if showFullDiscussion {
                // 完整显示所有轮次
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(discussionTurns) { turn in
                        DiscussionTurnCard(turn: turn, isExpanded: true)
                    }
                }
            } else {
                // 只显示前3轮，更多用按钮展开
                let visibleTurns = Array(discussionTurns.prefix(3))
                
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(visibleTurns) { turn in
                        DiscussionTurnCard(turn: turn, isExpanded: expandedTurns.contains(turn.id))
                            .onTapGesture {
                                withAnimation {
                                    if expandedTurns.contains(turn.id) {
                                        expandedTurns.remove(turn.id)
                                    } else {
                                        expandedTurns.insert(turn.id)
                                    }
                                }
                            }
                    }
                }
                
                if discussionTurns.count > 3 {
                    Button(action: {
                        withAnimation {
                            showFullDiscussion = true
                        }
                    }) {
                        HStack {
                            Text("查看更多 (\(discussionTurns.count - 3)轮)")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                        }
                        .foregroundColor(themeLightColor)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(themeLightColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var referenceAnswerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(themeColor)
                    .font(.system(size: 16))
                Text("参考答案")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(themeColor)
            }
            
            Text(report.standardStory)
                .font(.system(size: 14))
                .lineSpacing(5)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
        }
    }
    
    @ViewBuilder
    private var pictureReviewSection: some View {
        if let config = storyConfig {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "photo.stack.fill")
                        .foregroundColor(themeColor)
                        .font(.system(size: 16))
                    Text("图画回顾")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeColor)
                }
                
                VStack(spacing: 24) {
                    ForEach(0..<config.images.count, id: \.self) { index in
                        PictureReviewCard(
                            index: index,
                            imageName: config.images[index],
                            description: config.pictureDescriptions[index]
                        )
                    }
                }
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
            
            if #available(iOS 26, *) {
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
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
            } else {
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
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
            }
        }
    }
    
    @ViewBuilder
    private var encouragementSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.pink)
                    .font(.system(size: 16))
                Text("鼓励")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(.primary)
            
            if #available(iOS 26, *) {
                Text(report.encouragement)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .glassEffect(.regular, in: .rect(cornerRadius: 12))
            } else {
                Text(report.encouragement)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.pink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
                    .padding()
                    .background(Color("baiseanniucolor"))
                    .cornerRadius(12)
            }
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
    
    func getSubtitle() -> String {
        guard let config = storyConfig else { return "加载中..." }
        switch config.type {
        case .pictureStory: return "看图说故事"
        case .oralReport: return "口头报告"
        case .discussion: return "小组讨论"
        }
    }
}

// MARK: - 讨论轮次卡片
struct DiscussionTurnCard: View {
    let turn: DiscussionTurn
    let isExpanded: Bool
    
    private let themeLightColor = Color("ziselansecolor")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(turn.summary)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeLightColor)
                
                Spacer()
                
                if !isExpanded {
                    Text(turn.firstMessagePreview)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(turn.messages.enumerated()), id: \.offset) { _, message in
                        HStack(alignment: .top) {
                            Text(message.speaker)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(message.isUser ? themeLightColor : .blue)
                                .frame(width: 50, alignment: .leading)
                            
                            Text(message.content)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.leading, 4)
            }
        }
        .padding(10)
        .background(Color("baiseanniucolor"))
        .cornerRadius(8)
    }
}

// MARK: - 主视图 TSAChineseStoryView
struct TSAChineseStoryView: View {
    // 年级参数（由外部传入）
    let grade: String
    let fixedQuestionType: StoryConfig.StoryType?
    let language: String
    
    // 计时相关
    @State private var currentStage: Stage = .preparing
    @State private var timeRemaining = 180
    @State private var timer: Timer?
    
    // 语音识别相关
    @State private var isRecording = false
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    private var speechRecognizer: SFSpeechRecognizer? {
        let localeIdentifier: String
        switch language {
        case "普通话":
            localeIdentifier = "zh-CN"
        default:
            localeIdentifier = "zh-HK"
        }
        return SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
    
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    @State private var fullTranscript = ""
    
    @State private var aiReport: AIReportData?
    @State private var showReport = false
    @State private var isLoadingReport = false
    
    @State private var storyConfig: StoryConfig?
    @State private var isLoadingStory = true
    @State private var loadError: String?
    
    // 小组讨论相关
    @State private var showDiscussionView = false
    @State private var discussionTranscript = ""
    
    private let aliyunEndpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    private let aliyunApiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    
    private let themeColor = Color("SelectionColor")
    private let themeLightColor = Color("ziselansecolor")
    
    @StateObject private var storyManager = StoryManager()
    
    enum Stage {
        case preparing, speaking, finished
    }
    
    init(grade: String, questionType: StoryConfig.StoryType? = nil, language: String = "粤语") {
        self.grade = grade
        self.fixedQuestionType = questionType
        self.language = language
        print("📖 TSAChineseStoryView 初始化，年级: \(grade), 题型: \(questionType.map { String(describing: $0) } ?? "随机"), 语言: \(language)")
    }
    
    // MARK: - 标题区域
    @ViewBuilder
    var headerView: some View {
        VStack(spacing: 6) {
            Text(getGradeDisplayName())
                .font(.system(size: 26, weight: .bold))
            Text(getSubtitle())
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }
    
    func getGradeDisplayName() -> String {
        return grade == "小三" ? "小三TSA中国语文" : "小六TSA中国语文"
    }
    
    func getSubtitle() -> String {
        guard let config = storyConfig else { return "加载中..." }
        switch config.type {
        case .pictureStory: return "看图说故事"
        case .oralReport: return "口头报告"
        case .discussion: return "小组讨论"
        }
    }
    
    // MARK: - 阶段状态视图
    @ViewBuilder
    var stageStatusView: some View {
        if #available(iOS 26, *) {
            VStack(spacing: 12) {
                let title: String = {
                    switch currentStage {
                    case .preparing: return "准备阶段"
                    case .speaking: return "讨论阶段"
                    case .finished: return "报告"
                    }
                }()
                
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(themeLightColor)
                
                if currentStage == .preparing {
                    if storyConfig?.type == .pictureStory {
                        Text("请用3分钟时间观察图画，准备故事内容")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else if storyConfig?.type == .discussion {
                        Text("请用1分钟时间准备，然后进行3分钟小组讨论")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else {
                        Text("请用3分钟时间准备你的回答")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                } else if currentStage == .speaking {
                    if storyConfig?.type == .pictureStory {
                        Text("你有1分钟来讲故事")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else if storyConfig?.type == .oralReport {
                        Text("请根据题目进行口头报告（1分钟）")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else {
                        Text("正在与同学进行小组讨论...")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
        } else {
            VStack(spacing: 12) {
                let title: String = {
                    switch currentStage {
                    case .preparing: return "准备阶段"
                    case .speaking: return "讨论阶段"
                    case .finished: return "报告"
                    }
                }()
                
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(themeLightColor)
                
                if currentStage == .preparing {
                    if storyConfig?.type == .pictureStory {
                        Text("请用3分钟时间观察图画，准备故事内容")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else if storyConfig?.type == .discussion {
                        Text("请用1分钟时间准备，然后进行3分钟小组讨论")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else {
                        Text("请用3分钟时间准备你的回答")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                } else if currentStage == .speaking {
                    if storyConfig?.type == .pictureStory {
                        Text("正在录音中...")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else if storyConfig?.type == .oralReport {
                        Text("请根据题目进行口头报告")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    } else {
                        Text("正在与同学进行小组讨论...")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color("baiseanniucolor"))
            .cornerRadius(16)
        }
    }
    
    // MARK: - 题目内容视图
    @ViewBuilder
    var questionContentView: some View {
        if let config = storyConfig, let questionText = config.pictureDescriptions.first {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: config.type == .oralReport ? "mic.circle.fill" : "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 24))
                        .foregroundColor(themeLightColor)
                    Text(config.type == .oralReport ? "报告题目" : "讨论题目")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(themeLightColor)
                }
                .padding(.bottom, 4)
                
                Text(questionText)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color("baiseanniucolor"))
                    .cornerRadius(12)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 学生须知
    @ViewBuilder
    var studentNoticeView: some View {
        if storyConfig?.type == .pictureStory {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("📋 学生须知：")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                HStack(alignment: .top, spacing: 6) {
                    Text("1. 请用三分钟时间细心观察图画。")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top, spacing: 6) {
                    Text("2. 然后用一分钟时间，依图画内容说一个完整故事。")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 6) {
                Text("请细心观察以下图画，然后讲述一个完整的故事。")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .padding(.top, 5)
            }
            .padding(.top, -10)
        } else if storyConfig?.type == .oralReport {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("📋 学生须知：")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("请用三分钟时间准备，然后进行一分钟的口头报告。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
        } else if storyConfig?.type == .discussion {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("📋 学生须知：")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("请用1分钟时间准备，然后与两位AI同学进行3分钟的小组讨论。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - 加载视图
    @ViewBuilder
    var loadingStoryView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("正在加载...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("systemBackgroundColor"))
    }
    
    @ViewBuilder
    var errorView: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text(loadError ?? "加载失败")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                HapticFeedbackManager.medium()
                loadRandomStory()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
        .background(Color("systemBackgroundColor"))
    }
    
    @ViewBuilder
    var loadingReportView: some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            Text("正在评估...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            Text("请稍等片刻")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("systemBackgroundColor"))
    }
    
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Body
    var body: some View {
        ZStack {
            if isLoadingStory {
                loadingStoryView
            } else if let error = loadError {
                errorView
            } else if showReport {
                if isLoadingReport {
                    loadingReportView
                } else if let report = aiReport {
                    ReportContentView(
                        report: report,
                        storyConfig: storyConfig,
                        discussionTranscript: discussionTranscript,
                        language: language,
                        onRestart: resetAll
                    )
                }
            } else if showDiscussionView, let config = storyConfig, config.type == .discussion {
                DiscussionGroupView(
                    topic: config.pictureDescriptions.first ?? config.topic,
                    language: language,
                    onFinish: { transcript in
                        discussionTranscript = transcript
                        showDiscussionView = false
                        finishStory(with: transcript)
                    }
                )
            } else if let config = storyConfig {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        headerView
                        stageStatusView
                        Divider()
                        
                        studentNoticeView
                        
                        if config.type != .pictureStory {
                            questionContentView
                        }
                        
                        if config.type == .pictureStory && !config.images.isEmpty {
                            VStack(spacing: 24) {
                                ForEach(0..<config.images.count, id: \.self) { index in
                                    PictureRow(num: index + 1, imageName: config.images[index])
                                }
                            }
                        }
                        
                        Divider()
                        
                        if config.type == .discussion {
                            Button(action: {
                                HapticFeedbackManager.medium()
                                if currentStage == .preparing {
                                    skipToSpeaking()
                                }
                            }) {
                                Text(currentStage == .preparing ? "开始讨论" : "讨论中...")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(currentStage == .preparing ? themeLightColor : Color.gray)
                                    .cornerRadius(14)
                            }
                            .disabled(currentStage != .preparing)
                        } else {
                            HStack {
                                Text(!isRecording ? (currentStage == .preparing ? "跳过准备阶段" : "开始讲述...") : "正在录音中...")
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
            
            if !showReport && (currentStage == .preparing || currentStage == .speaking) && !showDiscussionView {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        Image(systemName: currentStage == .preparing ? "clock" : "mic.fill")
                            .font(.system(size: 16))
                            .foregroundColor(themeLightColor)
                        Text(timeString(from: timeRemaining))
                            .font(.system(size: 20, weight: .semibold, design: .monospaced))
                            .foregroundColor(themeLightColor)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .cornerRadius(20)
                }
            }
        }
        .onAppear {
            requestSpeechPermission()
            setupAudioSession()
            loadRandomStory()
        }
        .onDisappear {
            stopRecording()
            timer?.invalidate()
        }
    }
    
    // MARK: - 加载随机故事
    func loadRandomStory() {
        isLoadingStory = true
        loadError = nil
        
        if storyManager.allStories == nil && storyManager.errorMessage == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                loadRandomStory()
            }
            return
        }
        
        if let error = storyManager.errorMessage {
            loadError = error
            isLoadingStory = false
            return
        }
        
        if grade == "小六", let fixedType = fixedQuestionType {
            let type = storyManager.convertToQuestionType(from: fixedType)
            if let config = storyManager.randomStoryConfig(for: grade, type: type) {
                storyConfig = config
                isLoadingStory = false
                startPreparing()
                return
            }
        }
        
        if let config = storyManager.randomStoryConfig(for: grade) {
            storyConfig = config
            isLoadingStory = false
            startPreparing()
        } else {
            loadError = "无法加载\(grade)的数据"
            isLoadingStory = false
        }
    }
    
    func timeString(from seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    // MARK: - 录音
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
        let filename = "story_recording_\(Date().timeIntervalSince1970).m4a"
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
    
    // MARK: - 计时逻辑
    func startPreparing() {
        currentStage = .preparing
        
        if storyConfig?.type == .discussion {
            timeRemaining = 60
        } else {
            timeRemaining = 180
        }
        
        fullTranscript = ""
        aiReport = nil
        showReport = false
        isLoadingReport = false
        recordingURL = nil
        stopRecording()
        
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
        
        if storyConfig?.type == .discussion {
            showDiscussionView = true
        } else if storyConfig?.type == .pictureStory {
            timeRemaining = 60
            startRecording()
            startRecordingToFile()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    finishStory()
                }
            }
        } else if storyConfig?.type == .oralReport {
            timeRemaining = 60
            startRecording()
            startRecordingToFile()
            
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    finishStory()
                }
            }
        }
    }
    
    func finishStory(with transcript: String = "") {
        timer?.invalidate()
        timer = nil
        
        if storyConfig?.type != .discussion {
            stopRecording()
            stopRecordingToFile()
        }
        
        showReport = true
        isLoadingReport = true
        
        if storyConfig?.type == .discussion {
            performAIAnalysisForDiscussion(with: transcript)
        } else {
            performAIAnalysis()
        }
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
        aiReport = nil
        showReport = false
        isLoadingReport = false
        recordingURL = nil
        showDiscussionView = false
        discussionTranscript = ""
        startPreparing()
    }
    
    // MARK: - 语音识别
    func requestSpeechPermission() {
        guard let recognizer = speechRecognizer else {
            print("❌ 无法创建语音识别器，语言: \(language)")
            return
        }
        
        recognizer.defaultTaskHint = .dictation
        
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                print("语音识别授权状态（\(self.language)）：\(status.rawValue)")
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
        
        if #available(iOS 13, *) {
            recognitionRequest.requiresOnDeviceRecognition = false
        }
        
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
            print("\n🎤 开始录音（\(language)）...\n")
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
                print("\r📝 [\(self.language)] \(transcribedText)", terminator: "")
                fflush(__stdoutp)
            }
            
            if let error = error {
                if (error as NSError).code != 4 {
                    print("\n❌ 识别错误: \(error.localizedDescription)")
                }
                self.stopRecording()
            }
            
            if result?.isFinal == true {
                print("\n✅ 录音完成（\(self.language)）\n")
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
    
    // MARK: - AI 报告生成（看图说故事/口头报告）
    func performAIAnalysis() {
        guard let config = storyConfig else {
            useFallbackReport()
            return
        }
        
        guard !fullTranscript.isEmpty else {
            let defaultReport = AIReportData(
                score: 0,
                scoreReason: "未检测到录音内容，请确保麦克风权限已开启。",
                standardStory: "请确保麦克风权限已开启，并重新尝试。",
                completeness: AIReportData.EvaluationItem(level: "待加强", comment: "未能检测到内容"),
                language: AIReportData.EvaluationItem(level: "待加强", comment: "未能检测到语言表达"),
                creativity: AIReportData.EvaluationItem(level: "待加强", comment: "未能检测到创意表现"),
                suggestions: ["请检查麦克风权限", "确保在安静环境下录音", "点击重新开始按钮重试"],
                encouragement: "没关系，我们再试一次！相信你可以做得更好。"
            )
            self.aiReport = defaultReport
            self.isLoadingReport = false
            return
        }
        
        let languageHint = language == "普通话" ? "普通话（简体中文）" : "粤语（繁体中文）"
        
        var prompt = ""
        
        if config.type == .pictureStory {
            let pictureDescriptionsText = config.pictureDescriptions.enumerated().map { index, desc in
                "图\(index + 1): \(desc)"
            }.joined(separator: "\n")
            
            prompt = """
            你是一个专业的小学语文老师，熟悉香港\(grade)TSA中国语文评估标准。请根据图画内容，先自动生成一个标准答案故事，然后分析学生的口语故事，并以JSON格式返回结果。评分采用100分制。
            
            注意：学生使用的语言是 \(languageHint)。

            【题目主题】
            \(config.topic)

            【图画内容描述】
            \(pictureDescriptionsText)

            【学生的口语故事】
            \(fullTranscript)

            【返回格式要求】
            必须严格按照以下JSON格式返回：
            {
                "score": 85,
                "scoreReason": "故事完整，语言流畅",
                "standardStory": "标准答案故事",
                "completeness": {"level": "良好", "comment": "故事结构完整"},
                "language": {"level": "良好", "comment": "语言表达流畅"},
                "creativity": {"level": "一般", "comment": "可加入更多创意"},
                "suggestions": ["建议1", "建议2", "建议3"],
                "encouragement": "鼓励的话"
            }
            """
        } else {
            let questionText = config.pictureDescriptions.first ?? ""
            prompt = """
            你是一个专业的小学语文老师，熟悉香港\(grade)TSA中国语文评估标准。请分析学生的口头报告，并以JSON格式返回结果。评分采用100分制。
            
            注意：学生使用的语言是 \(languageHint)。

            【报告题目】
            \(questionText)

            【学生的口头报告内容】
            \(fullTranscript)

            【返回格式要求】
            必须严格按照以下JSON格式返回：
            {
                "score": 85,
                "scoreReason": "观点清晰，表达流畅",
                "standardStory": "示范性的口头报告",
                "completeness": {"level": "良好", "comment": "内容完整"},
                "language": {"level": "良好", "comment": "语言表达流畅"},
                "creativity": {"level": "一般", "comment": "可加入更多个人见解"},
                "suggestions": ["建议1", "建议2", "建议3"],
                "encouragement": "鼓励的话"
            }
            """
        }
        
        callAIAPI(with: prompt)
    }
    
    // MARK: - AI 报告生成（小组讨论）
    func performAIAnalysisForDiscussion(with transcript: String) {
        guard !transcript.isEmpty else {
            useFallbackDiscussionReport()
            return
        }
        
        let languageHint = language == "普通话" ? "普通话（简体中文）" : "粤语（繁体中文）"
        let topicText = storyConfig?.pictureDescriptions.first ?? "小组讨论"
        
        let prompt = """
        你是一个专业的小学语文老师，熟悉香港小六TSA中国语文评估标准。
        请分析学生的【小组讨论】表现，并以JSON格式返回结果。评分采用100分制。
        
        注意：学生使用的语言是 \(languageHint)。
        
        【讨论题目】
        \(topicText)
        
        【讨论记录】
        \(transcript)
        
        【评分标准】
        1. 内容完整性 (30分): 是否围绕主题展开讨论，观点是否清晰
        2. 语言表达 (30分): 语言是否流畅，用词是否恰当
        3. 互动表现 (40分): 是否能回应他人观点，是否能有效沟通
        
        【返回格式要求】
        必须严格按照以下JSON格式返回，不要有任何其他文字：
        {
            "score": 85,
            "scoreReason": "能够积极参与讨论，表达清晰，能回应同学观点",
            "standardStory": "小组讨论的示范回答：首先清晰表达自己的立场，然后说明2-3个理由，最后回应同学观点并总结。",
            "completeness": {"level": "良好", "comment": "能够围绕主题展开讨论，观点表达完整"},
            "language": {"level": "良好", "comment": "语言表达流畅，用词恰当"},
            "creativity": {"level": "一般", "comment": "可以提出更多创新的观点"},
            "suggestions": ["建议更积极地回应同学观点", "可以用更多例子支持自己的看法", "注意控制发言时间"],
            "encouragement": "做得很好！继续保持积极参与讨论的态度！"
        }
        """
        
        callAIAPI(with: prompt)
    }
    
    // MARK: - 通用 API 调用方法
    private func callAIAPI(with prompt: String) {
        guard let url = URL(string: aliyunEndpoint) else {
            if storyConfig?.type == .discussion {
                useFallbackDiscussionReport()
            } else {
                useFallbackReport()
            }
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
                ["role": "system", "content": "你是一个专业的小学语文老师，只返回纯JSON格式，不要有任何其他解释文字。"],
                ["role": "user", "content": prompt]
            ],
            "stream": false,
            "temperature": 0.5,
            "max_tokens": 2000
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            if storyConfig?.type == .discussion {
                useFallbackDiscussionReport()
            } else {
                useFallbackReport()
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("网络错误：\(error)")
                    if self.storyConfig?.type == .discussion {
                        self.useFallbackDiscussionReport()
                    } else {
                        self.useFallbackReport()
                    }
                    return
                }
                
                guard let data = data else {
                    if self.storyConfig?.type == .discussion {
                        self.useFallbackDiscussionReport()
                    } else {
                        self.useFallbackReport()
                    }
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
                                var report = try JSONDecoder().decode(AIReportData.self, from: jsonData)
                                report.score = min(max(report.score, 0), 100)
                                self.aiReport = report
                                self.isLoadingReport = false
                                return
                            }
                        }
                    }
                    if self.storyConfig?.type == .discussion {
                        self.useFallbackDiscussionReport()
                    } else {
                        self.useFallbackReport()
                    }
                } catch {
                    print("解析错误：\(error)")
                    if self.storyConfig?.type == .discussion {
                        self.useFallbackDiscussionReport()
                    } else {
                        self.useFallbackReport()
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Fallback 报告
    func useFallbackReport() {
        let wordCount = fullTranscript.count
        var score = 50
        var completenessLevel = "一般"
        
        if wordCount > 100 {
            score = 80
            completenessLevel = "优秀"
        } else if wordCount > 50 {
            score = 65
            completenessLevel = "良好"
        } else if wordCount < 20 {
            score = 30
            completenessLevel = "待加强"
        }
        
        let fallbackReport = AIReportData(
            score: score,
            scoreReason: "根据内容长度自动评估",
            standardStory: "根据题目要求，一个完整的回答应该包含清晰的观点。",
            completeness: AIReportData.EvaluationItem(level: completenessLevel, comment: "内容\(wordCount > 50 ? "较为完整" : "需要补充内容")"),
            language: AIReportData.EvaluationItem(level: wordCount > 80 ? "良好" : "一般", comment: "语言表达\(wordCount > 80 ? "较为流畅" : "有待提升")"),
            creativity: AIReportData.EvaluationItem(level: "一般", comment: "可以尝试加入更多个人见解"),
            suggestions: ["建议先理清思路", "尝试用更丰富的词语", "注意表达连贯性"],
            encouragement: "继续努力！多练习会越来越棒！"
        )
        self.aiReport = fallbackReport
        self.isLoadingReport = false
    }
    
    func useFallbackDiscussionReport() {
        let wordCount = discussionTranscript.count
        
        var score = 70
        var completenessLevel = "良好"
        var completenessComment = "能够参与讨论"
        
        if wordCount > 200 {
            score = 85
            completenessLevel = "优秀"
            completenessComment = "积极参与讨论，观点丰富"
        } else if wordCount < 50 {
            score = 50
            completenessLevel = "待加强"
            completenessComment = "发言较少，需要更积极参与"
        }
        
        let fallbackReport = AIReportData(
            score: score,
            scoreReason: "根据讨论参与度自动评估",
            standardStory: "小组讨论的示范：首先清晰表达自己的立场，然后说明理由，最后回应同学观点。",
            completeness: AIReportData.EvaluationItem(level: completenessLevel, comment: completenessComment),
            language: AIReportData.EvaluationItem(level: wordCount > 100 ? "良好" : "一般", comment: "语言表达\(wordCount > 100 ? "较为流畅" : "可以进一步提升")"),
            creativity: AIReportData.EvaluationItem(level: "一般", comment: "可以尝试提出更多创新观点"),
            suggestions: ["多倾听他人意见", "提出更多建设性观点", "注意讨论时间管理"],
            encouragement: "做得很好！继续保持讨论的积极性！"
        )
        self.aiReport = fallbackReport
        self.isLoadingReport = false
    }
}


// MARK: - 预览
struct TSAChineseStoryView_Previews: PreviewProvider {
    static var previews: some View {
        TSAChineseStoryView(grade: "小六", questionType: .discussion, language: "普通话")
    }
}

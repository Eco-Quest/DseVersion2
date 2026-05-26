//
//  TSAChineseStoryView.swift
//  dse_test
//
//  Created by Matt on 2026/5/23.
//

import SwiftUI
import Speech
import AVFoundation

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

// MARK: - 讨论题型
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
        case discussion        // 小六：讨论
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
        case discussion = "同学讨论"
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
                    print("  小六讨论数量：\(qTypes.discussion.items.count)")
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
            print("📖 随机抽取【小六-讨论】：\(item.topic)")
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

// MARK: - AnimatedGIFView
struct AnimatedGIFView: UIViewRepresentable {
    let gifName: String
    var isAnimating: Bool = true
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        
        let imageView = UIImageView()
        imageView.tag = 100
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        loadGIF(into: imageView)
        
        containerView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let imageView = uiView.viewWithTag(100) as? UIImageView else { return }
        
        if isAnimating {
            if imageView.animationImages == nil || imageView.animationImages?.isEmpty == true {
                loadGIF(into: imageView)
            }
            imageView.startAnimating()
        } else {
            imageView.stopAnimating()
        }
    }
    
    private func loadGIF(into imageView: UIImageView) {
        if let gifImage = UIImage.animatedGIF(named: gifName) {
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.startAnimating()
            return
        }
        
        if let path = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let gifImage = UIImage.animatedGIF(at: path) {
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.startAnimating()
            return
        }
        
        if let path = Bundle.main.path(forResource: gifName, ofType: nil),
           let gifImage = UIImage.animatedGIF(at: path) {
            imageView.image = gifImage
            imageView.animationImages = gifImage.images
            imageView.animationDuration = gifImage.duration
            imageView.startAnimating()
            return
        }
        
        imageView.image = UIImage(systemName: "hourglass")
        imageView.tintColor = .white
    }
}

// MARK: - UIImage GIF 扩展
extension UIImage {
    static func animatedGIF(named name: String) -> UIImage? {
        guard let path = Bundle.main.path(forResource: name, ofType: "gif") else {
            return nil
        }
        return animatedGIF(at: path)
    }
    
    static func animatedGIF(at path: String) -> UIImage? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        var images: [UIImage] = []
        var duration: TimeInterval = 0
        
        let count = CGImageSourceGetCount(source)
        for i in 0..<count {
            if let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(UIImage(cgImage: cgImage))
                
                let frameDuration = getFrameDuration(from: source, at: i)
                duration += frameDuration
            }
        }
        
        return UIImage.animatedImage(with: images, duration: duration)
    }
    
    private static func getFrameDuration(from source: CGImageSource, at index: Int) -> TimeInterval {
        let defaultDuration: TimeInterval = 0.1
        
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [String: Any],
              let gifProps = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any] else {
            return defaultDuration
        }
        
        if let delayTime = gifProps[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
            return TimeInterval(delayTime.doubleValue)
        }
        
        return defaultDuration
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
                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                .fill(Color.white)
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
                .stroke(Color.gray.opacity(0.3), lineWidth: 1.5)
                .fill(Color.white)
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

// MARK: - 主视图
struct TSAChineseStoryView: View {
    // 年级参数（由外部传入）
    let grade: String  // "小三" 或 "小六"
    let fixedQuestionType: StoryConfig.StoryType?  // 固定题型（小六使用，nil 表示随机）
    let language: String  // 语言参数 "粤语" 或 "普通话"
    
    // 计时相关
    @State private var currentStage: Stage = .preparing
    @State private var timeRemaining = 180
    @State private var timer: Timer?
    
    // 语音识别相关
    @State private var isRecording = false
    @State private var audioEngine = AVAudioEngine()
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    
    // 根据传入的语言动态设置语音识别器
    private var speechRecognizer: SFSpeechRecognizer? {
        let localeIdentifier: String
        switch language {
        case "普通话":
            localeIdentifier = "zh-CN"  // 普通话（简体中文）
        default:  // 粤语
            localeIdentifier = "zh-HK"  // 繁体中文（香港）
        }
        return SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier))
    }
    
    // 录音回放相关
    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordingURL: URL?
    
    // 存储识别到的文字
    @State private var fullTranscript = ""
    
    // AI 报告相关
    @State private var aiReport: AIReportData?
    @State private var showReport = false
    @State private var isLoadingReport = false
    
    // 故事配置
    @State private var storyConfig: StoryConfig?
    @State private var isLoadingStory = true
    @State private var loadError: String?
    
    // 阿里云 API 配置
    private let aliyunEndpoint = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
    private let aliyunApiKey = "sk-92262754eca4423a9e2e5b84ebe0af5c"
    
    // 主题色
    private let themeColor = Color("SelectionColor")
    private let themeLightColor = Color("ziselansecolor")
    
    // 故事管理器
    @StateObject private var storyManager = StoryManager()
    
    enum Stage {
        case preparing, speaking, finished
    }
    
    // 指定题型初始化
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
    
    // 获取年级显示名称
    func getGradeDisplayName() -> String {
        return grade == "小三" ? "小三TSA中国语文" : "小六TSA中国语文"
    }
    
    // 根据题型显示不同副标题
    func getSubtitle() -> String {
        guard let config = storyConfig else { return "加载中..." }
        switch config.type {
        case .pictureStory:
            return "看图说故事"
        case .oralReport:
            return "口头报告"
        case .discussion:
            return "小组讨论"
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
                    case .speaking: return "请开始讲述"
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
                            .multilineTextAlignment(.center)
                    } else {
                        Text("请用3分钟时间准备你的回答")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else if currentStage == .speaking {
                    if storyConfig?.type == .pictureStory {
                        Text("你有1分钟来讲故事")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else if storyConfig?.type == .oralReport {
                        Text("请根据题目进行口头报告（1分钟）")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("请根据题目与同学讨论（1分钟）")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
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
                    case .speaking: return "请开始讲述"
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
                            .multilineTextAlignment(.center)
                    } else {
                        Text("请用3分钟时间准备你的回答")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                } else if currentStage == .speaking {
                    if storyConfig?.type == .pictureStory {
                        Text("正在录音中...")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else if storyConfig?.type == .oralReport {
                        Text("请根据题目进行口头报告")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("请根据题目与同学讨论")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
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
    }
    
    // MARK: - 题目内容视图（用于口头报告和讨论）
    @ViewBuilder
    var questionContentView: some View {
        if let config = storyConfig, config.type != .pictureStory, let questionText = config.pictureDescriptions.first {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(themeLightColor.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 学生须知
    @ViewBuilder
    var studentNoticeView: some View {
        if storyConfig?.type == .pictureStory {
            // 看图说故事的须知
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
                    Text("2. 然后用一分钟时间，依图画内容说一个完整故事，录音会自动开始和停止。")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                        .lineSpacing(5)
                }
            }
            
            HStack(spacing: 6) {
                Text("请细心观察以下图画，然后讲述一个完整的故事。")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineSpacing(5)
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
                
                Text("请用三分钟时间准备，然后进行一分钟的口头报告。报告时请清晰表达你的观点和感受。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
            }
        } else {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text("📋 学生须知：")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Text("请用三分钟时间准备，然后与同学进行一分钟的讨论。请积极发表你的意见，并尊重他人的观点。")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .lineSpacing(5)
            }
        }
    }
    
    // MARK: - 报告内容视图
    @ViewBuilder
    func ReportContentView(report: AIReportData) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                
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
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("详细评估")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(themeColor)
                    
                    EvaluationCard(title: "内容完整性", level: report.completeness.level, comment: report.completeness.comment)
                    EvaluationCard(title: "语言表达", level: report.language.level, comment: report.language.comment)
                    EvaluationCard(title: "创意表现", level: report.creativity.level, comment: report.creativity.comment)
                }
                
                if let url = recordingURL {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(themeColor)
                                .font(.system(size: 16))
                            Text("你的录音")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(themeColor)
                        }
                        AudioPlaybackView(audioURL: url)
                    }
                }
                
                if let config = storyConfig, config.type == .pictureStory {
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
                
                Button(action: {
                    HapticFeedbackManager.medium()
                    resetAll()
                    
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
            .padding(20)
        }
        .background(Color("systemBackgroundColor"))
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
            AnimatedGIFView(gifName: "大象等待", isAnimating: true)
                .frame(width: 180, height: 180)
            Text("正在评估...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            Text("请稍等片刻约5-10秒")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("systemBackgroundColor"))
    }
    
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
                        ReportContentView(report: report)
                    }
                } else if let config = storyConfig {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            headerView
                            stageStatusView
                            Divider()
                            
                            studentNoticeView
                            
                            // 如果是口头报告或讨论，显示题目
                            if config.type != .pictureStory {
                                questionContentView
                            }
                            
                            // 显示图片（看图说故事时）
                            if config.type == .pictureStory && !config.images.isEmpty {
                                VStack(spacing: 24) {
                                    ForEach(0..<config.images.count, id: \.self) { index in
                                        PictureRow(num: index + 1, imageName: config.images[index])
                                    }
                                }
                            }
                            
                            Divider()
                            
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
                            
                            Spacer(minLength: 20)
                        }
                        .padding(20)
                    }
                    .background(Color("systemBackgroundColor"))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showReport && (currentStage == .preparing || currentStage == .speaking) {
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
        
        // 等待 storyManager 加载完成
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
        
        // 小六且指定了题型时，使用指定题型
        if grade == "小六", let fixedType = fixedQuestionType {
            let type = storyManager.convertToQuestionType(from: fixedType)
            if let config = storyManager.randomStoryConfig(for: grade, type: type) {
                storyConfig = config
                isLoadingStory = false
                startPreparing()
                return
            }
        }
        
        // 默认随机抽取
        if let config = storyManager.randomStoryConfig(for: grade) {
            storyConfig = config
            isLoadingStory = false
            startPreparing()
        } else {
            loadError = "无法加载\(grade)的数据"
            isLoadingStory = false
        }
    }
    
    // MARK: - 辅助函数
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
        timeRemaining = 180
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
    
    func finishStory() {
        timer?.invalidate()
        timer = nil
        
        stopRecording()
        stopRecordingToFile()
        
        showReport = true
        isLoadingReport = true
        
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
        aiReport = nil
        showReport = false
        isLoadingReport = false
        recordingURL = nil
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
    
    // MARK: - AI 报告生成
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
        
        // 语言提示
        let languageHint = language == "普通话" ? "普通话（简体中文）" : "粤语（繁体中文）"
        
        // 根据不同题型构建不同的 prompt
        var prompt = ""
        
        if config.type == .pictureStory {
            let pictureDescriptionsText = config.pictureDescriptions.enumerated().map { index, desc in
                "图\(index + 1): \(desc)"
            }.joined(separator: "\n")
            
            prompt = """
            你是一个专业的小学语文老师，熟悉香港\(grade)TSA中国语文评估标准（口语评估）。请根据图画内容，先自动生成一个标准答案故事，然后分析学生的口语故事，并以JSON格式返回结果。评分采用100分制。
            
            注意：学生使用的语言是 \(languageHint)。

            【题目主题】
            \(config.topic)

            【图画内容描述】
            \(pictureDescriptionsText)

            【学生的口语故事】
            \(fullTranscript)

            【返回格式要求】
            必须严格按照以下JSON格式返回，不要包含任何其他文字：
            {
                "score": 85,
                "scoreReason": "故事完整，语言流畅，角色齐全",
                "standardStory": "标准答案故事（200-300字）",
                "completeness": {"level": "良好", "comment": "故事结构完整，情节连贯"},
                "language": {"level": "良好", "comment": "语言表达流畅，用词恰当"},
                "creativity": {"level": "一般", "comment": "按照图画顺序讲述，可加入更多创意"},
                "suggestions": ["建议1", "建议2", "建议3"],
                "encouragement": "鼓励的话"
            }

            注意：level 只能是"优秀"、"良好"、"一般"、"待加强"中的一个。
            score 范围 0-100。
            """
        } else if config.type == .oralReport {
            let questionText = config.pictureDescriptions.first ?? ""
            prompt = """
            你是一个专业的小学语文老师，熟悉香港\(grade)TSA中国语文评估标准（口语评估）。请分析学生的口头报告，并以JSON格式返回结果。评分采用100分制。
            
            注意：学生使用的语言是 \(languageHint)。

            【报告题目】
            \(questionText)

            【学生的口头报告内容】
            \(fullTranscript)

            【返回格式要求】
            必须严格按照以下JSON格式返回，不要包含任何其他文字：
            {
                "score": 85,
                "scoreReason": "观点清晰，表达流畅",
                "standardStory": "一份示范性的口头报告（200-300字）",
                "completeness": {"level": "良好", "comment": "内容完整，观点明确"},
                "language": {"level": "良好", "comment": "语言表达流畅，用词恰当"},
                "creativity": {"level": "一般", "comment": "可以加入更多个人见解"},
                "suggestions": ["建议1", "建议2", "建议3"],
                "encouragement": "鼓励的话"
            }

            注意：level 只能是"优秀"、"良好"、"一般"、"待加强"中的一个。
            score 范围 0-100。
            """
        } else {
            let questionText = config.pictureDescriptions.first ?? ""
            prompt = """
            你是一个专业的小学语文老师，熟悉香港\(grade)TSA中国语文评估标准（口语评估）。请分析学生的讨论发言，并以JSON格式返回结果。评分采用100分制。
            
            注意：学生使用的语言是 \(languageHint)。

            【讨论题目】
            \(questionText)

            【学生的讨论内容】
            \(fullTranscript)

            【返回格式要求】
            必须严格按照以下JSON格式返回，不要包含任何其他文字：
            {
                "score": 85,
                "scoreReason": "观点清晰，积极参与讨论",
                "standardStory": "示范性的讨论发言（200-300字）",
                "completeness": {"level": "良好", "comment": "观点表达完整"},
                "language": {"level": "良好", "comment": "语言表达流畅"},
                "creativity": {"level": "一般", "comment": "可以提出更多建设性意见"},
                "suggestions": ["建议1", "建议2", "建议3"],
                "encouragement": "鼓励的话"
            }

            注意：level 只能是"优秀"、"良好"、"一般"、"待加强"中的一个。
            score 范围 0-100。
            """
        }
        
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
                ["role": "system", "content": "你是一个专业的小学语文老师，只返回纯JSON格式。"],
                ["role": "user", "content": prompt]
            ],
            "stream": false,
            "temperature": 0.5,
            "max_tokens": 2000
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
                    useFallbackReport()
                    return
                }
                
                guard let data = data else {
                    useFallbackReport()
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
                    useFallbackReport()
                } catch {
                    print("解析错误：\(error)")
                    useFallbackReport()
                }
            }
        }.resume()
        
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
                scoreReason: "根据内容长度自动评估（网络连接暂时不可用）",
                standardStory: "根据题目要求，一个完整的回答应该包含清晰的观点和充分的理由。",
                completeness: AIReportData.EvaluationItem(level: completenessLevel, comment: "内容\(wordCount > 50 ? "较为完整" : "需要补充内容")"),
                language: AIReportData.EvaluationItem(level: wordCount > 80 ? "良好" : "一般", comment: "语言表达\(wordCount > 80 ? "较为流畅" : "有待提升")"),
                creativity: AIReportData.EvaluationItem(level: "一般", comment: "可以尝试加入更多个人见解"),
                suggestions: ["建议先理清思路再回答", "尝试用更丰富的词语表达观点", "可以加入更多具体例子", "注意表达的前后连贯性"],
                encouragement: "继续努力！多练习会越来越棒！"
            )
            self.aiReport = fallbackReport
            self.isLoadingReport = false
        }
    }
}

// MARK: - 预览
struct TSAChineseStoryView_Previews: PreviewProvider {
    static var previews: some View {
        TSAChineseStoryView(grade: "小三", language: "粤语")
    }
}

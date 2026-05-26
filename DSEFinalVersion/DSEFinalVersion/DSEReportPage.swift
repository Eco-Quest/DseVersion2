import SwiftUI
import AVKit
import AVFoundation

// MARK: - 对话回顾用的消息模型
struct ReviewChatMessage: Identifiable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
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
            return speakerName ?? "Group Member"
        }
    }
}

// MARK: - 对话回顾聊天气泡（与 AIChatBubble 样式一致）
struct ReviewChatBubble: View {
    let message: ReviewChatMessage
    
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
                    if message.role == .user {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(Color(hex: "5C43A8"))
                            .font(.caption)
                    } else {
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
            }
            
            if message.role == .ai {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

// MARK: - 对话回顾视图（使用聊天气泡样式）
// MARK: - 对话回顾视图（使用聊天气泡样式，直接接收 ChatMessage 数组）
struct ConversationReviewView: View {
    let chatMessages: [ChatMessage]  // 直接使用 ChatMessage 数组
    let preparationNote: String
    
    // 将 ChatMessage 转换为 ReviewChatMessage
    private var messages: [ReviewChatMessage] {
        return chatMessages.map { message in
            ReviewChatMessage(
                role: message.role == .user ? .user : .ai,
                content: message.content,
                timestamp: message.timestamp,
                speakerName: message.speakerName
            )
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if messages.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "bubble.left.and.bubble.right")
                            .font(.system(size: 50))
                            .foregroundColor(Color("blackorwhitecolor").opacity(0.8))
                        Text("暂无对话记录")
                            .font(.headline)
                            .foregroundColor(Color("blackorwhitecolor").opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    ForEach(messages) { message in
                        ReviewChatBubble(message: message)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
        }
        .background(Color("systemBackgroundColor"))
    }
}

// MARK: - 准备笔记视图（接收从 VideoCallView 传递的笔记）
struct PreparationNotesView: View {
    @State private var notes: String
   
    
    init(preparationNote: String = "") {
        _notes = State(initialValue: preparationNote)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("个人笔记")
                    .font(.headline)
                
                // 使用 TextField 或可自动扩展的文本框
                TextField("输入笔记...", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                 
                    .background(Color.clear)
                    .cornerRadius(12)
                    .lineLimit(5...)
            }
            .padding()
        }
        .background(.clear)
        .onAppear {
            loadNotes()
        }
    }
    
    private func saveNotes() {
        UserDefaults.standard.set(notes, forKey: "preparationNotes")
        print("笔记已保存")
    }
    
    private func loadNotes() {
        if notes.isEmpty {
            notes = UserDefaults.standard.string(forKey: "preparationNotes") ?? ""
        }
    }
}

// MARK: - 清单项目模型
struct ChecklistItem: Identifiable {
    let id = UUID()
    var title: String
    var isChecked: Bool
}

// MARK: - 自定义视频播放器（无系统控件，支持全屏）
struct CustomVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer?
    @Binding var isFullScreen: Bool
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false
        controller.videoGravity = .resizeAspect
        controller.view.backgroundColor = .black
        
        controller.delegate = context.coordinator
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var parent: CustomVideoPlayer
        
        init(_ parent: CustomVideoPlayer) {
            self.parent = parent
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            parent.isFullScreen = true
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, willEndFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            parent.isFullScreen = false
        }
    }
}

// MARK: - 加载视图
struct LoadingView111: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
                
                Text("正在评估中...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
    }
}

// MARK: - 自定义视频控制栏（一行布局，固定在底部）
struct VideoControlBar: View {
    @Binding var isPlaying: Bool
    @Binding var currentTime: Double
    let duration: Double
    let customPurple: Color
    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    let onFullScreen: () -> Void
    
    @State private var isDragging = false
    @State private var dragTempTime: Double = 0
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
            }
            
            Text(formatTime(currentTime))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 45, alignment: .leading)
            
            GeometryReader { geometry in
                let width = geometry.size.width
                
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 3)
                        .cornerRadius(1.5)
                    
                    Rectangle()
                        .fill(customPurple)
                        .frame(width: width * CGFloat(currentTime / (duration == 0 ? 1 : duration)), height: 3)
                        .cornerRadius(1.5)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .position(
                            x: width * CGFloat(currentTime / (duration == 0 ? 1 : duration)),
                            y: 6
                        )
                }
                .frame(height: 12)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let progress = min(max(0, value.location.x / width), 1)
                            let newTime = progress * duration
                            isDragging = true
                            dragTempTime = newTime
                            currentTime = newTime
                        }
                        .onEnded { _ in
                            isDragging = false
                            onSeek(dragTempTime)
                        }
                )
                .onTapGesture { location in
                    let progress = min(max(0, location.x / width), 1)
                    let newTime = progress * duration
                    currentTime = newTime
                    onSeek(newTime)
                }
            }
            .frame(height: 12)
            
            Text(formatTime(duration))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 45, alignment: .trailing)
            
            Button(action: onFullScreen) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: SwiftUI.Gradient(colors: [
                    Color.black.opacity(0),
                    Color.black.opacity(0.7),
                    Color.black.opacity(0.9)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func formatTime(_ time: Double) -> String {
        guard time.isFinite && !time.isNaN && time > 0 else {
            return "00:00"
        }
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - 声量变化趋势图表
struct VolumeChartView: View {
    let volumePoints: [DSEVolumeSample]
    let volumeStabilityText: String
    let color: Color
    
    @State private var selectedPointIndex: Int? = nil
    
    private let pointWidth: CGFloat = 60
    private let chartLeftPadding: CGFloat = 20
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("声量变化")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                if let avg = volumePoints.map({ $0.value }).average() {
                    Text("平均: \(String(format: "%.1f", avg)) dB")
                        .font(.caption)
                        .foregroundColor(color)
                }
            }
            
            HStack(spacing: 4) {
                Text(volumeStabilityText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 4) {
                    let screenWidth = UIScreen.main.bounds.width
                    let dataWidth = CGFloat(volumePoints.count) * pointWidth
                    // 网格线宽度：铺满屏幕
                    let gridWidth = max(dataWidth, screenWidth - chartLeftPadding - 40)
                    let height: CGFloat = 120
                    let values = volumePoints.map { $0.value }
                    let maxValue = (values.max() ?? 70) + 10
                    let minValue = (values.min() ?? 30) - 10
                    let range = maxValue - minValue
                    
                    // 图表区域
                    ZStack(alignment: .topLeading) {
                        // 背景网格线 - 铺满屏幕
                        VStack(spacing: 0) {
                            ForEach(0...4, id: \.self) { i in
                                Spacer()
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 1)
                                if i < 4 {
                                    Spacer()
                                }
                            }
                        }
                        .frame(width: gridWidth, height: height)
                        
                        // 折线和填充 - 只在数据区域，使用 dataWidth
                        if volumePoints.count > 1 {
                            // 折线
                            Path { path in
                                let points = volumePoints.enumerated().map { index, sample in
                                    let x = CGFloat(index) * pointWidth + pointWidth / 2
                                    let y = height - (CGFloat((sample.value - minValue) / range) * height)
                                    return CGPoint(x: x, y: min(max(y, 0), height))
                                }
                                
                                path.move(to: points[0])
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                            }
                            .stroke(color, lineWidth: 1.5)
                            
                            // 填充区域
                            Path { path in
                                let points = volumePoints.enumerated().map { index, sample in
                                    let x = CGFloat(index) * pointWidth + pointWidth / 2
                                    let y = height - (CGFloat((sample.value - minValue) / range) * height)
                                    return CGPoint(x: x, y: y)
                                }
                                
                                path.move(to: CGPoint(x: pointWidth / 2, y: height))
                                path.addLine(to: points[0])
                                for point in points.dropFirst() {
                                    path.addLine(to: point)
                                }
                                path.addLine(to: CGPoint(x: CGFloat(volumePoints.count - 1) * pointWidth + pointWidth / 2, y: height))
                                path.closeSubpath()
                            }
                            .fill(color.opacity(0.15))
                        }
                        
                        // 数据点
                        ForEach(Array(volumePoints.enumerated()), id: \.offset) { index, sample in
                            let x = CGFloat(index) * pointWidth + pointWidth / 2
                            let y = height - (CGFloat((sample.value - minValue) / range) * height)
                            let pointY = min(max(y, 0), height)
                            
                            // 数值标签
                            Text("\(Int(sample.value))dB")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(color)
                                .background(
                                    .clear
                                )
                                .position(x: x, y: pointY - 12)
                            
                            // 圆点
                            Circle()
                                .fill(Color.white)
                                .frame(width: 8, height: 8)
                                .overlay(
                                    Circle()
                                        .stroke(color, lineWidth: 1.5)
                                )
                                .position(x: x, y: pointY)
                        }
                    }
                    .frame(width: gridWidth, height: height)
                    .overlay(alignment: .leading) {
                        VStack(spacing: 0) {
                            ForEach(0...4, id: \.self) { i in
                                let value = maxValue - (CGFloat(i) / 4) * CGFloat(range)
                                Text(String(format: "%.0f", value))
                                    .font(.system(size: 8))
                                    .foregroundColor(.gray)
                                    .frame(width: 30, alignment: .trailing)
                                Spacer()
                            }
                        }
                        .frame(height: height)
                        .offset(x: -35)
                    }
                    
                    // ✅ 修改：X轴时间标签 - 左对齐，不使用居中
                    HStack(spacing: 0) {
                        ForEach(Array(volumePoints.enumerated()), id: \.offset) { index, sample in
                            Text(formatShortTimeLabel(sample.timestamp))
                                .font(.system(size: 8))
                                .foregroundColor(.gray)
                                .frame(width: pointWidth, alignment: .center)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .frame(width: gridWidth, height: 20, alignment: .leading)  // 左对齐
                }
                .padding(.leading, chartLeftPadding)
            }
            .frame(height: 170)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 0)
        .background(.clear)
        .cornerRadius(10)
        
        Divider()
    }
    
    private func formatShortTimeLabel(_ seconds: Double) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}


// MARK: - 语速仪表盘
struct PaceSpeedometerView: View {
    let pace: Double
    let minPace: Double = 80
    let maxPace: Double = 180
    let color: Color
    
    var percentage: Double {
        min(max((pace - minPace) / (maxPace - minPace), 0), 1)
    }
    
    var speedLevel: (text: String, description: String, color: Color) {
        switch pace {
        case ..<100:
            return ("偏慢", "语速较慢，可能让听众感到拖沓，建议适当加快节奏", Color.orange)
        case 100...140:
            return ("适中", "语速适中，清晰易懂，继续保持当前节奏", Color.green)
        default:
            return ("偏快", "语速偏快，可能影响理解，建议适当放慢", Color.red)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("语速分析")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(speedLevel.text)")
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            HStack(spacing: 4) {
                Text(speedLevel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            
            ZStack {
                Circle()
                    .trim(from: 0.5, to: 1.0)
                    .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(0))
                    .offset(y: 60)
                
                Circle()
                    .trim(from: 0.5, to: 0.5 + (percentage * 0.5))
                    .stroke(color, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(0))
                    .animation(.easeInOut(duration: 1.0), value: percentage)
                    .offset(y: 60)
                
                VStack(spacing: 2) {
                    Text("平均语速")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(Int(pace))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(color)
                    Text("字/分钟")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .position(x: 100, y: 130)
            }
            .frame(width: 200, height: 130)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 0)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 0)
        .background(.clear)
        .cornerRadius(10)
        
        Divider()
    }
}

// MARK: - 饼图形状
// MARK: - 饼图形状
struct PieSliceShape111: Shape {
    let startAngle: Double
    let endAngle: Double
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        
        path.move(to: center)
        path.addArc(center: center, radius: radius, startAngle: Angle(degrees: startAngle), endAngle: Angle(degrees: endAngle), clockwise: false)
        path.closeSubpath()
        
        return path
    }
}

// MARK: - 眼神接触饼图
struct EyeContactPieChartView: View {
    let eyeContactPercentages: [String: Double]
    let color: Color
    
    struct PieSlice: Identifiable {
        let id = UUID()
        let name: String
        let percentage: Double
        let color: Color
        let startAngle: Double
        let endAngle: Double
        let midAngle: Double
    }
    
    private let sliceColors: [String: Color] = [
        "center": Color(hex: "5C43A9"),
        "left": Color(hex: "3EA0C6"),
        "right": Color(hex: "63BEF3"),
        "lookAway": Color(hex: "FFCC41"),
        "noFace": Color(hex: "445CB4")
    ]
    
    private let sliceNames: [String: String] = [
        "center": "直视镜头",
        "left": "看左方",
        "right": "看右方",
        "lookAway": "视线游离",
        "noFace": "未录到面部"
    ]
    
    var slices: [PieSlice] {
        let order = ["center", "left", "right", "lookAway", "noFace"]
        var startAngle = 0.0
        var result: [PieSlice] = []
        
        for key in order {
            let percentage = eyeContactPercentages[key] ?? 0
            if percentage > 0 {
                let endAngle = startAngle + (percentage / 100) * 360
                let midAngle = startAngle + (percentage / 100) * 180
                result.append(PieSlice(
                    name: sliceNames[key] ?? key,
                    percentage: percentage,
                    color: sliceColors[key] ?? color,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    midAngle: midAngle
                ))
                startAngle = endAngle
            }
        }
        return result
    }
    
    // 所有图例项（包括0%）
    var allLegendItems: [(name: String, percentage: Double, color: Color)] {
        let order = ["center", "left", "right", "lookAway", "noFace"]
        return order.map { key in
            let percentage = eyeContactPercentages[key] ?? 0
            return (name: sliceNames[key] ?? key, percentage: percentage, color: sliceColors[key] ?? color)
        }
    }
    
    var dominantSlice: PieSlice? {
        slices.max(by: { $0.percentage < $1.percentage })
    }
    
    // 检查是否有数据
    var hasData: Bool {
        return !slices.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("眼神接触分析")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let dominant = dominantSlice {
                    Text(dominant.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dominant.color)
                }
            }
            
            HStack(spacing: 16) {
                ZStack {
                    if hasData {
                        ForEach(slices) { slice in
                            PieSliceShape111(startAngle: slice.startAngle, endAngle: slice.endAngle)
                                .fill(slice.color)
                        }
                        
                        ForEach(slices) { slice in
                            if slice.percentage >= 8 {
                                let angle = slice.midAngle * .pi / 180
                                let radius: CGFloat = 50
                                let x = 75 + radius * cos(angle)
                                let y = 75 + radius * sin(angle)
                                
                                Text(String(format: "%.0f%%", slice.percentage))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white)
                                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 0)
                                    .position(x: x, y: y)
                            }
                        }
                    } else {
                        // 无数据时显示灰色圆环
                        Circle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            .background(
                                Circle()
                                    .fill(Color.gray.opacity(0.05))
                            )
                    }
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 70, height: 70)
                    
                    VStack(spacing: 2) {
                        Text("眼神")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("分析")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 150, height: 150)
                .padding(.leading, 8)
                .padding(.trailing, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(allLegendItems, id: \.name) { item in
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(item.color)
                                .frame(width: 12, height: 12)
                                .cornerRadius(2)
                            
                            Text(item.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(String(format: "%.0f%%", item.percentage))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(item.percentage > 0 ? item.color : .gray)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.trailing, 8)
            }
            .padding(.horizontal, 0)
            .padding(.top, 20)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 0)
        .background(.clear)
        
        Divider()
    }
}


// MARK: - 表情条形图
struct EmotionBarChartView: View {
    let emotionPercentages: [String: Double]
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    struct EmotionData: Identifiable {
        let id = UUID()
        let name: String
        let percentage: Double
    }
    
    var emotions: [EmotionData] {
        let order = ["surprise", "joy", "sad", "calm", "fear", "disgust", "angry"]
        let names = ["惊讶", "喜悦", "悲伤", "平静", "害怕", "厌恶", "愤怒"]
        
        return zip(order, names).map { key, name in
            EmotionData(
                name: name,
                percentage: emotionPercentages[key] ?? 0
            )
        }
    }
    
    var dominantEmotion: EmotionData? {
        emotions.max(by: { $0.percentage < $1.percentage })
    }
    
    let maxY: Double = 100
    let yLabels = [100, 80, 60, 40, 20, 0]
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("面部表情")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if let dominant = dominantEmotion, dominant.percentage > 0 {
                    Text(dominant.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                }
            }
            
            HStack(alignment: .bottom, spacing: 8) {
                VStack(spacing: 0) {
                    ForEach(yLabels, id: \.self) { num in
                        Text("\(num)")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(secondaryTextColor)
                            .frame(height: 30)
                    }
                }
                .frame(width: 30)
                
                ZStack(alignment: .bottomLeading) {
                    VStack(spacing: 0) {
                        ForEach(0..<5) { i in
                            Divider()
                                .background(Color.primary.opacity(0.15))
                                .frame(height: 30)
                        }
                    }
                    
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(emotions) { emotion in
                            VStack(spacing: 6) {
                                Text(String(format: "%.1f", emotion.percentage))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(textColor)
                                
                                let barHeight = (CGFloat(emotion.percentage) / CGFloat(maxY)) * 120
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(color)
                                    .frame(height: max(barHeight, 2))
                                
                                Text(emotion.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(textColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.bottom, -4)
                }
            }
            .frame(height: 180)
            
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 14, height: 14)
                
                Text("百分比 (%)")
                    .font(.system(size: 12))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 38)
            .padding(.top, 12)
        }
        .padding(.vertical, 15)
        .padding(.horizontal, 0)
        .background(.clear)
        
        Divider()
    }
}

// MARK: - 填充词图表
struct FillerWordsChartView: View {
    let fillerWords: [String]
    let count: Int
    let color: Color
    
    var wordFrequency: [(word: String, count: Int)] {
        let grouped = Dictionary(grouping: fillerWords, by: { $0 })
        return grouped.map { ($0.key, $0.value.count) }.sorted { $0.count > $1.count }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("填充词统计")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                Spacer()
                Text("共 \(count) 次")
                    .font(.caption)
                    .foregroundColor(color)
            }
            
            if !fillerWords.isEmpty {
                let columns = [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ]
                
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(wordFrequency, id: \.word) { item in
                        VStack(spacing: 4) {
                            Text(item.word)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(color.opacity(0.12))
                                .cornerRadius(6)
                            
                            Text("\(item.count)次")
                                .font(.caption2)
                                .foregroundColor(color)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                HStack {
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("未检测到填充词")
                        .font(.caption)
                        .foregroundColor(.green)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 0)
        
        Divider()
    }
}

// MARK: - 说话轮次图表
struct SpeakingTurnsChartView: View {
    let speakingTurnDetails: [DSESpeakingTurnData]
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var totalTurns: Int { speakingTurnDetails.count }
    var totalWords: Int { speakingTurnDetails.map { $0.wordCount }.reduce(0, +) }
    var avgWordsPerTurn: Int { totalTurns > 0 ? totalWords / totalTurns : 0 }
    
    var maxWordCount: Int {
        let max = speakingTurnDetails.map { $0.wordCount }.max() ?? 100
        return ((max + 19) / 20) * 20
    }
    
    var yLabels: [Int] {
        let step = maxWordCount / 5
        return (0...5).map { $0 * step }.reversed()
    }
    
    var barWidth: CGFloat {
        let minWidth: CGFloat = 50
        let maxWidth: CGFloat = 80
        let totalWidth: CGFloat = UIScreen.main.bounds.width - 100
        let calculatedWidth = totalWidth / CGFloat(totalTurns)
        return min(max(calculatedWidth, minWidth), maxWidth)
    }
    
    // 获取屏幕宽度
    var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    // 数据区域宽度
    var dataAreaWidth: CGFloat {
        CGFloat(totalTurns) * (barWidth + 12)
    }
    
    // 总内容宽度（确保至少铺满屏幕）
    var contentWidth: CGFloat {
        max(dataAreaWidth, screenWidth - 30) // 减去Y轴标签宽度
    }
    
    private var textColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark ? .gray : .secondary
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("说话轮次分析")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("平均")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                    Text("\(avgWordsPerTurn)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(color)
                    Text("字/轮")
                        .font(.caption2)
                        .foregroundColor(secondaryTextColor)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(yLabels, id: \.self) { num in
                            Text("\(num)")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundColor(secondaryTextColor)
                                .frame(height: 24)
                        }
                    }
                    .frame(width: 30)
                    
                    ZStack(alignment: .bottomLeading) {
                        // 横线 - 铺满屏幕宽度
                        VStack(spacing: 0) {
                            ForEach(0..<5) { i in
                                Divider()
                                    .background(Color.primary.opacity(0.15))
                                    .frame(height: 24)
                            }
                        }
                        .frame(width: screenWidth - 30) // 减去Y轴标签宽度
                        
                        // 柱状图区域
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(speakingTurnDetails, id: \.turnIndex) { turn in
                                VStack(spacing: 6) {
                                    Text("\(turn.wordCount)字")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(textColor)
                                    
                                    let barHeight = (CGFloat(turn.wordCount) / CGFloat(maxWordCount)) * 120
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(color)
                                        .frame(width: barWidth, height: max(barHeight, 2))
                                    
                                    Text("第\(turn.turnIndex)轮")
                                        .font(.system(size: 10))
                                        .foregroundColor(textColor)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.7)
                                }
                                .frame(width: barWidth)
                            }
                        }
                        .padding(.bottom, -4)
                        .frame(width: dataAreaWidth, alignment: .leading)
                    }
                    .frame(width: contentWidth, alignment: .leading)
                }
                .padding(.horizontal, 0)
                Spacer().frame(height: 5)
            }
            .frame(height: 170)
            
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 14, height: 14)
                
                Text("字数")
                    .font(.system(size: 11))
                    .foregroundColor(textColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 38)
            .padding(.top, 0)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 0)
        .background(.clear)
        
        Divider()
    }
}

// MARK: - 评分卡片视图
struct ScoreCardView: View {
    let tabName: String?
    let score: Double
    let maxScore: Double = 7
    let accentColor: Color
    
    var percentage: Double {
        min(max(score / maxScore, 0), 1)
    }
    
    var displayTitle: String {
        if let tabName = tabName {
            return "\(tabName)(细项得分)"
        }
        return "具体得分"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text(displayTitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(score))/\(Int(maxScore))分")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(accentColor)
            }
        }
    }
}

// MARK: - 得分详情行
struct ScoreDetailRow: View {
    let title: String
    let score: Int
    let maxScore: Int
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var percentage: Double {
        Double(score) / Double(maxScore)
    }
    
    private var progressBackgroundColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.2) : Color.gray.opacity(0.2)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(score)/\(maxScore)分")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
                    .monospacedDigit()
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(progressBackgroundColor)
                        .frame(height: 4)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geometry.size.width * percentage, height: 4)
                }
            }
            .frame(height: 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 评级说明行
struct RatingRow: View {
    let level: String
    let range: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(level)
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 70, alignment: .leading)
            
            Text(range)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 细分得分详情弹窗
struct ScoreDetailSheet: View {
    let performance: DSEPerformance?
    let accentColor: Color
    @Environment(\.dismiss) private var dismiss
    
    private var pronunciationScore: Int {
        Int(performance?.pronunciationDelivery.score ?? 0)
    }
    
    private var communicationScore: Int {
        Int(performance?.communicationStrategies.score ?? 0)
    }
    
    private var vocabularyScore: Int {
        Int(performance?.vocabularyLanguagePatterns.score ?? 0)
    }
    
    private var ideasScore: Int {
        Int(performance?.ideasOrganization.score ?? 0)
    }
    
    var maxPerCategory: Int = 7
    
    var body: some View {
        NavigationView {
            List {
                ScoreDetailRow(
                    title: "发音与表达",
                    score: pronunciationScore,
                    maxScore: maxPerCategory,
                    color: accentColor
                )
                
                ScoreDetailRow(
                    title: "沟通技巧",
                    score: communicationScore,
                    maxScore: maxPerCategory,
                    color: accentColor
                )
                
                ScoreDetailRow(
                    title: "词汇与配搭",
                    score: vocabularyScore,
                    maxScore: maxPerCategory,
                    color: accentColor
                )
                
                ScoreDetailRow(
                    title: "灵感与组织",
                    score: ideasScore,
                    maxScore: maxPerCategory,
                    color: accentColor
                )
            }
            .listStyle(.insetGrouped)
            .navigationTitle("详细得分")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                    .font(.body)
                    .foregroundColor(accentColor)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 总体评分视图
struct OverallScoreView: View {
    let band: String
    let score: Int
    let maxScore: Int = 28
    let accentColor: Color
    let performance: DSEPerformance?
    
    @State private var showingDetails = false
    
    var percentage: Double {
        min(max(Double(score) / Double(maxScore), 0), 1)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("DSE模拟评级")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 8) {
                    Text("Level " + band)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(accentColor)
                    
                    Button(action: {
                        showingDetails = true
                    }) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDetails) {
            ScoreDetailSheet(performance: performance, accentColor: accentColor)
        }
    }
}

// MARK: - Array Extension for Average
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}

// MARK: - View Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner111(radius: radius, corners: corners))
    }
}

struct RoundedCorner111: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

// MARK: - DSEReportPage
struct DSEReportPage: View {
    let videoURL: URL?
    let performance: DSEPerformance?
    let chatMessages: [ChatMessage]  // 新增：接收对话消息数组
    let preparationNote: String
    
    @State private var selectedSegment = 0
    @State private var selectedAnalysisTab = 0
    @State private var selectedVideoTab = 0
    @State private var bottomPanelRatio: CGFloat = 1.0
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isFullScreen = false
    @State private var isLoading = false
    
    let analysisTabs = ["发音与表达", "沟通技巧", "词汇与配搭", "灵感与组织"]
    let videoTabs = ["对话回顾", "准备笔记"]
    private let customPurple = Color("ziselansecolor")

    private let minBottomRatio: CGFloat = 0.4
    private let maxBottomRatio: CGFloat = 1.0
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var statusObserver: NSKeyValueObservation?
    
    private let criteriaOrder: [DSECriterionType] = [
        .pronunciationDelivery,
        .communicationStrategies,
        .vocabularyLanguagePatterns,
        .ideasOrganization
    ]
    
    init(videoURL: URL?, performance: DSEPerformance? = nil, chatMessages: [ChatMessage] = [], preparationNote: String = "") {
        self.videoURL = videoURL
        self.performance = performance
        self.chatMessages = chatMessages
        self.preparationNote = preparationNote
    }
    
    private var currentCriterion: DSECriterionType {
        criteriaOrder[min(max(selectedAnalysisTab, 0), criteriaOrder.count - 1)]
    }
    
    private var currentScore: Double {
        guard let performance else { return 0 }
        switch selectedAnalysisTab {
        case 0:
            return performance.pronunciationDelivery.score
        case 1:
            return performance.communicationStrategies.score
        case 2:
            return performance.vocabularyLanguagePatterns.score ?? 0
        case 3:
            return performance.ideasOrganization.score ?? 0
        default:
            return 0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            let videoHeight: CGFloat = selectedSegment == 1 ? screenHeight * 0.35 : 0
            let panelHeight = screenHeight * bottomPanelRatio
            
            VStack(spacing: 0) {
                customNavigationBar
                
                if selectedSegment == 0 {
                    analysisTabBarView
                        .frame(height: 50)
                } else {
                    videoTabBarView
                        .frame(height: 50)
                }
                
                if selectedSegment == 1 {
                    ZStack(alignment: .bottom) {
                        ZStack {
                
                                CustomVideoPlayer(player: player, isFullScreen: $isFullScreen)
                                    .frame(height: videoHeight)
                                    .onTapGesture {
                                        handlePlayPause()
                                    }
                                    .opacity(isLoading ? 0 : 1)
                                
                              
                            
                           
                            if isLoading {
                                LoadingView111()
                                    .frame(height: videoHeight)
                            }
                        }
                        
                        if !isFullScreen && !isLoading {
                            VideoControlBar(
                                isPlaying: $isPlaying,
                                currentTime: $currentTime,
                                duration: duration,
                                customPurple: customPurple,
                                onPlayPause: handlePlayPause,
                                onSeek: handleSeek,
                                onFullScreen: handleFullScreen
                            )
                        }
                    }
                    .frame(height: videoHeight)
                    .onAppear {
                        setupPlayer()
                    }
                }
                
                bottomPanelView
                    .frame(height: panelHeight)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let delta = -value.translation.height / screenHeight
                                let newRatio = bottomPanelRatio + delta
                                if newRatio >= minBottomRatio && newRatio <= maxBottomRatio {
                                    bottomPanelRatio = newRatio
                                }
                            }
                    )
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background(Color(.systemBackground))
        .onDisappear {
            statusObserver?.invalidate()
            player?.pause()
            player = nil
        }
    }
    
    private func handleSegmentChange() {
        withAnimation(.easeInOut(duration: 0.3)) {
            if selectedSegment == 0 {
                bottomPanelRatio = 1.0
            } else {
                bottomPanelRatio = 0.5
            }
        }
    }
    
    private func handlePlayPause() {
        if isPlaying {
            player?.pause()
            isPlaying = false
        } else {
            player?.play()
            isPlaying = true
        }
    }
    
    private func handleSeek(_ time: Double) {
        let seekTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: seekTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }
    
    private func handleFullScreen() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        func findAVPlayerViewController(from viewController: UIViewController) -> AVPlayerViewController? {
            if let avPlayerVC = viewController as? AVPlayerViewController {
                return avPlayerVC
            }
            for child in viewController.children {
                if let found = findAVPlayerViewController(from: child) {
                    return found
                }
            }
            return nil
        }
        
        if let avPlayerVC = findAVPlayerViewController(from: rootVC) {
            if isFullScreen {
                avPlayerVC.dismiss(animated: true)
            } else {
                let fullScreenPlayer = AVPlayerViewController()
                fullScreenPlayer.player = player
                fullScreenPlayer.showsPlaybackControls = true
                fullScreenPlayer.videoGravity = .resizeAspect
                
                rootVC.present(fullScreenPlayer, animated: true) {
                    fullScreenPlayer.player?.play()
                }
            }
        }
    }
    
    private func setupPlayer() {
        let finalVideoURL: URL?
        
        if let videoURL = videoURL {
            finalVideoURL = videoURL
            isLoading = true
            print("使用传入的视频: \(videoURL)")
        } else {
            finalVideoURL = Bundle.main.url(forResource: "test", withExtension: "MOV")
            isLoading = false
            print("使用默认视频: test.mov")
        }
        
        guard let url = finalVideoURL else {
            print("找不到视频文件")
            isLoading = false
            return
        }
        
        player = AVPlayer(url: url)
        
        if let playerItem = player?.currentItem {
            statusObserver = playerItem.observe(\.status, options: [.new, .initial]) { [self] item, _ in
                DispatchQueue.main.async {
                    if item.status == .readyToPlay {
                        isLoading = false
                        print("视频加载完成")
                    } else if item.status == .failed {
                        isLoading = false
                        print("视频加载失败: \(item.error?.localizedDescription ?? "未知错误")")
                    }
                }
            }
        }
        
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentTime = time.seconds
            if let duration = player?.currentItem?.duration.seconds, duration.isFinite {
                self.duration = duration
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
            currentTime = 0
            player?.seek(to: .zero)
        }
        
        isPlaying = false
    }
    
    private var customNavigationBar: some View {
        ZStack {
            Text("表现报告")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(Color(hex:"63BEF3"))
                }
                .frame(width: 44, height: 44)
                
                Spacer()
            }
            .padding(.leading, 10)
            
            HStack {
                Spacer()
                
                Picker("", selection: $selectedSegment) {
                    Text("分析").tag(0)
                    Text("影片").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
                .padding(.trailing, 10)
                .onChange(of: selectedSegment) { _ in
                    handleSegmentChange()
                }
                .onAppear {
                    UISegmentedControl.appearance().setTitleTextAttributes(
                        [.foregroundColor: UIColor(red: 62/255, green: 159/255, blue: 197/255, alpha: 1.0)],
                        for: .selected
                    )
                    UISegmentedControl.appearance().setTitleTextAttributes(
                        [.foregroundColor: UIColor.white],
                        for: .normal
                    )
                    UISegmentedControl.appearance().selectedSegmentTintColor = UIColor.white
                    UISegmentedControl.appearance().backgroundColor = UIColor(red: 62/255, green: 159/255, blue: 197/255, alpha: 1.0)
                }
            }
        }
        .frame(height: 44)
        .background(Color(.systemBackground))
    }
    
    private var analysisTabBarView: some View {
        HStack(spacing: 0) {
            ForEach(analysisTabs.indices, id: \.self) { idx in
                Text(analysisTabs[idx])
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedAnalysisTab == idx ? .white : .gray)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .minimumScaleFactor(0.9)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(selectedAnalysisTab == idx ? Color(hex:"5C43A9") : Color("baiseanniucolor"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedAnalysisTab = idx
                        }
                    }
            }
        }
        .frame(minHeight: 50)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var videoTabBarView: some View {
        HStack(spacing: 0) {
            ForEach(videoTabs.indices, id: \.self) { idx in
                Text(videoTabs[idx])
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(selectedVideoTab == idx ? .white : .gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(selectedVideoTab == idx ? Color(hex:"5C43A9") : Color("baiseanniucolor"))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedVideoTab = idx
                        }
                    }
            }
        }
        .frame(minHeight: 50)
        .background(Color.clear)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var bottomPanelView: some View {
        VStack(spacing: 0) {
            if selectedSegment == 1 {
                Capsule()
                    .frame(width: 40, height: 4)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            } else {
                Spacer().frame(height: 10)
            }
           
            ScrollView(showsIndicators: false) {
                if selectedSegment == 0 {
                    VStack(alignment: .leading, spacing: 20) {
                        if let performance = performance {
                            OverallScoreView(
                                band: performance.overallBand.rawValue,
                                score: Int(performance.overallScore),
                                accentColor: customPurple,
                                performance: performance
                            )
                        } else {
                            OverallScoreView(
                                band: "Level 3",
                                score: 18,
                                accentColor: customPurple,
                                performance: nil
                            )
                        }
                        
                        ScoreCardView(
                            tabName: analysisTabs[selectedAnalysisTab],
                            score: currentScore,
                            accentColor: customPurple
                        )
                        Divider()
                        
                        if let performance = performance {
                            switch selectedAnalysisTab {
                            case 0:
                                VStack(spacing: 16) {
                                    if !performance.volumePoints.isEmpty {
                                        VolumeChartView(
                                            volumePoints: performance.volumePoints,
                                            volumeStabilityText: performance.pronunciationDelivery.volumeStabilityText,
                                            color: customPurple
                                        )
                                    }
                                    
                                    if performance.pronunciationDelivery.avg_pace > 0 {
                                        PaceSpeedometerView(
                                            pace: performance.pronunciationDelivery.avg_pace,
                                            color: customPurple
                                        )
                                    }
                                    
                                    FillerWordsChartView(
                                        fillerWords: performance.pronunciationDelivery.filler_words_used,
                                        count: performance.pronunciationDelivery.filler_words_count,
                                        color: customPurple
                                    )
                                }
                                
                            case 1:
                                VStack(spacing: 16) {
                                    EyeContactPieChartView(
                                        eyeContactPercentages: performance.communicationStrategies.eyeContactPercentages,
                                        color: customPurple
                                    )
                                    
                                    EmotionBarChartView(
                                        emotionPercentages: performance.communicationStrategies.emotionPercentages,
                                        color: customPurple
                                    )
                                }
                                
                            case 3:
                                VStack(spacing: 16) {
                                    if !performance.speakingTurnDetails.isEmpty {
                                        SpeakingTurnsChartView(
                                            speakingTurnDetails: performance.speakingTurnDetails,
                                            color: customPurple
                                        )
                                    }
                                }
                                
                            default:
                                EmptyView()
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("详细建议")
                                .font(.headline)
                            
                            let details = detailLines(for: selectedAnalysisTab)
                            if details.indices.contains(0) { detailRow(text: details[0]) }
                            if details.indices.contains(1) { detailRow(text: details[1]) }
                            if details.indices.contains(2) { detailRow(text: details[2]) }
                            if details.indices.contains(3) { detailRow(text: details[3]) }
                        }
                        
                        Spacer().frame(height: 50)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Spacer().frame(height: 150)
                } else {
                    if selectedVideoTab == 0 {
                        // 对话回顾 - 使用 chatMessages
                        ConversationReviewView(chatMessages: chatMessages, preparationNote: preparationNote)
                    } else {
                        // 准备笔记 - 传递笔记
                        PreparationNotesView(preparationNote: preparationNote)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("systemBackgroundColor"))
        .cornerRadius(selectedSegment == 0 ? 0 : 24, corners: [.topLeft, .topRight])
        .shadow(color: .black.opacity(0.05), radius: selectedSegment == 0 ? 0 : 8, x: 0, y: selectedSegment == 0 ? 0 : -2)
    }
    
    private func detailRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
                .foregroundColor(customPurple)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 2)
    }
    
    private func detailLines(for tab: Int) -> [String] {
        guard let performance else {
            return ["暫無數據"]
        }
        
        switch tab {
        case 0:
            let feedback = performance.feedback(for: .pronunciationDelivery)
            return [
                feedback?.justification ?? "justification",
                feedback?.strength ?? "strength",
                feedback?.weakness ?? "weakness",
                feedback?.suggestion ?? "suggestion"
            ]
        case 1:
            let feedback = performance.feedback(for: .communicationStrategies)
            return [
                feedback?.justification ?? "justification",
                feedback?.strength ?? "strength",
                feedback?.weakness ?? "weakness",
                feedback?.suggestion ?? "suggestion"
            ]
        case 2:
            let feedback = performance.feedback(for: .vocabularyLanguagePatterns)
            return [
                feedback?.justification ?? "justification",
                feedback?.strength ?? "strength",
                feedback?.weakness ?? "weakness",
                feedback?.suggestion ?? "suggestion"
            ]
        default:
            let feedback = performance.feedback(for: .ideasOrganization)
            return [
                feedback?.justification ?? "justification",
                feedback?.strength ?? "strength",
                feedback?.weakness ?? "weakness",
                feedback?.suggestion ?? "suggestion"
            ]
        }
    }
}

// MARK: - Preview
#Preview {
    DSEReportPage(videoURL: nil, performance: previewPerformance, preparationNote: "输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...输入笔记...")
}

private let previewPerformance = DSEPerformance(
    overallScore: 18,
    overallBand: .level3,
    overallComment: "Preview sample",
    speakingTurns: 12,
    speakingTurnDetails: [
        DSESpeakingTurnData(turnIndex: 1, wordCount: 45, durationSeconds: 18.5)
    ],
    transcript: "user: 我认为重建应该在社区需求与经济发展之间取得平衡。\nassistant: 非常同意，这是一个重要的考量。\nuser: 同时也要考虑环境保护的问题。\nassistant: 很好的观点，可持续发展很重要。\nuser: 还有社会公平和经济效益的平衡。\nassistant: 这些都是重建计划中的关键因素。",
    transcriptWordCount: 86,
    speakingDurationSeconds: 92,
    volumePoints: [
        DSEVolumeSample(timestamp: 0, value: 48),
        DSEVolumeSample(timestamp: 5, value: 52)
    ],
    emotionCounts: ["calm": 60, "joy": 20, "surprise": 10, "sad": 10],
    eyeContactCounts: ["center": 0, "left": 0, "right": 0, "lookAway": 0, "noFace": 0],
    eyeContactLookAwaySeconds: [12, 36, 58],
    pronunciationDelivery: DSEPronunciationDeliveryData(
        score: 5,
        band: .level2,
        avg_volume: 51,
        sd_volume: 8,
        stabilityScore: 72,
        volumeStabilityText: "語調起伏適中，整體自然",
        avg_pace: 118,
        sd_pace: 10,
        filler_words_count: 4,
        filler_words_used: ["um", "you know", "like", "actually"]
    ),
    communicationStrategies: DSECommunicationStrategiesData(
        score: 4,
        band: .level3,
        emotionPercentages: ["calm": 60, "joy": 20, "surprise": 10, "sad": 10],
        eyeContactPercentages: ["center": 0, "left": 0, "right": 0, "lookAway": 0, "noFace": 0]
    ),
    vocabularyLanguagePatterns: DSEVocabularyLanguagePatternsData(score: 4, band: .level5),
    ideasOrganization: DSEIdeasOrganizationData(score: 5, band: .level5)
)

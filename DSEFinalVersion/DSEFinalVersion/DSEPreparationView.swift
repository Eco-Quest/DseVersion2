import SwiftUI

// MARK: - 懒加载包装器
struct LazyView<Content: View>: View {
    let build: () -> Content
    
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    
    var body: Content {
        build()
    }
}

// MARK: - 键盘响应扩展
extension View {
    func keyboardAwareHeight(_ keyboardHeight: Binding<CGFloat>) -> some View {
        self
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main
                ) { notification in
                    if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                        withAnimation(.easeOut(duration: 0.25)) {
                            keyboardHeight.wrappedValue = keyboardFrame.height
                        }
                    }
                }
                
                NotificationCenter.default.addObserver(
                    forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    withAnimation(.easeOut(duration: 0.25)) {
                        keyboardHeight.wrappedValue = 0
                    }
                }
            }
    }
}

struct DSEPreparationView: View {
    let candidates: [DSECandidate]
    let paper: Paper
    
    @Environment(\.dismiss) private var dismiss
    @State private var remainingSeconds: Int = 10 * 60
    @State private var noteText = ""
    @State private var showNoteEditor = false
    @State private var noteEditorPosition: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 190, y: UIScreen.main.bounds.height - 250)
    @State private var noteEditorOffset: CGSize = .zero
    @State private var showVideoCall = false
    @State private var keyboardHeight: CGFloat = 0  // 键盘高度
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    private let themeColor = Color("SelectionColor")
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("ENGLISH LANGUAGE PAPER 4")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // 计时器区域
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Preparation Timer")
                            .font(.headline)
                            .foregroundColor(themeColor)
                        
                        Text(formattedRemainingTime)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(remainingSeconds == 0 ? .red : themeColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(remainingSeconds == 0 ? "Preparation time is up." : "Discussion starts automatically when time is up.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                    .background(Color("baiseanniucolor"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // PART A
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("PART A Group Interaction")
                                .font(.headline)
                                .foregroundColor(themeColor)
                        }
                        
                        Text(paper.partA.title)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text(paper.partA.content)
                            .font(.body)
                            .lineSpacing(6)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color("baiseanniucolor"))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Task
                    VStack(alignment: .leading, spacing: 8) {
                        Text(paper.partA.task)
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Discussion Points
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(paper.partA.discussionPoints.enumerated()), id: \.offset) { index, point in
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .foregroundColor(.secondary)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 8)
                                
                                Text("\(point)")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // 开始讨论按钮
                    Button(action: {
                        showVideoCall = true
                    }) {
                        Text("开始小组讨论")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(themeColor)
                            .cornerRadius(12)
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .background(Color("systemBackgroundColor"))
            
            // 笔记浮窗
            if showNoteEditor {
                VStack(alignment: .leading, spacing: 8) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.5))
                        .frame(width: 40, height: 4)
                        .padding(.top, 4)
                        .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("你的稿纸")
                            .font(.headline)
                            .foregroundColor(themeColor)
                        Spacer()
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showNoteEditor = false
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $noteText)
                            .font(.body)
                            .frame(height: 160)
                            .padding(10)
                            .background(Color("baiseanniucolor"))
                            .cornerRadius(10)
                            .scrollContentBackground(.hidden)
                        
                        if noteText.isEmpty {
                            Text("在此输入你的口试准备笔记...\n\n例如：\n• 论点一\n• 反驳观点\n• 例子")
                                .font(.body)
                                .foregroundColor(.gray.opacity(0.6))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 20)
                                .allowsHitTesting(false)
                        }
                    }
                }
                .padding(14)
                .frame(width: 320)
                .background(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(14)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                .position(adjustedNoteEditorPosition)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newX = noteEditorPosition.x + value.translation.width - noteEditorOffset.width
                            let newY = noteEditorPosition.y + value.translation.height - noteEditorOffset.height
                            
                            let screenWidth = UIScreen.main.bounds.width
                            let screenHeight = UIScreen.main.bounds.height
                            let clampedX = min(max(newX, 160), screenWidth - 160)
                            
                            // 拖拽时的上下边界考虑键盘高度
                            let topBound: CGFloat = 80
                            let bottomBound = screenHeight - keyboardHeight - 100
                            let clampedY = min(max(newY, topBound), max(bottomBound, topBound))
                            
                            noteEditorPosition = CGPoint(x: clampedX, y: clampedY)
                            noteEditorOffset = value.translation
                        }
                        .onEnded { _ in
                            noteEditorOffset = .zero
                        }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .navigationTitle("\(paper.year)年真题")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .keyboardAwareHeight($keyboardHeight)
        .onReceive(timer) { _ in
            guard remainingSeconds > 0 else { return }
            remainingSeconds -= 1
            if remainingSeconds == 0 {
                showVideoCall = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.medium))
                    }
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNoteEditor.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showNoteEditor ? "note.text.badge.xmark" : "pencil")
                            .font(.system(size: 18, weight: .medium))
                        Text(showNoteEditor ? "关闭稿纸" : "稿纸")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showVideoCall) {
            VideoCallView(
                paper: paper,
                dseCandidates: candidates,
                preparationNote: noteText,
                onDismiss: {
                    showVideoCall = false
                }
            )
        }
    }
    
    private var formattedRemainingTime: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // 调整后的位置（键盘弹出时自动上移）
    private var adjustedNoteEditorPosition: CGPoint {
        let screenHeight = UIScreen.main.bounds.height
        let noteHeight: CGFloat = 220  // 浮窗大致高度（含内边距）
        
        // 如果键盘弹起，且浮窗位置会被键盘遮挡，则上移
        if keyboardHeight > 0 {
            let keyboardTop = screenHeight - keyboardHeight
            let noteBottom = noteEditorPosition.y + noteHeight / 2 + 80  // 估算浮窗底部位置
            
            if noteBottom > keyboardTop - 20 {
                // 需要上移，让浮窗底部距离键盘顶部 20pt
                let newY = keyboardTop - noteHeight / 2 - 20
                return CGPoint(x: noteEditorPosition.x, y: max(100, newY))
            }
        }
        return noteEditorPosition
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        DSEPreparationView(candidates: previewCandidates, paper: previewPaper)
    }
}

private let previewPaper: Paper = {
    if let url = Bundle.main.url(forResource: "questions", withExtension: "json"),
       let data = try? Data(contentsOf: url),
       let response = try? JSONDecoder().decode([String: [Paper]].self, from: data),
       let firstPaper = response["papers"]?.first {
        return firstPaper
    }
    
    return Paper(
        id: 0,
        type: "past paper",
        year: "2024",
        topic: "Redevelopment in old districts",
        partA: PartA(
            title: "Group Interaction",
            content: "Your class is discussing the problems redevelopment causes.",
            discussionPoints: [
                "Impact on local shops",
                "Noise and quality of life",
                "Balancing development and community needs"
            ],
            task: "Discuss the major problems and suggest possible solutions."
        ),
        partB: []
    )
}()

private let previewCandidates: [DSECandidate] = [
    DSECandidate(letter: "A", name: "Parrot", iconName: "user1icon", description: "Fluent expression", level: 3),
    DSECandidate(letter: "B", name: "Puppy", iconName: "user2icon", description: "Good interaction", level: 4),
    DSECandidate(letter: "C", name: "Monkey", iconName: "user3icon", description: "Basic expression", level: 2)
]

//
//  DSESettingView.swift
//  dse_test
//
//  Created by Matt on 2026/5/6.
//

import SwiftUI
import Combine

// MARK: - 数据模型

// 试卷模型
struct Paper: Codable, Identifiable {
    let id: Int
    let type: String        // "past paper" 或 "mock"
    let year: String        // 年份，如 "2014"
    let topic: String
    let partA: PartA
    let partB: [String]
}

struct PartA: Codable {
    let title: String
    let content: String
    let discussionPoints: [String]
    let task: String
}

// 试卷类型枚举
enum PaperTypeEnum: String, CaseIterable {
    case pastPaper = "past paper"
    case mock = "mock"
    
    var displayName: String {
        switch self {
        case .pastPaper: return "Past Paper"
        case .mock: return "Mock"
        }
    }
    
    var displayNameCN: String {
        switch self {
        case .pastPaper: return "历年真题"
        case .mock: return "模拟试题"
        }
    }
    
    var icon: String {
        switch self {
        case .pastPaper: return "doc.text.fill"
        case .mock: return "star.fill"
        }
    }
    
    // 主题颜色 - 统一使用紫色
    var themeColor: Color {
        return Color(red: 71/255, green: 59/255, blue: 147/255)
    }
    
    // 未选中背景 - 苹果浅灰
    static var unselectedBackground: Color {
        return Color(.systemGray5)
    }
    
    static var unselectedForeground: Color {
        return Color.primary
    }
}

// 考生模型
struct DSECandidate: Identifiable {
    let id = UUID()
    let letter: String        // "A", "B", "C"
    let name: String          // "Parrot", "Puppy", "Monkey"
    let iconName: String
    let description: String   // 英文描述
    var level: Int = 3
    
    var displayName: String {
        return "Candidate \(letter)"
    }
    
    var levelDescription: String {
        switch level {
        case 1: return "Expresses with difficulty, quite nervous"
        case 2: return "Basic expression, lacks fluency"
        case 3: return "Fluent expression, clear structure"
        case 4: return "Natural expression, rich details"
        case 5: return "Authentic expression, logical and precise"
        default: return ""
        }
    }
}

// MARK: - JSON 管理器

class QuestionManager: ObservableObject {
    @Published var allPapers: [Paper] = []
    @Published var filteredPapers: [Paper] = []
    @Published var isLoading = true
    
    static let shared = QuestionManager()
    
    init() {
        loadQuestions()
    }
    
    func loadQuestions() {
        isLoading = true
        
        guard let url = Bundle.main.url(forResource: "questions", withExtension: "json") else {
            print("错误: 找不到 questions.json 文件")
            isLoading = false
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let response = try JSONDecoder().decode([String: [Paper]].self, from: data)
            allPapers = response["papers"] ?? []
            filteredPapers = allPapers
            isLoading = false
        } catch {
            print("JSON 解析错误: \(error)")
            isLoading = false
        }
    }
    
    func filter(by type: PaperTypeEnum?) {
        if let type = type {
            filteredPapers = allPapers.filter { $0.type == type.rawValue }
        } else {
            filteredPapers = allPapers
        }
    }
}

// MARK: - 导航路径枚举
enum DSENavigationDestination: Hashable {
    case dsePreparation(candidates: [DSECandidate], paper: Paper)
}

// 为了让 Paper 和 DSECandidate 支持 Hashable
extension Paper: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Paper, rhs: Paper) -> Bool {
        lhs.id == rhs.id
    }
}

extension DSECandidate: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: DSECandidate, rhs: DSECandidate) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 星级评分组件

struct StarRatingView: View {
    let rating: Int
    var starSize: CGFloat = 14
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .font(.system(size: starSize))
                    .foregroundColor(star <= rating ? .yellow : .gray.opacity(0.3))
            }
        }
    }
}

// MARK: - 题目显示视图 (仅Part A)
struct QuestionView: View {
    let candidates: [DSECandidate]
    let papers: [Paper]
    @State private var currentIndex = 0
    @State private var showPreparationView = false
    @Environment(\.dismiss) private var dismiss
    
    var currentPaper: Paper {
        papers[currentIndex]
    }
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // 三位考生信息卡片
                    HStack(spacing: 16) {
                        ForEach(candidates) { candidate in
                            VStack(spacing: 8) {
                                Image(candidate.iconName)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 65, height: 65)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(PaperTypeEnum.pastPaper.themeColor.opacity(0.5), lineWidth: 2)
                                    )
                                
                                Text(candidate.displayName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .multilineTextAlignment(.center)
                                
                                StarRatingView(rating: candidate.level, starSize: 12)
                                
                                Text(candidate.levelDescription)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(.secondarySystemBackground).opacity(0.5))
                            .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // 试卷进度
                    HStack {
                        Label(currentPaper.type.uppercased(), systemImage: "doc.text")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(PaperTypeEnum.pastPaper.themeColor.opacity(0.15))
                            .cornerRadius(8)
                            .foregroundColor(PaperTypeEnum.pastPaper.themeColor)
                        
                        Text("年份: \(currentPaper.year)")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) / \(papers.count)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Topic
                    Text(currentPaper.topic)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                    
                    // Part A (Group Interaction)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("PART A ")
                                .font(.headline)
                                .foregroundColor(PaperTypeEnum.pastPaper.themeColor)
                            Text("Group Interaction")
                                .font(.subheadline)
                                .foregroundColor(PaperTypeEnum.pastPaper.themeColor.opacity(0.7))
                        }
                        
                        Text(currentPaper.partA.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 4)
                        
                        Text(currentPaper.partA.content)
                            .font(.body)
                            .lineSpacing(4)
                            .foregroundColor(.secondary)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        Text("📌 Task:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(currentPaper.partA.task)
                            .font(.body)
                            .foregroundColor(PaperTypeEnum.pastPaper.themeColor)
                        
                        Text("💬 Discussion Points:")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding(.top, 8)
                        
                        ForEach(currentPaper.partA.discussionPoints, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Circle()
                                    .fill(PaperTypeEnum.pastPaper.themeColor)
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 8)
                                Text(point)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Button(action: {
                        showPreparationView = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "timer")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Start Preparation")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(PaperTypeEnum.pastPaper.themeColor)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 20) {
                        Button(action: {
                            if currentIndex > 0 {
                                currentIndex -= 1
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(currentIndex == 0 ? .gray.opacity(0.5) : PaperTypeEnum.pastPaper.themeColor)
                        }
                        .disabled(currentIndex == 0)
                        
                        Button(action: {
                            if currentIndex < papers.count - 1 {
                                currentIndex += 1
                            }
                        }) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(currentIndex == papers.count - 1 ? .gray.opacity(0.5) : PaperTypeEnum.pastPaper.themeColor)
                        }
                        .disabled(currentIndex == papers.count - 1)
                    }
                }
            }
            .fullScreenCover(isPresented: $showPreparationView) {
                DSEPreparationView(candidates: candidates, paper: currentPaper)
            }
        }
    }
}

// MARK: - CandidateLevelCard
struct CandidateLevelCard: View {
    @Binding var candidate: DSECandidate
    let cardBackgroundColor = Color("baiseanniucolor")
    let themeColor = Color("SelectionColor")
    let levelRange = Array(1...5)
    
    var body: some View {
        if #available(iOS 26, *) {
            HStack(alignment: .center, spacing: 16) {
                // 左侧：头像 + 名称 + 星级 + 描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 16) {
                        // 圆形头像
                        Image(candidate.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(themeColor.opacity(0.3), lineWidth: 1.5))
                        
                        // 名称 + 描述
                        VStack(alignment: .leading, spacing: 6) {
                            Text(candidate.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(candidate.description)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                
                // 右侧：等级控制模块
                HStack(spacing: 8) {
                    Text("Level")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeColor)
                    
                    Picker("Level", selection: $candidate.level) {
                        ForEach(levelRange, id: \.self) { level in
                            Text("\(level)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(themeColor)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 40, height: 100)
                    .labelsHidden()
                    
                }
                .padding(.vertical, 8)
                .frame(width: UIScreen.main.bounds.width * 0.25)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 0)
            .glassEffect(.regular, in: .rect(cornerRadius: 16))
            
        } else {
            HStack(alignment: .center, spacing: 16) {
                // 左侧：头像 + 名称 + 星级 + 描述
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 16) {
                        // 圆形头像
                        Image(candidate.iconName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 60, height: 60)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(themeColor.opacity(0.3), lineWidth: 1.5))
                        
                        // 名称 + 描述
                        VStack(alignment: .leading, spacing: 6) {
                            Text(candidate.displayName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(candidate.description)
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
                
                // 右侧：等级控制模块
                HStack(spacing: 8) {
                    Text("Level")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(themeColor)
                    
                    Picker("Level", selection: $candidate.level) {
                        ForEach(levelRange, id: \.self) { level in
                            Text("\(level)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(themeColor)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 40, height: 100)
                    .labelsHidden()
                   
                }
                .padding(.vertical, 8)
                .frame(width: UIScreen.main.bounds.width * 0.25)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 0)
            .background(cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        }
    }
}

// MARK: - PaperDetailPopupView
struct PaperDetailPopupView: View {
    let paper: Paper
    @Environment(\.dismiss) private var dismiss
    let themeColor = PaperTypeEnum.pastPaper.themeColor
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // 头部信息
                    VStack(spacing: 12) {
                        HStack {
                            Text("\(paper.year)年 " + paper.type.uppercased())
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color("SelectionColor").opacity(0.15))
                                .cornerRadius(8)
                                .foregroundColor(Color("SelectionColor"))
                            
                            Spacer()
                        }
                        
                        Text("ENGLISH LANGUAGE PAPER 4")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    // 核心外框
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("PART A Group Interaction")
                                .font(.headline)
                                .foregroundColor(Color("SelectionColor"))
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
                    .background(Color.clear)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    
                    // Task
                    Text(paper.partA.task)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Discussion Points
                    ForEach(paper.partA.discussionPoints, id: \.self) { point in
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - 苹果风格分段选择器
struct AppleStyleSegmentedPicker: View {
    @Binding var selectedType: PaperTypeEnum
    let types: [PaperTypeEnum]
    let onTap: (PaperTypeEnum) -> Void
    
    @Namespace private var selectionAnimation
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(types, id: \.self) { type in
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        onTap(type)
                    }
                }) {
                    Text(type.displayNameCN)
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            ZStack {
                                if selectedType == type {
                                    Capsule()
                                        .fill(type.themeColor)
                                        .matchedGeometryEffect(id: "SELECTION", in: selectionAnimation)
                                }
                            }
                        )
                        .foregroundColor(selectedType == type ? .white : .primary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(.systemGray6))
        .clipShape(Capsule())
    }
}

// MARK: - 书本样式卡片
struct BookStylePaperCard: View {
    let paper: Paper
    let isSelected: Bool
    let themeColor: Color
    var onPreview: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 卡片背景
            if #available(iOS 26, *) {
                Color.clear
                    .glassEffect(.regular,in: .rect(cornerRadius: 16))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("baiseanniucolor"))
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
            }
            
            // 选中效果
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color("SelectionColor").opacity(0.1))
            }
            
            // 选中边框
            if isSelected {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color("SelectionColor").opacity(0.3), lineWidth: 0.5)
            }
            
            // 选中打勾图标
            if isSelected {
                VStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(Color("SelectionColor"))
                                .frame(width: 24, height: 24)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        
                        Spacer()
                    }
                    Spacer()
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                // 右上角 DSE logo
                HStack {
                    Spacer()
                    Text("DSE")
                        .font(.system(size: 24, weight: .heavy))
                        .foregroundColor(themeColor.opacity(0.25))
                }
                
                // 年份信息
                VStack(alignment: .leading, spacing: 4) {
                    Text(paper.year)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(themeColor)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 11, weight: .medium))
                        Text("Paper 4")
                            .font(.system(size: 14, weight: .medium))
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Part A+B")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.secondary)
                }
                
                // 分隔线
                Rectangle()
                    .fill(Color(.separator))
                    .frame(height: 0.5)
                
                // 标题
                Text(paper.topic)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
                
                Spacer(minLength: 8)
                
                // 预览按钮
                HStack {
                    Spacer()
                    
                    Button(action: {
                        onPreview?()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye")
                                .font(.system(size: 13, weight: .medium))
                            Text("预览")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(themeColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                        )
                        .overlay(
                            Capsule()
                                .stroke(themeColor.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 主视图
struct DSESettingView: View {
    @StateObject private var questionManager = QuestionManager.shared
    @State private var selectedPaperType: PaperTypeEnum = .pastPaper
    @State private var showModeInfo = false
    @State private var selectedPaper: Paper? = nil
    @State private var selectedYear: String = ""
    @State private var selectedDetailPaper: Paper? = nil
    @State private var navigationPath = NavigationPath()
    
    @State private var candidates: [DSECandidate] = [
        DSECandidate(letter: "A", name: "Parrot", iconName: "user1icon", description: "Chatty Parrot", level: 3),
        DSECandidate(letter: "B", name: "Puppy", iconName: "user2icon", description: "Energetic Parrot", level: 3),
        DSECandidate(letter: "C", name: "Monkey", iconName: "user3icon", description: "Smart Parrot", level: 3)
    ]
    
    private var availableYears: [String] {
        Array(Set(questionManager.filteredPapers.map { $0.year })).sorted(by: >)
    }
    
    private var papersByYear: [Paper] {
        questionManager.filteredPapers.filter { $0.year == selectedYear }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Image("dsebgimage")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                       
                    VStack(spacing: 24) {
                        // DSE 口语说明卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DSE 英国语文科口语考试共设两部分：Part A 小组互动 (Group Interaction) 及 Part B 个人回应 (Individual Response)。考生需就指定议题进行讨论及表达个人观点，小组讨论考试时间约8分钟。")
                                .font(.subheadline)
                                .foregroundColor(Color("anniucolor"))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                                .opacity(0.6)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding()
                        .cornerRadius(16)
                        .padding(.horizontal, 0)
                        
                        // 考生难度设置标题
                        HStack(alignment: .center) {
                            Text("考生陪练程度")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            Button(action: {
                                showModeInfo = true
                            }) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 4)
                        
                        // 三位考生的卡片式等级选择器
                        VStack(spacing: 16) {
                            ForEach($candidates) { $candidate in
                                CandidateLevelCard(candidate: $candidate)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // 选择考试题目标题
                        HStack(alignment: .center) {
                            Text("选择试卷")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.primary)
                            
                            if !availableYears.isEmpty {
                                Menu {
                                    ForEach(availableYears, id: \.self) { year in
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedYear = year
                                                selectedPaper = nil
                                            }
                                        }) {
                                            HStack {
                                                Text(year + "年真题")
                                                if selectedYear == year {
                                                    Spacer()
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(selectedPaperType.themeColor)
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(Color("SelectionColor"))
                                        
                                        Text(selectedYear.isEmpty ? "请选择" : selectedYear + "年真题")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemGray5))
                                    )
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // 试卷选择区域
                        if !questionManager.isLoading && !questionManager.filteredPapers.isEmpty && !selectedYear.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(papersByYear) { paper in
                                            BookStylePaperCard(
                                                paper: paper,
                                                isSelected: selectedPaper?.id == paper.id,
                                                themeColor: Color("blackorwhitecolor"),
                                                onPreview: {
                                                    selectedDetailPaper = paper
                                                }
                                            )
                                            .frame(width: 200, height: 270)
                                           
                                            .onTapGesture {
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    selectedPaper = paper
                                                }
                                                let generator = UIImpactFeedbackGenerator(style: .light)
                                                generator.impactOccurred()
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        } else if !selectedYear.isEmpty && papersByYear.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "doc.text.magnifyingglass")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)
                                Text("该年份暂无试卷")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .padding(.horizontal, 20)
                        }
                        
                        if questionManager.isLoading {
                            ProgressView()
                                .padding()
                        }
                        
                        Spacer(minLength: 20)
                        
                        // 开始练习按钮
                        Group {
                            if let paper = selectedPaper {
                                Button(action: {
                                    HapticFeedbackManager.medium()
                                    navigateToPreparation(paper: paper)
                                }) {
                                    Text("开始练习")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 52)
                                        .background(selectedPaperType.themeColor)
                                        .cornerRadius(14)
                                }
                            } else {
                                Text("开始练习")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(Color.gray.opacity(0.5))
                                    .cornerRadius(14)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
            }
            .background(Color("systemBackgroundColor"))
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        HapticFeedbackManager.medium()
                        if !navigationPath.isEmpty {
                            navigationPath.removeLast()
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
                
                ToolbarItem(placement: .principal) {
                    Text("DSE英文口试")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .onAppear {
                questionManager.filter(by: selectedPaperType)
                if let firstYear = availableYears.first {
                    selectedYear = firstYear
                }
            }
            .sheet(isPresented: $showModeInfo) {
                DSEModeInfoView()
            }
            .sheet(item: $selectedDetailPaper) { paper in
                PaperDetailPopupView(paper: paper)
            }
            .navigationDestination(for: DSENavigationDestination.self) { destination in
                switch destination {
                case .dsePreparation(let candidates, let paper):
                    DSEPreparationView(candidates: candidates, paper: paper)
                }
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    // 导航方法
    private func navigateToPreparation(paper: Paper) {
        navigationPath.append(DSENavigationDestination.dsePreparation(candidates: candidates, paper: paper))
    }
}

// MARK: - 练习模式说明视图
// MARK: - 考生陪练程度说明视图
struct DSEModeInfoView: View {
    @Environment(\.dismiss) private var dismiss
    
    // 陪练等级说明 - L1-L5
    let levelDescriptions: [(level: String, title: String, description: String)] = [
        ("Lv.1", "入门", "表达尚浅，需要较多引导"),
        ("Lv.2", "合格", "能基本表达，可完成简单任务"),
        ("Lv.3", "满意", "表达流畅，能正常参与讨论"),
        ("Lv.4", "良好", "表达自然，有不错见解"),
        ("Lv.5", "卓越", "表达地道，逻辑清晰，表现优秀"),
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 头部
                VStack(spacing: 12) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(Color("SelectionColor"))
                    
                    Text("陪练等级说明")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Lv.1入门 → Lv.5卓越")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                // 等级列表
                VStack(spacing: 12) {
                    ForEach(levelDescriptions, id: \.level) { item in
                        HStack(spacing: 16) {
                            // 等级标签
                            Text(item.level)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(Color("SelectionColor"))
                                .frame(width: 50, alignment: .leading)
                            
                            // 等级标题
                            Text(item.title)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(width: 50, alignment: .leading)
                            
                            // 等级描述
                            Text(item.description)
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(Color("baiseanniucolor").opacity(0.5))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
                
                // 底部按钮
                Button(action: {
                    dismiss()
                }) {
                    Text("知道了")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color("SelectionColor"))
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
            .presentationDetents([.height(500)])
            .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - 预览
#Preview {
    DSESettingView()
}

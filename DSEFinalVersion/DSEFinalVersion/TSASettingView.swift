//
//  TSASettingView.swift
//  dse_test
//
//  Created by Matt on 2026/5/23.
//

import SwiftUI

// MARK: - 数据模型

// TSA 考试类型
enum TSAGradeEnum: String, CaseIterable {
    case p3 = "小学三年级"
    case p6 = "小学六年级"
    
    var displayName: String {
        return self.rawValue
    }
    
    var icon: String {
        switch self {
        case .p3: return "person.2.fill"
        case .p6: return "person.3.fill"
        }
    }
    
    var themeColor: Color {
        return Color(hex: "5C43A9")
    }
    
    // 转换为 JSON 中使用的 key
    var jsonKey: String {
        switch self {
        case .p3: return "小三"
        case .p6: return "小六"
        }
    }
}

// TSA 语言类型 - 粤语在前，普通话在后
enum TSALanguageEnum: String, CaseIterable {
    case cantonese = "粤语"
    case putonghua = "普通话"
    
    var displayName: String {
        return self.rawValue
    }
    
    var flag: String {
        switch self {
        case .putonghua: return "🇨🇳"
        case .cantonese: return "🇭🇰"
        }
    }
}

// 小六题型枚举
enum SixthGradeQuestionType: String, CaseIterable {
    case pictureStory = "看图说故事"
    case oralReport = "口头报告"
    case discussion = "小组讨论"
    
    var displayName: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .pictureStory:
            return "观察图画，用1分钟讲述一个完整的故事"
        case .oralReport:
            return "根据题目要求，进行1分钟的口头报告"
        case .discussion:
            return "与同学讨论，发表自己的观点和意见"
        }
    }
    
    var icon: String {
        switch self {
        case .pictureStory: return "photo.stack.fill"
        case .oralReport: return "mic.fill"
        case .discussion: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    // 对应的 StoryConfig 类型
    var storyConfigType: StoryConfig.StoryType {
        switch self {
        case .pictureStory: return .pictureStory
        case .oralReport: return .oralReport
        case .discussion: return .discussion
        }
    }
}

// MARK: - 导航路径枚举 - 添加唯一标识符
enum NavigationDestination: Hashable {
    case tsaStory(grade: String, questionType: StoryConfig.StoryType?, language: String, id: String = UUID().uuidString)
    
    // 实现 Hashable
    func hash(into hasher: inout Hasher) {
        switch self {
        case .tsaStory(let grade, let questionType, let language, let id):
            hasher.combine(grade)
            hasher.combine(questionType?.hashValue ?? 0)
            hasher.combine(language)
            hasher.combine(id)
        }
    }
    
    static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        switch (lhs, rhs) {
        case (.tsaStory(let g1, let q1, let l1, let id1), .tsaStory(let g2, let q2, let l2, let id2)):
            return g1 == g2 && q1 == q2 && l1 == l2 && id1 == id2
        }
    }
}

// MARK: - 主视图
struct TSASettingView: View {
    @State private var selectedGrade: TSAGradeEnum = .p3
    @State private var selectedLanguage: TSALanguageEnum = .cantonese
    @State private var selectedQuestionType: SixthGradeQuestionType = .pictureStory
    @State private var navigationPath = NavigationPath()
    
    // ✅ 添加一个唯一标识，每次开始练习时更新
    @State private var navigationId = UUID()
    
    var navigationTitle: String {
        if selectedGrade == .p3 {
            return "小三 TSA 看图说故事"
        } else {
            switch selectedQuestionType {
            case .pictureStory:
                return "小六 TSA 看图说故事"
            case .oralReport:
                return "小六 TSA 口头报告"
            case .discussion:
                return "小六 TSA 小组讨论"
            }
        }
    }
    
    // 主题色
    private let themeColor = Color(hex: "5C43A9")
    private let themeLightColor = Color("SelectionColor")
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 顶部装饰图片
                    Image("tsastorytelling")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    VStack(spacing: 18) {
                        // TSA 说明卡片
                        VStack(alignment: .leading, spacing: 12) {
                            Text(getDescriptionText())
                                .font(.subheadline)
                                .foregroundColor(Color("anniucolor"))
                                .lineSpacing(4)
                                .multilineTextAlignment(.leading)
                                .opacity(0.6)
                                .padding(EdgeInsets(top: 15, leading: 20, bottom: 0, trailing: 20))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                      
                        // 年级选择标题
                        HStack(alignment: .center) {
                            Text("学习阶段")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("anniucolor"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        // 年级选择
                        ZStack {
                            Rectangle()
                                .fill(Color("baiseanniucolor"))
                                .frame(height: 65)
                                .cornerRadius(20)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            HStack(spacing: 20) {
                                ForEach(TSAGradeEnum.allCases, id: \.self) { grade in
                                    Button(action: {
                                        HapticFeedbackManager.medium()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedGrade = grade
                                        }
                                    }) {
                                        ZStack {
                                            Rectangle()
                                                .fill(selectedGrade == grade ? Color("SelectionColor") : Color("UnSelectionColor"))
                                                .frame(height: 45)
                                                .cornerRadius(112)
                                            
                                            HStack(spacing: 8) {
                                                Text(grade.displayName)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(selectedGrade == grade ? Color("SelectionTextColor") : Color("UnSelectionTextColor"))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 20)
                        
                        // 小六题型选择（仅当选择小学六年级时显示）
                        if selectedGrade == .p6 {
                            VStack(spacing: 12) {
                                // 题型选择标题
                                HStack(alignment: .center) {
                                    Text("练习题型")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(Color("anniucolor"))
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                
                                // 三个题型选项卡片
                                VStack(spacing: 12) {
                                    ForEach(SixthGradeQuestionType.allCases, id: \.self) { type in
                                        Button(action: {
                                            HapticFeedbackManager.medium()
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                selectedQuestionType = type
                                            }
                                        }) {
                                            HStack(spacing: 15) {
                                                // 图标
                                                ZStack {
                                                    Circle()
                                                        .fill(selectedQuestionType == type ? themeLightColor.opacity(0.15) : Color.gray.opacity(0.1))
                                                        .frame(width: 50, height: 50)
                                                    
                                                    Image(systemName: type.icon)
                                                        .font(.system(size: 24))
                                                        .foregroundColor(selectedQuestionType == type ? themeLightColor : .gray)
                                                }
                                                
                                                // 文字说明
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(type.displayName)
                                                        .font(.system(size: 17, weight: .semibold))
                                                        .foregroundColor(selectedQuestionType == type ? themeLightColor : .primary)
                                                    
                                                    Text(type.description)
                                                        .font(.system(size: 13))
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(2)
                                                }
                                                
                                                Spacer()
                                                
                                                // 选中标记
                                                if selectedQuestionType == type {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .font(.system(size: 22))
                                                        .foregroundColor(themeLightColor)
                                                }
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(selectedQuestionType == type ? themeLightColor.opacity(0.08) : Color("baiseanniucolor"))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(selectedQuestionType == type ? themeLightColor : Color.clear, lineWidth: 1.5)
                                                    )
                                            )
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.top, 5)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        
                        // 语言选择标题
                        HStack(alignment: .center) {
                            Text("口试语言")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("anniucolor"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, selectedGrade == .p6 ? 5 : 0)
                        
                        // 语言选择
                        ZStack {
                            Rectangle()
                                .fill(Color("baiseanniucolor"))
                                .frame(height: 65)
                                .cornerRadius(20)
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            HStack(spacing: 20) {
                                ForEach(TSALanguageEnum.allCases, id: \.self) { language in
                                    Button(action: {
                                        HapticFeedbackManager.medium()
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedLanguage = language
                                        }
                                    }) {
                                        ZStack {
                                            Rectangle()
                                                .fill(selectedLanguage == language ? Color("SelectionColor") : Color("UnSelectionColor"))
                                                .frame(height: 45)
                                                .cornerRadius(112)
                                            
                                            HStack(spacing: 8) {
                                                Text(language.displayName)
                                                    .font(.system(size: 16, weight: .medium))
                                                    .foregroundColor(selectedLanguage == language ? Color("SelectionTextColor") : Color("UnSelectionTextColor"))
                                            }
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 20)
                        
                        // 开始练习按钮
                        Button(action: {
                            HapticFeedbackManager.medium()
                            // ✅ 每次点击时生成新的 ID，确保视图不会重复
                            navigationId = UUID()
                            navigateToStoryView()
                        }) {
                            Text("开始练习")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(themeColor)
                                .cornerRadius(20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .padding(.top, 10)
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
                        // 检查是否可以返回，如果 navigationPath 不为空则先 pop，否则 dismiss
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
                    Text("TSA中文口试")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedGrade)
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .tsaStory(let grade, let questionType, let language, _):
                    if let questionType = questionType {
                        TSAChineseStoryView(
                            grade: grade,
                            questionType: questionType,
                            language: language
                        )
                        .id("\(grade)-\(questionType)-\(language)")  // ✅ 添加 id 确保视图正确更新
                    } else {
                        TSAChineseStoryView(
                            grade: grade,
                            language: language
                        )
                        .id("\(grade)-\(language)")  // ✅ 添加 id 确保视图正确更新
                    }
                }
            }
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    
    // 导航方法
    private func navigateToStoryView() {
        let languageValue = selectedLanguage.rawValue
        
        if selectedGrade == .p3 {
            navigationPath.append(NavigationDestination.tsaStory(
                grade: selectedGrade.jsonKey,
                questionType: nil,
                language: languageValue,
                id: navigationId.uuidString
            ))
        } else {
            navigationPath.append(NavigationDestination.tsaStory(
                grade: selectedGrade.jsonKey,
                questionType: selectedQuestionType.storyConfigType,
                language: languageValue,
                id: navigationId.uuidString
            ))
        }
    }
    
    // 根据年级和题型获取说明文字
    private func getDescriptionText() -> String {
        if selectedGrade == .p3 {
            return "全港性评估（TSA）看图说故事考试（小三）共设3分钟准备时间及1分钟讲述时间。学生需细心观察图画内容，组织完整故事，并以流畅的语言表达。"
        } else {
            switch selectedQuestionType {
            case .pictureStory:
                return "全港性评估（TSA）看图说故事考试（小六）共设3分钟准备时间及1分钟讲述时间。学生需细心观察图画内容，组织完整故事，并以流畅的语言表达。"
            case .oralReport:
                return "全港性评估（TSA）口头报告考试（小六）共设3分钟准备时间及1分钟报告时间。学生需根据题目要求，清晰表达自己的观点和感受。"
            case .discussion:
                return "全港性评估（TSA）小组讨论考试（小六）共设1分钟准备时间及3分钟讨论时间。学生需与同学讨论，积极发表意见，并尊重他人观点。"
            }
        }
    }
}

// MARK: - 预览
#Preview {
    TSASettingView()
}

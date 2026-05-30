//
//  TSAEnglishSettingView.swift
//  dse_test
//
//  Created by Matt on 2026/5/25.
//

import SwiftUI


// MARK: - 导航路径枚举
enum EnglishNavigationDestination: Hashable {
    case englishPractice(grade: String, questionType: EnglishQuestionType)
}

// MARK: - 主视图
struct TSAEnglishSettingView: View {
    @State private var selectedGrade: TSAEnglishGrade = .p3
    @State private var selectedP3Type: TSAEnglishP3Type = .readAloud
    @State private var selectedP6Type: TSAEnglishP6Type = .readingInteraction
    @State private var navigationPath = NavigationPath()
    @Environment(\.dismiss) private var dismiss
    private let themeColor = Color(hex: "5C43A9")
    private let themeLightColor = Color("SelectionColor")
    
    var navigationTitle: String {
        if selectedGrade == .p3 {
            return "小三 TSA 英文口试"
        } else {
            switch selectedP6Type {
            case .readingInteraction:
                return "小六 TSA 英文口试"
            case .presentation:
                return "小六 TSA 英文口头报告"
            }
        }
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // 顶部装饰图
                    Image("tsaxiaoliubg")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                    
                    VStack(spacing: 18) {
                        // 说明文字
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
                        
                        // 年级选择
                        HStack {
                            Text("学习阶段")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color("anniucolor"))
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        ZStack {
                            Rectangle()
                                .fill(Color("baiseanniucolor"))
                                .frame(height: 65)
                                .cornerRadius(20)
                            
                            HStack(spacing: 20) {
                                ForEach(TSAEnglishGrade.allCases, id: \.self) { grade in
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
                                            
                                            Text(grade.displayName)
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(selectedGrade == grade ? Color("SelectionTextColor") : Color("UnSelectionTextColor"))
                                        }
                                        .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.horizontal, 20)
                        
                        // 小三题型
                        if selectedGrade == .p3 {
                            p3TypeSelector
                        }
                        
                        // 小六题型
                        if selectedGrade == .p6 {
                            p6TypeSelector
                        }
                        
                        // 开始按钮
                        Button(action: {
                            HapticFeedbackManager.medium()
                            navigateToPracticeView()
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
                    Text("TSA英文口试")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: selectedGrade)
            .navigationDestination(for: EnglishNavigationDestination.self) { destination in
                switch destination {
                case .englishPractice(let grade, let questionType):
                    TSAEnglishPracticeView(grade: grade, questionType: questionType)
                }
            }
        }
    }
    
    // MARK: - 导航方法
    private func navigateToPracticeView() {
        if selectedGrade == .p3 {
            navigationPath.append(EnglishNavigationDestination.englishPractice(
                grade: "小三",
                questionType: selectedP3Type.questionType
            ))
        } else {
            navigationPath.append(EnglishNavigationDestination.englishPractice(
                grade: "小六",
                questionType: selectedP6Type.questionType
            ))
        }
    }
    
    // MARK: - 小三题型选择器
    @ViewBuilder
    private var p3TypeSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Text("练习题型")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("anniucolor"))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(TSAEnglishP3Type.allCases, id: \.self) { type in
                    Button(action: {
                        HapticFeedbackManager.medium()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedP3Type = type
                        }
                    }) {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(selectedP3Type == type ? themeLightColor.opacity(0.15) : Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: type.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedP3Type == type ? themeLightColor : .gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(selectedP3Type == type ? themeLightColor : .primary)
                                Text(type.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if selectedP3Type == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(themeLightColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedP3Type == type ? themeLightColor.opacity(0.08) : Color("baiseanniucolor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedP3Type == type ? themeLightColor : Color.clear, lineWidth: 1.5)
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
    
    // MARK: - 小六题型选择器
    @ViewBuilder
    private var p6TypeSelector: some View {
        VStack(spacing: 12) {
            HStack {
                Text("练习题型")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color("anniucolor"))
                Spacer()
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                ForEach(TSAEnglishP6Type.allCases, id: \.self) { type in
                    Button(action: {
                        HapticFeedbackManager.medium()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedP6Type = type
                        }
                    }) {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(selectedP6Type == type ? themeLightColor.opacity(0.15) : Color.gray.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                Image(systemName: type.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedP6Type == type ? themeLightColor : .gray)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(selectedP6Type == type ? themeLightColor : .primary)
                                Text(type.description)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Spacer()
                            
                            if selectedP6Type == type {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 22))
                                    .foregroundColor(themeLightColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedP6Type == type ? themeLightColor.opacity(0.08) : Color("baiseanniucolor"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedP6Type == type ? themeLightColor : Color.clear, lineWidth: 1.5)
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
    
    // MARK: - 说明文字（完整句子版本）
    private func getDescriptionText() -> String {
        if selectedGrade == .p3 {
            switch selectedP3Type {
            case .readAloud:
                return "全港性评估（TSA）英文口试（小三）朗读与答问部分共设2分钟准备时间及3分钟作答时间。学生需清晰朗读指定文章，并根据文章内容回答老师提问，以完整句子表达。"
            case .pictureAnswer:
                return "全港性评估（TSA）英文口试（小三）看图答问部分共设3分钟准备时间及2分钟作答时间。学生需仔细观察图片，描述图片内容，并回答老师提问。"
            }
        } else {
            switch selectedP6Type {
            case .readingInteraction:
                return "全港性评估（TSA）英文口试（小六）朗读与师生互动部分共设2分钟准备时间及3分钟互动时间。学生需清晰朗读文章，并与老师进行实时互动问答，表达个人观点。"
            case .presentation:
                return "全港性评估（TSA）英文口试（小六）口头报告部分共设3分钟准备时间及2分钟报告时间。学生需根据指定题目进行口头报告，清晰流畅地表达观点和想法。"
            }
        }
    }
}


// MARK: - 预览
#Preview {
    TSAEnglishSettingView()
}

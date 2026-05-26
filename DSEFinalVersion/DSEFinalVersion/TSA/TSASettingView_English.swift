//
//  TSAEnglishSettingView.swift
//  dse_test
//
//  Created by Matt on 2026/5/25.
//

import SwiftUI

// MARK: - 英文 TSA 独立枚举（避免与中文冲突）

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
}

// 小六题型
enum TSAEnglishP6Type: String, CaseIterable {
    case readingInteraction = "朗读 + 师生互动"
    case presentation = "口头报告"
    
    var displayName: String { self.rawValue }
    
    var description: String {
        switch self {
        case .readingInteraction:
            return "第一部分：朗读短文 → 第二部分：师生互动问答"
        case .presentation:
            return "根据题目进行2分钟口头报告"
        }
    }
    
    var icon: String {
        switch self {
        case .readingInteraction: return "bubble.left.and.bubble.right.fill"
        case .presentation: return "mic.fill"
        }
    }
}

// MARK: - 主视图
struct TSAEnglishSettingView: View {
    @State private var selectedGrade: TSAEnglishGrade = .p3
    @State private var selectedP3Type: TSAEnglishP3Type = .readAloud
    @State private var selectedP6Type: TSAEnglishP6Type = .readingInteraction
    
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
                                    selectedGrade = grade
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
                    NavigationLink(destination:
                                    
                                    getDestinationView()
                        .onAppear{
                            HapticFeedbackManager.medium()
                        }
                    
                    ) {
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
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("TSA英文口试")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
            }
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
                        selectedP3Type = type
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
                        selectedP6Type = type
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
    }
    
    // MARK: - 说明文字
    private func getDescriptionText() -> String {
        if selectedGrade == .p3 {
            switch selectedP3Type {
            case .readAloud:
                return "TSA英文口试（小三）- 朗读一篇短文，根据文章内容回答老师问题。（准备3分钟，作答1分钟）"
            case .pictureAnswer:
                return "TSA英文口试（小三）- 仔细观察图片，描述你所看到的内容并回答提问。（准备3分钟，作答1分钟）"
            }
        } else {
            switch selectedP6Type {
            case .readingInteraction:
                return "TSA英文口试（小六）- 朗读短文后师生互动，回答问题并表达个人观点。（准备3分钟，作答2分钟）"
            case .presentation:
                return "TSA英文口试（小六）- 根据指定题目进行口头报告，清晰流畅表达观点。（准备3分钟，作答2分钟）"
            }
        }
    }
    
    // MARK: - 跳转目标
    @ViewBuilder
    private func getDestinationView() -> some View {
        if selectedGrade == .p3 {
            if selectedP3Type == .readAloud {
                TSAEnglishPracticeView(grade: "小三", questionType: .readAloud)
            } else {
                TSAEnglishPracticeView(grade: "小三", questionType: .pictureAnswer)
            }
        } else {
            if selectedP6Type == .readingInteraction {
                TSAEnglishPracticeView(grade: "小六", questionType: .readingInteraction)
            } else {
                TSAEnglishPracticeView(grade: "小六", questionType: .presentation)
            }
        }
    }
    
    private func getTypeName() -> String {
        if selectedGrade == .p3 {
            return selectedP3Type.displayName
        } else {
            return selectedP6Type.displayName
        }
    }
}

// MARK: - 预览
#Preview {
    TSAEnglishSettingView()
}

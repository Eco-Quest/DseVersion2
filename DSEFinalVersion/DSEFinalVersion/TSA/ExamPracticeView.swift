//
//  ExamPracticeView.swift
//  fyp
//
//  Created by Matt on 2026/4/8.
//  Copyright © 2026 Riseverse tech limited. All rights reserved.
//

import SwiftUI
import UIKit

// 考试类型结构体
struct ExamType: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let icon: String
    let imageName: String
    let category: ExamCategory
    let grades: [String]?        // 年级选项
    let languages: [ExamLanguage] // 语言选项
    let examId: String
}

// 语言
enum ExamLanguage: String, CaseIterable {
    case chinese = "中文"
    case english = "英文"
    
    var flag: String {
        switch self {
        case .chinese: return "🇨🇳"
        case .english: return "🇬🇧"
        }
    }
}

// 考试类别
enum ExamCategory: String, CaseIterable {
    case all = "全部"
    case primary = "小学"
    case junior = "初中"
    case senior = "高中"
    case international = "国际考试"
    
    var icon: String {
        switch self {
        case .all: return "square.grid.2x2.fill"
        case .primary: return "building.columns.fill"
        case .junior: return "building.2.fill"
        case .senior: return "graduationcap.fill"
        case .international: return "globe.asia.australia.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return Color(hex: "445CB4")
        case .primary: return Color(hex: "63BEF3")
        case .junior: return Color(hex: "7C66DC")
        case .senior: return Color(hex: "FFCC41")
        case .international: return Color(hex: "3EA0C6")
        }
    }
}

struct ExamPracticeView: View {
    // MARK: - 考试数据
    let exams: [ExamType] = [
        ExamType(
            name: "TSA中文口试",
            description: "看图说故事·口语报告·小组讨论",
            icon: "photo.stack.fill",
            imageName: "exam_primary",
            category: .primary,
            grades: ["小三", "小六"],
            languages: [.chinese, .english],
            examId: "primary_tsa_chinese"
        ),
        ExamType(
            name: "TSA英文口试",
            description:"朗读短文·师生互动问答·口语报告",
            icon: "photo.stack.fill",
            imageName: "exam_xiaoliuoral",
            category: .primary,
            grades: ["小三", "小六"],
            languages: [.chinese, .english],
            examId: "primary_tsa_english"
        ),
        ExamType(
            name: "DSE英文口试",
            description: "小组讨论·个人短讲",
            icon: "book.closed.fill",
            imageName: "exam_senior",
            category: .senior,
            grades: nil,
            languages: [.english],
            examId: "dse_english"
        ),
        ExamType(
            name: "IELTS英文口试",
            description: "全真模拟·一对一",
            icon: "globe.asia.australia.fill",
            imageName: "exam_international",
            category: .international,
            grades: nil,
            languages: [.english],
            examId: "ielts"
        ),
    ]
    
    @State private var selectedCategory: ExamCategory = .all
    @State private var searchText: String = ""
    
    private func getGradeText(for exam: ExamType) -> String {
        // 1. 优先使用 grades 数组（如果有）
        if let grades = exam.grades, !grades.isEmpty {
            if grades.count == 1 {
                return grades[0]
            } else {
                return grades.joined(separator: "、")
            }
        }
        
        // 2. 根据考试名称返回对应的年级
        switch exam.name {
        // --- 高中阶段 (Senior Secondary) ---
        case "DSE英文口试",
             "DSE 英文说话",
             "SBA 口头汇报",
             "SBA 个人短讲",
             "SBA 小组讨论":
            return "中四 - 中六"
            
        // --- 国际考试 ---
        case "IELTS英文口试":
            return "高中以上"
            
        // --- 默认情况 ---
        default:
            return "通用"
        }
    }
    
    var filteredExams: [ExamType] {
        var filtered = exams
        
        if selectedCategory != .all {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { exam in
                exam.name.localizedCaseInsensitiveContains(searchText) ||
                exam.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // 标题区域
                    headerSection
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                    
                    // 搜索框
                    searchBar
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                    
                    // 分类选择器
                    categoryScrollView
                        .padding(.bottom, 16)
                    
                    // 考试列表
                    LazyVStack(spacing: 12) {
                        ForEach(filteredExams, id: \.id) { exam in
                            ExamCard(
                                exam: exam,
                                categoryColor: exam.category.color,
                                gradeText: getGradeText(for: exam)
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    // 底部联系提示
                    if !filteredExams.isEmpty {
                        contactFooterView
                            .padding(.top, 24)
                            .padding(.bottom, 20)
                    }
                }
            }
            .background(Color("systemBackgroundColor"))
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - 标题区域
    var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("考试评估")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("模拟真实考试题目，获取智能评分与反馈")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.secondary)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - 搜索框
    var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 17))
            
            TextField("搜索考试类型", text: $searchText)
                .font(.system(size: 17))
                .foregroundColor(.primary)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 17))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color("baiseanniucolor"))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - 分类选择器
    var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ExamCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: {
                            HapticFeedbackManager.medium()
                            selectedCategory = category
                            
                        }
                    )
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - 底部联系提示
    var contactFooterView: some View {
        VStack(spacing: 16) {
            Divider()
            
            Button(action: {
                if let url = URL(string: "mailto:support@riseverse.com") {
                    UIApplication.shared.open(url)
                }
            }) {
                HStack(spacing: 8) {
                    Text("想要更多口试评估？")
                        .font(.system(size: 15))
                        .foregroundColor(.primary)
                    
                    Text("联系我们")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color(hex: "445CB4"))
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "445CB4"))
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - 分类按钮
struct CategoryButton: View {
    let category: ExamCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                Text(category.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? .white : category.color)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? category.color : category.color.opacity(0.12))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - 考试卡片
struct ExamCard: View {
    let exam: ExamType
    let categoryColor: Color
    let gradeText: String
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            if #available(iOS 26, *) {
                HStack(spacing: 12) {
                    // 考试图标
                    Image(exam.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 66, height: 66)
                        .foregroundColor(categoryColor)
                    
                    // 考试信息
                    VStack(alignment: .leading, spacing: 7) {
                        Text(exam.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(exam.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    // 年级标签
                    Text(gradeText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.12))
                        )
                }
                .padding(12)
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
            } else {
                HStack(spacing: 12) {
                    // 考试图标
                    Image(exam.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 66, height: 66)
                        .foregroundColor(categoryColor)
                    
                    // 考试信息
                    VStack(alignment: .leading, spacing: 4) {
                        Text(exam.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(exam.description)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer(minLength: 8)
                    
                    // 年级标签
                    Text(gradeText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(categoryColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(categoryColor.opacity(0.12))
                        )
                }
                .padding(12)
                .background(Color("baiseanniucolor"))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 根据 examId 跳转到不同视图
    @ViewBuilder
    var destinationView: some View {
        switch exam.examId {
        case "primary_tsa_chinese":
            // 中文 TSA 口试
            TSASettingView()
                .onAppear{
                    HapticFeedbackManager.medium()
                }
        case "primary_tsa_english":
            // 英文 TSA 口试
            TSAEnglishSettingView()
                .onAppear{
                    HapticFeedbackManager.medium()
                }
        case "dse_english":
            // DSE 英文口试
            DSESettingView()
                .onAppear{
                    HapticFeedbackManager.medium()
                }
        case "ielts":
            // 雅思口语的视图
            VStack {
                Text("雅思口语")
                    .font(.largeTitle)
                    .padding()
                Text("即将推出")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("雅思口语")
        default:
            VStack {
                Text(exam.name)
                    .font(.largeTitle)
                    .padding()
                Text("准备中")
                    .foregroundColor(.secondary)
            }
            .navigationTitle(exam.name)
        }
    }
}

#Preview {
    ExamPracticeView()
}

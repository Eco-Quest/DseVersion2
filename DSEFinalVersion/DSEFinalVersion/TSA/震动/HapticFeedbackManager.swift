//
//  HapticFeedbackManager.swift
//  dse_test
//
//  Created by Matt on 2026/5/25.
//


import Foundation
import UIKit

import Foundation
import UIKit

class HapticFeedbackManager {
    
    /// 触发轻微震动
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    /// 触发中等震动
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    /// 触发强烈震动
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    /// 触发软性震动
    static func soft() {
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred()
    }
    
    /// 触发刚性震动
    static func rigid() {
        let generator = UIImpactFeedbackGenerator(style: .rigid)
        generator.impactOccurred()
    }
    
    /// 触发成功通知震动
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    /// 触发警告通知震动
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    /// 触发错误通知震动
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    /// 触发选择改变震动
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // 新增：漸弱震動（3秒從強到弱）
       static func startFadingVibration(duration: TimeInterval = 3.0) {
           let totalSteps = 6 // 震動次數
           let stepDuration = duration / Double(totalSteps)
           
           for step in 0..<totalSteps {
               DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                   // 計算強度（從強到弱）
                   let intensity: CGFloat
                   switch step {
                   case 0, 1:
                       intensity = 1.0 // 強
                   case 2, 3:
                       intensity = 0.6 // 中
                   case 4, 5:
                       intensity = 0.3 // 弱
                   default:
                       intensity = 0.3
                   }
                   
                   // 使用 UIImpactFeedbackGenerator 並設置強度
                   let generator = UIImpactFeedbackGenerator(style: .heavy)
                   generator.prepare()
                   
                   // iOS 13+ 支持自定義強度
                   if #available(iOS 13.0, *) {
                       generator.impactOccurred(intensity: intensity)
                   } else {
                       generator.impactOccurred()
                   }
               }
           }
       }
       
       // 替代方案：使用連續震動（iOS 10+）
       static func startContinuousVibration(duration: TimeInterval = 3.0) {
           let generator = UIImpactFeedbackGenerator(style: .heavy)
           generator.prepare()
           
           // 開始震動
           if #available(iOS 13.0, *) {
               // iOS 13+ 可以使用連續震動
               generator.impactOccurred(intensity: 1.0)
               
               // 漸弱效果
               let totalSteps = 10
               let stepDuration = duration / Double(totalSteps)
               
               for step in 0..<totalSteps {
                   DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                       let intensity = max(0.1, 1.0 - (Double(step) / Double(totalSteps)))
                       generator.impactOccurred(intensity: intensity)
                   }
               }
           } else {
               // iOS 10-12 的替代方案
               let totalSteps = 6
               let stepDuration = duration / Double(totalSteps)
               
               for step in 0..<totalSteps {
                   DispatchQueue.main.asyncAfter(deadline: .now() + Double(step) * stepDuration) {
                       switch step {
                       case 0, 1:
                           heavy()
                       case 2, 3:
                           medium()
                       case 4, 5:
                           light()
                       default:
                           light()
                       }
                   }
               }
           }
       }
}

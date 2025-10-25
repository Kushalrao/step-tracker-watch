//
//  ContentView.swift
//  steps tracker Watch App
//
//  Created by Kushal on 24/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()
    @State private var showGoalSetting = true
    
    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()
            
            if showGoalSetting {
                GoalSettingView { goal in
                    healthKitManager.setDailyGoal(goal)
                    showGoalSetting = false
                }
            } else {
                VStack(spacing: 20) {
                    // Progress Circle
                    ZStack {
                        // Background circle
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 8)
                            .frame(width: 140, height: 140)
                        
                        // Progress circle
                        Circle()
                            .trim(from: 0, to: min(CGFloat(healthKitManager.stepCount) / CGFloat(healthKitManager.dailyGoal), 1.0))
                            .stroke(Color.white, lineWidth: 8)
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.5), value: healthKitManager.stepCount)
                        
                        // Step count
                        VStack(spacing: 4) {
                            Text("\(healthKitManager.stepCount.formatted())")
                                .font(.custom("SF Pro Rounded", size: 37))
                                .foregroundColor(.white)
                                .fontWeight(.medium)
                            
                            Text("of \(healthKitManager.dailyGoal.formatted())")
                                .font(.custom("SF Pro Rounded", size: 14))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    
                    // Goal progress text
                    Text("\(Int((Double(healthKitManager.stepCount) / Double(healthKitManager.dailyGoal)) * 100))% of goal")
                        .font(.custom("SF Pro Rounded", size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .onAppear {
            if !healthKitManager.isAuthorized {
                healthKitManager.requestAuthorization()
            }
        }
    }
}

#Preview {
    ContentView()
}

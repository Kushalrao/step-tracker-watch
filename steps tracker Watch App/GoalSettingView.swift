//
//  GoalSettingView.swift
//  steps tracker Watch App
//
//  Created by Kushal on 24/10/25.
//

import SwiftUI

struct GoalSettingView: View {
    @State private var goal: Double = 8000
    @State private var showContinueButton = false
    @State private var scrollOffset: CGFloat = 0
    
    let onGoalSet: (Int) -> Void
    
    private let minGoal: Double = 200
    private let maxGoal: Double = 20000
    private let stepSize: Double = 200
    
    // Computed properties for styling
    private var isOvershooting: Bool {
        goal > 10000
    }
    
    private var gradientColors: [Color] {
        if isOvershooting {
            return [Color.orange, Color.red]
        } else {
            let progress = min(goal / 10000, 1.0)
            return [
                Color.yellow,
                Color.green.opacity(progress)
            ]
        }
    }
    
    // Dotted border properties
    private var dotSize: CGFloat {
        isOvershooting ? 6 : 4
    }
    
    private var dotSpacing: CGFloat {
        isOvershooting ? 12 : 8
    }
    
    private var totalDots: Int {
        let circumference = Double.pi * (isOvershooting ? 130 : 120)
        return Int(circumference / Double(dotSpacing))
    }
    
    private var progressDots: Int {
        let progress = min(goal / 10000, 1.0)
        return Int(Double(totalDots) * progress)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Progress Circle - Centered
                    ZStack {
                        // Background dots (unfilled portion)
                        ForEach(progressDots..<totalDots, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(0.3))
                                .frame(width: dotSize, height: dotSize)
                                .offset(y: -(isOvershooting ? 80 : 75))
                                .rotationEffect(.degrees(Double(index) * 360.0 / Double(totalDots)))
                        }
                        
                        // Progress dots (filled portion with gradient)
                        ForEach(0..<progressDots, id: \.self) { index in
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: gradientColors),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: dotSize, height: dotSize)
                                .offset(y: -(isOvershooting ? 80 : 75))
                                .rotationEffect(.degrees(Double(index) * 360.0 / Double(totalDots)))
                        }
                        
                        // Goal number
                        Text("\(Int(goal))")
                            .font(.system(size: isOvershooting ? 28 : 24, weight: isOvershooting ? .black : .medium, design: .rounded))
                            .foregroundColor(.white)
                            .animation(.easeInOut(duration: 0.3), value: isOvershooting)
                        
                    }
                    
                    Spacer()
                    
                    // Continue Button (appears when scrolling)
                    if showContinueButton {
                        Button("Continue") {
                            onGoalSet(Int(goal))
                        }
                        .font(.custom("SF Pro Rounded", size: 18))
                        .foregroundColor(.black)
                        .background(Color.white)
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.3), value: showContinueButton)
                    }
                }
                .padding()
            }
        }
        .focusable()
        .digitalCrownRotation(
            $goal,
            from: minGoal,
            through: maxGoal,
            by: stepSize,
            sensitivity: .medium,
            isContinuous: false
        )
        .onChange(of: scrollOffset) { _, newValue in
            withAnimation {
                showContinueButton = newValue > 20
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    scrollOffset = value.translation.height
                }
                .onEnded { _ in
                    scrollOffset = 0
                }
        )
    }
}

#Preview {
    GoalSettingView { goal in
        print("Goal set to: \(goal)")
    }
}

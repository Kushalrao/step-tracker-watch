//
//  GoalSettingView.swift
//  steps tracker Watch App
//
//  Created by Kushal on 24/10/25.
//

import SwiftUI

struct GoalSettingView: View {
    @State private var goal: Double = 12000  // Start in second layer to see spiral effect
    @State private var showContinueButton = false
    @State private var scrollOffset: CGFloat = 0
    
    let onGoalSet: (Int) -> Void
    
    private let minGoal: Double = 200
    private let maxGoal: Double = 40000  // Support up to 4 layers (40,000 steps)
    private let stepSize: Double = 200
    
    // Computed properties for styling
    private var isOvershooting: Bool {
        goal > 10000
    }
    
    private func getGradientColors(for layer: Int) -> [Color] {
        let layerColors: [[Color]] = [
            [Color.yellow, Color.green],           // Layer 0: Yellow to Green
            [Color.green, Color.blue],             // Layer 1: Green to Blue  
            [Color.blue, Color.purple],            // Layer 2: Blue to Purple
            [Color.purple, Color.pink]             // Layer 3: Purple to Pink
        ]
        
        return layerColors[min(layer, layerColors.count - 1)]
    }
    
    // Dynamic spiral properties
    private let layerThreshold: Double = 10000
    private let maxLayers: Int = 4 // 1 base layer + 3 additional layers
    
    private var currentLayer: Int {
        min(Int(goal / layerThreshold), maxLayers - 1)
    }
    
    private var layerProgress: Double {
        let layerGoal = goal - Double(currentLayer) * layerThreshold
        return min(layerGoal / layerThreshold, 1.0)
    }
    
    private var dotSize: CGFloat {
        let baseSize: CGFloat = 4
        let layerBonus: CGFloat = CGFloat(currentLayer) * 0.5
        return baseSize + layerBonus
    }
    
    private var dotSpacing: CGFloat {
        let baseSpacing: CGFloat = 8
        let layerBonus: CGFloat = CGFloat(currentLayer) * 1.0
        return baseSpacing + layerBonus
    }
    
    private func getLayerRadius(for layer: Int) -> CGFloat {
        let baseRadius: CGFloat = 60
        let layerSpacing: CGFloat = 25
        return baseRadius + CGFloat(layer) * layerSpacing
    }
    
    private func getTotalDots(for layer: Int) -> Int {
        let radius = getLayerRadius(for: layer)
        let circumference = Double.pi * Double(radius * 2)
        return Int(circumference / Double(dotSpacing))
    }
    
    private func getProgressDots(for layer: Int) -> Int {
        if layer < currentLayer {
            // Previous layers are completely filled
            return getTotalDots(for: layer)
        } else if layer == currentLayer {
            // Current layer fills based on progress
            return Int(Double(getTotalDots(for: layer)) * layerProgress)
        } else {
            // Future layers are empty
            return 0
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Dynamic Spiral Circle - Centered
                    ZStack {
                        // Render each layer
                        ForEach(0..<maxLayers, id: \.self) { layer in
                            let radius = getLayerRadius(for: layer)
                            let totalDots = getTotalDots(for: layer)
                            let progressDots = getProgressDots(for: layer)
                            let layerDotSize = dotSize
                            
                            // Background dots (unfilled portion) for this layer
                            ForEach(progressDots..<totalDots, id: \.self) { index in
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: layerDotSize, height: layerDotSize)
                                    .offset(y: -radius)
                                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(totalDots)))
                            }
                            
                            // Progress dots (filled portion with gradient) for this layer
                            ForEach(0..<progressDots, id: \.self) { index in
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: getGradientColors(for: layer)),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: layerDotSize, height: layerDotSize)
                                    .offset(y: -radius)
                                    .rotationEffect(.degrees(Double(index) * 360.0 / Double(totalDots)))
                            }
                        }
                        
                        // Goal number
                        Text("\(Int(goal))")
                            .font(.system(size: currentLayer > 0 ? 28 : 24, weight: currentLayer > 0 ? .black : .medium, design: .rounded))
                            .foregroundColor(.white)
                            .animation(.easeInOut(duration: 0.3), value: currentLayer)
                        
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

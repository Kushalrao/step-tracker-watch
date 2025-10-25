//
//  GoalSettingView.swift
//  steps tracker Watch App
//
//  Created by Kushal on 24/10/25.
//

import SwiftUI

struct GoalSettingView: View {
    @State private var goal: Double = 10000  // Start at first threshold
    @State private var showContinueButton = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isDigitalCrownActive = false
    
    let onGoalSet: (Int) -> Void
    
    private let minGoal: Double = 200
    private let maxGoal: Double = 40000  // Support up to 4 layers (40,000 steps)
    private let stepSize: Double = 200
    
    // Continuous spiral properties - MUST BE DEFINED FIRST
    private let layerThreshold: Double = 10000
    private let maxLayers: Int = 4 // 1 base layer + 3 additional layers
    private let spiralTurns: Double = 2.0 // Number of turns per layer
    
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
    
    private var currentLayer: Int {
        min(Int(goal / layerThreshold), maxLayers - 1)
    }
    
    // Show all layers up to current progress (always add layers outward)
    private var visibleLayers: Int {
        min(currentLayer + 1, maxLayers) // +1 to include the layer we're currently on
    }
    
    private var zoomScale: CGFloat {
        // Calculate if spiral fits on screen
        // Watch screen allows much more space - be generous before zooming
        let maxVisibleRadius: CGFloat = 120 // Increased significantly to avoid early zoom
        
        // Calculate the ACTUAL outer radius of the outermost layer
        let baseRadius: CGFloat = 65
        let layerSpacing: CGFloat = 14
        // The outermost layer index is (visibleLayers - 1), plus add full spacing for that layer
        let currentOuterRadius = baseRadius + CGFloat(visibleLayers - 1) * layerSpacing + layerSpacing
        
        // Only zoom out if it doesn't fit
        if currentOuterRadius > maxVisibleRadius {
            return maxVisibleRadius / currentOuterRadius
        } else {
            return 1.0 // No zoom needed, keep it 100%
        }
    }
    
    // No offset needed - keep everything centered
    private var zoomOffset: CGSize {
        return CGSize.zero
    }
    
    private var layerProgress: Double {
        let layerGoal = goal - Double(currentLayer) * layerThreshold
        return min(layerGoal / layerThreshold, 1.0)
    }
    
    // Get the color for the current progress (last dot color)
    private var currentProgressColor: Color {
        return getSmoothColor(layer: currentLayer, progress: layerProgress)
    }
    
    // Calculate spiral position for a given progress (0.0 to 1.0)
    private func getSpiralPosition(progress: Double) -> (x: CGFloat, y: CGFloat, layer: Int, color: Color) {
        let totalProgress = progress * Double(visibleLayers) * spiralTurns
        
        // Determine which layer we're in
        let layer = Int(totalProgress / spiralTurns)
        let layerProgress = (totalProgress.truncatingRemainder(dividingBy: spiralTurns)) / spiralTurns
        
        // Calculate radius - FIXED spacing, zoom handles the fitting
        let baseRadius: CGFloat = 65 // FIXED inner breathing room
        let layerSpacing: CGFloat = 14 // FIXED layer spacing - zoom will handle fitting
        let radius = baseRadius + CGFloat(layer) * layerSpacing + CGFloat(layerProgress) * layerSpacing
        
        // Calculate angle (continuous spiral)
        let angle = totalProgress * 2 * Double.pi
        
        // Convert to Cartesian coordinates
        let x = CGFloat(cos(angle)) * radius
        let y = CGFloat(sin(angle)) * radius
        
        // Smooth color transition based on layer progress
        let color = getSmoothColor(layer: layer, progress: layerProgress)
        
        return (x: x, y: y, layer: layer, color: color)
    }
    
    // Smooth color interpolation between layers - rainbow gradient
    private func getSmoothColor(layer: Int, progress: Double) -> Color {
        let layerColors: [Color] = [
            Color.red,      // Layer 0 start
            Color.orange,   // Layer 0-1 transition
            Color.yellow,   // Layer 1
            Color.green,    // Layer 2
            Color.cyan,     // Layer 2-3 transition
            Color.blue,     // Layer 3
            Color.purple,   // Layer 3-4 transition
            Color.pink      // Layer 4 (overflow)
        ]
        
        // Map layer and progress to color gradient
        // Each layer covers 2 color transitions for smooth rainbow effect
        let colorIndex = Double(layer) * 2.0 + progress * 2.0
        let currentColorIndex = Int(colorIndex)
        let nextColorIndex = min(currentColorIndex + 1, layerColors.count - 1)
        let colorProgress = colorIndex - Double(currentColorIndex)
        
        let currentColorIdx = min(currentColorIndex, layerColors.count - 1)
        let nextColorIdx = min(nextColorIndex, layerColors.count - 1)
        
        // Interpolate between current and next color
        return layerColors[currentColorIdx].interpolated(to: layerColors[nextColorIdx], amount: colorProgress)
    }
    
    // Calculate total dots for continuous spiral
    private var totalSpiralDots: Int {
        let totalTurns = Double(visibleLayers) * spiralTurns
        let baseRadius: CGFloat = 65 // FIXED
        let layerSpacing: CGFloat = 14 // FIXED - match getSpiralPosition
        let avgRadius = baseRadius + CGFloat(visibleLayers) * layerSpacing / 2
        let totalCircumference = Double.pi * Double(avgRadius) * 2 * totalTurns
        return Int(totalCircumference / 8.0) // 8pt spacing
    }
    
    // Calculate progress dots for continuous spiral
    private var progressSpiralDots: Int {
        let totalProgress = (Double(currentLayer) + layerProgress) * spiralTurns
        let totalTurns = Double(visibleLayers) * spiralTurns
        return Int(Double(totalSpiralDots) * (totalProgress / totalTurns))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black
                    .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Dynamic Zoom Spiral - Centered
                    ZStack {
                        // Background dots (unfilled portion of spiral)
                        ForEach(progressSpiralDots..<totalSpiralDots, id: \.self) { index in
                            let progress = Double(index) / Double(totalSpiralDots)
                            let position = getSpiralPosition(progress: progress)
                            
                            Circle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: 4, height: 4)
                                .offset(x: position.x, y: position.y)
                        }
                        
                        // Progress dots (filled portion of spiral)
                        ForEach(0..<progressSpiralDots, id: \.self) { index in
                            let progress = Double(index) / Double(totalSpiralDots)
                            let position = getSpiralPosition(progress: progress)
                            
                            // Calculate ripple effect for last 10 dots (only when digital crown is active)
                            let distanceFromEnd = progressSpiralDots - 1 - index
                            let isInRippleRange = distanceFromEnd < 10
                            let rippleScale: CGFloat = isDigitalCrownActive && isInRippleRange ? (2.0 - CGFloat(distanceFromEnd) * 0.1) : 1.0
                            
                            Circle()
                                .fill(position.color)
                                .frame(width: 4, height: 4)
                                .scaleEffect(rippleScale)
                                .offset(x: position.x, y: position.y)
                                .animation(.easeOut(duration: 0.3), value: rippleScale)
                        }
                        
                        // Goal number with dynamic color
                        Text("\(Int(goal))")
                            .font(.system(size: currentLayer > 0 ? 28 : 24, weight: currentLayer > 0 ? .black : .medium, design: .rounded))
                            .foregroundColor(currentProgressColor)
                            .animation(.easeInOut(duration: 0.3), value: currentLayer)
                            .animation(.easeInOut(duration: 0.5), value: currentProgressColor)
                        
                    }
                    .scaleEffect(zoomScale)
                    .offset(zoomOffset)
                    .animation(.easeInOut(duration: 0.8), value: zoomScale)
                    
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
        .onChange(of: goal) { _, _ in
            // Digital crown is being used
            isDigitalCrownActive = true
            
            // Reset after a short delay (0.5 seconds of no movement)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isDigitalCrownActive = false
                }
            }
        }
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

// Color interpolation extension for smooth transitions
extension Color {
    func interpolated(to endColor: Color, amount: Double) -> Color {
        let amount = min(max(amount, 0.0), 1.0) // Clamp between 0 and 1
        
        // Convert colors to RGB components
        guard let startComponents = UIColor(self).cgColor.components,
              let endComponents = UIColor(endColor).cgColor.components else {
            return self
        }
        
        // Interpolate each component
        let r = startComponents[0] + (endComponents[0] - startComponents[0]) * amount
        let g = startComponents[1] + (endComponents[1] - startComponents[1]) * amount
        let b = startComponents[2] + (endComponents[2] - startComponents[2]) * amount
        
        return Color(red: r, green: g, blue: b)
    }
}

#Preview {
    GoalSettingView { goal in
        print("Goal set to: \(goal)")
    }
}

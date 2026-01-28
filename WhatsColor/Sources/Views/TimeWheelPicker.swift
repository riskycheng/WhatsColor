// MARK: - Professional iOS-Style Time Picker Ruler

import SwiftUI
import AudioToolbox

struct TimeWheelPicker: View {
    @Binding var selectedTime: Int
    @State private var offset: CGFloat = 0 // This will now represent the knob's position relative to center
    @State private var rulerOffset: CGFloat = 0 // This will represent the ruler's scroll
    @State private var lastOffset: CGFloat = 0
    @State private var isInteracting: Bool = false
    @GestureState private var isDragging: Bool = false
    
    private let minTime: Int = 10
    private let maxTime: Int = 900
    private let tickSpacing: CGFloat = 12
    private let viewHeight: CGFloat = 320
    private let knobTravelLimit: CGFloat = 100 // How far knob can move before ruler slides
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Ruler Portion
            ZStack {
                // The Ticks and Numbers
                GeometryReader { geometry in
                    let midY = geometry.size.height / 2
                    
                    ZStack(alignment: .trailing) {
                        ForEach(Array(stride(from: minTime, through: maxTime, by: 1)), id: \.self) { time in
                            // Ruler hangs around the center, moved by rulerOffset
                            // We use a fixed reference (60s at midY + rulerOffset)
                            let timeDifference = CGFloat(time - 60)
                            let currentY = midY + rulerOffset - (timeDifference * tickSpacing)
                            
                            // Only render visible ticks
                            if currentY > -50 && currentY < viewHeight + 50 {
                                RulerItemView(time: time, isSelected: time == selectedTime)
                                    .position(x: 40, y: currentY)
                            }
                        }
                    }
                }
                .frame(width: 85)
                
                // MARK: - Curved Line Overlay (Moves with knob)
                RulerLineShape()
                    .stroke(
                        LinearGradient(
                            colors: [.white.opacity(0.1), .white.opacity(0.6), .white.opacity(0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 30)
                    .offset(x: 35, y: offset)
                    .overlay(
                        // Blue Glow
                        RulerCurveGlow()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.5), Color.blue.opacity(0)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 30
                                )
                            )
                            .blur(radius: 5)
                            .frame(width: 40, height: 100)
                            .offset(x: 35, y: offset)
                    )
            }
            .frame(height: viewHeight)
            .clipped()
            
            // MARK: - Knob portion (Moves with finger)
            KnobView(isDragging: isInteracting)
                .offset(y: offset)
                .padding(.horizontal, 10)
            
            // MARK: - Large Display
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("\(selectedTime)")
                    .font(.system(size: 80, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                
                Text("s")
                    .font(.system(size: 20, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 8)
            }
            .frame(width: 150, alignment: .leading)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    isInteracting = true
                    
                    let deltaY = value.translation.height - lastOffset
                    lastOffset = value.translation.height
                    
                    // Logic: 
                    // 1. Move knob first
                    // 2. If knob hits boundary, scroll ruler instead
                    
                    let potentialOffset = offset + deltaY
                    if abs(potentialOffset) <= knobTravelLimit {
                        offset = potentialOffset
                    } else {
                        // At boundary, move ruler in opposite direction of drag to pull new scales in
                        rulerOffset -= deltaY
                        // Clamp knob exactly at limit
                        offset = potentialOffset > 0 ? knobTravelLimit : -knobTravelLimit
                    }
                    
                    updateSelectionFromPositions()
                }
                .onEnded { _ in
                    lastOffset = 0
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isInteracting = false
                    }
                }
        )
        .frame(height: viewHeight)
        .onAppear {
            if selectedTime == 0 { selectedTime = 60 }
            // Initialize ruler so selectedTime is at the knob
            syncPositionsFromSelection()
        }
    }
    
    private func syncPositionsFromSelection() {
        // Center the ruler at 60, then scroll it so selectedTime is at center
        rulerOffset = CGFloat(selectedTime - 60) * tickSpacing
        offset = 0 // Knob starts at center
    }
    
    private func updateSelectionFromPositions() {
        // totalTimeOffset = rulerOffset - knobOffset
        // time = 60 + totalTimeOffset / tickSpacing
        let totalPixels = rulerOffset - offset
        let newTime = 60 + Int(round(totalPixels / tickSpacing))
        let clampedTime = max(minTime, min(maxTime, newTime))
        
        if clampedTime != selectedTime {
            selectedTime = clampedTime
            triggerFeedback()
        }
    }
    
    private func triggerFeedback() {
        // Haptic feedback
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        
        // Audio feedback (Standard iOS Picker Tick Sound)
        // SystemSoundID 1104 is the classic wheel "tick" sound
        AudioServicesPlaySystemSound(1104)
    }
}

struct RulerItemView: View {
    let time: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            if time % 5 == 0 {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(time)")
                        .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .monospaced))
                    
                    Text("SEC")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.3))
                }
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .frame(width: 45, alignment: .trailing)
                
                Rectangle()
                    .fill(isSelected ? Color.white : Color.white.opacity(0.3))
                    .frame(width: 12, height: 1.5)
            } else {
                Spacer()
                    .frame(width: 45) // Match text width
                
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 6, height: 1)
            }
        }
    }
}

struct RulerLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width / 2
        let midY = rect.height / 2
        let curveHeight: CGFloat = 50
        let curveWidth: CGFloat = 15
        
        path.move(to: CGPoint(x: centerX, y: 0))
        path.addLine(to: CGPoint(x: centerX, y: midY - curveHeight))
        
        // Outward curve for the bump
        path.addCurve(
            to: CGPoint(x: centerX, y: midY + curveHeight),
            control1: CGPoint(x: centerX + curveWidth, y: midY - curveHeight / 2),
            control2: CGPoint(x: centerX + curveWidth, y: midY + curveHeight / 2)
        )
        
        path.addLine(to: CGPoint(x: centerX, y: rect.height))
        
        return path
    }
}

struct RulerCurveGlow: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let centerX = rect.width / 2
        let midY = rect.height / 2
        let curveHeight: CGFloat = 50
        let curveWidth: CGFloat = 15
        
        // Just the curve part
        path.move(to: CGPoint(x: centerX, y: midY - curveHeight))
        path.addCurve(
            to: CGPoint(x: centerX, y: midY + curveHeight),
            control1: CGPoint(x: centerX + curveWidth, y: midY - curveHeight / 2),
            control2: CGPoint(x: centerX + curveWidth, y: midY + curveHeight / 2)
        )
        
        return path
    }
}

struct KnobView: View {
    let isDragging: Bool
    
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.2), Color(white: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 54, height: 54)
                .shadow(color: .black.opacity(0.5), radius: 5, x: 0, y: 2)
                .scaleEffect(isDragging ? 1.1 : 1.0)
            
            // Inner circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.25), Color(white: 0.15)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 20
                    )
                )
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            
            // Icons
            VStack(spacing: 6) {
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundColor(.white.opacity(0.6))
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isDragging)
    }
}

struct TimeWheelPicker_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color(white: 0.1).ignoresSafeArea()
            TimeWheelPicker(selectedTime: .constant(60))
        }
    }
}

// MARK: - Professional iOS-Style Time Picker Ruler

import SwiftUI
import AudioToolbox

struct TimeWheelPicker: View {
    @Binding var selectedTime: Int
    @State private var offset: CGFloat = 0
    @State private var lastOffset: CGFloat = 0
    @State private var isInteracting: Bool = false
    @GestureState private var isDragging: Bool = false
    
    private let minTime: Int = 10
    private let maxTime: Int = 300
    private let tickSpacing: CGFloat = 12
    private let viewHeight: CGFloat = 320
    
    // Using a separate state for the visual "scrolling" value to keep it smooth
    @State private var displayTime: Double = 60
    
    var body: some View {
        HStack(spacing: 0) {
            // MARK: - Ruler Portion
            ZStack {
                // The Ticks and Numbers
                GeometryReader { geometry in
                    let midY = geometry.size.height / 2
                    
                    ZStack(alignment: .trailing) {
                        ForEach(Array(stride(from: minTime, through: maxTime, by: 1)), id: \.self) { time in
                            // Calculation: Higher values are at the TOP
                            // When time == selectedTime, currentY should be midY
                            let timeDifference = CGFloat(time - selectedTime)
                            let currentY = midY + offset - (timeDifference * tickSpacing)
                            
                            // Only render visible ticks for performance
                            if currentY > -50 && currentY < viewHeight + 50 {
                                RulerItemView(time: time, isSelected: time == selectedTime)
                                    .position(x: 40, y: currentY)
                            }
                        }
                    }
                }
                .frame(width: 85)
                
                // MARK: - Curved Line Overlay
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
                    .offset(x: 35)
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
                            .offset(x: 35)
                    )
            }
            .frame(height: viewHeight)
            .clipped()
            
            // MARK: - Knob portion
            KnobView(isDragging: isInteracting)
                .padding(.horizontal, 10)
            
            // MARK: - Large Display
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(selectedTime)")
                    .font(.system(size: 85, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                
                Text("s")
                    .font(.system(size: 24, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 12)
            }
            .frame(width: 155, alignment: .leading)
        }
        .contentShape(Rectangle()) // Make the whole area draggable
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isDragging) { _, state, _ in
                    state = true
                }
                .onChanged { value in
                    if !isInteracting {
                        isInteracting = true
                    }
                    // Traditional drag: dragging DOWN reveals things ABOVE (larger values)
                    // So finger moving DOWN (translation.height > 0) should increase value
                    // In our currentY formula: currentY = midY + offset - (time - selected) * 12
                    // Dragging down makes offset positive, which moves 61, 62 towards midY. Correct.
                    offset = lastOffset + value.translation.height
                    updateSelection(isFinal: false)
                }
                .onEnded { value in
                    let finalOffset = lastOffset + value.translation.height
                    let snappedOffset = round(finalOffset / tickSpacing) * tickSpacing
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = snappedOffset
                        updateSelection(isFinal: true)
                        isInteracting = false
                    }
                    
                    lastOffset = snappedOffset
                }
        )
        .frame(height: viewHeight)
        .onAppear {
            // Ensure default is 60 if it's not yet set
            if selectedTime == 0 {
                selectedTime = 60
            }
        }
    }
    
    private func updateSelection(isFinal: Bool) {
        // newTime = selectedTime + (offset / tickSpacing)
        let delta = Int(round(offset / tickSpacing))
        let newTime = selectedTime + delta
        let clampedTime = max(minTime, min(maxTime, newTime))
        
        if clampedTime != selectedTime {
            // Only update the actual binding and trigger haptics when we jump to a new integer
            selectedTime = clampedTime
            // If we moved "one snap worth", we reset the offset relative to the new selection
            // This makes the ruler feel infinite and prevents offset from becoming huge
            lastOffset -= CGFloat(delta) * tickSpacing
            offset -= CGFloat(delta) * tickSpacing
            
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

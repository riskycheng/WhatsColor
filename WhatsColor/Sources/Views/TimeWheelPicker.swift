// MARK: - Professional iOS-Style Time Picker Ruler

import SwiftUI
import AudioToolbox

struct TimeWheelPicker: View {
    @Binding var selectedTime: Int
    @State private var offset: CGFloat = 0 // This will now represent the knob's position relative to center
    @State private var rulerOffset: CGFloat = 0 // This will represent the ruler's scroll
    @State private var lastOffset: CGFloat = 0
    @State private var isInteracting: Bool = false
    @State private var isFastScrolling: Bool = false
    @GestureState private var isDragging: Bool = false
    
    private let minTime: Int = 10
    private let maxTime: Int = 600
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
                            // Calculation: Smaller values are at the TOP (10 -> top, 600 -> bottom)
                            let timeDifference = CGFloat(time - 60)
                            let currentY = midY + rulerOffset + (timeDifference * tickSpacing)
                            
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
                    .font(.system(size: 72, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text("s")
                    .font(.system(size: 18, weight: .light, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 6)
            }
            .frame(width: 155, alignment: .leading)
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
                    
                    // Natural Coordinates: 10 at top, 600 at bottom.
                    // To scroll to 10: rulerOffset becomes positive (50*tickSpacing)
                    // To scroll to 600: rulerOffset becomes negative (-540*tickSpacing)
                    let minTotalPixels = CGFloat(60 - maxTime) * tickSpacing // -540 * 12
                    let maxTotalPixels = CGFloat(60 - minTime) * tickSpacing // 50 * 12
                    let currentTotal = rulerOffset - offset
                    
                    // Detect if touch started on the left ruler side for "Fast Scroll"
                    if value.startLocation.x < 110 {
                        isFastScrolling = true
                        // Fast scroll: Dragging DOWN (deltaY > 0) moves ruler DOWN (increases rulerOffset)
                        let proposedDelta = (deltaY * 4.5)
                        let newTotal = max(minTotalPixels, min(maxTotalPixels, currentTotal + proposedDelta))
                        rulerOffset = newTotal + offset
                    } else {
                        isFastScrolling = false
                        // Knob Logic: Dragging DOWN (deltaY > 0) moves knob DOWN (increases offset)
                        // Resulting in value changing towards bottom (larger numbers)
                        let speed: CGFloat = abs(offset) <= knobTravelLimit ? 1.0 : 2.5
                        let proposedDelta = (deltaY * speed)
                        // Invert sign of delta for totalPixels (ruler - offset) so that offset follows finger
                        let newTotal = max(minTotalPixels, min(maxTotalPixels, currentTotal - proposedDelta))
                        
                        // Distribute the new pixel total between offset and ruler
                        let targetOffset = rulerOffset - newTotal
                        if abs(targetOffset) <= knobTravelLimit {
                            offset = targetOffset
                        } else {
                            offset = targetOffset > 0 ? knobTravelLimit : -knobTravelLimit
                            rulerOffset = newTotal + offset
                        }
                    }
                    
                    updateSelectionFromPositions()
                }
                .onEnded { _ in
                    lastOffset = 0
                    isFastScrolling = false
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
        // Natural: To center 70 (which is below center), ruler must move UP (-10k)
        rulerOffset = CGFloat(60 - selectedTime) * tickSpacing
        offset = 0 // Knob starts at center
    }
    
    private func updateSelectionFromPositions() {
        // totalPixels = rulerOffset - offset
        // In natural layout (10 at top):
        // Higher Time -> Ruler moves UP (neg) or Knob moves DOWN (pos) -> totalPixels becomes more NEGATIVE
        // Time = 60 - (totalPixels / tickSpacing)
        let totalPixels = rulerOffset - offset
        let rawSecondsOffset = Double(totalPixels) / Double(tickSpacing)
        let seconds = 60.0 - rawSecondsOffset
        
        // Snap to 10s increments as requested
        let snappedTime = Int(round(seconds / 10.0)) * 10
        let clampedTime = max(minTime, min(maxTime, snappedTime))
        
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

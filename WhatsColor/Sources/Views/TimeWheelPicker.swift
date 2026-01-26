// MARK: - Professional iOS-Style Time Picker Wheel

import SwiftUI
import AudioToolbox

struct TimeWheelPicker: View {
    @Binding var selectedTime: Int
    @State private var scrollOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @State private var lastDragValue: CGFloat = 0
    @State private var velocity: CGFloat = 0
    @State private var lastTime: Date = Date()
    @State private var currentIndex: Int = 3  // 初始选中60秒 (index 3 = 30 + 3*10)

    private let minTime: Int = 30
    private let maxTime: Int = 900
    private let step: Int = 10
    private let itemHeight: CGFloat = 44
    private var allItems: [Int] {
        Array(stride(from: minTime, through: maxTime, by: step))
    }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width

            ZStack {
                // 深色金属质感背景
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(white: 0.12),
                                Color(white: 0.08),
                                Color(white: 0.12)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)

                // 中间选择区域高亮框
                VStack {
                    // 上分割线
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.top, itemHeight * 3)

                    Spacer()

                    // 下分割线
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)
                        .padding(.bottom, itemHeight * 3)
                }

                // 顶部渐变遮罩
                VStack {
                    LinearGradient(
                        colors: [Color(white: 0.1), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: itemHeight * 2)
                    .allowsHitTesting(false)

                    Spacer()

                    LinearGradient(
                        colors: [Color.clear, Color(white: 0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: itemHeight * 2)
                    .allowsHitTesting(false)
                }
                .allowsHitTesting(false)

                // 滚轮内容
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        Color.clear.frame(height: itemHeight * 3)

                        ForEach(allItems, id: \.self) { seconds in
                            TimeWheelItem(seconds: seconds, isSelected: seconds == selectedTime)
                                .frame(height: itemHeight)
                        }

                        Color.clear.frame(height: itemHeight * 3)
                    }
                    .frame(width: width)
                    .offset(y: scrollOffset)
                    .animation(isDragging ? .none : .spring(response: 0.35, dampingFraction: 0.8), value: scrollOffset)
                }
                .disabled(true)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let now = Date()
                        let dt = now.timeIntervalSince(lastTime)
                        if dt > 0 {
                            velocity = (value.location.y - lastDragValue) / CGFloat(dt)
                        }
                        lastTime = now
                        lastDragValue = value.location.y

                        if !isDragging {
                            isDragging = true
                        }
                        scrollOffset += value.translation.height
                    }
                    .onEnded { value in
                        isDragging = false
                        let inertialOffset = velocity * 0.15
                        let totalOffset = -scrollOffset + inertialOffset
                        let itemOffset = totalOffset / itemHeight
                        var newIndex = currentIndex + Int(round(itemOffset))
                        newIndex = max(0, min(allItems.count - 1, newIndex))

                        if newIndex != currentIndex {
                            playGearTickSound()
                            currentIndex = newIndex
                            selectedTime = allItems[newIndex]
                        }

                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            scrollOffset = -CGFloat(currentIndex) * itemHeight
                        }
                    }
            )
            .onAppear {
                scrollOffset = -CGFloat(currentIndex) * itemHeight
            }
        }
        .frame(height: itemHeight * 7)
    }

    private func playGearTickSound() {
        AudioServicesPlaySystemSound(1104)
    }
}

struct TimeWheelItem: View {
    let seconds: Int
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            // 选中指示器
            if isSelected {
                Circle()
                    .fill(Color.gameGreen)
                    .frame(width: 8, height: 8)
            } else {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 6, height: 6)
            }

            // 数字 - 居中显示
            Text("\(seconds)")
                .font(.system(size: isSelected ? 28 : 22, weight: isSelected ? .bold : .regular, design: .rounded))
                .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                .frame(minWidth: 50, alignment: .trailing)
                .shadow(color: .black.opacity(isSelected ? 0.4 : 0), radius: 3, x: 0, y: 2)

            // 单位
            Text("SEC")
                .font(.system(size: isSelected ? 12 : 10, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundColor(isSelected ? Color.gameGreen : .white.opacity(0.3))
                .padding(.top, isSelected ? 3 : 0)

            Spacer()
        }
        .frame(height: 44)
        .padding(.horizontal, 24)
        .background(
            Group {
                if isSelected {
                    LinearGradient(
                        colors: [Color.gameGreen.opacity(0.15), Color.gameGreen.opacity(0.08)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                } else {
                    Color.clear
                }
            }
        )
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

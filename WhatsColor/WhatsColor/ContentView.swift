//
//  ContentView.swift
//  WhatsColor
//
//  Created by Jian Cheng on 2026/1/25.
//

import SwiftUI

struct DeviceHeader: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Antenna / Toggle Switch Area
            ZStack {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color(hex: "555555"))
                    .frame(width: 80, height: 26)
                
                // Mode indicator switch
                Rectangle()
                    .fill(Color(hex: "333333"))
                    .frame(width: 30, height: 10)
                    .cornerRadius(5)
                    .overlay(
                        Circle()
                            .fill(viewModel.gameMode == .advanced ? Color.green : Color.orange)
                            .frame(width: 14, height: 14)
                            .offset(x: viewModel.gameMode == .advanced ? 10 : -10)
                    )
                    .onTapGesture {
                        viewModel.gameMode = (viewModel.gameMode == .advanced ? .beginner : .advanced)
                    }
            }
            .padding(.bottom, -10)
            .zIndex(1)
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            Color(hex: "f0f0f0").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Text("Super Code")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .padding(.top, 20)
                    
                    VStack(spacing: 0) {
                        DeviceHeader(viewModel: viewModel)
                        
                        VStack(spacing: 25) {
                            // Game Board
                            GameBoardView(viewModel: viewModel)
                            
                            // Lower Panel
                            VStack(spacing: 15) {
                                // Range Indicator
                                HStack {
                                    Text("Range:")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    HStack(spacing: 4) {
                                        ForEach(viewModel.allColors) { color in
                                            RoundedRectangle(cornerRadius: 1)
                                                .fill(color.color)
                                                .frame(width: 12, height: 6)
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 15)
                                .background(Color.black)
                                .cornerRadius(4)
                                
                                // Status Display
                                StatusDisplayView(viewModel: viewModel)
                                
                                if viewModel.isGameOver {
                                    HStack(spacing: 12) {
                                        Text("SECRET:")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                        
                                        HStack(spacing: 8) {
                                            ForEach(viewModel.secretCode) { color in
                                                Circle()
                                                    .fill(color.color)
                                                    .frame(width: 20, height: 20)
                                                    .shadow(color: color.color.opacity(0.8), radius: 5)
                                            }
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(10)
                                }
                                
                                // Input and Knob
                                VStack(spacing: 25) {
                                    CurrentInputView(viewModel: viewModel)
                                    
                                    KnobButton(viewModel: viewModel)
                                }
                            }
                        }
                        .padding(30)
                        .background(Color(hex: "8db568"))
                        .cornerRadius(40)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                    }
                    .frame(maxWidth: 400)
                    
                    Button(action: {
                        viewModel.startNewGame()
                    }) {
                        Text("NEW GAME")
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(Color.black)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
}

struct GameBoardView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            // Row numbers
            VStack(spacing: 12) {
                ForEach((1...7).reversed(), id: \.self) { i in
                    Text("\(i)")
                        .font(.system(size: 14))
                        .foregroundColor(Color.white.opacity(0.2))
                        .frame(height: 40)
                }
            }
            
            // Grid
            VStack(spacing: 12) {
                ForEach((0..<7).reversed(), id: \.self) { rowIndex in
                    let attempt = rowIndex < viewModel.attempts.count ? viewModel.attempts[rowIndex] : nil
                    GuessRowView(attempt: attempt, gameMode: viewModel.gameMode)
                }
            }
        }
        .padding(20)
        .background(Color(hex: "333333"))
        .cornerRadius(12)
    }
}

struct GuessRowView: View {
    let attempt: Attempt?
    let gameMode: GameMode
    
    var body: some View {
        HStack(spacing: 12) {
            // Slots
            HStack(spacing: 10) {
                ForEach(0..<4) { i in
                    ZStack {
                        let color = attempt?.guess[i]?.color ?? Color(hex: "222222")
                        let isFilled = attempt?.guess[i] != nil
                        
                        RoundedRectangle(cornerRadius: 6)
                            .fill(color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(hex: "444444"), lineWidth: 1)
                            )
                            .shadow(color: color.opacity(isFilled ? 0.6 : 0), radius: 5)
                        
                        if gameMode == .beginner, let feedback = attempt?.feedback[i] {
                            Rectangle()
                                .fill(feedbackColor(feedback))
                                .frame(width: 20, height: 4)
                                .cornerRadius(2)
                                .offset(y: 12)
                        }
                    }
                }
            }
            
            // Feedback dots for advanced mode
            if gameMode == .advanced {
                FeedbackDotsView(feedback: attempt?.feedback ?? [.none, .none, .none, .none], isAttempted: attempt != nil)
            }
        }
    }
    
    func feedbackColor(_ type: FeedbackType) -> Color {
        switch type {
        case .correct: return Color(hex: "4cd964")
        case .misplaced: return .white
        case .none: return .clear
        }
    }
}

struct FeedbackDotsView: View {
    let feedback: [FeedbackType]
    let isAttempted: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                dot(feedback[0])
                dot(feedback[1])
            }
            HStack(spacing: 4) {
                dot(feedback[2])
                dot(feedback[3])
            }
        }
        .padding(.leading, 10)
    }
    
    @ViewBuilder
    func dot(_ type: FeedbackType) -> some View {
        let color = feedbackColor(type)
        let border = borderColor(type)
        
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(border, lineWidth: 1)
            )
            .shadow(color: type != .none ? color.opacity(0.8) : .clear, radius: 3)
    }
    
    func feedbackColor(_ type: FeedbackType) -> Color {
        if !isAttempted { return Color(hex: "111111") }
        switch type {
        case .correct: return Color(hex: "4cd964")
        case .misplaced: return .white
        case .none: return Color(hex: "111111")
        }
    }
    
    func borderColor(_ type: FeedbackType) -> Color {
        if !isAttempted { return Color(hex: "333333") }
        switch type {
        case .correct: return Color(hex: "4cd964")
        case .misplaced: return .white
        case .none: return Color(hex: "333333")
        }
    }
}

struct StatusDisplayView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        HStack {
            Text(String(format: "%03d", viewModel.level))
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(Color(hex: "ff3b30"))
                .shadow(color: Color(hex: "ff3b30").opacity(0.5), radius: 5)
            
            Spacer()
            
            Text(viewModel.statusMessage)
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 10)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(hex: "222222"), lineWidth: 3)
        )
    }
}

struct CurrentInputView: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var showingColorPicker = false
    
    var body: some View {
        HStack(spacing: 15) {
            ForEach(0..<4) { i in
                RoundedRectangle(cornerRadius: 10)
                    .fill(viewModel.currentGuess[i]?.color ?? Color(hex: "222222"))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(viewModel.selectedSlotIndex == i ? Color.white : Color.clear, lineWidth: 3)
                    )
                    .onTapGesture {
                        viewModel.selectedSlotIndex = i
                        showingColorPicker = true
                    }
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(viewModel: viewModel)
                .presentationDetents([.height(150)])
        }
    }
}

struct ColorPickerSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Select Color")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 20) {
                ForEach(viewModel.allColors) { color in
                    Circle()
                        .fill(color.color)
                        .frame(width: 40, height: 40)
                        .onTapGesture {
                            viewModel.selectColor(color)
                            dismiss()
                        }
                }
            }
            .padding()
            
            Spacer()
        }
    }
}

struct KnobButton: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        Button(action: {
            viewModel.submitGuess()
        }) {
            ZStack {
                Circle()
                    .fill(Color(hex: "ff6b6b"))
                    .frame(width: 80, height: 80)
                    .shadow(radius: 5, y: 5)
                
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .padding(2)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: 15)
                    .offset(y: -25)
            }
        }
    }
}

#Preview {
    ContentView()
}

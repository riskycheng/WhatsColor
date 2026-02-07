import SwiftUI

struct ThemeSelectionView: View {
    @ObservedObject var viewModel: GameViewModel
    
    // Fixed dialog dimensions to match handheld aesthetic
    private let dialogWidth: CGFloat = 360
    private let dialogPadding: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Semi-transparent overlay
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.showThemeSelection = false
                }
            
            VStack(spacing: 0) {
                // Header section (Industrial Panel style)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("VISUALIZATION ENGINE")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("SELECT DATA ASSET MODULE")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(.gameGreen.opacity(0.6))
                            .tracking(2)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        viewModel.showThemeSelection = false
                    }) {
                        Image(systemName: "xmark.square.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .padding(.horizontal, dialogPadding)
                .padding(.top, 24)
                .padding(.bottom, 20)
                
                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 1)
                    .padding(.horizontal, dialogPadding)
                
                // Theme Grid
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(GameTheme.allCases) { theme in
                            ThemeSelectionCard(
                                theme: theme,
                                isSelected: viewModel.state.theme == theme,
                                onTap: {
                                    viewModel.state.theme = theme
                                    viewModel.saveTheme()
                                }
                            )
                        }
                    }
                    .padding(dialogPadding)
                }
                .frame(maxHeight: 450)
                
                // Footer / Confirm
                Button(action: {
                    viewModel.showThemeSelection = false
                }) {
                    Text("ENGAGE MODULE")
                        .font(.system(size: 14, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gameGreen)
                        )
                        .shadow(color: .gameGreen.opacity(0.4), radius: 10, y: 4)
                }
                .padding(dialogPadding)
            }
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(white: 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 40, x: 0, y: 20)
            )
            .frame(width: min(dialogWidth, UIScreen.main.bounds.width - 40))
        }
    }
}

struct ThemeSelectionCard: View {
    let theme: GameTheme
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticLight()
            onTap()
        }) {
            HStack(spacing: 16) {
                // Icon Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.4))
                        .frame(width: 56, height: 56)
                    
                    if let folder = theme.folderName {
                        // Show the first icon of the theme as preview
                        let previewName = theme.iconNames().first ?? ""
                        if let icon = theme.image(for: GameColor.red) { // Reusing first color index
                            icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 38, height: 38)
                        }
                    } else {
                        // Classic colored circles
                        HStack(spacing: -10) {
                            Circle().fill(Color.red).frame(width: 20, height: 20)
                            Circle().fill(Color.blue).frame(width: 20, height: 20)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.gameGreen : Color.white.opacity(0.1), lineWidth: 2)
                )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.rawValue)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                    
                    Text(theme == .classic ? "LEGACY CHROMA SENSORS" : "ENHANCED DATA MODULE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(isSelected ? .gameGreen : .white.opacity(0.2))
                        .tracking(1)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gameGreen)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.white.opacity(0.05) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.gameGreen.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        ThemeSelectionView(viewModel: GameViewModel())
    }
}

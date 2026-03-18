import SwiftUI

struct GameStartView: View {
    @ObservedObject var viewModel: GameViewModel
    
    var body: some View {
        ZStack {
            // Background hardware details
            VStack {
                HStack {
                    Spacer()
                    Text("SER. NO. WC-2026-XMT")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.black.opacity(0.15))
                        .padding(20)
                }
                Spacer()
                // Ventilation grilles pattern
                VStack(spacing: 4) {
                    ForEach(0..<6) { _ in
                        Capsule()
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 40, height: 3)
                    }
                }
                .padding(.bottom, 30)
            }

            VStack(spacing: 0) {
                Spacer(minLength: 10)
                
                // App Title - Stylized hardware logo (LARGER)
                VStack(spacing: 8) {
                    ZStack {
                        // Metallic backing plate
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.95), Color(white: 0.75)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 340, height: 220)
                            .shadow(color: .black.opacity(0.3), radius: 12, x: 0, y: 6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                        
                        VStack(spacing: 0) {
                            Text("WHATS")
                                .font(.system(size: 20, weight: .black, design: .monospaced))
                                .tracking(6)
                                .foregroundColor(Color(white: 0.3))
                                .padding(.top, 14)
                            
                            // BRAND THEME GEAR SELECTOR
                            LogoThemeGear(viewModel: viewModel)
                                .frame(height: 120)
                            
                            // Theme Preview Strip - Shows items from selected theme
                            ThemePreviewStrip(theme: viewModel.state.theme)
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)
                        }
                    }
                }
                
                Spacer(minLength: 12)
                
                // Main Console Panel (LARGER)
                VStack(spacing: 32) {
                    // Difficulty Section
                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gameGreen)
                                .frame(width: 4, height: 18)
                                .shadow(color: .gameGreen.opacity(0.5), radius: 3)
                            Text("DIFFICULTY SELECTOR")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 16) {
                            ForEach(GameDifficulty.allCases) { diff in
                                IndustrialSwitch(
                                    title: diff.rawValue,
                                    isSelected: viewModel.state.difficulty == diff,
                                    onTap: { viewModel.changeDifficulty(to: diff) }
                                )
                            }
                        }
                    }
                    
                    // Mission Section
                    VStack(spacing: 20) {
                        HStack(spacing: 8) {
                            Rectangle()
                                .fill(Color.gameGreen)
                                .frame(width: 4, height: 18)
                                .shadow(color: .gameGreen.opacity(0.5), radius: 3)
                            Text("MISSION TYPE BUS")
                                .font(.system(size: 15, weight: .black, design: .monospaced))
                                .tracking(1.5)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        
                        HStack(spacing: 18) {
                            IndustrialSwitch(
                                title: "SOLO",
                                isSelected: viewModel.state.mode == .advanced,
                                onTap: { viewModel.changeMode(to: .advanced) }
                            )
                            
                            IndustrialSwitch(
                                title: "DUAL",
                                isSelected: viewModel.state.mode == .beginner,
                                onTap: { viewModel.changeMode(to: .beginner) }
                            )
                        }
                    }
                }
                .padding(32)
                .background(
                    ZStack {
                        // Main Panel Body
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [Color(white: 0.15), Color(white: 0.1)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        
                        // Screw Details
                        VStack {
                            HStack {
                                ScrewHead().padding(10)
                                Spacer()
                                ScrewHead().padding(10)
                            }
                            Spacer()
                            HStack {
                                ScrewHead().padding(10)
                                Spacer()
                                ScrewHead().padding(10)
                            }
                        }
                    }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                                    LinearGradient(
                                        colors: [.white.opacity(0.1), .clear, .black.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                .padding(.horizontal, 16)

                // Dedicated Statistics Area - High-Tech Telemetry Bay
                ZStack {
                    if viewModel.state.mode == .advanced {
                        HStack(spacing: 25) {
                            DataModuleSmall(label: "LOG", value: "\(viewModel.state.level)/500", color: .gameGreen)
                            
                            DataModuleSmall(label: "MISSION", value: viewModel.state.difficulty.rawValue, color: .gameGreen)
                            
                            Spacer()
                            
                            // Technical progress graph indicator
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("COMPLETION")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.15))
                                
                                HStack(spacing: 2) {
                                    ForEach(0..<10) { i in
                                        Rectangle()
                                            .fill(Double(i + 1) <= (Double(viewModel.state.level) / 50.0) ? Color.gameGreen : Color.black.opacity(0.4))
                                            .frame(width: 3, height: 8)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(0.45))
                                
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            }
                        )
                        .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64) 
                .padding(.horizontal, 16)
                .padding(.top, 10)
                
                Spacer()
                
                // Bottom Action Row: How to Play + Engage Mission (LARGER)
                HStack(spacing: 16) {
                    // How to Play Button - More prominent design
                    Button(action: {
                        SoundManager.shared.playSelection()
                        viewModel.showHowToPlay = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(white: 0.2), Color(white: 0.12)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                            
                            HStack(spacing: 10) {
                                Image(systemName: "book.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.gameGreen)
                                
                                Text("RULES")
                                    .font(.system(size: 15, weight: .black, design: .monospaced))
                                    .tracking(1)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                        .frame(width: 110, height: 68)
                    }
                    .buttonStyle(PressedButtonStyle())
                    
                    // Engage Mission Button
                    Button(action: {
                        SoundManager.shared.playSuccess()
                        SoundManager.shared.hapticSuccess()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.startGame()
                        }
                    }) {
                        ZStack {
                            // Safety Housing - Deep Metallic
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(white: 0.12), Color(white: 0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1.5)
                                )
                            
                            // Internal Component Path
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(0.6))
                                .padding(4)
                            
                            // The Primary Actuator
                            ZStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(white: 0.25), Color(white: 0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .shadow(color: .gameGreen.opacity(0.15), radius: 10, y: 5)
                                
                                HStack(spacing: 14) {
                                    Image(systemName: "power")
                                        .font(.system(size: 18, weight: .black))
                                        .foregroundColor(.gameGreen.opacity(0.6))
                                    
                                    Text("ENGAGE MISSION")
                                        .font(.system(size: 18, weight: .black, design: .monospaced))
                                        .tracking(1.5)
                                        .foregroundColor(.white)
                                    
                                    Image(systemName: "chevron.right.2")
                                        .font(.system(size: 16, weight: .black))
                                        .foregroundColor(.gameGreen.opacity(0.6))
                                }
                            }
                            .padding(6)
                        }
                        .frame(height: 68)
                    }
                    .buttonStyle(PressedButtonStyle())
                }
                .padding(.horizontal, 16)
                
                Spacer(minLength: 8)
            }
        }
    }
}

// MARK: - Theme Preview Strip

struct ThemePreviewStrip: View {
    let theme: GameTheme
    
    var body: some View {
        HStack(spacing: 12) {
            if theme == .classic {
                // For classic theme, show colored circles
                ForEach(0..<4) { i in
                    Circle()
                        .fill(colorForIndex(i))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                }
            } else {
                // For image themes, show sample images
                let icons = theme.iconNames()
                let displayIcons = Array(icons.prefix(4))
                
                ForEach(displayIcons.indices, id: \.self) { index in
                    if let image = loadImage(named: displayIcons[index], folder: theme.folderName) {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    } else {
                        // Fallback placeholder
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 36, height: 36)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.08))
        )
    }
    
    private func colorForIndex(_ index: Int) -> Color {
        let colors: [Color] = [.gameRed, .gameGreen, .gameBlue, .gameYellow, .gamePurple, .gameCyan, .gameOrange]
        return colors[index % colors.count]
    }
    
    private func loadImage(named: String, folder: String?) -> Image? {
        if let uiImage = UIImage(named: named) {
            return Image(uiImage: uiImage)
        }
        if let folder = folder {
            if let uiImage = UIImage(named: "icon_materials/\(folder)/\(named)") {
                return Image(uiImage: uiImage)
            }
        }
        return nil
    }
}

struct DigitalDisplayItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 7, weight: .bold, design: .monospaced))
                .foregroundColor(Color.gameGreen.opacity(0.4))
            Text(value)
                .font(.system(size: 11, weight: .black, design: .monospaced))
                .foregroundColor(Color.gameGreen)
                .shadow(color: Color.gameGreen.opacity(0.5), radius: 2)
        }
    }
}

struct DataModuleSmall: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Industrial vertical indicator
            Rectangle()
                .fill(color.opacity(0.3))
                .frame(width: 2, height: 22)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.25))
                    .tracking(1)
                
                Text(value.uppercased())
                    .font(.system(size: 15, weight: .black, design: .monospaced))
                    .foregroundColor(color)
                    .shadow(color: color.opacity(0.3), radius: 2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }
}

struct ScrewHead: View {
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [Color(white: 0.4), Color(white: 0.2)],
                    center: .center,
                    startRadius: 0,
                    endRadius: 5
                )
            )
            .frame(width: 8, height: 8)
            .overlay(
                Rectangle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: 6, height: 1)
                    .rotationEffect(.degrees(45))
            )
    }
}

// MARK: - Brand Logo Theme Selector (Interactive Gear)

struct LogoThemeGear: View {
    @ObservedObject var viewModel: GameViewModel
    @State private var dragOffset: CGFloat = 0
    @GestureState private var gestureOffset: CGFloat = 0
    @State private var lastReportedIndex: Int = 0
    @State private var isTouching: Bool = false
    @State private var pulseOpacity: Double = 0.2
    @State private var scanOffset: CGFloat = -40
    @State private var chevronOffset: CGFloat = 0
    
    // Calculate the sequence of themes for the wheel
    private let themes = GameTheme.allCases
    private let itemHeight: CGFloat = 70

    private func themeDescriptor(for theme: GameTheme) -> String {
        switch theme {
        case .classic: return "ORIGINAL_CHROMA"
        case .pixelFruit: return "VIBRANT_PIXEL"
        case .cuteCat: return "FELINE_UNIT"
        case .cuteDog: return "CANINE_UNIT"
        case .fastFood: return "FUEL_RESOURCE"
        case .fruit: return "ORGANIC_PACK"
        case .vegetables: return "VITAL_GREENS"
        }
    }
    
    var body: some View {
        let currentThemeIndex = themes.firstIndex(of: viewModel.state.theme) ?? 0
        let totalLiveOffset = dragOffset + gestureOffset
        
        ZStack {
            // 1. TACTICAL HIGHLIGHT GLOW (Activates on Touch)
            if isTouching {
                RoundedRectangle(cornerRadius: 15)
                    .fill(Color.gameGreen.opacity(0.08))
                    .frame(width: 280, height: 100)
                    .blur(radius: 20)
                    .transition(.opacity)
            }
            
            // 2. THEME LOGO SLIDER
            ZStack {
                // Background Mechanical Grids
                VStack(spacing: 6) {
                    ForEach(0..<20) { i in
                        Rectangle()
                            .fill(Color.black.opacity(isTouching ? 0.12 : 0.06))
                            .frame(width: 250, height: 1)
                            .offset(y: (CGFloat(i * 12) + totalLiveOffset).remainder(dividingBy: 12))
                    }
                }
                .frame(height: 140)
                .opacity(0.6)
                
                // The Moving Wheel Items
                ForEach(0..<themes.count, id: \.self) { index in
                    let theme = themes[index]
                    let distance = CGFloat(index - currentThemeIndex)
                    let itemOffset = (distance * itemHeight) + totalLiveOffset
                    
                    if abs(itemOffset) < 180 {
                        VStack(spacing: 1) {
                            Text(theme.logoName)
                                .font(.system(size: 52, weight: .black, design: .monospaced))
                                .foregroundColor(Color(white: 0.1))
                                .shadow(color: .white.opacity(max(0, 1.2 - abs(itemOffset)/80.0)), radius: 0.5, x: 1, y: 1)
                                .scaleEffect(1.0 - abs(itemOffset) / 350.0)
                                .opacity(1.0 - abs(itemOffset) / 130.0)
                                .brightness(abs(itemOffset) < 10 ? (isTouching ? 0.08 : 0) : -0.1)

                            // SUB-INFOGRAPHIC LABEL
                            if abs(itemOffset) < 40 {
                                Text(themeDescriptor(for: theme))
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black.opacity(0.4))
                                    .tracking(3)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.gameGreen.opacity(0.1))
                                    .cornerRadius(2)
                                    .opacity(1.0 - abs(itemOffset) / 30.0)
                            }
                        }
                        .offset(y: itemOffset)
                    }
                }

                // 2.5 INFRARED SCANNING BEAM
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.clear, .gameGreen.opacity(0.15), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 280, height: 15)
                    .offset(y: scanOffset)
                    .blendMode(.screen)
                
                // 3. SECTOR ALIGNMENT CROSSHAIRS (Fixed indicators)
                HStack {
                    Rectangle().fill(Color.gameRed).frame(width: 20, height: 2)
                    Spacer()
                    Rectangle().fill(Color.gameRed).frame(width: 20, height: 2)
                }
                .frame(width: 260)
                .opacity(isTouching ? 0.8 : 0.3)
                .shadow(color: .gameRed.opacity(0.5), radius: 4)
            }
            .frame(height: 75)
            .clipped()
            
            // 4. INTERACTION TELEMETRY
            VStack {
                Text("ENGINEER CONFIG_MODULE")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundColor(isTouching ? .gameGreen.opacity(0.6) : .black.opacity(0.2))
                    .tracking(2.5)
                    .offset(y: -42)

                // Pulsing Tactical Chevrons
                VStack(spacing: 65) {
                    Image(systemName: "chevron.up.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(pulseOpacity))
                        .offset(y: -chevronOffset)
                    
                    Image(systemName: "chevron.down.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(pulseOpacity))
                        .offset(y: chevronOffset)
                }
            }
            .frame(height: 100)
            
            // 5. HARDWARE LENS (Frosted look over the gear)
            RoundedRectangle(cornerRadius: 15)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.1), .clear, .black.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 260, height: 85)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onAppear {
            lastReportedIndex = currentThemeIndex
            
            // Indicator Pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.6
            }
            
            // Scanning Beam Loop
            withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                scanOffset = 40
            }
            
            // Chevron Guidance Animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                chevronOffset = 5
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($gestureOffset) { value, state, _ in
                    state = value.translation.height
                    
                    // Live Haptic Tick Logic (Mechanical Feedback)
                    let currentIndex = themes.firstIndex(of: viewModel.state.theme) ?? 0
                    let shift = -Int((value.translation.height / itemHeight).rounded())
                    let virtualIndex = currentIndex + shift
                    
                    if virtualIndex != lastReportedIndex && virtualIndex >= 0 && virtualIndex < themes.count {
                        DispatchQueue.main.async {
                            if virtualIndex != lastReportedIndex {
                                lastReportedIndex = virtualIndex
                                SoundManager.shared.hapticLight()
                                // Small mechanical click sound could be added here if available
                            }
                        }
                    }
                }
                .onChanged { _ in
                    if !isTouching {
                        withAnimation(.easeIn(duration: 0.15)) { isTouching = true }
                        SoundManager.shared.playSelection() // Activation click
                    }
                }
                .onEnded { value in
                    withAnimation(.easeOut(duration: 0.25)) { isTouching = false }
                    
                    let movement = value.translation.height
                    let indexChange = -Int((movement / itemHeight).rounded())
                    
                    withAnimation(.interpolatingSpring(stiffness: 300, damping: 20)) {
                        let newIndex = max(0, min(themes.count - 1, currentThemeIndex + indexChange))
                        if newIndex != currentThemeIndex {
                            viewModel.state.theme = themes[newIndex]
                            SoundManager.shared.playDrop() // Engagement "Thud"
                            SoundManager.shared.hapticMedium()
                            viewModel.saveTheme()
                        }
                    }
                }
        )
    }
}

struct IndustrialSwitch: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticLight()
            onTap()
        }) {
            ZStack {
                // Button Base (Recessed look)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.6))
                    .frame(height: 62)
                
                // Button Face
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(white: 0.25), Color(white: 0.15)] :
                                [Color(white: 0.2), Color(white: 0.1)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 58)
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.gameGreen.opacity(0.5) : Color.white.opacity(0.05), lineWidth: 1.5)
                            .padding(2)
                    )
                
                VStack(spacing: 6) {
                    // Indicator LED
                    Circle()
                        .fill(isSelected ? Color.gameGreen : Color(white: 0.2))
                        .frame(width: 5, height: 5)
                        .shadow(color: isSelected ? Color.gameGreen.opacity(0.8) : .clear, radius: 2)
                    
                    Text(title)
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .tracking(1)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                }
            }
            .offset(y: isPressed ? 1 : 0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct SkeuomorphicButton: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            SoundManager.shared.playSelection()
            SoundManager.shared.hapticLight()
            onTap()
        }) {
            ZStack {
                // Bottom shadow layer (always visible, creates depth)
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.6))
                    .offset(y: 2)

                // Main button face
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: isSelected ?
                                [Color(red: 0.4, green: 0.6, blue: 0.4), Color(red: 0.3, green: 0.5, blue: 0.3)] :
                                [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                // Highlight on top half
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.15 : 0.1),
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                    .padding(1)

                // Text
                Text(title)
                    .font(.system(size: isSelected ? 16 : 14, weight: .bold, design: .monospaced))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    .padding(.horizontal, 10)
            }
            .frame(height: 50)
            .offset(y: isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    ZStack {
        Color.launchBackground.ignoresSafeArea()
        GameStartView(viewModel: GameViewModel())
            .padding(20)
    }
}

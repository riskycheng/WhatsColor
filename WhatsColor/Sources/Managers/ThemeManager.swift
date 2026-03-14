import Foundation
import SwiftUI
import Combine

/// Manages themes and optimizes asset loading with caching
@MainActor
class ThemeManager: ObservableObject {
    @Published var currentTheme: GameTheme = .pixelFruit

    private let themeKey = "WhatsColor_Theme"
    private let userDefaults = UserDefaults.standard

    // Asset cache to avoid repeated bundle lookups
    private var imageCache: [String: UIImage] = [:]
    private var assetPathCache: [String: String] = [:]

    // Bundle diagnostics - only run once in debug mode
    private var bundleAnalyzed = false

    init() {
        loadTheme()
        // Perform one-time bundle analysis in debug mode
        #if DEBUG
        performBundleAnalysis()
        #endif
        preCacheAssets()
    }

    // MARK: - Theme Management

    func loadTheme() {
        if let savedTheme = userDefaults.string(forKey: themeKey),
           let theme = GameTheme(rawValue: savedTheme) {
            currentTheme = theme
        } else {
            currentTheme = .pixelFruit
        }
    }

    func changeTheme(to theme: GameTheme) {
        currentTheme = theme
        saveTheme()
    }

    private func saveTheme() {
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
        // Trigger UI update
        objectWillChange.send()
    }

    // MARK: - Asset Loading Optimization

    func image(for color: GameColor, theme: GameTheme? = nil) -> Image? {
        let targetTheme = theme ?? currentTheme
        let names = targetTheme.iconNames()
        guard color.rawValue < names.count else {
            return nil
        }

        let iconName = names[color.rawValue]
        let cacheKey = "\(targetTheme.rawValue)_\(iconName)"

        // Check cache first
        if let cachedImage = imageCache[cacheKey] {
            return themeImage(cachedImage, for: targetTheme)
        }

        // Load image with optimized path lookup
        if let uiImage = loadImageOptimized(name: iconName, theme: targetTheme) {
            imageCache[cacheKey] = uiImage
            return themeImage(uiImage, for: targetTheme)
        }

        return nil
    }

    private func loadImageOptimized(name: String, theme: GameTheme) -> UIImage? {
        let cacheKey = "\(theme.rawValue)_\(name)"

        // Check if we already found the path
        if let cachedPath = assetPathCache[cacheKey] {
            if let img = UIImage(contentsOfFile: cachedPath) {
                return img
            }
        }

        // 1. Try simple named lookup (Asset Catalog or root)
        if let uiImage = UIImage(named: name) {
            return uiImage
        }

        // 2. Try with theme folder prefix (if added as folder reference)
        if let folder = theme.folderName {
            if let uiImage = UIImage(named: "icon_materials/\(folder)/\(name)") {
                return uiImage
            }

            // 3. Absolute bundle path lookup with variations
            let extensions = ["png", "jpg", "jpeg"]
            for ext in extensions {
                // Try the standard path
                if let path = Bundle.main.path(forResource: name, ofType: ext, inDirectory: "icon_materials/\(folder)") {
                    assetPathCache[cacheKey] = path
                    return UIImage(contentsOfFile: path)
                }

                // Try flattened if it ended up in the root
                if let path = Bundle.main.path(forResource: name, ofType: ext) {
                    assetPathCache[cacheKey] = path
                    return UIImage(contentsOfFile: path)
                }
            }
        } else {
            // Theme with no folder (e.g., standard/classic)
            let extensions = ["png", "jpg", "jpeg"]
            for ext in extensions {
                if let path = Bundle.main.path(forResource: name, ofType: ext) {
                    assetPathCache[cacheKey] = path
                    return UIImage(contentsOfFile: path)
                }
            }
        }

        return nil
    }

    private func themeImage(_ uiImage: UIImage, for theme: GameTheme) -> Image {
        let img = Image(uiImage: uiImage)
        return theme == .pixelFruit ? img.interpolation(.none) : img
    }

    // MARK: - Asset Pre-caching

    private func preCacheAssets() {
        // Pre-cache assets for the current theme
        cacheThemeAssets(currentTheme)

        // Pre-cache classic theme (no assets to load)
        // Other themes can be cached on-demand when switched
    }

    private func cacheThemeAssets(_ theme: GameTheme) {
        let iconNames = theme.iconNames()
        for (index, iconName) in iconNames.enumerated() {
            if index < GameColor.allCases.count {
                let cacheKey = "\(theme.rawValue)_\(iconName)"
                if imageCache[cacheKey] == nil {
                    if let uiImage = loadImageOptimized(name: iconName, theme: theme) {
                        imageCache[cacheKey] = uiImage
                    }
                }
            }
        }
    }

    func preCacheTheme(_ theme: GameTheme) {
        // Pre-cache a theme when user is about to switch to it
        Task {
            cacheThemeAssets(theme)
        }
    }

    // MARK: - Bundle Analysis (Debug Only)

    #if DEBUG
    private func performBundleAnalysis() {
        guard !bundleAnalyzed else { return }
        bundleAnalyzed = true

        let fm = FileManager.default
        let bundlePath = Bundle.main.bundlePath

        if let items = try? fm.contentsOfDirectory(atPath: bundlePath) {
            let hasIconMaterials = items.contains("icon_materials")
            let hasIcons = items.contains { $0.contains("icon_") || $0.contains("boluo") }

            if hasIconMaterials {
                let themePath = bundlePath + "/icon_materials"
                if let themes = try? fm.contentsOfDirectory(atPath: themePath) {
                    print("🎨 ThemeManager: Themes found: \(themes.joined(separator: ", "))")
                }
            } else if hasIcons {
                print("🎨 ThemeManager: Icons appear to be FLATTENED in the bundle root")
            } else {
                print("⚠️ ThemeManager: No icon assets detected in bundle")
            }
        }
    }
    #endif

    // MARK: - Memory Management

    func clearCache() {
        imageCache.removeAll()
        assetPathCache.removeAll()
    }

    func trimCache() {
        // Keep only current theme in cache
        let currentThemePrefix = currentTheme.rawValue
        imageCache = imageCache.filter { key, _ in
            key.hasPrefix(currentThemePrefix)
        }
        assetPathCache = assetPathCache.filter { key, _ in
            key.hasPrefix(currentThemePrefix)
        }
    }

    // MARK: - Computed Properties

    var availableThemes: [GameTheme] {
        GameTheme.allCases
    }

    var currentThemeName: String {
        currentTheme.rawValue
    }

    var currentThemeLogoName: String {
        currentTheme.logoName
    }
}
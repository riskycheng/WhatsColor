import XCTest
@testable import WhatsColor

@MainActor
class ThemeManagerTests: XCTestCase {
    var themeManager: ThemeManager!

    override func setUp() {
        super.setUp()
        themeManager = ThemeManager()
    }

    override func tearDown() {
        themeManager = nil
        super.tearDown()
    }

    func testInitialTheme() {
        // Should load saved theme or default to pixelFruit
        XCTAssertNotNil(themeManager.currentTheme)
        XCTAssertTrue(GameTheme.allCases.contains(themeManager.currentTheme))
    }

    func testThemeChange() {
        let originalTheme = themeManager.currentTheme
        let newTheme: GameTheme = originalTheme == .pixelFruit ? .classic : .pixelFruit

        themeManager.changeTheme(to: newTheme)

        XCTAssertEqual(themeManager.currentTheme, newTheme)
        XCTAssertNotEqual(themeManager.currentTheme, originalTheme)
    }

    func testAvailableThemes() {
        let availableThemes = themeManager.availableThemes
        XCTAssertEqual(availableThemes.count, GameTheme.allCases.count)
        XCTAssertTrue(availableThemes.contains(.classic))
        XCTAssertTrue(availableThemes.contains(.pixelFruit))
        XCTAssertTrue(availableThemes.contains(.cuteCat))
    }

    func testThemeProperties() {
        themeManager.changeTheme(to: .pixelFruit)

        XCTAssertEqual(themeManager.currentThemeName, "PIXEL FRUIT")
        XCTAssertEqual(themeManager.currentThemeLogoName, "PIXEL")

        themeManager.changeTheme(to: .classic)

        XCTAssertEqual(themeManager.currentThemeName, "CLASSIC")
        XCTAssertEqual(themeManager.currentThemeLogoName, "COLOR")
    }

    func testImageLoadingForClassicTheme() {
        themeManager.changeTheme(to: .classic)

        // Classic theme should return nil for images (uses colors only)
        let image = themeManager.image(for: .red)
        XCTAssertNil(image)
    }

    func testImageLoadingForThemedThemes() {
        themeManager.changeTheme(to: .pixelFruit)

        // Even if the actual image files don't exist in tests, the method should
        // attempt to load them without crashing
        let image = themeManager.image(for: .red)
        // We can't test for specific image content without actual assets
        // but we can verify the method doesn't crash
        XCTAssertTrue(true) // Method completed without crashing
    }

    func testCacheOperations() {
        // Test cache clearing
        themeManager.clearCache()
        XCTAssertTrue(true) // Should complete without crashing

        // Test cache trimming
        themeManager.trimCache()
        XCTAssertTrue(true) // Should complete without crashing
    }

    func testPreCaching() {
        // Test pre-caching doesn't crash
        themeManager.preCacheTheme(.cuteCat)
        XCTAssertTrue(true) // Should complete without crashing
    }

    func testThemePersistence() {
        let testTheme = GameTheme.cuteCat
        themeManager.changeTheme(to: testTheme)

        // Create a new manager to test persistence
        let newManager = ThemeManager()
        XCTAssertEqual(newManager.currentTheme, testTheme)
    }
}
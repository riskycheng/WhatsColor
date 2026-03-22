import XCTest
@testable import WhatsColor

@MainActor
class ThemeUnlockManagerTests: XCTestCase {
    var themeUnlockManager: ThemeUnlockManager!
    
    override func setUp() {
        super.setUp()
        themeUnlockManager = ThemeUnlockManager.shared
        themeUnlockManager.resetThemeUnlocks()
    }
    
    override func tearDown() {
        themeUnlockManager.resetThemeUnlocks()
        themeUnlockManager = nil
        super.tearDown()
    }
    
    func testInitialUnlocks() {
        // Classic and PixelFruit should always be unlocked
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.classic))
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.pixelFruit))
        
        // Others should be locked initially
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.cuteCat))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.cuteDog))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.fastFood))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.fruit))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.vegetables))
    }
    
    func testUnlockRequirements() {
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .classic), 1)
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .pixelFruit), 1)
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .cuteCat), 5)
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .cuteDog), 10)
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .fastFood), 20)
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .fruit), 35)
        XCTAssertEqual(themeUnlockManager.getUnlockRequirement(for: .vegetables), 50)
    }
    
    func testThemeUnlockAtLevel5() {
        // Level 5 should unlock cuteCat
        let unlocked = themeUnlockManager.checkAndUnlockThemes(currentLevel: 5)
        
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.cuteCat))
        XCTAssertTrue(unlocked.contains(.cuteCat))
        
        // Others should still be locked
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.cuteDog))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.fastFood))
    }
    
    func testThemeUnlockAtLevel10() {
        // Level 10 should unlock cuteCat and cuteDog
        let unlocked = themeUnlockManager.checkAndUnlockThemes(currentLevel: 10)
        
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.cuteCat))
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.cuteDog))
        XCTAssertTrue(unlocked.contains(.cuteCat))
        XCTAssertTrue(unlocked.contains(.cuteDog))
    }
    
    func testThemeUnlockAtMaxLevel() {
        // Level 50 should unlock all themes
        let unlocked = themeUnlockManager.checkAndUnlockThemes(currentLevel: 50)
        
        XCTAssertEqual(unlocked.count, 5) // cuteCat, cuteDog, fastFood, fruit, vegetables
        
        for theme in GameTheme.allCases {
            XCTAssertTrue(themeUnlockManager.isThemeUnlocked(theme))
        }
    }
    
    func testNoDuplicateUnlocks() {
        // Unlock themes at level 10
        _ = themeUnlockManager.checkAndUnlockThemes(currentLevel: 10)
        
        // Check again at level 15 - should not return already unlocked themes
        let unlocked = themeUnlockManager.checkAndUnlockThemes(currentLevel: 15)
        
        XCTAssertFalse(unlocked.contains(.cuteCat))
        XCTAssertFalse(unlocked.contains(.cuteDog))
    }
    
    func testGetProgressForTheme() {
        let progress = themeUnlockManager.getProgressForTheme(.cuteCat, currentLevel: 3)
        
        XCTAssertEqual(progress.current, 3)
        XCTAssertEqual(progress.required, 5)
        XCTAssertFalse(progress.isUnlocked)
    }
    
    func testGetProgressForUnlockedTheme() {
        _ = themeUnlockManager.checkAndUnlockThemes(currentLevel: 10)
        
        let progress = themeUnlockManager.getProgressForTheme(.cuteCat, currentLevel: 10)
        
        XCTAssertEqual(progress.current, 10)
        XCTAssertEqual(progress.required, 5)
        XCTAssertTrue(progress.isUnlocked)
    }
    
    func testGetNextUnlockableTheme() {
        // At level 1, next unlock should be cuteCat at level 5
        let next = themeUnlockManager.getNextUnlockableTheme(currentLevel: 1)
        
        XCTAssertEqual(next?.theme, .cuteCat)
        XCTAssertEqual(next?.requirement, 5)
    }
    
    func testGetNextUnlockableThemeMidLevel() {
        // At level 7, next unlock should be cuteDog at level 10
        _ = themeUnlockManager.checkAndUnlockThemes(currentLevel: 7)
        
        let next = themeUnlockManager.getNextUnlockableTheme(currentLevel: 7)
        
        XCTAssertEqual(next?.theme, .cuteDog)
        XCTAssertEqual(next?.requirement, 10)
    }
    
    func testGetNextUnlockableThemeAllUnlocked() {
        // At level 50, all themes unlocked - should return nil
        _ = themeUnlockManager.checkAndUnlockThemes(currentLevel: 50)
        
        let next = themeUnlockManager.getNextUnlockableTheme(currentLevel: 50)
        
        XCTAssertNil(next)
    }
    
    func testUnlockDescriptions() {
        XCTAssertTrue(themeUnlockManager.getUnlockDescription(for: .classic).contains("Always available"))
        XCTAssertTrue(themeUnlockManager.getUnlockDescription(for: .cuteCat).contains("Level 5"))
        XCTAssertTrue(themeUnlockManager.getUnlockDescription(for: .vegetables).contains("Level 50"))
    }
    
    func testManualUnlock() {
        // Manually unlock a theme
        themeUnlockManager.unlockTheme(.fruit)
        
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.fruit))
    }
    
    func testResetThemeUnlocks() {
        // Unlock some themes
        _ = themeUnlockManager.checkAndUnlockThemes(currentLevel: 20)
        
        // Reset
        themeUnlockManager.resetThemeUnlocks()
        
        // Only classic and pixelFruit should be unlocked
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.classic))
        XCTAssertTrue(themeUnlockManager.isThemeUnlocked(.pixelFruit))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.cuteCat))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.cuteDog))
        XCTAssertFalse(themeUnlockManager.isThemeUnlocked(.fastFood))
    }
}

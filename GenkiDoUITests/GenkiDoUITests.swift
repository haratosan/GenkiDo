import XCTest

final class GenkiDoUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify Fitness tab is visible
        XCTAssertTrue(app.tabBars.buttons["Fitness"].exists)

        // Verify Essen tab is visible
        XCTAssertTrue(app.tabBars.buttons["Essen"].exists)

        // Navigate to Essen tab
        app.tabBars.buttons["Essen"].tap()

        // Navigate back to Fitness tab
        app.tabBars.buttons["Fitness"].tap()
    }

    @MainActor
    func testFitnessViewDisplaysExercises() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify exercise names are displayed
        XCTAssertTrue(app.staticTexts["Liegestütze"].exists)
        XCTAssertTrue(app.staticTexts["Schulterheber"].exists)
        XCTAssertTrue(app.staticTexts["Kniebeugen"].exists)
        XCTAssertTrue(app.staticTexts["Rumpfbeugen"].exists)
    }
}

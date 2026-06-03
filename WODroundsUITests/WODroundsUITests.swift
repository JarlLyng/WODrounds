//
//  WODroundsUITests.swift
//  WODroundsUITests
//
//  Created by Jarl Lyng on 15/02/2026.
//

import XCTest

final class WODroundsUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    /// Smoke test for the count-in Cancel feature (#38): Start → "Get ready"
    /// count-in shows a Cancel button → tapping it returns to setup.
    @MainActor
    func testCountInCancelReturnsToSetup() throws {
        let app = XCUIApplication()
        app.launch()

        // Dismiss the HealthKit authorization sheet if it appears on first Start.
        addUIInterruptionMonitor(withDescription: "Health Access") { element in
            for label in ["Allow", "Don't Allow", "Turn On All", "OK", "Dismiss"] {
                let button = element.buttons[label]
                if button.exists { button.tap(); return true }
            }
            return false
        }

        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Start button should exist on the idle screen")
        start.tap()
        app.tap() // Nudge so the interruption monitor handles the Health sheet.

        // The count-in overlay must expose a Cancel button (the #38 feature).
        let cancel = app.buttons["Cancel countdown"]
        XCTAssertTrue(cancel.waitForExistence(timeout: 8), "Count-in should show a Cancel button (#38)")
        cancel.tap()

        // Cancelling the count-in returns to setup.
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Cancelling the count-in should return to the setup screen")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

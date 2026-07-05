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

        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Start button should exist on the idle screen")
        start.tap()

        // The count-in overlay must expose a Cancel button (the #38 feature).
        let cancel = app.buttons["Cancel countdown"]
        XCTAssertTrue(waitDismissingHealthSheet(for: cancel, timeout: 45, in: app),
                      "Count-in should show a Cancel button (#38)")
        cancel.tap()

        // Cancelling the count-in returns to setup.
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Cancelling the count-in should return to the setup screen")
    }

    /// End-to-end For Time flow (#15): switch to For Time → Start → count-in →
    /// running shows Stop → Stop → Done screen shows "Finished in" → Reset returns
    /// to setup.
    @MainActor
    func testForTimeStartStopShowsFinishedTime() throws {
        let app = XCUIApplication()
        app.launch()

        // Switch to For Time; its setup shows the Time cap stepper.
        let forTime = app.buttons["For Time"]
        XCTAssertTrue(forTime.waitForExistence(timeout: 5), "Mode switch should have a For Time segment")
        forTime.tap()
        XCTAssertTrue(app.staticTexts["Time cap"].waitForExistence(timeout: 3), "For Time setup should show the Time cap stepper")

        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 5))
        start.tap()

        // After the 10s count-in, a running For Time shows Stop (not Pause).
        let stop = app.buttons["Stop"]
        XCTAssertTrue(waitDismissingHealthSheet(for: stop, timeout: 45, in: app),
                      "Running For Time should show a Stop button")
        XCTAssertFalse(app.buttons["Pause"].exists, "For Time must not offer Pause while running")

        // Let a couple of seconds elapse, then stop and expect the finished time.
        sleep(2)
        stop.tap()
        // SharedDoneView combines its children into one accessibility element, so
        // "Finished in …" is part of a combined label, not a standalone staticText.
        let finished = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS 'Finished in'")).firstMatch
        XCTAssertTrue(finished.waitForExistence(timeout: 5), "Done screen should show 'Finished in MM:SS' for For Time")

        // Reset returns to setup.
        let reset = app.buttons["Reset"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5))
        reset.tap()
        XCTAssertTrue(start.waitForExistence(timeout: 5), "Reset should return to the setup screen")
    }

    /// Waits for `element`, dismissing the HealthKit authorization sheet whenever
    /// it shows up along the way. The sheet is hosted by a remote process and its
    /// appearance time varies wildly (slow on a freshly-booted simulator), and
    /// interruption monitors only fire on interactions — waitForExistence never
    /// triggers them — so a fixed pre-wait either wastes the count-in window or
    /// misses a late sheet. Polling for the target and swatting the sheet by its
    /// locale-independent identifier (labels are localized, e.g. "Tillad ikke")
    /// handles both orders. The budget is generous because on a fresh simulator
    /// the HealthKit authorization *completion* can arrive 20-30s after the sheet
    /// is dismissed, and the count-in only starts once it fires; the loop returns
    /// as soon as the target exists, so the extra budget costs nothing when fast.
    @MainActor
    @discardableResult
    private func waitDismissingHealthSheet(for element: XCUIElement, timeout: TimeInterval, in app: XCUIApplication) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let deny = app.buttons["UIA.Health.AuthSheet.CancelButton"]
        // On a completely fresh device, denying pops a confirmation alert on top
        // ("you can enable categories later in Health"); authorization does not
        // complete (and the count-in never starts) until its OK is tapped.
        let confirmOK = app.alerts.buttons["OK"]
        // Tap deny at most once: the first tap dismisses the sheet, and a second
        // tap attempt races its dismissal (exists → true, then tap() re-resolves
        // against a gone element and fails the test).
        var deniedOnce = false
        while Date() < deadline {
            if confirmOK.exists {
                confirmOK.tap()
            } else if !deniedOnce, deny.exists {
                deniedOnce = true
                deny.tap()
            }
            if element.exists { return true }
            usleep(300_000) // 0.3s between polls
        }
        return element.exists
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}

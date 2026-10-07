// Copyright (c) 2026 Michael Ju (github.com/mhju0)
import XCTest
import UIKit

final class AppearanceFlowTests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testAppearanceSelectionPersistsAcrossRelaunchAndReturnsToSystem() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_SETTINGS": "1",
        ]
        app.launch()
        choose("dark", in: app)
        XCTAssertTrue(waitForBackground(in: app, light: false))
        attach(app, name: "settings-dark")
        app.terminate()
        app.launch()
        revealAppearance(in: app)
        XCTAssertTrue(waitForBackground(in: app, light: false))
        choose("light", in: app)
        XCTAssertTrue(waitForBackground(in: app, light: true))
        attach(app, name: "settings-light")
        choose("system", in: app)
        app.terminate()
        app.launch()
        revealAppearance(in: app)
        XCTAssertTrue(app.buttons["settings-appearance"].exists)
    }

    func testAllAppearanceChoicesRemainReachableAtAccessibilityXXXL() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(ko)", "-glassTable.language", "korean",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment = ["GT_TEST_STORE_ID": UUID().uuidString,
                                 "GT_DEMO_SEED": "1", "GT_DEMO_SETTINGS": "1"]
        app.launch()
        for mode in ["light", "dark", "system"] { choose(mode, in: app) }
        attach(app, name: "settings-accessibility")
    }

    private func revealAppearance(in app: XCUIApplication) {
        let picker = app.buttons["settings-appearance"]
        XCTAssertTrue(picker.waitForExistence(timeout: 15))
        for _ in 0..<12 where !picker.isHittable { app.swipeUp() }
        XCTAssertTrue(picker.isHittable)
        XCTAssertGreaterThanOrEqual(picker.frame.height, 44)
    }

    private func choose(_ mode: String, in app: XCUIApplication) {
        revealAppearance(in: app)
        app.buttons["settings-appearance"].tap()
        let option = app.buttons["appearance-\(mode)"]
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        option.tap()
    }

    private func attach(_ app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func waitForBackground(in app: XCUIApplication, light: Bool) -> Bool {
        let predicate = NSPredicate { _, _ in
            guard let image = app.screenshot().image.cgImage else { return false }
            // The side gutter is outside the settings panels in both appearances.
            let sample = CGRect(x: Int(Double(image.width) * 0.025),
                                y: Int(Double(image.height) * 0.4), width: 1, height: 1)
            guard let pixel = image.cropping(to: sample) else { return false }
            var rgba = [UInt8](repeating: 0, count: 4)
            let rendered = rgba.withUnsafeMutableBytes { bytes -> Bool in
                guard let context = CGContext(data: bytes.baseAddress, width: 1, height: 1,
                                              bitsPerComponent: 8, bytesPerRow: 4,
                                              space: CGColorSpaceCreateDeviceRGB(),
                                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                else { return false }
                context.draw(pixel, in: CGRect(x: 0, y: 0, width: 1, height: 1))
                return true
            }
            let brightness = Double(rgba[0]) + Double(rgba[1]) + Double(rgba[2])
            return rendered && (light ? brightness > 575 : brightness < 230)
        }
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: nil)],
                             timeout: 8) == .completed
    }
}

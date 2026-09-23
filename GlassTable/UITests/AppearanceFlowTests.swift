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
        let dark = app.buttons["appearance-dark"]
        XCTAssertTrue(dark.waitForExistence(timeout: 15))
        dark.tap()
        XCTAssertTrue(dark.isSelected)
        XCTAssertTrue(waitForBackground(in: app, light: false))
        attach(app, name: "settings-dark")

        app.terminate()
        app.launch()
        XCTAssertTrue(dark.waitForExistence(timeout: 15))
        XCTAssertTrue(dark.isSelected, "Appearance must survive an app restart")

        let light = app.buttons["appearance-light"]
        light.tap()
        XCTAssertTrue(light.isSelected)
        XCTAssertTrue(waitForBackground(in: app, light: true),
                      "Selecting light must update Settings, not only its checkmark")
        attach(app, name: "settings-light")

        let system = app.buttons["appearance-system"]
        system.tap()
        XCTAssertTrue(system.isSelected)
        app.terminate()
        app.launch()
        XCTAssertTrue(system.waitForExistence(timeout: 15))
        XCTAssertTrue(system.isSelected)
    }

    func testAllAppearanceChoicesRemainReachableAtAccessibilityXXXL() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ko)", "-AppleLocale", "ko_KR", "-glassTable.language", "korean"]
        app.launchEnvironment = [
            "GT_TEST_STORE_ID": UUID().uuidString,
            "GT_DEMO_SEED": "1",
            "GT_DEMO_SETTINGS": "1",
        ]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        for mode in ["light", "dark", "system"] {
            let choice = app.buttons["appearance-\(mode)"]
            XCTAssertTrue(choice.waitForExistence(timeout: 15))
            for _ in 0..<10 where !choice.isHittable {
                if choice.frame.midY < app.frame.midY { app.swipeDown() }
                else { app.swipeUp() }
            }
            XCTAssertTrue(choice.isHittable)
            XCTAssertGreaterThanOrEqual(choice.frame.height, 44)
            choice.tap()
            let selected = NSPredicate(format: "isSelected == true")
            expectation(for: selected, evaluatedWith: choice)
            waitForExpectations(timeout: 5)
        }
        attach(app, name: "settings-accessibility")
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

//
//  twintrackUITestsLaunchTests.swift
//  twintrackUITests
//
//  Created by Z73 on 07/09/2026.
//

import XCTest

final class twintrackUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        let session = UUID().uuidString
        app.launchArguments = ["--synthetic-v2-ui-tests", session,
                               "--synthetic-profile-ui-tests", session,
                               "--synthetic-appearance-ui-tests", session,
                               "--synthetic-chat-library", session,
                               "--synthetic-chat-ui-tests"]
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

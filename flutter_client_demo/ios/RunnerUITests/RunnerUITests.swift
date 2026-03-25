import Foundation
import XCTest

final class RunnerUITests: XCTestCase {
    private var app: XCUIApplication!
    private var recorder: TestRecorder!
    private var runID: String!

    override func setUpWithError() throws {
        continueAfterFailure = false
        runID = ProcessInfo.processInfo.environment["QA_RUN_ID"]
            ?? Self.loadPinnedRunID()
            ?? Self.makeRunID()
        recorder = TestRecorder(
            runID: runID,
            testName: Self.normalizedTestName(from: name),
            artifactsRootPath: ProcessInfo.processInfo.environment["QA_ARTIFACTS_DIR"]
        )
        UITestRuntime.recorder = recorder

        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "1"]
        app.launchEnvironment["QA_MODE"] = "1"
        app.launchEnvironment["QA_RUN_ID"] = runID
        app.launch()

        recorder.beginTest()
    }

    override func tearDownWithError() throws {
        defer { UITestRuntime.recorder = nil }

        guard let recorder else { return }
        let didFail = recorder.hasFailed

        if didFail, let app {
            let failurePrefix = recorder.failureStepID ?? recorder.currentStepID ?? "FAIL"
            let screenshot = app.screenshot()
            let screenshotRelPath = recorder.captureScreenshot(screenshot, basename: "\(failurePrefix)_final_state")
            attachScreenshot(screenshot, named: "\(failurePrefix)_final_state")
            recorder.noteFailureArtifact(screenshotRelPath)

            if let debugDescriptionRelPath = recorder.writeDebugDescription(
                app.debugDescription,
                basename: "\(failurePrefix)_debug_description"
            ) {
                recorder.noteDebugDescription(debugDescriptionRelPath)
            }

            let attachment = XCTAttachment(string: app.debugDescription)
            attachment.name = "\(runID ?? "run")_debug_description"
            attachment.lifetime = .keepAlways
            add(attachment)
        }

        recorder.finishTest(status: didFail ? "failed" : "passed")
    }

    override func record(_ issue: XCTIssue) {
        recorder?.markFailure(stepID: recorder?.currentStepID, errorMessage: issue.compactDescription)
        super.record(issue)
    }

    func testSmoke_LoginBrowseProfileLogout() throws {
        let login = LoginPage(app: app)
        let discover = DiscoverPage(app: app)
        let profile = ProfilePage(app: app)
        let username = ProcessInfo.processInfo.environment["QA_TEST_USERNAME"] ?? "demo_operator"
        let password = ProcessInfo.processInfo.environment["QA_TEST_PASSWORD"] ?? "123456"

        try step("S001", "Wait for login screen") {
            try login.usernameField.requireExists(timeout: 5, description: "Username field did not appear.")
            try login.passwordField.requireExists(timeout: 5, description: "Password field did not appear.")
            try login.submitButton.requireExists(timeout: 5, description: "Login button did not appear.")
        }

        try step("S002", "Submit valid credentials") {
            try login.usernameField.clearAndEnterText(username)
            try login.passwordField.tapWhenReady(timeout: 5)
            try login.passwordField.enterText(password, redact: true)
            try login.submitButton.tapWhenReady(timeout: 5)
        }

        try step("S003", "Verify discover screen and search") {
            try discover.searchField.requireExists(timeout: 8, description: "Discover search field did not appear.")
            try discover.greeting.requireExists(timeout: 5, description: "Greeting did not appear on discover screen.")
            try require(
                discover.greeting.label.contains(username),
                "Greeting did not include the expected username: \(username)"
            )
            try discover.searchField.clearAndEnterText("Wave\n")
            try require(discover.addButtons.count == 1, "Expected one visible add button after search.")
        }

        try step("S004", "Add a product to the cart") {
            try discover.firstAddButton.tapWhenReady(timeout: 5)
        }

        try step("S005", "Open profile and validate state") {
            try app.buttons["Profile"].tapWhenReady(timeout: 5)
            try profile.title.requireExists(timeout: 5, description: "Profile title did not appear.")
            try require(profile.summary.label.contains("0 favorites"), "Profile summary did not show favorite count.")
            try require(profile.summary.label.contains("1 bag items"), "Profile summary did not show bag count.")
        }

        try step("S006", "Toggle profile switches") {
            try profile.notifications.tapWhenReady(timeout: 5)
            try profile.darkMode.tapWhenReady(timeout: 5)
        }

        try step("S007", "Logout back to login") {
            try profile.logoutButton.tapWhenReady(timeout: 5)
            try login.usernameField.requireExists(timeout: 8, description: "Username field did not reappear after logout.")
            try login.submitButton.requireExists(timeout: 5, description: "Login button did not reappear after logout.")
        }
    }

    func testSearchAndCategoryFilters() throws {
        let login = LoginPage(app: app)
        let discover = DiscoverPage(app: app)

        try step("S001", "Login into the demo app") {
            try login.usernameField.clearAndEnterText("qa_filter")
            try login.passwordField.tapWhenReady(timeout: 5)
            try login.passwordField.enterText("123456", redact: true)
            try login.submitButton.tapWhenReady(timeout: 5)
            try discover.searchField.requireExists(timeout: 8, description: "Discover search field did not appear after login.")
        }

        try step("S002", "Search for a matching product") {
            try discover.searchField.clearAndEnterText("Wave\n")
            try require(discover.addButtons.count == 1, "Expected one add button after matching search.")
            try require(!discover.emptyState.exists, "Empty state should not be visible for a matching search.")
        }

        try step("S003", "Clear search and filter by category") {
            try discover.searchField.clearAndEnterText("")
            try discover.categoryChip("audio").tapWhenReady(timeout: 5)
            try require(discover.addButtons.count == 1, "Expected one add button after category filter.")
        }

        try step("S004", "Drive the empty state") {
            try discover.searchField.clearAndEnterText("no-match-keyword\n")
            try discover.emptyState.requireExists(timeout: 5, description: "Empty state did not appear for unmatched search.")
        }
    }

    private func step(_ stepID: String, _ name: String, body: () throws -> Void) throws {
        recorder.beginStep(id: stepID, name: name)

        do {
            try XCTContext.runActivity(named: "\(stepID) \(name)") { _ in
                try body()
            }

            let screenshot = app.screenshot()
            let screenshotRelPath = recorder.captureScreenshot(screenshot, basename: "\(stepID)_success")
            attachScreenshot(screenshot, named: "\(stepID)_success")
            recorder.endCurrentStep(status: "passed", screenshotRelPath: screenshotRelPath, errorMessage: nil)
        } catch {
            let screenshot = app.screenshot()
            let screenshotRelPath = recorder.captureScreenshot(screenshot, basename: "\(stepID)_failure")
            attachScreenshot(screenshot, named: "\(stepID)_failure")
            recorder.endCurrentStep(
                status: "failed",
                screenshotRelPath: screenshotRelPath,
                errorMessage: Self.describe(error)
            )
            throw error
        }
    }

    private func attachScreenshot(_ screenshot: XCUIScreenshot, named name: String) {
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(runID ?? "run")_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private static func makeRunID() -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        return "xcuitest_\(timestamp)"
    }

    fileprivate static func defaultArtifactsRootPath(for runID: String) -> String {
        qaDirectoryURL()
            .appendingPathComponent("artifacts", isDirectory: true)
            .appendingPathComponent(runID, isDirectory: true)
            .path
    }

    private static func loadPinnedRunID() -> String? {
        let pinnedRunIDURL = qaDirectoryURL().appendingPathComponent(".current_swift_ui_run_id")
        guard let contents = try? String(contentsOf: pinnedRunIDURL, encoding: .utf8) else {
            return nil
        }

        let trimmed = contents.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func qaDirectoryURL() -> URL {
        var url = URL(fileURLWithPath: #filePath, isDirectory: false)
        for _ in 0..<4 {
            url.deleteLastPathComponent()
        }
        return url.appendingPathComponent("qa", isDirectory: true)
    }

    private static func normalizedTestName(from rawName: String) -> String {
        guard let separator = rawName.lastIndex(of: " "), let closer = rawName.lastIndex(of: "]"), separator < closer else {
            return rawName
        }
        return String(rawName[rawName.index(after: separator)..<closer])
    }

    fileprivate static func describe(_ error: Error) -> String {
        if let localized = error as? LocalizedError, let description = localized.errorDescription {
            return description
        }
        return error.localizedDescription
    }
}

private struct LoginPage {
    let app: XCUIApplication

    var usernameField: XCUIElement {
        app.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "Username")).firstMatch
    }

    var passwordField: XCUIElement {
        let secureField = app.secureTextFields.firstMatch
        return secureField.exists
            ? secureField
            : app.textFields.matching(NSPredicate(format: "label CONTAINS[c] %@", "Password")).firstMatch
    }

    var submitButton: XCUIElement {
        app.buttons["Enter Demo Workspace"]
    }
}

private struct DiscoverPage {
    let app: XCUIApplication

    var greeting: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Welcome back")).firstMatch
    }

    var searchField: XCUIElement {
        app.textFields.matching(NSPredicate(format: "identifier != %@", "qa.discover.search")).firstMatch
    }

    var emptyState: XCUIElement {
        app.staticTexts["No products match your current search."]
    }

    var addButtons: XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "label == %@", "Add"))
    }

    var firstAddButton: XCUIElement {
        addButtons.firstMatch
    }

    func categoryChip(_ identifier: String) -> XCUIElement {
        switch identifier {
        case "audio":
            return app.buttons["Audio"]
        case "focus":
            return app.buttons["Focus"]
        case "desk":
            return app.buttons["Desk"]
        default:
            return app.buttons["All"]
        }
    }
}

private struct ProfilePage {
    let app: XCUIApplication

    var title: XCUIElement {
        app.staticTexts["Profile settings"]
    }

    var summary: XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "favorites")).firstMatch
    }

    var notifications: XCUIElement {
        app.switches.element(boundBy: 0)
    }

    var darkMode: XCUIElement {
        app.switches.element(boundBy: 2)
    }

    var logoutButton: XCUIElement {
        app.buttons["Log out"]
    }
}

private final class TestRecorder {
    private let runID: String
    private let testName: String
    private let safeTestName: String
    private let rootDirURL: URL
    private let logsDirURL: URL
    private let screensDirURL: URL
    private let stepLogURL: URL
    private let actionLogURL: URL
    private let resultURL: URL
    private var debugDescriptionRelPath: String?
    private var failureArtifacts: [String] = []
    private var testStartedAtMs: Int64 = 0
    private var didFail = false
    private(set) var failureStepID: String?

    private(set) var currentStepID: String?
    private var currentStepName: String?
    private var currentStepStartedAtMs: Int64?

    init(runID: String, testName: String, artifactsRootPath: String?) {
        self.runID = runID
        self.testName = testName
        self.safeTestName = Self.sanitizeFileComponent(testName)

        let rootDirPath = artifactsRootPath?.isEmpty == false
            ? artifactsRootPath!
            : RunnerUITests.defaultArtifactsRootPath(for: runID)

        self.rootDirURL = URL(fileURLWithPath: rootDirPath, isDirectory: true)
        self.logsDirURL = rootDirURL.appendingPathComponent("logs", isDirectory: true)
        self.screensDirURL = rootDirURL
            .appendingPathComponent("screens", isDirectory: true)
            .appendingPathComponent(safeTestName, isDirectory: true)
        self.stepLogURL = logsDirURL.appendingPathComponent("\(safeTestName)_step_events.jsonl")
        self.actionLogURL = logsDirURL.appendingPathComponent("\(safeTestName)_action_events.jsonl")
        self.resultURL = logsDirURL.appendingPathComponent("\(safeTestName)_test_result.json")

        createDirectoryIfNeeded(rootDirURL)
        createDirectoryIfNeeded(logsDirURL)
        createDirectoryIfNeeded(screensDirURL)
    }

    func beginTest() {
        clearPreviousEvidenceFiles()
        testStartedAtMs = Self.nowMs()
    }

    func finishTest(status: String) {
        let finishedAtMs = Self.nowMs()
        let payload = compactJSON([
            "run_id": runID,
            "test_name": testName,
            "status": status,
            "started_at_ms": testStartedAtMs,
            "ended_at_ms": finishedAtMs,
            "duration_ms": finishedAtMs - testStartedAtMs,
            "failure_step_id": failureStepID,
            "failure_artifacts": failureArtifacts.isEmpty ? nil : failureArtifacts,
            "debug_description_relpath": debugDescriptionRelPath
        ])

        writeJSONObject(payload, to: resultURL, append: false)
    }

    func beginStep(id: String, name: String) {
        currentStepID = id
        currentStepName = name
        currentStepStartedAtMs = Self.nowMs()
    }

    func endCurrentStep(status: String, screenshotRelPath: String?, errorMessage: String?) {
        let endedAtMs = Self.nowMs()
        let startedAtMs = currentStepStartedAtMs ?? endedAtMs
        let payload = compactJSON([
            "event": "step",
            "ts_ms": endedAtMs,
            "run_id": runID,
            "test_name": testName,
            "step_id": currentStepID,
            "step_name": currentStepName,
            "status": status,
            "started_at_ms": startedAtMs,
            "ended_at_ms": endedAtMs,
            "duration_ms": endedAtMs - startedAtMs,
            "screenshot_relpath": screenshotRelPath,
            "error": errorMessage
        ])

        appendJSONObject(payload, to: stepLogURL)

        if status != "passed", let screenshotRelPath {
            noteFailureArtifact(screenshotRelPath)
        }

        if status == "passed" {
            currentStepID = nil
            currentStepName = nil
            currentStepStartedAtMs = nil
        } else {
            markFailure(stepID: currentStepID, errorMessage: errorMessage)
        }
    }

    var hasFailed: Bool {
        didFail
    }

    func markFailure(stepID: String?, errorMessage: String?) {
        didFail = true
        if failureStepID == nil {
            failureStepID = stepID
        }
    }

    func noteFailureArtifact(_ relPath: String) {
        if !failureArtifacts.contains(relPath) {
            failureArtifacts.append(relPath)
        }
    }

    func noteDebugDescription(_ relPath: String) {
        debugDescriptionRelPath = relPath
    }

    func captureScreenshot(_ screenshot: XCUIScreenshot, basename: String) -> String {
        let filename = "\(Self.sanitizeFileComponent(basename)).png"
        let fileURL = screensDirURL.appendingPathComponent(filename)
        do {
            try screenshot.pngRepresentation.write(to: fileURL)
        } catch {
            // Fall through. Report generation should not fail because one screenshot could not be written.
        }
        return "screens/\(safeTestName)/\(filename)"
    }

    @discardableResult
    func writeDebugDescription(_ content: String, basename: String) -> String? {
        let filename = "\(safeTestName)_\(Self.sanitizeFileComponent(basename)).txt"
        let fileURL = logsDirURL.appendingPathComponent(filename)

        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            return "logs/\(filename)"
        } catch {
            return nil
        }
    }

    func performAction<T>(action: String, target: String, detail: String?, block: () throws -> T) throws -> T {
        let startedAtMs = Self.nowMs()
        do {
            let result = try block()
            let endedAtMs = Self.nowMs()
            appendJSONObject(compactJSON([
                "event": "action",
                "ts_ms": endedAtMs,
                "run_id": runID,
                "test_name": testName,
                "step_id": currentStepID,
                "step_name": currentStepName,
                "action": action,
                "target": target,
                "detail": detail,
                "status": "passed",
                "started_at_ms": startedAtMs,
                "ended_at_ms": endedAtMs,
                "duration_ms": endedAtMs - startedAtMs
            ]), to: actionLogURL)
            return result
        } catch {
            let endedAtMs = Self.nowMs()
            appendJSONObject(compactJSON([
                "event": "action",
                "ts_ms": endedAtMs,
                "run_id": runID,
                "test_name": testName,
                "step_id": currentStepID,
                "step_name": currentStepName,
                "action": action,
                "target": target,
                "detail": detail,
                "status": "failed",
                "started_at_ms": startedAtMs,
                "ended_at_ms": endedAtMs,
                "duration_ms": endedAtMs - startedAtMs,
                "error": RunnerUITests.describe(error)
            ]), to: actionLogURL)
            throw error
        }
    }

    private func createDirectoryIfNeeded(_ url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            // Ignore. The test will still attempt to run and Xcode attachments remain as fallback evidence.
        }
    }

    private func clearPreviousEvidenceFiles() {
        for url in [stepLogURL, actionLogURL, resultURL] {
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    private func appendJSONObject(_ object: [String: Any], to url: URL) {
        writeJSONObject(object, to: url, append: true)
    }

    private func writeJSONObject(_ object: [String: Any], to url: URL, append: Bool) {
        guard JSONSerialization.isValidJSONObject(object),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.sortedKeys]) else {
            return
        }

        let newline = Data([0x0A])
        if append, FileManager.default.fileExists(atPath: url.path) {
            do {
                let handle = try FileHandle(forWritingTo: url)
                handle.seekToEndOfFile()
                handle.write(data)
                handle.write(newline)
                handle.closeFile()
            } catch {
                // Ignore write failures so the test result itself is not blocked by evidence collection.
            }
            return
        }

        do {
            var output = data
            output.append(newline)
            try output.write(to: url, options: .atomic)
        } catch {
            // Ignore write failures so the test result itself is not blocked by evidence collection.
        }
    }

    private func compactJSON(_ values: [String: Any?]) -> [String: Any] {
        var compacted: [String: Any] = [:]
        for (key, value) in values {
            guard let value else { continue }
            compacted[key] = value
        }
        return compacted
    }

    private static func nowMs() -> Int64 {
        Int64(Date().timeIntervalSince1970 * 1000)
    }

    private static func sanitizeFileComponent(_ raw: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-."))
        let scalars = raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }
        return String(scalars)
            .replacingOccurrences(of: "__", with: "_")
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
    }
}

private enum UITestRuntime {
    static var recorder: TestRecorder?
}

private struct UITestFailure: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

@discardableResult
private func require(_ condition: @autoclosure () -> Bool, _ message: String) throws -> Bool {
    guard condition() else {
        throw UITestFailure(message: message)
    }
    return true
}

private func performLoggedAction<T>(
    action: String,
    target: String,
    detail: String? = nil,
    block: () throws -> T
) throws -> T {
    if let recorder = UITestRuntime.recorder {
        return try recorder.performAction(action: action, target: target, detail: detail, block: block)
    }
    return try block()
}

private extension XCUIElement {
    func requireExists(timeout: TimeInterval, description: String) throws {
        guard waitForExistence(timeout: timeout) else {
            throw UITestFailure(message: description)
        }
    }

    func tapWhenReady(timeout: TimeInterval) throws {
        let target = targetDescription
        try performLoggedAction(action: "tap", target: target) {
            guard waitForExistence(timeout: timeout) else {
                throw UITestFailure(message: "Element did not appear in time: \(target)")
            }

            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "hittable == true"),
                object: self
            )
            let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
            guard result == .completed else {
                throw UITestFailure(message: "Element is not hittable: \(target)")
            }

            tap()
        }
    }

    func clearAndEnterText(_ text: String, redact: Bool = false) throws {
        let target = targetDescription
        let detail = redact ? "<redacted>" : text

        try performLoggedAction(action: "input", target: target, detail: detail) {
            guard waitForExistence(timeout: 5) else {
                throw UITestFailure(message: "Text input did not appear in time: \(target)")
            }

            let expectation = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "hittable == true"),
                object: self
            )
            let result = XCTWaiter.wait(for: [expectation], timeout: 5)
            guard result == .completed else {
                throw UITestFailure(message: "Text input is not hittable: \(target)")
            }

            tap()

            if let currentValue = value as? String, !currentValue.isEmpty {
                let placeholderLikeValue = currentValue == label || currentValue == "Search items or moods"
                if !placeholderLikeValue {
                    let deleteString = String(
                        repeating: XCUIKeyboardKey.delete.rawValue,
                        count: currentValue.count
                    )
                    typeText(deleteString)
                }
            }

            if !text.isEmpty {
                typeText(text)
            }
        }
    }

    func enterText(_ text: String, redact: Bool = false) throws {
        let target = targetDescription
        let detail = redact ? "<redacted>" : text

        try performLoggedAction(action: "type", target: target, detail: detail) {
            if !text.isEmpty {
                typeText(text)
            }
        }
    }

    private var targetDescription: String {
        let trimmedIdentifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedIdentifier.isEmpty {
            return trimmedIdentifier
        }

        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedLabel.isEmpty {
            return trimmedLabel
        }

        return String(describing: elementType)
    }
}

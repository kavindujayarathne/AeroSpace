@testable import AppBundle
import Common
import XCTest

@MainActor
final class CloseFloatingWindowFocusTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testFocusReturnsToPreviouslyFocusedWindowAfterFloatingWindowCloses() {
        let ws = focus.workspace
        // Materialise both containers before binding windows. These accessors create the
        // container when absent, and creating it marks it as the most recent child.
        let root = ws.rootTilingContainer
        let floating = ws.floatingWindowsContainer

        TestWindow.new(id: 1, parent: root) // first in binding order, never focused
        let focused = TestWindow.new(id: 2, parent: root)
        XCTAssertTrue(focused.focusWindow())

        let transient = TestWindow.new(id: 3, parent: floating)
        XCTAssertTrue(transient.focusWindow())
        transient.unbindFromParent()

        XCTAssertEqual(ws.toLiveFocus().windowOrNil, focused)
    }
}

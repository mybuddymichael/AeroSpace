@testable import AppBundle
import Common
import XCTest

@MainActor
final class FullscreenCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseWidthFlag() {
        let args = parseFullscreenCmdArgs(["--width", "70"].slice).cmdOrDie
        assertEquals(args.widthPercent, 70)
        assertEquals(args.toggle, .toggle)
    }

    func testParseWidthValidation() {
        testParseCommandFail("fullscreen --width 0", msg: "--width must be in range 1..100")
        testParseCommandFail("fullscreen off --width 70", msg: "--width is incompatible with 'off' argument")
    }

    func testToggleSwitchesStyleWithoutExitingFullscreen() async throws {
        let window = makeFocusedWindow()

        _ = try await parseCommand("fullscreen --width 70").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertTrue(window.isFullscreen)
        assertEquals(window.fullscreenWidthPercent, 70)

        _ = try await parseCommand("fullscreen").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertTrue(window.isFullscreen)
        assertNil(window.fullscreenWidthPercent)

        _ = try await parseCommand("fullscreen").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertTrue(!window.isFullscreen)
    }

    func testToggleSameStyleTurnsOffFullscreen() async throws {
        let window = makeFocusedWindow()

        _ = try await parseCommand("fullscreen --width 70").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertTrue(window.isFullscreen)

        _ = try await parseCommand("fullscreen --width 70").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertTrue(!window.isFullscreen)
        assertNil(window.fullscreenWidthPercent)
    }

    func testOnNoopAndStyleSwitch() async throws {
        let window = makeFocusedWindow()

        _ = try await parseCommand("fullscreen on --width 70").cmdOrDie.run(.defaultEnv, .emptyStdin)
        let noop = try await parseCommand("fullscreen on --width 70 --fail-if-noop").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(noop.exitCode, 1)
        assertTrue(window.isFullscreen)
        assertEquals(window.fullscreenWidthPercent, 70)

        let switched = try await parseCommand("fullscreen on").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(switched.exitCode, 0)
        assertTrue(window.isFullscreen)
        assertNil(window.fullscreenWidthPercent)
    }

    func testResolveFullscreenRectCentersPartialWidth() {
        let base = Rect(topLeftX: 100, topLeftY: 200, width: 1000, height: 700)
        let rect = resolveFullscreenRect(baseRect: base, widthPercent: 70)
        assertEquals(rect.topLeftX, 250)
        assertEquals(rect.topLeftY, 200)
        assertEquals(rect.width, 700)
        assertEquals(rect.height, 700)
    }

    func testFullscreenDoesNotReflowTree() async throws {
        let workspace = Workspace.get(byName: name)
        workspace.rootTilingContainer.apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }
        let before = workspace.layoutDescription

        _ = try await parseCommand("fullscreen --width 70").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(workspace.layoutDescription, before)
    }

    private func makeFocusedWindow() -> TestWindow {
        let window = TestWindow.new(id: 1, parent: Workspace.get(byName: name).rootTilingContainer)
        assertEquals(window.focusWindow(), true)
        return window
    }
}

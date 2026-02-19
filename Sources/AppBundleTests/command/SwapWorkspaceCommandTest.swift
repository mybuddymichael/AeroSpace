@testable import AppBundle
import Common
import XCTest

@MainActor
final class SwapWorkspaceCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParse() {
        assertEquals(parseCommand("swap-workspace").errorOrNil, "ERROR: Argument '<workspace>' is mandatory")
        testParseCommandSucc("swap-workspace target", SwapWorkspaceCmdArgs(workspace: "target"))
    }

    func testSwapWorkspace_SwapsWorkspaceTreesAndKeepsFocusedWorkspace() async throws {
        let sourceWorkspace = focus.workspace
        let targetWorkspace = Workspace.get(byName: "2")

        sourceWorkspace.rootTilingContainer.apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }
        TestWindow.new(id: 3, parent: sourceWorkspace)
        sourceWorkspace.macOsNativeHiddenAppsWindowsContainer.apply {
            TestWindow.new(id: 4, parent: $0)
        }

        targetWorkspace.rootTilingContainer.apply {
            TestWindow.new(id: 5, parent: $0)
        }
        TestWindow.new(id: 6, parent: targetWorkspace)
        targetWorkspace.macOsNativeFullscreenWindowsContainer.apply {
            TestWindow.new(id: 7, parent: $0)
        }

        let sourceWorkspaceName = sourceWorkspace.name
        try await SwapWorkspaceCommand(args: SwapWorkspaceCmdArgs(workspace: targetWorkspace.name))
            .run(.defaultEnv, .emptyStdin)

        assertEquals(focus.workspace.name, sourceWorkspaceName)
        assertEquals(sourceWorkspace.rootTilingContainer.allLeafWindowsRecursive.map(\.windowId), [5])
        assertEquals(targetWorkspace.rootTilingContainer.allLeafWindowsRecursive.map(\.windowId), [1, 2])
        assertEquals(sourceWorkspace.floatingWindows.map(\.windowId), [6])
        assertEquals(targetWorkspace.floatingWindows.map(\.windowId), [3])
        assertEquals(macosFullscreenWindowIds(sourceWorkspace), [7])
        assertEquals(macosHiddenAppsWindowIds(targetWorkspace), [4])
        assertEquals(Set(collectAllWindowIds(workspace: sourceWorkspace)), Set([5, 6, 7]))
        assertEquals(Set(collectAllWindowIds(workspace: targetWorkspace)), Set([1, 2, 3, 4]))
    }

    func testSwapWorkspace_NoopWhenTargetIsAlreadyFocused() async throws {
        let sourceWorkspace = focus.workspace
        sourceWorkspace.rootTilingContainer.apply {
            assertEquals(TestWindow.new(id: 1, parent: $0).focusWindow(), true)
            TestWindow.new(id: 2, parent: $0)
        }
        let before = sourceWorkspace.layoutDescription

        try await SwapWorkspaceCommand(args: SwapWorkspaceCmdArgs(workspace: sourceWorkspace.name))
            .run(.defaultEnv, .emptyStdin)

        assertEquals(sourceWorkspace.layoutDescription, before)
        assertEquals(focus.workspace, sourceWorkspace)
    }
}

extension SwapWorkspaceCmdArgs {
    init(workspace: String) {
        self = SwapWorkspaceCmdArgs(rawArgs: [])
        self.target = .initialized(.parse(workspace).getOrDie())
    }
}

private func macosFullscreenWindowIds(_ workspace: Workspace) -> [UInt32] {
    workspace.children
        .filterIsInstance(of: MacosFullscreenWindowsContainer.self)
        .flatMap { $0.children.filterIsInstance(of: Window.self).map(\.windowId) }
}

private func macosHiddenAppsWindowIds(_ workspace: Workspace) -> [UInt32] {
    workspace.children
        .filterIsInstance(of: MacosHiddenAppsWindowsContainer.self)
        .flatMap { $0.children.filterIsInstance(of: Window.self).map(\.windowId) }
}

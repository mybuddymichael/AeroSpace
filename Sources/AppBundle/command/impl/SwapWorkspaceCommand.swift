import Common

struct SwapWorkspaceCommand: Command {
    let args: SwapWorkspaceCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        let sourceWorkspace = focus.workspace
        let targetWorkspace = Workspace.get(byName: args.target.val.raw)
        if sourceWorkspace == targetWorkspace {
            return true
        }
        sourceWorkspace.swapChildren(with: targetWorkspace)
        return true
    }
}

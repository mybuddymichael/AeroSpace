public struct SwapWorkspaceCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = cmdParser(
        kind: .swapWorkspace,
        allowInConfig: true,
        help: swap_workspace_help_generated,
        flags: [:],
        posArgs: [newArgParser(\.target, parseSwapWorkspaceTarget, mandatoryArgPlaceholder: "<workspace>")],
    )

    public var target: Lateinit<WorkspaceName> = .uninitialized
}

private func parseSwapWorkspaceTarget(i: ArgParserInput) -> ParsedCliArgs<WorkspaceName> {
    .init(WorkspaceName.parse(i.arg), advanceBy: 1)
}

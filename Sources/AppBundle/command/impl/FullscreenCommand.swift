import AppKit
import Common

struct FullscreenCommand: Command {
    let args: FullscreenCmdArgs
    /*conforms*/ var shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else {
            return io.err(noWindowIsFocused)
        }
        let requestedStyle = FullscreenStyle(noOuterGaps: args.noOuterGaps, widthPercent: args.widthPercent)

        switch args.toggle {
            case .off:
                if !window.isFullscreen {
                    io.err("Already not fullscreen. Tip: use --fail-if-noop to exit with non-zero code")
                    return !args.failIfNoop
                }
                window.isFullscreen = false
                window.clearFullscreenStyle()
            case .on:
                if window.isFullscreen && window.fullscreenStyle == requestedStyle {
                    io.err("Already fullscreen. Tip: use --fail-if-noop to exit with non-zero code")
                    return !args.failIfNoop
                }
                window.isFullscreen = true
                window.setFullscreenStyle(requestedStyle)
            case .toggle:
                if !window.isFullscreen {
                    window.isFullscreen = true
                    window.setFullscreenStyle(requestedStyle)
                } else if window.fullscreenStyle == requestedStyle {
                    window.isFullscreen = false
                    window.clearFullscreenStyle()
                } else {
                    window.setFullscreenStyle(requestedStyle)
                }
        }

        // Focus on its own workspace
        window.markAsMostRecentChild()
        return true
    }
}

let noWindowIsFocused = "No window is focused"

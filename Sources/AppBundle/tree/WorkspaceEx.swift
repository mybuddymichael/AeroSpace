import Common

extension Workspace {
    @MainActor
    func swapChildren(with other: Workspace) {
        if self == other { return }

        let selfChildren = detachChildren()
        let otherChildren = other.detachChildren()

        other.attachChildren(selfChildren)
        attachChildren(otherChildren)
    }

    @MainActor
    private func detachChildren() -> [DetachedWorkspaceChild] {
        children.reversed()
            .map { child in DetachedWorkspaceChild(node: child, binding: child.unbindFromParent()) }
            .reversed()
    }

    @MainActor
    private func attachChildren(_ detached: [DetachedWorkspaceChild]) {
        for child in detached {
            child.node.bind(
                to: self,
                adaptiveWeight: child.binding.adaptiveWeight,
                index: child.binding.index,
            )
        }
    }

    @MainActor var rootTilingContainer: TilingContainer {
        let containers = children.filterIsInstance(of: TilingContainer.self)
        switch containers.count {
            case 0:
                let orientation: Orientation = switch config.defaultRootContainerOrientation {
                    case .horizontal: .h
                    case .vertical: .v
                    case .auto: workspaceMonitor.then { $0.width >= $0.height } ? .h : .v
                }
                return TilingContainer(parent: self, adaptiveWeight: 1, orientation, config.defaultRootContainerLayout, index: INDEX_BIND_LAST)
            case 1:
                return containers.singleOrNil().orDie()
            default:
                die("Workspace must contain zero or one tiling container as its child")
        }
    }

    var floatingWindows: [Window] {
        children.filterIsInstance(of: Window.self)
    }

    @MainActor var macOsNativeFullscreenWindowsContainer: MacosFullscreenWindowsContainer {
        let containers = children.filterIsInstance(of: MacosFullscreenWindowsContainer.self)
        return switch containers.count {
            case 0: MacosFullscreenWindowsContainer(parent: self)
            case 1: containers.singleOrNil().orDie()
            default: dieT("Workspace must contain zero or one MacosFullscreenWindowsContainer")
        }
    }

    @MainActor var macOsNativeHiddenAppsWindowsContainer: MacosHiddenAppsWindowsContainer {
        let containers = children.filterIsInstance(of: MacosHiddenAppsWindowsContainer.self)
        return switch containers.count {
            case 0: MacosHiddenAppsWindowsContainer(parent: self)
            case 1: containers.singleOrNil().orDie()
            default: dieT("Workspace must contain zero or one MacosHiddenAppsWindowsContainer")
        }
    }

    @MainActor var forceAssignedMonitor: Monitor? {
        guard let monitorDescriptions = config.workspaceToMonitorForceAssignment[name] else { return nil }
        let sortedMonitors = sortedMonitors
        return monitorDescriptions.lazy
            .compactMap { $0.resolveMonitor(sortedMonitors: sortedMonitors) }
            .first
    }
}

private struct DetachedWorkspaceChild {
    let node: TreeNode
    let binding: BindingData
}

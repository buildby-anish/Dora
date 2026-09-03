//
//  ApplicationCoordinator.swift
//  Dora
//
//  Owns the lifetime of Dora's major subsystems and wires them
//  together. In Stage 1 this is just the window controller. Future
//  stages (BehaviorEngine, sensors, memory, brain) will be created
//  and injected here rather than reached for as globals, so each
//  system stays testable and replaceable.
//

import AppKit

final class ApplicationCoordinator {

    private var windowController: WindowController?
    private var interactionController: InteractionController?
    private var chatWindowController: ChatWindowController?
    private var activityMonitor: UserActivityMonitor?

    func start() {
        let screen = ScreenCoordinator.primaryScreen()
        let controller = WindowController(screen: screen)
        self.windowController = controller

        let chatController = ChatWindowController()
        self.chatWindowController = chatController

        let scene = controller.scene

        chatController.onCatReaction = { [weak scene] reaction in
            scene?.dora?.play(reaction)
        }

        if let window = controller.window {
            interactionController = InteractionController(
                window: window,
                interactiveRectsProvider: { [weak scene] in
                    scene?.getInteractiveScreenRects() ?? []
                },
                onCatClicked: { [weak self, weak scene] in
                    guard let self = self, let scene = scene else { return }
                    scene.dora?.play(.happy)
                    let catPos = scene.catScreenPosition()
                    self.chatWindowController?.showNear(screenPoint: catPos)
                },
                onCatDragStarted: { [weak scene] point in
                    scene?.startDrag(at: point)
                },
                onCatDragged: { [weak scene] point in
                    scene?.updateDrag(to: point)
                },
                onCatDragEnded: { [weak scene] point in
                    scene?.endDrag(at: point)
                }
            )
        }

        let monitor = UserActivityMonitor()
        monitor.idleThresholdSeconds = 60.0 // 1 min idle trigger
        monitor.onUserBecameIdle = { [weak scene] in
            scene?.userBecameIdle()
        }
        monitor.onUserResumedActivity = { [weak scene] in
            scene?.userResumedWork()
        }
        self.activityMonitor = monitor

        controller.showWindow()
    }

    func stop() {
        activityMonitor?.stopMonitoring()
        activityMonitor = nil
        chatWindowController?.hidePanel()
        chatWindowController = nil
        interactionController = nil
        windowController?.closeWindow()
        windowController = nil
    }
}

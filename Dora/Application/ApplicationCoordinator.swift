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

    func start() {
        let screen = ScreenCoordinator.primaryScreen()
        let controller = WindowController(screen: screen)
        self.windowController = controller
        controller.showWindow()
    }

    func stop() {
        windowController?.closeWindow()
        windowController = nil
    }
}

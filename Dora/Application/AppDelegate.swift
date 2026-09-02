//
//  AppDelegate.swift
//  Dora
//
//  Owns the top-level lifecycle. Delegates real setup work to
//  ApplicationCoordinator so this class stays a thin adapter between
//  AppKit lifecycle callbacks and Dora's own systems.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var coordinator: ApplicationCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let coordinator = ApplicationCoordinator()
        self.coordinator = coordinator
        coordinator.start()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Dora's window closing should not quit the app in later stages
        // (menu bar item, "Hide Dora" vs quitting are distinct). For
        // Stage 1 this doesn't matter much since we don't expose a
        // close control yet, but we set the correct long-term default
        // now rather than relaxing it later.
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        coordinator?.stop()
    }
}

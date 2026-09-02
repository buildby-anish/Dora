//
//  InteractionController.swift
//  Dora
//
//  Manages transparent click-through and proximity hit-testing.
//  Ensures the user has 100% access to their screen, only intercepting
//  mouse clicks when directly hovering over or clicking the cat/bubble.
//

import AppKit

final class InteractionController {

    private weak var window: NSWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private var interactiveRectsProvider: (() -> [NSRect])?
    private var onCatClicked: (() -> Void)?
    private var onBubbleClicked: (() -> Void)?

    private var isMouseInsideInteractiveRegion = false

    init(
        window: NSWindow,
        interactiveRectsProvider: @escaping () -> [NSRect],
        onCatClicked: @escaping () -> Void,
        onBubbleClicked: @escaping () -> Void
    ) {
        self.window = window
        self.interactiveRectsProvider = interactiveRectsProvider
        self.onCatClicked = onCatClicked
        self.onBubbleClicked = onBubbleClicked

        // Start with click-through ENABLED so desktop is immediately accessible
        window.ignoresMouseEvents = true

        setupMonitors()
    }

    deinit {
        stopMonitors()
    }

    private func setupMonitors() {
        // Global monitor (fires when mouse moves over any other app)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            self?.handleMouseMovement(screenPoint: NSEvent.mouseLocation)
        }

        // Local monitor (fires when mouse moves over Dora's window)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self] event in
            guard let self = self else { return event }
            let point = NSEvent.mouseLocation

            if event.type == .leftMouseDown {
                if self.isPointInsideInteractiveRegion(point) {
                    self.onCatClicked?()
                }
            } else if event.type == .mouseMoved {
                self.handleMouseMovement(screenPoint: point)
            }
            return event
        }
    }

    private func stopMonitors() {
        if let globalMonitor = globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor = localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    private func handleMouseMovement(screenPoint: NSPoint) {
        guard let window = window else { return }

        let inside = isPointInsideInteractiveRegion(screenPoint)
        if inside != isMouseInsideInteractiveRegion {
            isMouseInsideInteractiveRegion = inside
            DispatchQueue.main.async {
                // If inside interactive area (cat / bubble), capture mouse clicks;
                // otherwise pass all clicks through to underlying desktop apps.
                window.ignoresMouseEvents = !inside
            }
        }
    }

    private func isPointInsideInteractiveRegion(_ screenPoint: NSPoint) -> Bool {
        guard let rects = interactiveRectsProvider?() else { return false }
        for rect in rects {
            if rect.contains(screenPoint) {
                return true
            }
        }
        return false
    }
}

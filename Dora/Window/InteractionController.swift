//
//  InteractionController.swift
//  Dora
//
//  Manages transparent click-through, proximity hit-testing, and
//  mouse drag-and-drop (Pick & Drop) vs. Click-to-Chat.
//

import AppKit

final class InteractionController {

    private weak var window: NSWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private var interactiveRectsProvider: (() -> [NSRect])?
    private var onCatClicked: (() -> Void)?
    private var onCatDragStarted: ((NSPoint) -> Void)?
    private var onCatDragged: ((NSPoint) -> Void)?
    private var onCatDragEnded: ((NSPoint) -> Void)?

    private var isMouseInsideInteractiveRegion = false
    private var isTrackingPress = false
    private var isDragging = false
    private var mouseDownPoint: NSPoint = .zero

    private static let dragThreshold: CGFloat = 6.0

    init(
        window: NSWindow,
        interactiveRectsProvider: @escaping () -> [NSRect],
        onCatClicked: @escaping () -> Void,
        onCatDragStarted: @escaping (NSPoint) -> Void,
        onCatDragged: @escaping (NSPoint) -> Void,
        onCatDragEnded: @escaping (NSPoint) -> Void
    ) {
        self.window = window
        self.interactiveRectsProvider = interactiveRectsProvider
        self.onCatClicked = onCatClicked
        self.onCatDragStarted = onCatDragStarted
        self.onCatDragged = onCatDragged
        self.onCatDragEnded = onCatDragEnded

        // Start with click-through ENABLED so desktop is immediately accessible
        window.ignoresMouseEvents = true

        setupMonitors()
    }

    deinit {
        stopMonitors()
    }

    private func setupMonitors() {
        let eventMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .leftMouseDragged, .leftMouseUp]

        // Global monitor (fires when mouse interactions occur over any app)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleMouseEvent(event)
        }

        // Local monitor (fires when mouse interactions occur over Dora's window)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleMouseEvent(event)
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

    private func handleMouseEvent(_ event: NSEvent) {
        let point = NSEvent.mouseLocation

        switch event.type {
        case .mouseMoved:
            if !isDragging {
                handleMouseHover(screenPoint: point)
            }

        case .leftMouseDown:
            if isPointInsideInteractiveRegion(point) {
                isTrackingPress = true
                isDragging = false
                mouseDownPoint = point
                window?.ignoresMouseEvents = false
            }

        case .leftMouseDragged:
            if isTrackingPress {
                let dx = point.x - mouseDownPoint.x
                let dy = point.y - mouseDownPoint.y
                let dist = hypot(dx, dy)

                if dist >= Self.dragThreshold {
                    if !isDragging {
                        isDragging = true
                        onCatDragStarted?(point)
                    }
                    onCatDragged?(point)
                }
            }

        case .leftMouseUp:
            if isTrackingPress {
                isTrackingPress = false
                if isDragging {
                    isDragging = false
                    onCatDragEnded?(point)
                } else {
                    // It was a click / tap! Open chat text box
                    onCatClicked?()
                }
                handleMouseHover(screenPoint: point)
            }

        default:
            break
        }
    }

    private func handleMouseHover(screenPoint: NSPoint) {
        guard let window = window else { return }

        let inside = isPointInsideInteractiveRegion(screenPoint)
        if inside != isMouseInsideInteractiveRegion {
            isMouseInsideInteractiveRegion = inside
            DispatchQueue.main.async {
                // If hovering inside Dora's rect, capture mouse; otherwise pass through
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


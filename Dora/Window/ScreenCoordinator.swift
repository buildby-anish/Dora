//
//  ScreenCoordinator.swift
//  Dora
//
//  Centralizes screen-geometry decisions so window/movement code
//  never queries NSScreen directly. This is also the seam where
//  future multi-monitor support gets added — everything else in the
//  app should ask this type "where is the desktop" rather than
//  assuming NSScreen.main.
//

import AppKit

enum ScreenCoordinator {

    /// The screen Dora currently lives on. For Stage 1 this is always
    /// the primary screen; later stages may track "the screen the
    /// mouse is on" or a user-selected screen.
    static func primaryScreen() -> NSScreen {
        NSScreen.main ?? NSScreen.screens[0]
    }

    /// Full usable frame (excludes menu bar / Dock) for the given
    /// screen, in screen coordinates (origin bottom-left, per AppKit
    /// convention).
    static func visibleFrame(for screen: NSScreen) -> NSRect {
        screen.visibleFrame
    }

    /// Full frame including the area under the menu bar, useful for
    /// a window that should be allowed to render behind/near it.
    static func fullFrame(for screen: NSScreen) -> NSRect {
        screen.frame
    }

    /// `screen`'s visible frame (excludes menu bar & Dock), converted
    /// into the local coordinate space of a window whose frame is
    /// `windowFrame` — i.e. the same coordinate space as an SKNode's
    /// `position` inside that window's content view (bottom-left
    /// origin, per AppKit/SpriteKit convention).
    ///
    /// This is the seam that lets MovementController stay ignorant of
    /// NSScreen entirely: it only ever sees "here is the rectangle
    /// Dora is allowed to roam in," already adjusted for the Dock and
    /// menu bar, in the same coordinates as her own position.
    static func walkableBounds(windowFrame: NSRect, screen: NSScreen) -> CGRect {
        let visible = visibleFrame(for: screen)
        return CGRect(
            x: visible.minX - windowFrame.minX,
            y: visible.minY - windowFrame.minY,
            width: visible.width,
            height: visible.height
        )
    }

    /// Finds the active screen currently containing a screen coordinate point
    static func screenContaining(point: NSPoint) -> NSScreen {
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return primaryScreen()
    }

    /// Returns key resting and perching spots (corners, Dock ledge) across the display
    static func perchLocations(for screen: NSScreen, windowFrame: NSRect) -> [CGPoint] {
        let bounds = walkableBounds(windowFrame: windowFrame, screen: screen)
        let inset: CGFloat = 28
        return [
            CGPoint(x: bounds.maxX - inset, y: bounds.minY + inset), // Bottom-Right Dock area
            CGPoint(x: bounds.minX + inset, y: bounds.minY + inset), // Bottom-Left
            CGPoint(x: bounds.maxX - inset, y: bounds.maxY - inset), // Top-Right menu ledge
            CGPoint(x: bounds.minX + inset, y: bounds.maxY - inset)  // Top-Left Apple logo area
        ]
    }
}

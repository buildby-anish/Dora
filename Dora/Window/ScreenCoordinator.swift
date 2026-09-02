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
}

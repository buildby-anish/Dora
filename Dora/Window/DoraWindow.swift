//
//  DoraWindow.swift
//  Dora
//
//  A borderless, transparent, always-on-top window that hosts Dora's
//  SpriteKit scene. This is the "desktop overlay" surface.
//
//  Important macOS limitation (documented here rather than glossed
//  over): AppKit windows are rectangular. True per-pixel click-through
//  for arbitrary transparent regions is not something NSWindow gives
//  you for free — `ignoresMouseEvents` is all-or-nothing for the whole
//  window. The approach used across this project is:
//
//    1. The window itself is fully transparent and click-through
//       is toggled window-wide via `ignoresMouseEvents`.
//    2. Dora is interactive by temporarily setting
//       `ignoresMouseEvents = false` while the cursor is within a
//       small bounding region around her sprite (handled later by
//       InteractionController via mouse-moved tracking), and `true`
//       the rest of the time so clicks pass through to whatever is
//       beneath the window elsewhere on screen.
//
//  Stage 1 ships the window with click-through OFF by default (so you
//  can confirm the window/scene render correctly and interact with
//  it), since InteractionController doesn't exist yet. This will be
//  revisited in Stage 4 (Mouse Interaction).
//

import AppKit

final class DoraWindow: NSWindow {

    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        configureAppearance()
        configureBehavior()
    }

    private func configureAppearance() {
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        titlebarAppearsTransparent = true
        titleVisibility = .hidden
    }

    private func configureBehavior() {
        // Float above normal windows, but not above things like the
        // screen saver or lock screen.
        level = .floating

        // Visible across every Space, including full-screen apps'
        // Spaces, and doesn't get its own Mission Control space.
        collectionBehavior = [
            .canJoinAllSpaces,
            .stationary,
            .fullScreenAuxiliary,
            .ignoresCycle
        ]

        isMovableByWindowBackground = false
        isReleasedWhenClosed = false

        // Click-through is ENABLED by default so the entire desktop is accessible.
        // InteractionController will selectively disable this when hovering near the cat.
        ignoresMouseEvents = true
        animationBehavior = .none
        sharingType = .readOnly
    }

    // Borderless windows normally can't become key/main, which would
    // prevent mouse-down events from reaching the content view. Dora
    // needs to receive mouse events for interaction (hover/click/drag
    // in later stages), so both are opted into here.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Smoothly transitions the desktop overlay visibility
    func smoothFadeIn(duration: TimeInterval = 0.3) {
        alphaValue = 0.0
        orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().alphaValue = 1.0
        }
    }

    func smoothFadeOut(duration: TimeInterval = 0.25, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().alphaValue = 0.0
        }, completionHandler: {
            completion?()
        })
    }
}

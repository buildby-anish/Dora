//
//  WindowController.swift
//  Dora
//
//  Builds the DoraWindow, hosts an SKView sized to the screen, and
//  presents DoraScene inside it. This is the seam between "AppKit
//  window plumbing" and "SpriteKit character rendering" — later
//  systems (MovementController, InteractionController, etc.) talk to
//  DoraScene, not to this class.
//

import AppKit
import SpriteKit

final class WindowController: NSWindowController {

    let skView: SKView
    let scene: DoraScene
    var doraWindow: DoraWindow? { window as? DoraWindow }

    init(screen: NSScreen) {
        let frame = ScreenCoordinator.fullFrame(for: screen)

        let window = DoraWindow(contentRect: frame)

        let view = SKView(frame: NSRect(origin: .zero, size: frame.size))
        view.allowsTransparency = true
        view.preferredFramesPerSecond = 120
        view.ignoresSiblingOrder = true
        view.shouldCullNonVisibleNodes = true

        #if DEBUG
        view.showsFPS = false
        view.showsNodeCount = false
        #endif

        let doraScene = DoraScene(size: frame.size)
        doraScene.scaleMode = .resizeFill
        doraScene.backgroundColor = .clear

        self.skView = view
        self.scene = doraScene

        super.init(window: window)

        window.contentView = view
        view.presentScene(doraScene)
    }

    required init?(coder: NSCoder) {
        fatalError("DoraWindowController does not support NSCoding")
    }

    func showWindow() {
        guard let window else { return }
        window.setFrame(ScreenCoordinator.fullFrame(for: ScreenCoordinator.primaryScreen()), display: true)
        window.orderFrontRegardless()
    }

    /// Re-aligns the window and scene when display resolution or multi-monitor arrangement changes
    func reconfigureForScreen(_ screen: NSScreen) {
        let frame = ScreenCoordinator.fullFrame(for: screen)
        window?.setFrame(frame, display: true)
        skView.frame = NSRect(origin: .zero, size: frame.size)
        scene.size = frame.size
    }

    func closeWindow() {
        window?.close()
    }
}

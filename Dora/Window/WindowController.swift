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
        // Stage 1 has almost nothing on screen; debug stats are handy
        // during bring-up and cheap to leave in for now. These should
        // be gated behind a debug build flag before shipping.
        #if DEBUG
        view.showsFPS = true
        view.showsNodeCount = true
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

    func closeWindow() {
        window?.close()
    }
}

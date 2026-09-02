//
//  DoraScene.swift
//  Dora
//
//  The SpriteKit scene that fills the transparent overlay window.
//  Stage 1 responsibility: render nothing but Dora's placeholder body
//  near the bottom of the screen. Movement, behavior, and interaction
//  systems attach to this scene in later stages — it should stay a
//  thin container, not accumulate game logic itself.
//

import SpriteKit

final class DoraScene: SKScene {

    private(set) var dora: DoraCharacter?

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        anchorPoint = .zero
        scaleMode = .resizeFill

        placeDoraNearBottom()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Keep Dora roughly anchored to the bottom of the screen if
        // the window/scene is resized (e.g. display resolution
        // change). Later stages with real movement will replace this
        // with boundary-aware repositioning via MovementController.
        guard let dora else { return }
        let groundY = dora.size.height / 2 + Self.groundInset
        dora.position = CGPoint(x: dora.position.x, y: groundY)
    }

    private static let groundInset: CGFloat = 24

    private func placeDoraNearBottom() {
        let character = DoraCharacter()
        character.position = CGPoint(
            x: size.width * 0.5,
            y: character.size.height / 2 + Self.groundInset
        )
        addChild(character)
        self.dora = character
    }
}

//
//  DoraScene.swift
//  Dora
//
//  The SpriteKit scene that fills the transparent overlay window.
//  Stays a thin container: places Dora, computes her walkable
//  boundary from the real screen, and drives MovementController once
//  per frame. Real mood/battery/time-driven behavior still doesn't
//  exist yet — that's BehaviorEngine, Stage 5 — so for now
//  MovementController is making its own simple idle/walk/sit
//  decisions, and this scene's only job is to keep it supplied with
//  accurate timing and boundaries.
//
//  Deviation from the Stage 2 plan, noted per the project's "explain
//  before changing" rule: Stage 2 left a DEBUG-only animation demo
//  here that cycled through all 12 states on a timer, with a note
//  that it would be removed once BehaviorEngine (Stage 5) existed to
//  drive real state changes. MovementController now drives idle/walk/
//  sit for real, two stages earlier than planned — leaving the demo
//  in would fight it for control of the same animations (both calling
//  `character.play(...)` on independent timers), so it's removed now
//  rather than at Stage 5 as originally noted. Sleep/wake/thinking/
//  happy/concerned/charging/celebrate still have no driver until
//  BehaviorEngine and the sensor stages exist — they remain reachable
//  via `DoraCharacter.play(_:)` for whoever calls it next.
//

import AppKit
import SpriteKit

final class DoraScene: SKScene {

    private(set) var dora: DoraCharacter?
    private var movementController: MovementController?
    private var lastUpdateTime: TimeInterval?

    /// Caps the delta passed to MovementController for any single
    /// frame. Without this, a stalled frame (app backgrounded, display
    /// sleep, breakpoint during debugging) would hand MovementController
    /// a huge deltaTime on the next frame, which — multiplied by
    /// movementSpeed — would make Dora jump a large distance in one
    /// step. That's exactly the "teleportation" the movement spec says
    /// to avoid, so it's prevented at the timing layer rather than
    /// trusted to position-clamping alone.
    private static let maxDeltaTime: TimeInterval = 0.25
    private static let defaultGroundInset: CGFloat = 24

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        anchorPoint = .zero
        scaleMode = .resizeFill

        let character = placeDoraNearBottom()
        let bounds = currentWalkableBounds()
        movementController = MovementController(
            character: character,
            bounds: bounds,
            groundInset: Self.defaultGroundInset
        )
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        movementController?.updateBounds(currentWalkableBounds())
    }

    override func update(_ currentTime: TimeInterval) {
        defer { lastUpdateTime = currentTime }
        guard let lastUpdateTime else { return }

        let rawDelta = currentTime - lastUpdateTime
        let deltaTime = min(max(rawDelta, 0), Self.maxDeltaTime)
        movementController?.update(deltaTime: deltaTime)
    }

    @discardableResult
    private func placeDoraNearBottom() -> DoraCharacter {
        let character = DoraCharacter()
        // Placed at a reasonable starting x; MovementController
        // clamps this into the real walkable bounds (and sets the
        // correct ground y) immediately in its initializer, so this
        // is only ever a starting guess, never Dora's final position.
        character.position = CGPoint(x: size.width * 0.5, y: 0)
        addChild(character)
        self.dora = character
        return character
    }

    /// Dora's allowed roaming rectangle, in this scene's coordinate
    /// space, accounting for the Dock and menu bar. Falls back to the
    /// full scene frame (with no Dock/menu-bar awareness) if the
    /// scene isn't attached to a real window/screen yet — this should
    /// only happen very briefly during setup, if at all.
    private func currentWalkableBounds() -> CGRect {
        guard let window = view?.window, let screen = window.screen else {
            return CGRect(origin: .zero, size: size)
        }
        return ScreenCoordinator.walkableBounds(windowFrame: window.frame, screen: screen)
    }
}

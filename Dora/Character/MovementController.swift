//
//  MovementController.swift
//  Dora
//
//  Deterministic autonomous movement. Owns exactly the "movement
//  data" the spec calls for — current position, target position,
//  movement speed, facing direction — and a small state machine
//  (idle / walking / sitting) that decides, on its own, when Dora
//  should walk somewhere, sit for a while, or just stay put.
//
//  This is intentionally simple, weighted-random decision-making, not
//  a stand-in for BehaviorEngine (Stage 5). Once BehaviorEngine exists
//  it will own the "should Dora walk/sit/sleep right now" decision
//  based on mood/battery/time/etc., and call into this controller to
//  execute that decision (e.g. `beginWalking(toward:)`); the
//  random-choice logic below is scoped to be easy to delete or
//  demote to "what happens when BehaviorEngine has no strong opinion"
//  at that point, without changing this file's public surface.
//
//  MovementController never touches window/screen APIs directly — it
//  is handed a walkable CGRect (from ScreenCoordinator, via DoraScene)
//  and works entirely in that coordinate space. It also never depends
//  on the LLM or any AI system, per the architecture rules: movement
//  is 100% deterministic.
//

import CoreGraphics
import Foundation

enum MovementState {
    case idle
    case walking
    case sitting
}

enum FacingDirection {
    case left
    case right
}

final class MovementController {

    private(set) var state: MovementState = .idle
    private(set) var currentPosition: CGPoint
    private(set) var targetPosition: CGPoint?
    private(set) var facingDirection: FacingDirection = .right

    /// Points per second. Public/mutable so a future Settings screen
    /// (Stage 20, "Animation activity") can tune it without needing
    /// new API here.
    var movementSpeed: CGFloat

    private weak var character: DoraCharacter?
    private var bounds: CGRect
    private var groundY: CGFloat
    private let groundInset: CGFloat

    /// How long the current idle/sitting state has lasted, and how
    /// long it's allowed to last before a new decision is made.
    private var stateTimer: TimeInterval = 0
    private var nextDecisionTime: TimeInterval

    /// Destinations closer than this aren't worth "walking" to — they'd
    /// produce a barely-visible flicker of motion. Below this distance
    /// a decision to walk instead nudges to a screen edge.
    private static let minimumWalkDistance: CGFloat = 40

    init(
        character: DoraCharacter,
        bounds: CGRect,
        groundInset: CGFloat = 24,
        movementSpeed: CGFloat = 90
    ) {
        self.character = character
        self.bounds = bounds
        self.groundInset = groundInset
        self.movementSpeed = movementSpeed
        self.groundY = bounds.minY + groundInset + character.size.height / 2
        self.nextDecisionTime = Self.randomIdleDuration()

        let halfWidth = character.size.width / 2
        let minX = bounds.minX + halfWidth
        let maxX = max(minX, bounds.maxX - halfWidth)
        let clampedX = min(max(character.position.x, minX), maxX)
        let startPosition = CGPoint(x: clampedX, y: groundY)

        self.currentPosition = startPosition
        character.position = startPosition
        character.play(.idle)
    }

    /// Called whenever the walkable area changes (screen resize,
    /// future multi-monitor switch). Keeps Dora — and any in-flight
    /// destination — inside the new bounds rather than letting her
    /// end up stranded off-screen or walking toward a point that no
    /// longer exists.
    func updateBounds(_ newBounds: CGRect) {
        bounds = newBounds
        guard let character else { return }

        let halfWidth = character.size.width / 2
        let minX = bounds.minX + halfWidth
        let maxX = max(minX, bounds.maxX - halfWidth)

        groundY = bounds.minY + groundInset + character.size.height / 2

        let clampedX = min(max(currentPosition.x, minX), maxX)
        currentPosition = CGPoint(x: clampedX, y: groundY)
        character.position = currentPosition

        if let target = targetPosition {
            let clampedTargetX = min(max(target.x, minX), maxX)
            targetPosition = CGPoint(x: clampedTargetX, y: groundY)
        }
    }

    /// Advances the state machine by `deltaTime` seconds. Call this
    /// once per frame (e.g. from `SKScene.update(_:)`); the caller is
    /// responsible for clamping `deltaTime` to something sane (see
    /// `DoraScene`) so a stalled frame (app backgrounded, machine
    /// asleep) doesn't cause Dora to jump — "avoid teleportation"
    /// applies to time gaps, not just to how position is written.
    func update(deltaTime: TimeInterval) {
        guard let character else { return }

        switch state {
        case .idle, .sitting:
            stateTimer += deltaTime
            guard stateTimer >= nextDecisionTime else { return }
            stateTimer = 0
            makeNextDecision(character: character)

        case .walking:
            stepTowardTarget(character: character, deltaTime: deltaTime)
        }
    }

    // MARK: - Decisions

    private func makeNextDecision(character: DoraCharacter) {
        if state == .sitting {
            // Stand up first, then make a fresh decision shortly
            // after — mirrors the flow diagram's
            // sitting → (later) idle → choose destination, rather
            // than jumping straight from sitting into a new walk.
            state = .idle
            character.play(.idle)
            nextDecisionTime = Self.shortIdleBeat()
            return
        }

        let roll = Double.random(in: 0..<1)
        switch roll {
        case ..<0.55:
            beginWalking(character: character)
        case 0.55..<0.75:
            beginSitting(character: character)
        default:
            // Explicitly "occasionally remain still": re-roll the
            // idle timer instead of doing anything.
            nextDecisionTime = Self.randomIdleDuration()
        }
    }

    private func beginWalking(character: DoraCharacter) {
        let halfWidth = character.size.width / 2
        let minX = bounds.minX + halfWidth
        let maxX = bounds.maxX - halfWidth

        guard maxX > minX else {
            // Screen/available width too narrow to roam meaningfully
            // (e.g. a tiny external display). Stay put rather than
            // fighting degenerate bounds.
            nextDecisionTime = Self.randomIdleDuration()
            return
        }

        var destinationX = CGFloat.random(in: minX...maxX)
        if abs(destinationX - currentPosition.x) < Self.minimumWalkDistance {
            destinationX = destinationX < currentPosition.x ? minX : maxX
        }

        let newFacing: FacingDirection = destinationX < currentPosition.x ? .left : .right
        facingDirection = newFacing
        targetPosition = CGPoint(x: destinationX, y: groundY)
        state = .walking

        // "Turn before changing direction": DoraCharacter mirrors
        // herself the instant a walk animation in the new facing
        // direction starts playing, so committing to the walk here —
        // before any position changes next frame — is the turn.
        character.play(newFacing == .left ? .walkLeft : .walkRight)
    }

    private func beginSitting(character: DoraCharacter) {
        state = .sitting
        character.play(.sit)
        nextDecisionTime = Self.randomSitDuration()
    }

    private func stepTowardTarget(character: DoraCharacter, deltaTime: TimeInterval) {
        guard let target = targetPosition else {
            // Defensive: walking state with no target shouldn't
            // happen, but fail safe into idle rather than getting
            // stuck.
            returnToIdle(character: character)
            return
        }

        let remaining = target.x - currentPosition.x
        let step = movementSpeed * CGFloat(deltaTime)

        if abs(remaining) <= step {
            currentPosition = target
            character.position = currentPosition
            targetPosition = nil
            returnToIdle(character: character)
            return
        }

        currentPosition.x += remaining > 0 ? step : -step
        currentPosition.y = groundY
        character.position = currentPosition
    }

    private func returnToIdle(character: DoraCharacter) {
        state = .idle
        character.play(.idle)
        nextDecisionTime = Self.randomIdleDuration()
    }

    // MARK: - Timing

    private static func randomIdleDuration() -> TimeInterval { .random(in: 3...8) }
    private static func randomSitDuration() -> TimeInterval { .random(in: 4...10) }
    private static func shortIdleBeat() -> TimeInterval { .random(in: 1...2) }
}

//
//  MovementController.swift
//  Dora
//
//  Manages cat location, smart roaming vs. corner sleep state.
//  - While user is actively working: Cat stays sleeping in the bottom corner beside the Dock.
//  - When user is idle for >= 1 minute: Cat wakes up, stretches, and walks out to roam near the screen center.
//  - When user resumes working: Cat walks back to her corner, curls up, and sleeps.
//

import CoreGraphics
import Foundation

enum CatBehaviorMode {
    case sleepingInCorner
    case wakingUp
    case walkingToCenter
    case roamingCenter
    case returningToCorner
}

enum MovementState {
    case idle
    case walking
    case sitting
    case sleeping
}

enum FacingDirection {
    case left
    case right
}

final class MovementController {

    private(set) var mode: CatBehaviorMode = .sleepingInCorner
    private(set) var state: MovementState = .sleeping
    private(set) var currentPosition: CGPoint
    private(set) var targetPosition: CGPoint?
    private(set) var facingDirection: FacingDirection = .left

    var movementSpeed: CGFloat

    private weak var character: DoraCharacter?
    private var bounds: CGRect
    private var groundY: CGFloat
    private let groundInset: CGFloat

    private var stateTimer: TimeInterval = 0
    private var nextDecisionTime: TimeInterval = 4.0

    private var homeCornerX: CGFloat {
        // Bottom right corner above dock
        max(bounds.minX + 50, bounds.maxX - 60)
    }

    private static let minimumWalkDistance: CGFloat = 40

    init(
        character: DoraCharacter,
        bounds: CGRect,
        groundInset: CGFloat = 24,
        movementSpeed: CGFloat = 85
    ) {
        self.character = character
        self.bounds = bounds
        self.groundInset = groundInset
        self.movementSpeed = movementSpeed
        self.groundY = bounds.minY + groundInset + character.size.height / 2

        let startPos = CGPoint(x: max(bounds.minX + 50, bounds.maxX - 60), y: groundY)
        self.currentPosition = startPos
        character.position = startPos
        self.facingDirection = .left
        character.xScale = -1

        // Start sleeping in cozy corner by default while user works
        self.mode = .sleepingInCorner
        self.state = .sleeping
        character.play(.sleep)
    }

    func updateBounds(_ newBounds: CGRect) {
        bounds = newBounds
        groundY = bounds.minY + groundInset + (character?.size.height ?? 75) / 2

        let halfWidth = (character?.size.width ?? 80) / 2
        let minX = bounds.minX + halfWidth
        let maxX = max(minX, bounds.maxX - halfWidth)

        let clampedX = min(max(currentPosition.x, minX), maxX)
        currentPosition = CGPoint(x: clampedX, y: groundY)
        character?.position = currentPosition

        if let target = targetPosition {
            let clampedTargetX = min(max(target.x, minX), maxX)
            targetPosition = CGPoint(x: clampedTargetX, y: groundY)
        }
    }

    func update(deltaTime: TimeInterval) {
        guard let character = character else { return }

        switch state {
        case .sleeping:
            // Just maintain sleep in corner
            break

        case .idle, .sitting:
            stateTimer += deltaTime
            guard stateTimer >= nextDecisionTime else { return }
            stateTimer = 0
            makeRoamingDecision(character: character)

        case .walking:
            stepTowardTarget(character: character, deltaTime: deltaTime)
        }
    }

    // MARK: - User Activity State Transitions

    func handleUserBecameIdle() {
        guard let character = character else { return }
        guard mode == .sleepingInCorner else { return }

        mode = .wakingUp
        character.play(.wake) { [weak self, weak character] in
            guard let self = self, let character = character else { return }
            // Stretch after waking up
            character.play(.stretch) { [weak self, weak character] in
                guard let self = self, let character = character else { return }
                self.mode = .walkingToCenter
                self.walkTowardCenter(character: character)
            }
        }
    }

    func handleUserResumedWork() {
        guard let character = character else { return }
        // If already sleeping in corner or returning, nothing to do
        guard mode != .sleepingInCorner && mode != .returningToCorner else { return }

        mode = .returningToCorner
        walkTowardCorner(character: character)
    }

    private func walkTowardCenter(character: DoraCharacter) {
        let centerMinX = bounds.midX - 180
        let centerMaxX = bounds.midX + 180
        let destX = CGFloat.random(in: centerMinX...centerMaxX)

        beginWalk(to: destX, character: character)
    }

    private func walkTowardCorner(character: DoraCharacter) {
        let destX = homeCornerX
        beginWalk(to: destX, character: character)
    }

    private func beginWalk(to destinationX: CGFloat, character: DoraCharacter) {
        let halfWidth = character.size.width / 2
        let minX = bounds.minX + halfWidth
        let maxX = bounds.maxX - halfWidth
        let clampedX = min(max(destinationX, minX), maxX)

        let newFacing: FacingDirection = clampedX < currentPosition.x ? .left : .right
        facingDirection = newFacing
        targetPosition = CGPoint(x: clampedX, y: groundY)
        state = .walking

        character.play(newFacing == .left ? .walkLeft : .walkRight)
    }

    private func makeRoamingDecision(character: DoraCharacter) {
        guard mode == .roamingCenter else { return }

        if state == .sitting {
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 2...4)
            return
        }

        let roll = Double.random(in: 0..<1)
        switch roll {
        case ..<0.45:
            // Walk to a new center spot
            let centerMinX = max(bounds.minX + 100, bounds.midX - 240)
            let centerMaxX = min(bounds.maxX - 100, bounds.midX + 240)
            var destX = CGFloat.random(in: centerMinX...centerMaxX)
            if abs(destX - currentPosition.x) < Self.minimumWalkDistance {
                destX = destX < currentPosition.x ? centerMinX : centerMaxX
            }
            beginWalk(to: destX, character: character)

        case 0.45..<0.65:
            // Sit in loaf pose
            state = .sitting
            character.play(.sit)
            nextDecisionTime = .random(in: 5...10)

        case 0.65..<0.80:
            // Grooming or yawning
            if Bool.random() {
                character.play(.groom) { [weak self] in
                    self?.state = .idle
                    self?.character?.play(.idle)
                }
            } else {
                character.play(.yawn) { [weak self] in
                    self?.state = .idle
                    self?.character?.play(.idle)
                }
            }
            nextDecisionTime = .random(in: 4...8)

        default:
            // Idle stay put
            character.play(.idle)
            nextDecisionTime = .random(in: 3...7)
        }
    }

    private func stepTowardTarget(character: DoraCharacter, deltaTime: TimeInterval) {
        guard let target = targetPosition else {
            returnToIdleOrSleep(character: character)
            return
        }

        let remaining = target.x - currentPosition.x
        let step = movementSpeed * CGFloat(deltaTime)

        if abs(remaining) <= step {
            currentPosition = target
            character.position = currentPosition
            targetPosition = nil
            handleReachedTarget(character: character)
            return
        }

        currentPosition.x += remaining > 0 ? step : -step
        currentPosition.y = groundY
        character.position = currentPosition
    }

    private func handleReachedTarget(character: DoraCharacter) {
        switch mode {
        case .walkingToCenter:
            mode = .roamingCenter
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 3...6)

        case .returningToCorner:
            mode = .sleepingInCorner
            state = .sleeping
            character.play(.sit)
            // Sits down then curls into deep sleep
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self, weak character] in
                guard let self = self, self.mode == .sleepingInCorner else { return }
                character?.play(.sleep)
            }

        case .roamingCenter:
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 3...7)

        default:
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 3...7)
        }
    }

    private func returnToIdleOrSleep(character: DoraCharacter) {
        if mode == .sleepingInCorner {
            state = .sleeping
            character.play(.sleep)
        } else {
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 3...6)
        }
    }
}

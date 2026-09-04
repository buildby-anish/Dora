//
//  MovementController.swift
//  Dora
//
//  Manages full-screen autonomous cat behaviors, 4-corner sleeping,
//  graceful 2D leaping/walking, and pick-and-drop repositioning.
//
//  - While user is actively working: Dora sits and sleeps in any screen corner.
//  - When user is idle for >= 1 minute: Dora wakes up, explores the entire screen,
//    leaps to elevated spots, pounces, grooms, loafs, and does random cat behaviors.
//  - Drag & Drop (Pick & Drop): User can pick up Dora and place her anywhere.
//

import CoreGraphics
import Foundation

enum CatBehaviorMode {
    case sleepingInCorner
    case wakingUp
    case fullScreenRoaming
    case returningToCorner
    case pickedUpByMouse
}

enum MovementState {
    case idle
    case walking
    case leaping
    case sitting
    case sleeping
    case dragged
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
    private var isUserIdle: Bool = false

    // Leap Physics State
    private var leapStartPos: CGPoint = .zero
    private var leapTargetPos: CGPoint = .zero
    private var leapProgress: CGFloat = 0.0
    private var leapDuration: TimeInterval = 0.8
    private var leapPeakHeight: CGFloat = 80

    private var stateTimer: TimeInterval = 0
    private var nextDecisionTime: TimeInterval = 4.0

    private static let margin: CGFloat = 32

    init(
        character: DoraCharacter,
        bounds: CGRect,
        groundInset: CGFloat = 16,
        movementSpeed: CGFloat = 78
    ) {
        self.character = character
        self.bounds = bounds
        self.movementSpeed = movementSpeed

        // Start in bottom-right corner cozy sleep
        let startPos = CGPoint(x: bounds.maxX - Self.margin, y: bounds.minY + groundInset + character.size.height / 2)
        self.currentPosition = startPos
        character.position = startPos
        self.facingDirection = .left
        character.xScale = -1

        self.mode = .sleepingInCorner
        self.state = .sleeping
        character.play(.sleep)
    }

    func updateBounds(_ newBounds: CGRect) {
        bounds = newBounds
        let clamped = clampToScreen(currentPosition)
        currentPosition = clamped
        character?.position = clamped
    }

    func update(deltaTime: TimeInterval) {
        guard let character = character else { return }

        switch state {
        case .dragged, .sleeping:
            break

        case .idle, .sitting:
            stateTimer += deltaTime
            guard stateTimer >= nextDecisionTime else { return }
            stateTimer = 0
            makeRoamingDecision(character: character)

        case .walking:
            stepWalking(character: character, deltaTime: deltaTime)

        case .leaping:
            stepLeaping(character: character, deltaTime: deltaTime)
        }
    }

    // MARK: - Drag & Drop (Pick & Drop)

    func setPickedUp(_ pickedUp: Bool) {
        guard let character = character else { return }

        if pickedUp {
            mode = .pickedUpByMouse
            state = .dragged
            targetPosition = nil
            character.play(.pickedUp)
        } else {
            // Dropped onto screen
            state = .idle
            character.play(.landing) { [weak self, weak character] in
                guard let self = self, let character = character else { return }
                if self.isUserIdle {
                    self.mode = .fullScreenRoaming
                    self.state = .idle
                    character.play(.idle)
                    self.nextDecisionTime = .random(in: 2...4)
                } else {
                    // Stay sitting or sleeping where user put her
                    self.mode = .sleepingInCorner
                    self.state = .sitting
                    character.play(.sit)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak character] in
                        guard let self = self, self.mode == .sleepingInCorner else { return }
                        self.state = .sleeping
                        character?.play(.sleep)
                    }
                }
            }
        }
    }

    func updateDraggedPosition(_ newScreenPos: CGPoint) {
        let clamped = clampToScreen(newScreenPos)
        currentPosition = clamped
        character?.position = clamped
    }

    // MARK: - User Activity State Transitions

    func handleUserBecameIdle() {
        isUserIdle = true
        guard let character = character else { return }
        guard mode == .sleepingInCorner else { return }

        mode = .wakingUp
        character.play(.wake) { [weak self, weak character] in
            guard let self = self, let character = character else { return }
            character.play(.stretch) { [weak self, weak character] in
                guard let self = self, let character = character else { return }
                self.mode = .fullScreenRoaming
                self.state = .idle
                character.play(.idle)
                self.nextDecisionTime = .random(in: 1...3)
            }
        }
    }

    func handleUserResumedWork() {
        isUserIdle = false
        guard let character = character else { return }
        guard mode != .sleepingInCorner && mode != .returningToCorner && mode != .pickedUpByMouse else { return }

        mode = .returningToCorner
        goToBestCorner(character: character)
    }

    // MARK: - 4-Corner Sleep Selection

    private func allCorners() -> [CGPoint] {
        let padX = character?.size.width ?? 48
        let padY = character?.size.height ?? 44
        let minX = bounds.minX + padX / 2 + 10
        let maxX = bounds.maxX - padX / 2 - 10
        let minY = bounds.minY + padY / 2 + 10
        let maxY = bounds.maxY - padY / 2 - 20

        return [
            CGPoint(x: maxX, y: minY), // Bottom-Right
            CGPoint(x: minX, y: minY), // Bottom-Left
            CGPoint(x: maxX, y: maxY), // Top-Right
            CGPoint(x: minX, y: maxY)  // Top-Left
        ]
    }

    private func goToBestCorner(character: DoraCharacter) {
        let corners = allCorners()
        // Pick closest corner or random corner
        let targetCorner = corners.min(by: { distance(from: currentPosition, to: $0) < distance(from: currentPosition, to: $1) }) ?? corners[0]

        // If far away, perform a graceful leap or walk
        let dist = distance(from: currentPosition, to: targetCorner)
        if dist > 280 {
            beginLeap(to: targetCorner, character: character)
        } else {
            beginWalk(to: targetCorner, character: character)
        }
    }

    // MARK: - Full-Screen Roaming Decisions

    private func makeRoamingDecision(character: DoraCharacter) {
        guard mode == .fullScreenRoaming else { return }

        if state == .sitting {
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 2...4)
            return
        }

        let roll = Double.random(in: 0..<1.0)
        switch roll {
        case ..<0.28:
            // 2D Walk to a nearby area across the screen
            let randPos = getRandomScreenPoint()
            beginWalk(to: randPos, character: character)

        case 0.28..<0.52:
            // Graceful leap / jump across the screen
            let randPos = getRandomScreenPoint()
            beginLeap(to: randPos, character: character)

        case 0.52..<0.66:
            // Cat Butt Wiggle & Pounce!
            state = .idle
            character.play(.pounce) { [weak self] in
                self?.state = .idle
                self?.character?.play(.idle)
            }
            nextDecisionTime = .random(in: 3...6)

        case 0.66..<0.78:
            // Curious head tilt and paw tapping
            state = .idle
            character.play(.curious) { [weak self] in
                self?.state = .idle
                self?.character?.play(.idle)
            }
            nextDecisionTime = .random(in: 4...7)

        case 0.78..<0.88:
            // Face grooming or yawning
            state = .idle
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

        case 0.88..<0.94:
            // Cozy loaf sitting
            state = .sitting
            character.play(.sit)
            nextDecisionTime = .random(in: 6...12)

        default:
            // Idle gazing / breathing
            character.play(.idle)
            nextDecisionTime = .random(in: 3...6)
        }
    }

    // MARK: - Walking Mechanics

    private func beginWalk(to destination: CGPoint, character: DoraCharacter) {
        let clamped = clampToScreen(destination)
        targetPosition = clamped
        state = .walking

        let newFacing: FacingDirection = clamped.x < currentPosition.x ? .left : .right
        facingDirection = newFacing
        character.play(newFacing == .left ? .walkLeft : .walkRight)
    }

    private func stepWalking(character: DoraCharacter, deltaTime: TimeInterval) {
        guard let target = targetPosition else {
            handleReachedDestination(character: character)
            return
        }

        let dx = target.x - currentPosition.x
        let dy = target.y - currentPosition.y
        let dist = hypot(dx, dy)
        let step = movementSpeed * CGFloat(deltaTime)

        if dist <= step {
            currentPosition = target
            character.position = currentPosition
            targetPosition = nil
            handleReachedDestination(character: character)
            return
        }

        let angle = atan2(dy, dx)
        currentPosition.x += cos(angle) * step
        currentPosition.y += sin(angle) * step
        character.position = currentPosition
    }

    // MARK: - Leaping Mechanics

    private func beginLeap(to destination: CGPoint, character: DoraCharacter) {
        let clamped = clampToScreen(destination)
        leapStartPos = currentPosition
        leapTargetPos = clamped
        leapProgress = 0.0

        let dist = distance(from: leapStartPos, to: leapTargetPos)
        leapDuration = max(0.55, min(1.2, Double(dist / 260)))
        leapPeakHeight = max(40, min(110, dist * 0.32))

        let newFacing: FacingDirection = clamped.x < currentPosition.x ? .left : .right
        facingDirection = newFacing
        character.xScale = newFacing == .left ? -1 : 1

        state = .leaping
        character.play(.jump)
    }

    private func stepLeaping(character: DoraCharacter, deltaTime: TimeInterval) {
        leapProgress += CGFloat(deltaTime / leapDuration)

        if leapProgress >= 1.0 {
            leapProgress = 1.0
            currentPosition = leapTargetPos
            character.position = currentPosition
            state = .idle

            character.play(.landing) { [weak self, weak character] in
                guard let self = self, let character = character else { return }
                self.handleReachedDestination(character: character)
            }
            return
        }

        // Parabolic arc interpolation: y = 4 * h * t * (1 - t)
        let t = leapProgress
        let currentX = leapStartPos.x + (leapTargetPos.x - leapStartPos.x) * t
        let linearY = leapStartPos.y + (leapTargetPos.y - leapStartPos.y) * t
        let arcY = 4.0 * leapPeakHeight * t * (1.0 - t)

        currentPosition = CGPoint(x: currentX, y: linearY + arcY)
        character.position = currentPosition
    }

    // MARK: - Destination Arrival Handler

    private func handleReachedDestination(character: DoraCharacter) {
        switch mode {
        case .returningToCorner:
            mode = .sleepingInCorner
            state = .sleeping
            character.play(.sit)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self, weak character] in
                guard let self = self, self.mode == .sleepingInCorner else { return }
                character?.play(.sleep)
            }

        case .fullScreenRoaming:
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 2...5)

        default:
            state = .idle
            character.play(.idle)
            nextDecisionTime = .random(in: 3...6)
        }
    }

    // MARK: - Geometry Utilities

    private func getRandomScreenPoint() -> CGPoint {
        let padX = (character?.size.width ?? 48) / 2 + 20
        let padY = (character?.size.height ?? 44) / 2 + 20
        let minX = bounds.minX + padX
        let maxX = bounds.maxX - padX
        let minY = bounds.minY + padY
        let maxY = bounds.maxY - padY

        return CGPoint(
            x: CGFloat.random(in: minX...maxX),
            y: CGFloat.random(in: minY...maxY)
        )
    }

    private func clampToScreen(_ point: CGPoint) -> CGPoint {
        let padX = (character?.size.width ?? 48) / 2 + 8
        let padY = (character?.size.height ?? 44) / 2 + 8
        let minX = bounds.minX + padX
        let maxX = bounds.maxX - padX
        let minY = bounds.minY + padY
        let maxY = bounds.maxY - padY

        return CGPoint(
            x: min(max(point.x, minX), maxX),
            y: min(max(point.y, minY), maxY)
        )
    }

    private func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        hypot(to.x - from.x, to.y - from.y)
    }
}


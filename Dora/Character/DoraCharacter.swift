//
//  DoraCharacter.swift
//  Dora
//
//  Dora's visual root node. Owns two visual layers and shows exactly
//  one at a time:
//
//    1. `spriteNode` — a plain SKSpriteNode that AnimationManager
//       drives with real sprite-sheet frames, once they exist.
//    2. A placeholder layer (vector shapes) with its own hand-built
//       reaction for every single DoraAnimation case, so Dora is
//       fully functional and visually distinguishable in every state
//       before any final art exists.
//
//  Everything outside this file only depends on `size`, `position`,
//  and `play(_:)` — so replacing/adding real art later, or reworking
//  the placeholder look, never requires touching DoraScene,
//  MovementController, or BehaviorEngine.
//

import AppKit
import SpriteKit

final class DoraCharacter: SKNode {

    /// Nominal footprint of the character, used for placement and
    /// (later) hit-testing / hover detection.
    let size: CGSize

    private(set) var currentAnimation: DoraAnimation = .idle

    private let animationManager: AnimationManager

    private let spriteNode: SKSpriteNode
    private let placeholderBody: SKShapeNode
    private let placeholderLeftEye: SKShapeNode
    private let placeholderRightEye: SKShapeNode

    private static let realArtKey = "doraRealArt"
    private static let placeholderKey = "doraPlaceholder"

    init(animationManager: AnimationManager = .shared) {
        let bodySize = CGSize(width: 72, height: 84)
        self.size = bodySize
        self.animationManager = animationManager

        spriteNode = SKSpriteNode(color: .clear, size: bodySize)
        spriteNode.isHidden = true

        placeholderBody = SKShapeNode(rectOf: bodySize, cornerRadius: bodySize.width * 0.35)
        placeholderBody.strokeColor = .clear
        placeholderBody.fillColor = .systemTeal
        placeholderBody.zPosition = 0

        let eyeSize = CGSize(width: 10, height: 14)
        placeholderLeftEye = SKShapeNode(ellipseOf: eyeSize)
        placeholderRightEye = SKShapeNode(ellipseOf: eyeSize)
        for eye in [placeholderLeftEye, placeholderRightEye] {
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.zPosition = 1
        }
        placeholderLeftEye.position = CGPoint(x: -14, y: 10)
        placeholderRightEye.position = CGPoint(x: 14, y: 10)

        super.init()

        addChild(spriteNode)
        addChild(placeholderBody)
        addChild(placeholderLeftEye)
        addChild(placeholderRightEye)

        play(.idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("DoraCharacter does not support NSCoding")
    }

    /// Plays `animation`, using real sprite-sheet frames if
    /// `Resources/DoraAssets/<atlasName>.atlas` exists, or a built-in
    /// placeholder reaction otherwise. Redundant calls (already
    /// playing this animation, no completion handler) are ignored so
    /// callers don't need to guard against repeatedly re-triggering
    /// the same state themselves — this also prevents animation
    /// conflicts from two systems requesting the same state back to
    /// back.
    func play(_ animation: DoraAnimation, frameDuration: TimeInterval? = nil, completion: (() -> Void)? = nil) {
        guard animation != currentAnimation || completion != nil else { return }
        currentAnimation = animation

        // walkLeft/walkRight share one atlas and one placeholder
        // reaction; direction is expressed by mirroring the whole
        // node rather than authoring separate assets.
        switch animation {
        case .walkLeft: xScale = -1
        case .walkRight: xScale = 1
        default: break
        }

        resetPlaceholderTransforms()

        let usedRealArt = animationManager.play(
            animation,
            on: spriteNode,
            frameDuration: frameDuration,
            key: Self.realArtKey,
            completion: completion
        )

        spriteNode.isHidden = !usedRealArt
        placeholderBody.isHidden = usedRealArt
        placeholderLeftEye.isHidden = usedRealArt
        placeholderRightEye.isHidden = usedRealArt

        if !usedRealArt {
            runPlaceholder(for: animation, completion: completion)
        }
    }

    // MARK: - Placeholder reactions

    private func resetPlaceholderTransforms() {
        placeholderBody.removeAction(forKey: Self.placeholderKey)
        placeholderLeftEye.removeAction(forKey: Self.placeholderKey)
        placeholderRightEye.removeAction(forKey: Self.placeholderKey)
        placeholderBody.setScale(1)
        placeholderBody.alpha = 1
        placeholderBody.zRotation = 0
        placeholderLeftEye.yScale = 1
        placeholderRightEye.yScale = 1
    }

    /// Stand-in reactions for every animation state while no real art
    /// exists yet, so each state is visually distinguishable during
    /// development rather than Dora looking frozen or identical
    /// regardless of mood. These are intentionally simple placeholder
    /// shapes/colors — nothing here is meant to be final art, and
    /// each is wholesale replaced the moment `AnimationManager` finds
    /// real frames for that state.
    private func runPlaceholder(for animation: DoraAnimation, completion: (() -> Void)?) {
        switch animation {
        case .idle:
            placeholderBody.fillColor = .systemTeal
            bob(placeholderBody, amount: 4, duration: 1.0)
            loopingBlink()

        case .blink:
            oneShotBlink(then: completion)

        case .walkLeft, .walkRight:
            placeholderBody.fillColor = .systemTeal
            rock(placeholderBody, degrees: 6, duration: 0.25)

        case .sit:
            placeholderBody.fillColor = .systemTeal
            placeholderBody.run(.scaleY(to: 0.85, duration: 0.2), withKey: Self.placeholderKey)

        case .sleep:
            placeholderBody.fillColor = NSColor.systemTeal.withAlphaComponent(0.7)
            placeholderLeftEye.yScale = 0.1
            placeholderRightEye.yScale = 0.1
            bob(placeholderBody, amount: 2, duration: 1.8)

        case .wake:
            placeholderLeftEye.yScale = 0.1
            placeholderRightEye.yScale = 0.1
            let openEyes = SKAction.run { [weak self] in
                self?.placeholderLeftEye.run(.scaleY(to: 1.0, duration: 0.15))
                self?.placeholderRightEye.run(.scaleY(to: 1.0, duration: 0.15))
            }
            let steps: [SKAction] = [.wait(forDuration: 0.2), openEyes, .wait(forDuration: 0.2)]
            let sequence = completion != nil
                ? SKAction.sequence(steps + [.run(completion!)])
                : SKAction.sequence(steps)
            placeholderBody.run(sequence, withKey: Self.placeholderKey)

        case .thinking:
            placeholderBody.fillColor = .systemIndigo
            let tiltUp = SKAction.rotate(toAngle: 0.08, duration: 0.6, shortestUnitArc: true)
            let tiltDown = SKAction.rotate(toAngle: -0.02, duration: 0.6, shortestUnitArc: true)
            placeholderBody.run(.repeatForever(.sequence([tiltUp, tiltDown])), withKey: Self.placeholderKey)

        case .happy:
            placeholderBody.fillColor = .systemYellow
            let up = SKAction.moveBy(x: 0, y: 10, duration: 0.15)
            up.timingMode = .easeOut
            let down = up.reversed()
            down.timingMode = .easeIn
            let bounce = SKAction.sequence([up, down])
            let action = completion != nil
                ? SKAction.sequence([bounce, bounce, .run(completion!)])
                : SKAction.repeatForever(bounce)
            placeholderBody.run(action, withKey: Self.placeholderKey)

        case .concerned:
            placeholderBody.fillColor = .systemOrange
            rock(placeholderBody, degrees: 3, duration: 0.15)

        case .charging:
            placeholderBody.fillColor = .systemGreen
            let pulse = SKAction.sequence([
                .fadeAlpha(to: 0.6, duration: 0.6),
                .fadeAlpha(to: 1.0, duration: 0.6)
            ])
            placeholderBody.run(.repeatForever(pulse), withKey: Self.placeholderKey)

        case .celebrate:
            placeholderBody.fillColor = .systemPink
            let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.5)
            let jump = SKAction.moveBy(x: 0, y: 16, duration: 0.25)
            let jumpBack = jump.reversed()
            let action = SKAction.group([spin, .sequence([jump, jumpBack])])
            let sequence = completion != nil
                ? SKAction.sequence([action, .run(completion!)])
                : action
            placeholderBody.run(sequence, withKey: Self.placeholderKey)
        }
    }

    private func bob(_ node: SKNode, amount: CGFloat, duration: TimeInterval) {
        let up = SKAction.moveBy(x: 0, y: amount, duration: duration)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        down.timingMode = .easeInEaseOut
        node.run(.repeatForever(.sequence([up, down])), withKey: Self.placeholderKey)
    }

    private func rock(_ node: SKNode, degrees: CGFloat, duration: TimeInterval) {
        let radians = degrees * .pi / 180
        let left = SKAction.rotate(toAngle: -radians, duration: duration, shortestUnitArc: true)
        let right = SKAction.rotate(toAngle: radians, duration: duration, shortestUnitArc: true)
        node.run(.repeatForever(.sequence([left, right])), withKey: Self.placeholderKey)
    }

    private func loopingBlink() {
        let close = SKAction.scaleY(to: 0.1, duration: 0.06)
        let open = SKAction.scaleY(to: 1.0, duration: 0.06)
        let blink = SKAction.sequence([.wait(forDuration: 2.5, withRange: 2.5), close, open])
        placeholderLeftEye.run(.repeatForever(blink), withKey: Self.placeholderKey)
        placeholderRightEye.run(.repeatForever(blink), withKey: Self.placeholderKey)
    }

    private func oneShotBlink(then completion: (() -> Void)?) {
        let close = SKAction.scaleY(to: 0.1, duration: 0.06)
        let open = SKAction.scaleY(to: 1.0, duration: 0.06)
        let sequence = completion != nil
            ? SKAction.sequence([close, open, .run(completion!)])
            : SKAction.sequence([close, open])
        placeholderLeftEye.run(sequence, withKey: Self.placeholderKey)
        placeholderRightEye.run(sequence, withKey: Self.placeholderKey)
    }
}

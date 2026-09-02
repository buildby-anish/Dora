//
//  DoraCharacter.swift
//  Dora
//
//  Dora's visual root node. Stage 1 has no final art, so this builds
//  a simple vector placeholder (a small rounded robot body with two
//  eyes) entirely out of SKShapeNodes. Later stages (Stage 2,
//  "Character architecture / Animation system / Fallback assets")
//  will introduce AnimationManager and texture-atlas-driven sprites;
//  this class is written so that swapping the placeholder body for a
//  real SKSpriteNode-based animated body later does not require
//  touching MovementController, BehaviorEngine, or anything outside
//  this file — everything else only depends on `DoraCharacter`'s
//  `position` and `size`.
//

import SpriteKit

final class DoraCharacter: SKNode {

    /// Nominal footprint of the character, used for placement and
    /// (later) hit-testing / hover detection.
    let size: CGSize

    private let body: SKShapeNode
    private let leftEye: SKShapeNode
    private let rightEye: SKShapeNode

    override init() {
        let bodySize = CGSize(width: 72, height: 84)
        self.size = bodySize

        body = SKShapeNode(
            rectOf: bodySize,
            cornerRadius: bodySize.width * 0.35
        )
        body.fillColor = NSColor.systemTeal
        body.strokeColor = NSColor.systemTeal.withAlphaComponent(0.6)
        body.lineWidth = 2
        body.zPosition = 0

        let eyeSize = CGSize(width: 10, height: 14)
        leftEye = SKShapeNode(ellipseOf: eyeSize)
        rightEye = SKShapeNode(ellipseOf: eyeSize)
        for eye in [leftEye, rightEye] {
            eye.fillColor = .black
            eye.strokeColor = .clear
            eye.zPosition = 1
        }
        leftEye.position = CGPoint(x: -14, y: 10)
        rightEye.position = CGPoint(x: 14, y: 10)

        super.init()

        addChild(body)
        addChild(leftEye)
        addChild(rightEye)

        runIdleAnimation()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("DoraCharacter does not support NSCoding")
    }

    /// A small looping bob + occasional blink so Stage 1 doesn't look
    /// like a static, dead image. This is a placeholder stand-in for
    /// AnimationManager, which arrives in Stage 2.
    private func runIdleAnimation() {
        let bobUp = SKAction.moveBy(x: 0, y: 4, duration: 1.0)
        bobUp.timingMode = .easeInEaseOut
        let bobDown = bobUp.reversed()
        let bob = SKAction.sequence([bobUp, bobDown])
        body.run(.repeatForever(bob))

        let blinkClose = SKAction.scaleY(to: 0.1, duration: 0.06)
        let blinkOpen = SKAction.scaleY(to: 1.0, duration: 0.06)
        let blink = SKAction.sequence([
            .wait(forDuration: 2.5, withRange: 2.5),
            blinkClose,
            blinkOpen
        ])
        leftEye.run(.repeatForever(blink))
        rightEye.run(.repeatForever(blink))
    }
}

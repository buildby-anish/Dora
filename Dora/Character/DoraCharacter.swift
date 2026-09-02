//
//  DoraCharacter.swift
//  Dora
//
//  Dora the Cat: A lifelike, fully animated procedural feline companion.
//  Features animated cat ears, expressive blinking eyes, twitching whiskers,
//  stepping paws, and a swishing tail with life-like feline animations:
//  - Idle, walking, loaf sitting
//  - Realistic sleeping with breathing and Zzz particles
//  - Cat morning stretch, face grooming, big cat yawn
//  - One-shot happy purring/pet reaction with heart sparkles
//

import AppKit
import SpriteKit

final class DoraCharacter: SKNode {

    /// Bounding size of the cat
    let size: CGSize

    private(set) var currentAnimation: DoraAnimation = .idle

    // MARK: - Cat Body & Feature Nodes
    private let catRootNode = SKNode()

    private let bodyNode: SKShapeNode
    private let chestFluffNode: SKShapeNode
    private let headNode: SKShapeNode
    private let leftEarNode: SKShapeNode
    private let rightEarNode: SKShapeNode
    private let leftInnerEarNode: SKShapeNode
    private let rightInnerEarNode: SKShapeNode

    private let leftEyeNode: SKShapeNode
    private let rightEyeNode: SKShapeNode
    private let leftPupilNode: SKShapeNode
    private let rightPupilNode: SKShapeNode
    private let leftHighlightNode: SKShapeNode
    private let rightHighlightNode: SKShapeNode

    private let noseNode: SKShapeNode
    private let mouthNode: SKShapeNode
    private let whiskersNode: SKShapeNode

    private let frontLeftPawNode: SKShapeNode
    private let frontRightPawNode: SKShapeNode
    private let backLeftPawNode: SKShapeNode
    private let backRightPawNode: SKShapeNode

    private let tailNode: SKShapeNode

    // Particle / Effect nodes
    private let effectsContainer = SKNode()

    private static let catAnimKey = "catAnimationAction"
    private static let tailAnimKey = "catTailAction"
    private static let blinkAnimKey = "catBlinkAction"
    private static let earAnimKey = "catEarAction"

    // Primary Cat Color Palette (Warm Ginger / Calico Cat)
    private static let furColor = NSColor(red: 0.98, green: 0.65, blue: 0.35, alpha: 1.0)
    private static let furShadowColor = NSColor(red: 0.88, green: 0.52, blue: 0.25, alpha: 1.0)
    private static let chestWhiteColor = NSColor(red: 0.98, green: 0.96, blue: 0.92, alpha: 1.0)
    private static let innerEarPink = NSColor(red: 0.98, green: 0.70, blue: 0.75, alpha: 1.0)
    private static let eyeGreen = NSColor(red: 0.25, green: 0.75, blue: 0.50, alpha: 1.0)
    private static let nosePink = NSColor(red: 0.95, green: 0.50, blue: 0.60, alpha: 1.0)

    init(animationManager: AnimationManager = .shared) {
        let catSize = CGSize(width: 80, height: 75)
        self.size = catSize

        // 1. Tail (Behind body)
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -24, y: -10))
        tailPath.addCurve(to: CGPoint(x: -42, y: 22), control1: CGPoint(x: -36, y: -6), control2: CGPoint(x: -46, y: 8))
        tailNode = SKShapeNode(path: tailPath)
        tailNode.strokeColor = Self.furShadowColor
        tailNode.lineWidth = 9
        tailNode.lineCap = .round
        tailNode.zPosition = -1

        // 2. Back Paws
        backLeftPawNode = SKShapeNode(ellipseOf: CGSize(width: 14, height: 10))
        backRightPawNode = SKShapeNode(ellipseOf: CGSize(width: 14, height: 10))
        for paw in [backLeftPawNode, backRightPawNode] {
            paw.fillColor = Self.chestWhiteColor
            paw.strokeColor = Self.furShadowColor.withAlphaComponent(0.4)
            paw.lineWidth = 1
            paw.zPosition = 0
        }
        backLeftPawNode.position = CGPoint(x: -18, y: -24)
        backRightPawNode.position = CGPoint(x: 18, y: -24)

        // 3. Body
        bodyNode = SKShapeNode(rectOf: CGSize(width: 58, height: 48), cornerRadius: 24)
        bodyNode.fillColor = Self.furColor
        bodyNode.strokeColor = Self.furShadowColor
        bodyNode.lineWidth = 2
        bodyNode.position = CGPoint(x: 0, y: -6)
        bodyNode.zPosition = 1

        // 4. White Chest Fluff
        chestFluffNode = SKShapeNode(ellipseOf: CGSize(width: 32, height: 28))
        chestFluffNode.fillColor = Self.chestWhiteColor
        chestFluffNode.strokeColor = .clear
        chestFluffNode.position = CGPoint(x: 0, y: -10)
        chestFluffNode.zPosition = 2

        // 5. Front Paws
        frontLeftPawNode = SKShapeNode(ellipseOf: CGSize(width: 13, height: 10))
        frontRightPawNode = SKShapeNode(ellipseOf: CGSize(width: 13, height: 10))
        for paw in [frontLeftPawNode, frontRightPawNode] {
            paw.fillColor = Self.chestWhiteColor
            paw.strokeColor = Self.furShadowColor.withAlphaComponent(0.4)
            paw.lineWidth = 1
            paw.zPosition = 3
        }
        frontLeftPawNode.position = CGPoint(x: -10, y: -25)
        frontRightPawNode.position = CGPoint(x: 10, y: -25)

        // 6. Head
        headNode = SKShapeNode(ellipseOf: CGSize(width: 54, height: 44))
        headNode.fillColor = Self.furColor
        headNode.strokeColor = Self.furShadowColor
        headNode.lineWidth = 2
        headNode.position = CGPoint(x: 0, y: 14)
        headNode.zPosition = 4

        // 7. Ears
        let leftEarPath = CGMutablePath()
        leftEarPath.move(to: CGPoint(x: -22, y: 24))
        leftEarPath.addLine(to: CGPoint(x: -18, y: 44))
        leftEarPath.addLine(to: CGPoint(x: -4, y: 32))
        leftEarPath.closeSubpath()
        leftEarNode = SKShapeNode(path: leftEarPath)
        leftEarNode.fillColor = Self.furColor
        leftEarNode.strokeColor = Self.furShadowColor
        leftEarNode.lineWidth = 2
        leftEarNode.zPosition = 3

        let leftInnerPath = CGMutablePath()
        leftInnerPath.move(to: CGPoint(x: -19, y: 26))
        leftInnerPath.addLine(to: CGPoint(x: -16, y: 38))
        leftInnerPath.addLine(to: CGPoint(x: -7, y: 31))
        leftInnerPath.closeSubpath()
        leftInnerEarNode = SKShapeNode(path: leftInnerPath)
        leftInnerEarNode.fillColor = Self.innerEarPink
        leftInnerEarNode.strokeColor = .clear
        leftInnerEarNode.zPosition = 4

        let rightEarPath = CGMutablePath()
        rightEarPath.move(to: CGPoint(x: 22, y: 24))
        rightEarPath.addLine(to: CGPoint(x: 18, y: 44))
        rightEarPath.addLine(to: CGPoint(x: 4, y: 32))
        rightEarPath.closeSubpath()
        rightEarNode = SKShapeNode(path: rightEarPath)
        rightEarNode.fillColor = Self.furColor
        rightEarNode.strokeColor = Self.furShadowColor
        rightEarNode.lineWidth = 2
        rightEarNode.zPosition = 3

        let rightInnerPath = CGMutablePath()
        rightInnerPath.move(to: CGPoint(x: 19, y: 26))
        rightInnerPath.addLine(to: CGPoint(x: 16, y: 38))
        rightInnerPath.addLine(to: CGPoint(x: 7, y: 31))
        rightInnerPath.closeSubpath()
        rightInnerEarNode = SKShapeNode(path: rightInnerPath)
        rightInnerEarNode.fillColor = Self.innerEarPink
        rightInnerEarNode.strokeColor = .clear
        rightInnerEarNode.zPosition = 4

        // 8. Eyes & Highlights
        let eyeSize = CGSize(width: 14, height: 16)
        leftEyeNode = SKShapeNode(ellipseOf: eyeSize)
        rightEyeNode = SKShapeNode(ellipseOf: eyeSize)
        for eye in [leftEyeNode, rightEyeNode] {
            eye.fillColor = Self.eyeGreen
            eye.strokeColor = .clear
            eye.zPosition = 5
        }
        leftEyeNode.position = CGPoint(x: -12, y: 16)
        rightEyeNode.position = CGPoint(x: 12, y: 16)

        let pupilSize = CGSize(width: 7, height: 12)
        leftPupilNode = SKShapeNode(ellipseOf: pupilSize)
        rightPupilNode = SKShapeNode(ellipseOf: pupilSize)
        for pupil in [leftPupilNode, rightPupilNode] {
            pupil.fillColor = .black
            pupil.strokeColor = .clear
            pupil.zPosition = 6
        }
        leftPupilNode.position = .zero
        rightPupilNode.position = .zero
        leftEyeNode.addChild(leftPupilNode)
        rightEyeNode.addChild(rightPupilNode)

        leftHighlightNode = SKShapeNode(circleOfRadius: 2.5)
        rightHighlightNode = SKShapeNode(circleOfRadius: 2.5)
        for highlight in [leftHighlightNode, rightHighlightNode] {
            highlight.fillColor = .white
            highlight.strokeColor = .clear
            highlight.zPosition = 7
        }
        leftHighlightNode.position = CGPoint(x: 2, y: 3)
        rightHighlightNode.position = CGPoint(x: 2, y: 3)
        leftEyeNode.addChild(leftHighlightNode)
        rightEyeNode.addChild(rightHighlightNode)

        // 9. Nose & Mouth
        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: -3.5, y: 10))
        nosePath.addLine(to: CGPoint(x: 3.5, y: 10))
        nosePath.addLine(to: CGPoint(x: 0, y: 6.5))
        nosePath.closeSubpath()
        noseNode = SKShapeNode(path: nosePath)
        noseNode.fillColor = Self.nosePink
        noseNode.strokeColor = .clear
        noseNode.zPosition = 6

        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -5, y: 4))
        mouthPath.addQuadCurve(to: CGPoint(x: 0, y: 6.5), control: CGPoint(x: -2.5, y: 2.5))
        mouthPath.addQuadCurve(to: CGPoint(x: 5, y: 4), control: CGPoint(x: 2.5, y: 2.5))
        mouthNode = SKShapeNode(path: mouthPath)
        mouthNode.strokeColor = NSColor(red: 0.5, green: 0.25, blue: 0.15, alpha: 1.0)
        mouthNode.lineWidth = 1.5
        mouthNode.lineCap = .round
        mouthNode.zPosition = 6

        // 10. Whiskers
        let whiskerPath = CGMutablePath()
        whiskerPath.move(to: CGPoint(x: -16, y: 9))
        whiskerPath.addLine(to: CGPoint(x: -34, y: 12))
        whiskerPath.move(to: CGPoint(x: -16, y: 7))
        whiskerPath.addLine(to: CGPoint(x: -35, y: 6))
        whiskerPath.move(to: CGPoint(x: -16, y: 5))
        whiskerPath.addLine(to: CGPoint(x: -33, y: 0))

        whiskerPath.move(to: CGPoint(x: 16, y: 9))
        whiskerPath.addLine(to: CGPoint(x: 34, y: 12))
        whiskerPath.move(to: CGPoint(x: 16, y: 7))
        whiskerPath.addLine(to: CGPoint(x: 35, y: 6))
        whiskerPath.move(to: CGPoint(x: 16, y: 5))
        whiskerPath.addLine(to: CGPoint(x: 33, y: 0))

        whiskersNode = SKShapeNode(path: whiskerPath)
        whiskersNode.strokeColor = NSColor(white: 0.2, alpha: 0.7)
        whiskersNode.lineWidth = 1.2
        whiskersNode.lineCap = .round
        whiskersNode.zPosition = 6

        effectsContainer.zPosition = 20

        super.init()

        catRootNode.addChild(tailNode)
        catRootNode.addChild(backLeftPawNode)
        catRootNode.addChild(backRightPawNode)
        catRootNode.addChild(bodyNode)
        catRootNode.addChild(chestFluffNode)
        catRootNode.addChild(frontLeftPawNode)
        catRootNode.addChild(frontRightPawNode)
        catRootNode.addChild(leftEarNode)
        catRootNode.addChild(leftInnerEarNode)
        catRootNode.addChild(rightEarNode)
        catRootNode.addChild(rightInnerEarNode)
        catRootNode.addChild(headNode)
        catRootNode.addChild(leftEyeNode)
        catRootNode.addChild(rightEyeNode)
        catRootNode.addChild(noseNode)
        catRootNode.addChild(mouthNode)
        catRootNode.addChild(whiskersNode)
        catRootNode.addChild(effectsContainer)

        addChild(catRootNode)

        play(.idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Animation State Execution

    func play(_ animation: DoraAnimation, frameDuration: TimeInterval? = nil, completion: (() -> Void)? = nil) {
        guard animation != currentAnimation || completion != nil else { return }
        currentAnimation = animation

        switch animation {
        case .walkLeft:
            catRootNode.xScale = -1
        case .walkRight:
            catRootNode.xScale = 1
        default:
            break
        }

        resetCatTransforms()
        runCatAnimation(for: animation, completion: completion)
    }

    private func resetCatTransforms() {
        catRootNode.removeAction(forKey: Self.catAnimKey)
        tailNode.removeAction(forKey: Self.tailAnimKey)
        leftEyeNode.removeAction(forKey: Self.blinkAnimKey)
        rightEyeNode.removeAction(forKey: Self.blinkAnimKey)
        leftEarNode.removeAction(forKey: Self.earAnimKey)
        rightEarNode.removeAction(forKey: Self.earAnimKey)
        effectsContainer.removeAllChildren()

        catRootNode.position = .zero
        catRootNode.zRotation = 0
        catRootNode.yScale = 1.0

        bodyNode.position = CGPoint(x: 0, y: -6)
        bodyNode.yScale = 1.0
        headNode.position = CGPoint(x: 0, y: 14)
        headNode.zRotation = 0

        leftEyeNode.yScale = 1.0
        rightEyeNode.yScale = 1.0
        leftPupilNode.isHidden = false
        rightPupilNode.isHidden = false

        frontLeftPawNode.position = CGPoint(x: -10, y: -25)
        frontRightPawNode.position = CGPoint(x: 10, y: -25)

        tailNode.zRotation = 0
        tailNode.position = .zero
    }

    private func runCatAnimation(for animation: DoraAnimation, completion: (() -> Void)?) {
        switch animation {
        case .idle:
            animateIdle()

        case .walkLeft, .walkRight:
            animateWalking()

        case .sit:
            animateSitting()

        case .sleep:
            animateSleeping()

        case .wake:
            animateWake(completion: completion)

        case .stretch:
            animateStretch(completion: completion)

        case .groom:
            animateGroom(completion: completion)

        case .yawn:
            animateYawn(completion: completion)

        case .happy:
            animateHappy(completion: completion)

        case .thinking:
            animateThinking()

        case .concerned:
            animateConcerned()

        case .charging:
            animateCharging()

        case .celebrate:
            animateCelebrate(completion: completion)

        case .blink:
            oneShotBlink(then: completion)
        }
    }

    // MARK: - Lifelike Cat Animation Routines

    private func animateIdle() {
        // Natural relaxed breathing
        let breatheUp = SKAction.moveBy(x: 0, y: 2.5, duration: 1.3)
        breatheUp.timingMode = .easeInEaseOut
        let breatheDown = breatheUp.reversed()
        catRootNode.run(.repeatForever(.sequence([breatheUp, breatheDown])), withKey: Self.catAnimKey)

        // Gentle tail swish
        let tailLeft = SKAction.rotate(toAngle: 0.22, duration: 1.1)
        tailLeft.timingMode = .easeInEaseOut
        let tailRight = SKAction.rotate(toAngle: -0.15, duration: 1.1)
        tailRight.timingMode = .easeInEaseOut
        tailNode.run(.repeatForever(.sequence([tailLeft, tailRight])), withKey: Self.tailAnimKey)

        loopingBlink()

        // Occasional ear twitch
        let twitchLeft = SKAction.rotate(toAngle: -0.12, duration: 0.08)
        let twitchBack = SKAction.rotate(toAngle: 0, duration: 0.08)
        let earTwitch = SKAction.sequence([
            .wait(forDuration: 3.5, withRange: 2.5),
            twitchLeft, twitchBack
        ])
        leftEarNode.run(.repeatForever(earTwitch), withKey: Self.earAnimKey)
    }

    private func animateWalking() {
        // Fluid paw steps & body waddle
        let step1 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.position.y = -19
            self?.frontRightPawNode.position.y = -26
            self?.tailNode.zRotation = 0.25
        }
        let step2 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.position.y = -26
            self?.frontRightPawNode.position.y = -19
            self?.tailNode.zRotation = -0.25
        }

        let stepSeq = SKAction.sequence([
            step1, .wait(forDuration: 0.16),
            step2, .wait(forDuration: 0.16)
        ])
        catRootNode.run(.repeatForever(stepSeq), withKey: Self.catAnimKey)

        let bobHead = SKAction.sequence([
            .moveBy(x: 0, y: -2, duration: 0.16),
            .moveBy(x: 0, y: 2, duration: 0.16)
        ])
        headNode.run(.repeatForever(bobHead))
        loopingBlink()
    }

    private func animateSitting() {
        // Cozy cat loaf
        bodyNode.run(.scaleY(to: 0.82, duration: 0.3))
        headNode.run(.moveTo(y: 8, duration: 0.3))
        frontLeftPawNode.run(.moveTo(y: -22, duration: 0.3))
        frontRightPawNode.run(.moveTo(y: -22, duration: 0.3))

        let curlTail = SKAction.rotate(toAngle: 0.45, duration: 0.4)
        tailNode.run(curlTail, withKey: Self.tailAnimKey)

        loopingBlink()
    }

    private func animateSleeping() {
        // Curled up sleeping pose
        bodyNode.run(.scaleY(to: 0.78, duration: 0.4))
        headNode.run(.moveTo(y: 5, duration: 0.4))
        frontLeftPawNode.run(.moveTo(y: -23, duration: 0.4))
        frontRightPawNode.run(.moveTo(y: -23, duration: 0.4))
        tailNode.run(.rotate(toAngle: 0.55, duration: 0.4), withKey: Self.tailAnimKey)

        // Closed crescent sleepy eyes
        leftEyeNode.yScale = 0.08
        rightEyeNode.yScale = 0.08

        // Slow deep sleep breathing
        let deepBreathe = SKAction.sequence([
            .scaleY(to: 0.75, duration: 1.8),
            .scaleY(to: 0.80, duration: 1.8)
        ])
        bodyNode.run(.repeatForever(deepBreathe), withKey: Self.catAnimKey)

        // Floating Zzz particle generation
        let spawnZzz = SKAction.run { [weak self] in
            guard let self = self else { return }
            let zLabel = SKLabelNode(text: "z")
            zLabel.fontSize = 13
            zLabel.fontName = "HelveticaNeue-Bold"
            zLabel.fontColor = NSColor.systemIndigo.withAlphaComponent(0.8)
            zLabel.position = CGPoint(x: 16, y: 20)
            zLabel.alpha = 0
            self.effectsContainer.addChild(zLabel)

            let floatUp = SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.moveBy(x: 12, y: 20, duration: 1.6),
                SKAction.scale(to: 1.3, duration: 1.6)
            ])
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            let remove = SKAction.removeFromParent()
            zLabel.run(SKAction.sequence([floatUp, fadeOut, remove]))
        }

        let zzzLoop = SKAction.repeatForever(SKAction.sequence([spawnZzz, .wait(forDuration: 1.5)]))
        effectsContainer.run(zzzLoop)
    }

    private func animateWake(completion: (() -> Void)?) {
        let openEyes = SKAction.run { [weak self] in
            self?.leftEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
            self?.rightEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
        }
        let stretch = SKAction.sequence([
            openEyes,
            .moveBy(x: 0, y: 5, duration: 0.25),
            .moveBy(x: 0, y: -5, duration: 0.25)
        ])
        if let completion = completion {
            catRootNode.run(.sequence([stretch, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(stretch, withKey: Self.catAnimKey)
        }
    }

    private func animateStretch(completion: (() -> Void)?) {
        // Realistic cat morning stretch: front drops, chest lowers, paws reach forward
        let stretchFront = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(.moveBy(x: 8, y: -2, duration: 0.4))
            self?.frontRightPawNode.run(.moveBy(x: 8, y: -2, duration: 0.4))
            self?.headNode.run(.moveBy(x: 4, y: -6, duration: 0.4))
            self?.bodyNode.run(.rotate(toAngle: -0.15, duration: 0.4))
            self?.tailNode.run(.rotate(toAngle: 0.4, duration: 0.4))
        }
        let holdStretch = SKAction.wait(forDuration: 0.8)
        let recover = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(.moveTo(y: -25, duration: 0.4))
            self?.frontRightPawNode.run(.moveTo(y: -25, duration: 0.4))
            self?.headNode.run(.moveTo(y: 14, duration: 0.4))
            self?.bodyNode.run(.rotate(toAngle: 0, duration: 0.4))
            self?.tailNode.run(.rotate(toAngle: 0, duration: 0.4))
        }
        let sequence = SKAction.sequence([
            stretchFront,
            holdStretch,
            recover,
            .wait(forDuration: 0.3)
        ])
        if let completion = completion {
            catRootNode.run(.sequence([sequence, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(sequence, withKey: Self.catAnimKey)
        }
    }

    private func animateGroom(completion: (() -> Void)?) {
        // Cat raises paw to lick/groom ear and face
        let raisePaw = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -8, y: 12), duration: 0.25))
            self?.headNode.run(.rotate(toAngle: -0.1, duration: 0.25))
        }
        let lickWipe1 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(.moveBy(x: -4, y: 4, duration: 0.15))
        }
        let lickWipe2 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(.moveBy(x: 4, y: -4, duration: 0.15))
        }
        let lowerPaw = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -10, y: -25), duration: 0.25))
            self?.headNode.run(.rotate(toAngle: 0, duration: 0.25))
        }

        let seq = SKAction.sequence([
            raisePaw, .wait(forDuration: 0.25),
            lickWipe1, .wait(forDuration: 0.15), lickWipe2, .wait(forDuration: 0.15),
            lickWipe1, .wait(forDuration: 0.15), lickWipe2, .wait(forDuration: 0.15),
            lowerPaw, .wait(forDuration: 0.3)
        ])

        if let completion = completion {
            catRootNode.run(.sequence([seq, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(seq, withKey: Self.catAnimKey)
        }
    }

    private func animateYawn(completion: (() -> Void)?) {
        // Big cat yawn
        let openMouth = SKAction.run { [weak self] in
            self?.headNode.run(.moveBy(x: 0, y: 3, duration: 0.3))
            self?.mouthNode.run(.scale(to: 1.8, duration: 0.3))
            self?.leftEyeNode.run(.scaleY(to: 0.1, duration: 0.3))
            self?.rightEyeNode.run(.scaleY(to: 0.1, duration: 0.3))
        }
        let holdYawn = SKAction.wait(forDuration: 0.7)
        let closeMouth = SKAction.run { [weak self] in
            self?.headNode.run(.moveTo(y: 14, duration: 0.3))
            self?.mouthNode.run(.scale(to: 1.0, duration: 0.3))
            self?.leftEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
            self?.rightEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
        }

        let seq = SKAction.sequence([openMouth, holdYawn, closeMouth, .wait(forDuration: 0.2)])
        if let completion = completion {
            catRootNode.run(.sequence([seq, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(seq, withKey: Self.catAnimKey)
        }
    }

    /// Fixed One-Shot Happy / Pet reaction (Stops automatically after ~2.5s)
    private func animateHappy(completion: (() -> Void)?) {
        let bounceUp = SKAction.moveBy(x: 0, y: 7, duration: 0.14)
        bounceUp.timingMode = .easeOut
        let bounceDown = bounceUp.reversed()
        bounceDown.timingMode = .easeIn
        let bounce = SKAction.sequence([bounceUp, bounceDown])

        // Fast wagging tail
        let wagFast = SKAction.sequence([
            .rotate(toAngle: 0.35, duration: 0.1),
            .rotate(toAngle: -0.35, duration: 0.1)
        ])
        tailNode.run(.repeat(wagFast, count: 8), withKey: Self.tailAnimKey)

        // Spawn a couple sweet hearts
        for i in 0..<3 {
            let delay = Double(i) * 0.3
            let spawn = SKAction.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in
                    guard let self = self else { return }
                    let heart = SKLabelNode(text: "💖")
                    heart.fontSize = 15
                    heart.position = CGPoint(x: CGFloat.random(in: -18...18), y: 28)
                    self.effectsContainer.addChild(heart)
                    let pop = SKAction.group([
                        SKAction.moveBy(x: 0, y: 20, duration: 0.9),
                        SKAction.fadeOut(withDuration: 0.9),
                        SKAction.scale(to: 1.3, duration: 0.9)
                    ])
                    heart.run(SKAction.sequence([pop, .removeFromParent()]))
                }
            ])
            effectsContainer.run(spawn)
        }

        // Bounces 3 times then finishes!
        let threeBounces = SKAction.repeat(bounce, count: 4)
        let finishAction = SKAction.run { [weak self] in
            if let completion = completion {
                completion()
            } else {
                self?.play(.idle)
            }
        }
        catRootNode.run(.sequence([threeBounces, finishAction]), withKey: Self.catAnimKey)
    }

    private func animateThinking() {
        headNode.run(.rotate(toAngle: 0.14, duration: 0.4))
        let thinkLabel = SKLabelNode(text: "💭")
        thinkLabel.fontSize = 17
        thinkLabel.position = CGPoint(x: 24, y: 34)
        effectsContainer.addChild(thinkLabel)

        let pulse = SKAction.sequence([
            .scale(to: 1.2, duration: 0.6),
            .scale(to: 0.9, duration: 0.6)
        ])
        thinkLabel.run(.repeatForever(pulse))
        loopingBlink()
    }

    private func animateConcerned() {
        let shiver = SKAction.sequence([
            .rotate(toAngle: 0.05, duration: 0.08),
            .rotate(toAngle: -0.05, duration: 0.08)
        ])
        catRootNode.run(.repeatForever(shiver), withKey: Self.catAnimKey)
    }

    private func animateCharging() {
        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.6, duration: 0.5),
            .fadeAlpha(to: 1.0, duration: 0.5)
        ])
        catRootNode.run(.repeatForever(pulse), withKey: Self.catAnimKey)
    }

    private func animateCelebrate(completion: (() -> Void)?) {
        let spin = SKAction.rotate(byAngle: .pi * 2, duration: 0.45)
        let jump = SKAction.moveBy(x: 0, y: 18, duration: 0.25)
        let jumpBack = jump.reversed()
        let action = SKAction.group([spin, .sequence([jump, jumpBack])])
        if let completion = completion {
            catRootNode.run(.sequence([action, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(action, withKey: Self.catAnimKey)
        }
    }

    // MARK: - Blinking Helpers

    private func loopingBlink() {
        let close = SKAction.scaleY(to: 0.1, duration: 0.06)
        let open = SKAction.scaleY(to: 1.0, duration: 0.06)
        let blink = SKAction.sequence([.wait(forDuration: 3.0, withRange: 2.0), close, open])
        leftEyeNode.run(.repeatForever(blink), withKey: Self.blinkAnimKey)
        rightEyeNode.run(.repeatForever(blink), withKey: Self.blinkAnimKey)
    }

    private func oneShotBlink(then completion: (() -> Void)?) {
        let close = SKAction.scaleY(to: 0.1, duration: 0.06)
        let open = SKAction.scaleY(to: 1.0, duration: 0.06)
        let sequence = completion != nil
            ? SKAction.sequence([close, open, .run(completion!)])
            : SKAction.sequence([close, open])
        leftEyeNode.run(sequence, withKey: Self.blinkAnimKey)
        rightEyeNode.run(sequence, withKey: Self.blinkAnimKey)
    }
}

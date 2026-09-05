//
//  DoraCharacter.swift
//  Dora
//
//  Dora the Cat: A compact, lifelike 3D-styled procedural feline companion.
//  Designed with non-distracting compact proportions, volumetric fur shading,
//  glossy 3D eyes, multi-joint fluid tail wave, and authentic feline behaviors:
//  - Slow affection blinks & independent ear scanning
//  - 4-paw diagonal sequence walking with spine counter-sway
//  - True cat loaf pose with tucked paws
//  - Deep curled sleep with dreaming twitches & breathing
//  - Two-stage morning stretch (front dip + back arch)
//  - Authentic face grooming (paw lick & ear wipe)
//  - Butt-wiggle pounce, curiosity alert, and scruff-picked dangling
//

import AppKit
import SpriteKit

final class DoraCharacter: SKNode {

    /// Compact bounding size of the cat (non-distracting on screen)
    let size: CGSize

    private(set) var currentAnimation: DoraAnimation = .idle

    // MARK: - Root & Dynamic Shadow
    private let catRootNode = SKNode()
    private let shadowNode: SKShapeNode

    // MARK: - 3D Body & Feature Nodes
    private let bodyContainer = SKNode()
    private let bodyNode: SKShapeNode
    private let bodyHighlightNode: SKShapeNode
    private let chestFluffNode: SKShapeNode

    private let headContainer = SKNode()
    private let headNode: SKShapeNode
    private let headHighlightNode: SKShapeNode

    private let leftEarNode: SKShapeNode
    private let rightEarNode: SKShapeNode
    private let leftInnerEarNode: SKShapeNode
    private let rightInnerEarNode: SKShapeNode
    private let leftEarTipNode: SKShapeNode
    private let rightEarTipNode: SKShapeNode

    private let leftEyeNode: SKShapeNode
    private let rightEyeNode: SKShapeNode
    private let leftPupilNode: SKShapeNode
    private let rightPupilNode: SKShapeNode
    private let leftHighlight1: SKShapeNode
    private let rightHighlight1: SKShapeNode
    private let leftHighlight2: SKShapeNode
    private let rightHighlight2: SKShapeNode

    private let muzzleNode: SKShapeNode
    private let noseNode: SKShapeNode
    private let mouthNode: SKShapeNode
    private let tongueNode: SKShapeNode
    private let whiskersNode: SKShapeNode

    // Paws & Toe Beans
    private let frontLeftPawNode: SKNode
    private let frontRightPawNode: SKNode
    private let backLeftPawNode: SKNode
    private let backRightPawNode: SKNode

    // Multi-Joint 3D Tail
    private let tailBaseNode = SKNode()
    private let tailSegment1: SKShapeNode
    private let tailSegment2: SKShapeNode
    private let tailSegment3: SKShapeNode
    private let tailTipNode: SKShapeNode

    // Effects & Overlays
    private let effectsContainer = SKNode()

    // Action Keys
    private static let catAnimKey = "catAnimationAction"
    private static let tailAnimKey = "catTailAction"
    private static let blinkAnimKey = "catBlinkAction"
    private static let earAnimKey = "catEarAction"
    private static let breathingAnimKey = "catBreathingAction"
    private static let pawWiggleKey = "catPawWiggleAction"
    private static let whiskerTwitchKey = "catWhiskerTwitchAction"

    // 3D Color Palette (Warm Golden Amber Tabby)
    private static let furBase = NSColor(red: 0.98, green: 0.62, blue: 0.28, alpha: 1.0)
    private static let furHighlight = NSColor(red: 1.0, green: 0.78, blue: 0.48, alpha: 1.0)
    private static let furShadow = NSColor(red: 0.82, green: 0.46, blue: 0.18, alpha: 1.0)
    private static let furDark = NSColor(red: 0.60, green: 0.30, blue: 0.10, alpha: 1.0)
    private static let chestWhite = NSColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1.0)
    private static let innerEarPink = NSColor(red: 0.98, green: 0.68, blue: 0.76, alpha: 1.0)
    private static let pawPadPink = NSColor(red: 0.96, green: 0.55, blue: 0.65, alpha: 1.0)
    private static let eyeEmerald = NSColor(red: 0.20, green: 0.78, blue: 0.52, alpha: 1.0)
    private static let nosePink = NSColor(red: 0.95, green: 0.48, blue: 0.58, alpha: 1.0)

    init(animationManager: AnimationManager = .shared) {
        // Compact, non-intrusive desktop size (~46x42 points)
        let catSize = CGSize(width: 48, height: 44)
        self.size = catSize

        // 0. Soft Contact Ground Shadow
        shadowNode = SKShapeNode(ellipseOf: CGSize(width: 38, height: 10))
        shadowNode.fillColor = NSColor(white: 0.0, alpha: 0.24)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -16)
        shadowNode.zPosition = -2

        // 1. Multi-Joint Articulated 3D Tail
        tailSegment1 = SKShapeNode(rectOf: CGSize(width: 6, height: 10), cornerRadius: 3)
        tailSegment1.fillColor = Self.furBase
        tailSegment1.strokeColor = Self.furShadow
        tailSegment1.lineWidth = 0.8
        tailSegment1.position = CGPoint(x: 0, y: 5)

        tailSegment2 = SKShapeNode(rectOf: CGSize(width: 5.5, height: 10), cornerRadius: 2.75)
        tailSegment2.fillColor = Self.furBase
        tailSegment2.strokeColor = Self.furShadow
        tailSegment2.lineWidth = 0.8
        tailSegment2.position = CGPoint(x: 0, y: 8)

        tailSegment3 = SKShapeNode(rectOf: CGSize(width: 5, height: 10), cornerRadius: 2.5)
        tailSegment3.fillColor = Self.furHighlight
        tailSegment3.strokeColor = Self.furShadow
        tailSegment3.lineWidth = 0.8
        tailSegment3.position = CGPoint(x: 0, y: 8)

        tailTipNode = SKShapeNode(circleOfRadius: 2.6)
        tailTipNode.fillColor = Self.chestWhite
        tailTipNode.strokeColor = .clear
        tailTipNode.position = CGPoint(x: 0, y: 6)

        tailSegment3.addChild(tailTipNode)
        tailSegment2.addChild(tailSegment3)
        tailSegment1.addChild(tailSegment2)
        tailBaseNode.addChild(tailSegment1)
        tailBaseNode.position = CGPoint(x: -14, y: -6)
        tailBaseNode.zPosition = -1

        // 2. Back Paws
        backLeftPawNode = DoraCharacter.createPaw(width: 9, height: 7)
        backRightPawNode = DoraCharacter.createPaw(width: 9, height: 7)
        backLeftPawNode.position = CGPoint(x: -11, y: -14)
        backRightPawNode.position = CGPoint(x: 11, y: -14)
        backLeftPawNode.zPosition = 0
        backRightPawNode.zPosition = 0

        // 3. Volumetric 3D Torso
        bodyNode = SKShapeNode(rectOf: CGSize(width: 36, height: 28), cornerRadius: 14)
        bodyNode.fillColor = Self.furBase
        bodyNode.strokeColor = Self.furShadow
        bodyNode.lineWidth = 1.2

        bodyHighlightNode = SKShapeNode(ellipseOf: CGSize(width: 26, height: 15))
        bodyHighlightNode.fillColor = Self.furHighlight.withAlphaComponent(0.45)
        bodyHighlightNode.strokeColor = .clear
        bodyHighlightNode.position = CGPoint(x: 0, y: 5)

        chestFluffNode = SKShapeNode(ellipseOf: CGSize(width: 20, height: 18))
        chestFluffNode.fillColor = Self.chestWhite
        chestFluffNode.strokeColor = .clear
        chestFluffNode.position = CGPoint(x: 0, y: -4)

        bodyContainer.position = CGPoint(x: 0, y: -3)
        bodyContainer.zPosition = 1
        bodyContainer.addChild(bodyNode)
        bodyContainer.addChild(bodyHighlightNode)
        bodyContainer.addChild(chestFluffNode)

        // 4. Front Paws
        frontLeftPawNode = DoraCharacter.createPaw(width: 8.5, height: 7)
        frontRightPawNode = DoraCharacter.createPaw(width: 8.5, height: 7)
        frontLeftPawNode.position = CGPoint(x: -6.5, y: -15)
        frontRightPawNode.position = CGPoint(x: 6.5, y: -15)
        frontLeftPawNode.zPosition = 4
        frontRightPawNode.zPosition = 4

        // 5. 3D Head & Features
        headNode = SKShapeNode(ellipseOf: CGSize(width: 33, height: 27))
        headNode.fillColor = Self.furBase
        headNode.strokeColor = Self.furShadow
        headNode.lineWidth = 1.2

        headHighlightNode = SKShapeNode(ellipseOf: CGSize(width: 22, height: 13))
        headHighlightNode.fillColor = Self.furHighlight.withAlphaComponent(0.5)
        headHighlightNode.strokeColor = .clear
        headHighlightNode.position = CGPoint(x: 0, y: 6)

        // 3D Ears with Depth
        let leftEarPath = CGMutablePath()
        leftEarPath.move(to: CGPoint(x: -14, y: 6))
        leftEarPath.addLine(to: CGPoint(x: -12, y: 19))
        leftEarPath.addLine(to: CGPoint(x: -2, y: 11))
        leftEarPath.closeSubpath()
        leftEarNode = SKShapeNode(path: leftEarPath)
        leftEarNode.fillColor = Self.furBase
        leftEarNode.strokeColor = Self.furShadow
        leftEarNode.lineWidth = 1.2

        let leftInnerPath = CGMutablePath()
        leftInnerPath.move(to: CGPoint(x: -12.5, y: 7.5))
        leftInnerPath.addLine(to: CGPoint(x: -10.8, y: 16))
        leftInnerPath.addLine(to: CGPoint(x: -4, y: 10.5))
        leftInnerPath.closeSubpath()
        leftInnerEarNode = SKShapeNode(path: leftInnerPath)
        leftInnerEarNode.fillColor = Self.innerEarPink
        leftInnerEarNode.strokeColor = .clear

        leftEarTipNode = SKShapeNode(circleOfRadius: 1.5)
        leftEarTipNode.fillColor = Self.furDark
        leftEarTipNode.strokeColor = .clear
        leftEarTipNode.position = CGPoint(x: -12, y: 18.5)

        let rightEarPath = CGMutablePath()
        rightEarPath.move(to: CGPoint(x: 14, y: 6))
        rightEarPath.addLine(to: CGPoint(x: 12, y: 19))
        rightEarPath.addLine(to: CGPoint(x: 2, y: 11))
        rightEarPath.closeSubpath()
        rightEarNode = SKShapeNode(path: rightEarPath)
        rightEarNode.fillColor = Self.furBase
        rightEarNode.strokeColor = Self.furShadow
        rightEarNode.lineWidth = 1.2

        let rightInnerPath = CGMutablePath()
        rightInnerPath.move(to: CGPoint(x: 12.5, y: 7.5))
        rightInnerPath.addLine(to: CGPoint(x: 10.8, y: 16))
        rightInnerPath.addLine(to: CGPoint(x: 4, y: 10.5))
        rightInnerPath.closeSubpath()
        rightInnerEarNode = SKShapeNode(path: rightInnerPath)
        rightInnerEarNode.fillColor = Self.innerEarPink
        rightInnerEarNode.strokeColor = .clear

        rightEarTipNode = SKShapeNode(circleOfRadius: 1.5)
        rightEarTipNode.fillColor = Self.furDark
        rightEarTipNode.strokeColor = .clear
        rightEarTipNode.position = CGPoint(x: 12, y: 18.5)

        // 6. Glossy 3D Eyes
        let eyeSize = CGSize(width: 9, height: 11)
        leftEyeNode = SKShapeNode(ellipseOf: eyeSize)
        rightEyeNode = SKShapeNode(ellipseOf: eyeSize)
        for eye in [leftEyeNode, rightEyeNode] {
            eye.fillColor = Self.eyeEmerald
            eye.strokeColor = Self.furDark
            eye.lineWidth = 0.8
        }
        leftEyeNode.position = CGPoint(x: -7.5, y: 2)
        rightEyeNode.position = CGPoint(x: 7.5, y: 2)

        // Pupils
        let pupilSize = CGSize(width: 4.2, height: 8.5)
        leftPupilNode = SKShapeNode(ellipseOf: pupilSize)
        rightPupilNode = SKShapeNode(ellipseOf: pupilSize)
        for pupil in [leftPupilNode, rightPupilNode] {
            pupil.fillColor = NSColor(white: 0.05, alpha: 1.0)
            pupil.strokeColor = .clear
        }
        leftEyeNode.addChild(leftPupilNode)
        rightEyeNode.addChild(rightPupilNode)

        // Specular Catchlights
        leftHighlight1 = SKShapeNode(circleOfRadius: 1.8)
        rightHighlight1 = SKShapeNode(circleOfRadius: 1.8)
        leftHighlight2 = SKShapeNode(circleOfRadius: 0.9)
        rightHighlight2 = SKShapeNode(circleOfRadius: 0.9)

        for h in [leftHighlight1, rightHighlight1, leftHighlight2, rightHighlight2] {
            h.fillColor = .white
            h.strokeColor = .clear
        }
        leftHighlight1.position = CGPoint(x: 1.5, y: 2.2)
        rightHighlight1.position = CGPoint(x: 1.5, y: 2.2)
        leftHighlight2.position = CGPoint(x: -1.5, y: -2.2)
        rightHighlight2.position = CGPoint(x: -1.5, y: -2.2)

        leftEyeNode.addChild(leftHighlight1)
        leftEyeNode.addChild(leftHighlight2)
        rightEyeNode.addChild(rightHighlight1)
        rightEyeNode.addChild(rightHighlight2)

        // 7. Muzzle, Nose, Mouth & Tongue
        muzzleNode = SKShapeNode(ellipseOf: CGSize(width: 14, height: 9))
        muzzleNode.fillColor = Self.chestWhite.withAlphaComponent(0.95)
        muzzleNode.strokeColor = .clear
        muzzleNode.position = CGPoint(x: 0, y: -3.5)

        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: -2.5, y: -1))
        nosePath.addLine(to: CGPoint(x: 2.5, y: -1))
        nosePath.addLine(to: CGPoint(x: 0, y: -3.5))
        nosePath.closeSubpath()
        noseNode = SKShapeNode(path: nosePath)
        noseNode.fillColor = Self.nosePink
        noseNode.strokeColor = .clear

        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -3.8, y: -5.5))
        mouthPath.addQuadCurve(to: CGPoint(x: 0, y: -4), control: CGPoint(x: -2, y: -6.8))
        mouthPath.addQuadCurve(to: CGPoint(x: 3.8, y: -5.5), control: CGPoint(x: 2, y: -6.8))
        mouthNode = SKShapeNode(path: mouthPath)
        mouthNode.strokeColor = Self.furDark
        mouthNode.lineWidth = 1.0
        mouthNode.lineCap = .round

        tongueNode = SKShapeNode(ellipseOf: CGSize(width: 4, height: 5))
        tongueNode.fillColor = Self.innerEarPink
        tongueNode.strokeColor = .clear
        tongueNode.position = CGPoint(x: 0, y: -6.5)
        tongueNode.isHidden = true

        // 8. Delicate Whiskers
        let whiskerPath = CGMutablePath()
        // Left
        whiskerPath.move(to: CGPoint(x: -10, y: -2))
        whiskerPath.addQuadCurve(to: CGPoint(x: -22, y: 1), control: CGPoint(x: -16, y: 0))
        whiskerPath.move(to: CGPoint(x: -10, y: -4))
        whiskerPath.addQuadCurve(to: CGPoint(x: -23, y: -4), control: CGPoint(x: -16, y: -4))
        whiskerPath.move(to: CGPoint(x: -10, y: -6))
        whiskerPath.addQuadCurve(to: CGPoint(x: -21, y: -9), control: CGPoint(x: -16, y: -7))
        // Right
        whiskerPath.move(to: CGPoint(x: 10, y: -2))
        whiskerPath.addQuadCurve(to: CGPoint(x: 22, y: 1), control: CGPoint(x: 16, y: 0))
        whiskerPath.move(to: CGPoint(x: 10, y: -4))
        whiskerPath.addQuadCurve(to: CGPoint(x: 23, y: -4), control: CGPoint(x: 16, y: -4))
        whiskerPath.move(to: CGPoint(x: 10, y: -6))
        whiskerPath.addQuadCurve(to: CGPoint(x: 21, y: -9), control: CGPoint(x: 16, y: -7))

        whiskersNode = SKShapeNode(path: whiskerPath)
        whiskersNode.strokeColor = NSColor(white: 0.18, alpha: 0.7)
        whiskersNode.lineWidth = 0.9
        whiskersNode.lineCap = .round

        // Head Assembly
        headContainer.position = CGPoint(x: 0, y: 9)
        headContainer.zPosition = 5
        headContainer.addChild(leftEarNode)
        headContainer.addChild(leftInnerEarNode)
        headContainer.addChild(leftEarTipNode)
        headContainer.addChild(rightEarNode)
        headContainer.addChild(rightInnerEarNode)
        headContainer.addChild(rightEarTipNode)
        headContainer.addChild(headNode)
        headContainer.addChild(headHighlightNode)
        headContainer.addChild(muzzleNode)
        headContainer.addChild(leftEyeNode)
        headContainer.addChild(rightEyeNode)
        headContainer.addChild(tongueNode)
        headContainer.addChild(noseNode)
        headContainer.addChild(mouthNode)
        headContainer.addChild(whiskersNode)

        effectsContainer.zPosition = 30

        super.init()

        addChild(shadowNode)

        catRootNode.addChild(tailBaseNode)
        catRootNode.addChild(backLeftPawNode)
        catRootNode.addChild(backRightPawNode)
        catRootNode.addChild(bodyContainer)
        catRootNode.addChild(frontLeftPawNode)
        catRootNode.addChild(frontRightPawNode)
        catRootNode.addChild(headContainer)
        catRootNode.addChild(effectsContainer)

        addChild(catRootNode)

        play(.idle)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Paw Factory with Toe Beans
    private static func createPaw(width: CGFloat, height: CGFloat) -> SKNode {
        let container = SKNode()
        let paw = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        paw.fillColor = chestWhite
        paw.strokeColor = furShadow.withAlphaComponent(0.5)
        paw.lineWidth = 0.8
        container.addChild(paw)

        let bean = SKShapeNode(ellipseOf: CGSize(width: width * 0.45, height: height * 0.35))
        bean.fillColor = pawPadPink.withAlphaComponent(0.85)
        bean.strokeColor = .clear
        bean.position = CGPoint(x: 0, y: -height * 0.15)
        container.addChild(bean)

        return container
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

    // MARK: - Interactive Feline Gaze Tracking

    /// Dynamically shifts pupils and angles head toward nearby points (e.g. mouse cursor)
    func updateGaze(targetPoint: CGPoint) {
        guard currentAnimation.allowsEyeTracking else { return }

        let dx = targetPoint.x - position.x
        let dy = targetPoint.y - position.y
        let dist = hypot(dx, dy)

        // Only track when cursor is reasonably close (< 450pt)
        if dist < 450 && dist > 15 {
            let normX = max(-1.0, min(1.0, (dx / 200.0) * catRootNode.xScale))
            let normY = max(-0.8, min(0.8, dy / 200.0))

            let maxPupilShiftX: CGFloat = 1.6
            let maxPupilShiftY: CGFloat = 2.0

            leftPupilNode.position = CGPoint(x: normX * maxPupilShiftX, y: normY * maxPupilShiftY)
            rightPupilNode.position = CGPoint(x: normX * maxPupilShiftX, y: normY * maxPupilShiftY)

            // Subtle head inclination
            let headTilt = max(-0.12, min(0.12, (dx / 400.0) * catRootNode.xScale))
            headContainer.zRotation = headTilt
        } else {
            leftPupilNode.position = .zero
            rightPupilNode.position = .zero
            headContainer.zRotation = 0
        }
    }

    // MARK: - Dynamic Landing FX

    private func spawnLandingPuff() {
        for i in 0..<4 {
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.2...2.2))
            puff.fillColor = NSColor(white: 0.85, alpha: 0.6)
            puff.strokeColor = .clear
            let xOffset = (i % 2 == 0 ? -1.0 : 1.0) * CGFloat.random(in: 6...14)
            puff.position = CGPoint(x: xOffset, y: -16)
            effectsContainer.addChild(puff)

            let floatPuff = SKAction.group([
                SKAction.moveBy(x: xOffset * 0.6, y: CGFloat.random(in: 4...8), duration: 0.35),
                SKAction.fadeOut(withDuration: 0.35),
                SKAction.scale(to: 1.8, duration: 0.35)
            ])
            puff.run(SKAction.sequence([floatPuff, .removeFromParent()]))
        }
    }

    private func resetCatTransforms() {
        catRootNode.removeAction(forKey: Self.catAnimKey)
        catRootNode.removeAction(forKey: Self.pawWiggleKey)
        bodyContainer.removeAction(forKey: Self.breathingAnimKey)
        tailBaseNode.removeAction(forKey: Self.tailAnimKey)
        tailSegment1.removeAction(forKey: Self.tailAnimKey)
        tailSegment2.removeAction(forKey: Self.tailAnimKey)
        tailSegment3.removeAction(forKey: Self.tailAnimKey)
        leftEyeNode.removeAction(forKey: Self.blinkAnimKey)
        rightEyeNode.removeAction(forKey: Self.blinkAnimKey)
        leftEarNode.removeAction(forKey: Self.earAnimKey)
        rightEarNode.removeAction(forKey: Self.earAnimKey)
        whiskersNode.removeAction(forKey: Self.whiskerTwitchKey)
        effectsContainer.removeAllChildren()

        catRootNode.position = .zero
        catRootNode.zRotation = 0
        catRootNode.yScale = 1.0
        catRootNode.alpha = 1.0

        shadowNode.setScale(1.0)
        shadowNode.alpha = 0.24
        shadowNode.position = CGPoint(x: 0, y: -16)

        bodyContainer.position = CGPoint(x: 0, y: -3)
        bodyContainer.yScale = 1.0
        bodyContainer.xScale = 1.0
        bodyContainer.zRotation = 0

        headContainer.position = CGPoint(x: 0, y: 9)
        headContainer.zRotation = 0
        headContainer.yScale = 1.0

        leftEyeNode.yScale = 1.0
        rightEyeNode.yScale = 1.0
        leftPupilNode.isHidden = false
        rightPupilNode.isHidden = false
        leftPupilNode.setScale(1.0)
        rightPupilNode.setScale(1.0)

        tongueNode.isHidden = true

        frontLeftPawNode.position = CGPoint(x: -6.5, y: -15)
        frontRightPawNode.position = CGPoint(x: 6.5, y: -15)
        frontLeftPawNode.zRotation = 0
        frontRightPawNode.zRotation = 0
        frontLeftPawNode.isHidden = false
        frontRightPawNode.isHidden = false

        backLeftPawNode.position = CGPoint(x: -11, y: -14)
        backRightPawNode.position = CGPoint(x: 11, y: -14)
        backLeftPawNode.isHidden = false
        backRightPawNode.isHidden = false

        tailBaseNode.zRotation = 0
        tailSegment1.zRotation = 0
        tailSegment2.zRotation = 0
        tailSegment3.zRotation = 0
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

        case .pickedUp:
            animatePickedUp()

        case .landing:
            animateLanding(completion: completion)

        case .jump:
            animateJump()

        case .pounce:
            animatePounce(completion: completion)

        case .curious:
            animateCurious(completion: completion)
        }
    }

    // MARK: - Lifelike Feline Procedural Animation Routines

    private func animateIdle() {
        // Natural relaxed feline breathing (2.8s full respiration cycle)
        let breatheIn = SKAction.group([
            SKAction.scaleY(to: 1.03, duration: 1.4),
            SKAction.scaleX(to: 0.985, duration: 1.4),
            SKAction.moveBy(x: 0, y: 1.0, duration: 1.4)
        ])
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.group([
            SKAction.scaleY(to: 0.98, duration: 1.4),
            SKAction.scaleX(to: 1.015, duration: 1.4),
            SKAction.moveBy(x: 0, y: -1.0, duration: 1.4)
        ])
        breatheOut.timingMode = .easeInEaseOut
        bodyContainer.run(.repeatForever(.sequence([breatheIn, breatheOut])), withKey: Self.breathingAnimKey)

        // Sinuous multi-joint feline tail wave with gentle tip flick
        animate3DTailWave(amplitude: 0.22, speed: 1.6)

        // Affectionate slow blinks + occasional standard blinks
        loopingFelineBlink()

        // Independent organic ear scanning
        let leftEarFlick = SKAction.sequence([
            .wait(forDuration: 3.8, withRange: 2.5),
            .rotate(toAngle: -0.14, duration: 0.08),
            .rotate(toAngle: 0.04, duration: 0.08),
            .rotate(toAngle: 0, duration: 0.08)
        ])
        leftEarNode.run(.repeatForever(leftEarFlick), withKey: Self.earAnimKey)

        let rightEarFlick = SKAction.sequence([
            .wait(forDuration: 4.5, withRange: 3.0),
            .rotate(toAngle: 0.14, duration: 0.08),
            .rotate(toAngle: -0.04, duration: 0.08),
            .rotate(toAngle: 0, duration: 0.08)
        ])
        rightEarNode.run(.repeatForever(rightEarFlick), withKey: Self.earAnimKey)
    }

    private func animateWalking() {
        // Authentic 4-leg diagonal feline gait cycle
        let stepDuration = 0.14

        let step1 = SKAction.run { [weak self] in
            guard let self = self else { return }
            // Back-left + front-right swing phase
            self.backLeftPawNode.run(SKAction.moveTo(y: -11, duration: stepDuration))
            self.frontRightPawNode.run(SKAction.moveTo(y: -11, duration: stepDuration))
            self.backRightPawNode.run(SKAction.moveTo(y: -15, duration: stepDuration))
            self.frontLeftPawNode.run(SKAction.moveTo(y: -15, duration: stepDuration))
            self.bodyContainer.run(SKAction.rotate(toAngle: -0.035, duration: stepDuration))
            self.headContainer.run(SKAction.moveTo(y: 8, duration: stepDuration))
        }

        let step2 = SKAction.run { [weak self] in
            guard let self = self else { return }
            // Back-right + front-left swing phase
            self.backLeftPawNode.run(SKAction.moveTo(y: -15, duration: stepDuration))
            self.frontRightPawNode.run(SKAction.moveTo(y: -15, duration: stepDuration))
            self.backRightPawNode.run(SKAction.moveTo(y: -11, duration: stepDuration))
            self.frontLeftPawNode.run(SKAction.moveTo(y: -11, duration: stepDuration))
            self.bodyContainer.run(SKAction.rotate(toAngle: 0.035, duration: stepDuration))
            self.headContainer.run(SKAction.moveTo(y: 10, duration: stepDuration))
        }

        let walkCycle = SKAction.sequence([
            step1, .wait(forDuration: stepDuration),
            step2, .wait(forDuration: stepDuration)
        ])
        catRootNode.run(.repeatForever(walkCycle), withKey: Self.catAnimKey)

        animate3DTailWave(amplitude: 0.38, speed: 0.8)
        loopingFelineBlink()
    }

    private func animateSitting() {
        // Authentic cat loaf: front paws tuck under chest, body lowers, tail wraps close
        bodyContainer.run(.group([
            SKAction.scaleY(to: 0.80, duration: 0.35),
            SKAction.scaleX(to: 1.08, duration: 0.35),
            SKAction.moveTo(y: -5, duration: 0.35)
        ]))
        headContainer.run(.moveTo(y: 5.5, duration: 0.35))

        // Paws tucked smoothly under loaf
        frontLeftPawNode.run(.group([SKAction.moveTo(y: -14, duration: 0.3), SKAction.fadeAlpha(to: 0.2, duration: 0.3)]))
        frontRightPawNode.run(.group([SKAction.moveTo(y: -14, duration: 0.3), SKAction.fadeAlpha(to: 0.2, duration: 0.3)]))

        // Tail wrapped neatly against the flank
        tailBaseNode.run(.rotate(toAngle: 0.65, duration: 0.4))
        tailSegment1.run(.rotate(toAngle: 0.45, duration: 0.4))
        tailSegment2.run(.rotate(toAngle: 0.35, duration: 0.4))
        tailSegment3.run(.rotate(toAngle: 0.25, duration: 0.4))

        loopingFelineBlink()
    }

    private func animateSleeping() {
        // Deep curled sleeping cat ball
        bodyContainer.run(.group([
            SKAction.scaleY(to: 0.74, duration: 0.4),
            SKAction.scaleX(to: 1.12, duration: 0.4),
            SKAction.moveTo(y: -6, duration: 0.4)
        ]))
        headContainer.run(.moveTo(y: 3.5, duration: 0.4))
        frontLeftPawNode.run(.group([SKAction.moveTo(y: -14.5, duration: 0.4), SKAction.fadeAlpha(to: 0.1, duration: 0.4)]))
        frontRightPawNode.run(.group([SKAction.moveTo(y: -14.5, duration: 0.4), SKAction.fadeAlpha(to: 0.1, duration: 0.4)]))

        tailBaseNode.run(.rotate(toAngle: 0.85, duration: 0.4))
        tailSegment1.run(.rotate(toAngle: 0.55, duration: 0.4))
        tailSegment2.run(.rotate(toAngle: 0.45, duration: 0.4))

        // Closed crescent peaceful eyes
        leftEyeNode.yScale = 0.06
        rightEyeNode.yScale = 0.06

        // Deep sleep breathing rhythm (slow 3.6s cycle)
        let sleepBreathe = SKAction.sequence([
            SKAction.scaleY(to: 0.70, duration: 1.8),
            SKAction.scaleY(to: 0.76, duration: 1.8)
        ])
        bodyContainer.run(.repeatForever(sleepBreathe), withKey: Self.catAnimKey)

        // Occasional sleeping paw/whisker dream twitch
        let dreamTwitch = SKAction.sequence([
            .wait(forDuration: 5.0, withRange: 3.0),
            .run { [weak self] in
                self?.tailTipNode.run(SKAction.sequence([
                    SKAction.moveBy(x: 1, y: 1, duration: 0.08),
                    SKAction.moveBy(x: -1, y: -1, duration: 0.08)
                ]))
            }
        ])
        catRootNode.run(.repeatForever(dreamTwitch), withKey: Self.whiskerTwitchKey)

        // Soft floating glowing Zzz bubbles
        let spawnZzz = SKAction.run { [weak self] in
            guard let self = self else { return }
            let zLabel = SKLabelNode(text: "z")
            zLabel.fontSize = CGFloat.random(in: 8...11)
            zLabel.fontName = "HelveticaNeue-Bold"
            zLabel.fontColor = NSColor.systemIndigo.withAlphaComponent(0.85)
            zLabel.position = CGPoint(x: 10, y: 11)
            zLabel.alpha = 0
            self.effectsContainer.addChild(zLabel)

            let floatUp = SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.moveBy(x: CGFloat.random(in: 6...12), y: 15, duration: 1.8),
                SKAction.scale(to: 1.35, duration: 1.8)
            ])
            floatUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            zLabel.run(SKAction.sequence([floatUp, fadeOut, .removeFromParent()]))
        }

        let zzzLoop = SKAction.repeatForever(SKAction.sequence([spawnZzz, .wait(forDuration: 1.8)]))
        effectsContainer.run(zzzLoop)
    }

    /// Two-stage realistic cat stretch (front dip followed by back arch)
    private func animateStretch(completion: (() -> Void)?) {
        // Stage 1: Front dip stretch (lordosis)
        let stretchFront = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.moveBy(x: 6, y: -1, duration: 0.4))
            self.frontRightPawNode.run(SKAction.moveBy(x: 6, y: -1, duration: 0.4))
            self.headContainer.run(SKAction.moveBy(x: 3, y: -5, duration: 0.4))
            self.bodyContainer.run(SKAction.rotate(toAngle: -0.16, duration: 0.4))
            self.tailBaseNode.run(SKAction.rotate(toAngle: 0.55, duration: 0.4))
        }

        let holdFront = SKAction.wait(forDuration: 0.7)

        // Stage 2: Back upward arch stretch
        let stretchBack = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.moveTo(y: -15, duration: 0.35))
            self.frontRightPawNode.run(SKAction.moveTo(y: -15, duration: 0.35))
            self.headContainer.run(SKAction.moveTo(y: 11, duration: 0.35))
            self.bodyContainer.run(SKAction.group([
                SKAction.rotate(toAngle: 0.12, duration: 0.35),
                SKAction.scaleY(to: 1.15, duration: 0.35)
            ]))
            self.tailBaseNode.run(SKAction.rotate(toAngle: -0.35, duration: 0.35))
        }

        let holdBack = SKAction.wait(forDuration: 0.6)

        // Reset to normal
        let recover = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.headContainer.run(SKAction.moveTo(y: 9, duration: 0.3))
            self.bodyContainer.run(SKAction.group([
                SKAction.rotate(toAngle: 0, duration: 0.3),
                SKAction.scaleY(to: 1.0, duration: 0.3)
            ]))
            self.tailBaseNode.run(SKAction.rotate(toAngle: 0, duration: 0.3))
        }

        let seq = SKAction.sequence([
            stretchFront, holdFront,
            stretchBack, holdBack,
            recover, .wait(forDuration: 0.25),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    /// Authentic face grooming (paw lick & ear wipe)
    private func animateGroom(completion: (() -> Void)?) {
        let raisePaw = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -5, y: 8), duration: 0.22))
            self?.headContainer.run(SKAction.rotate(toAngle: -0.10, duration: 0.22))
        }
        let lickPaw = SKAction.sequence([
            SKAction.run { [weak self] in self?.tongueNode.isHidden = false },
            .wait(forDuration: 0.14),
            SKAction.run { [weak self] in self?.tongueNode.isHidden = true },
            .wait(forDuration: 0.1)
        ])
        let wipeFace1 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.moveBy(x: -3, y: 3, duration: 0.15))
        }
        let wipeFace2 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.moveBy(x: 3, y: -3, duration: 0.15))
        }
        let lowerPaw = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -6.5, y: -15), duration: 0.22))
            self?.headContainer.run(SKAction.rotate(toAngle: 0, duration: 0.22))
        }

        let seq = SKAction.sequence([
            raisePaw, .wait(forDuration: 0.2),
            lickPaw, lickPaw,
            wipeFace1, .wait(forDuration: 0.15), wipeFace2, .wait(forDuration: 0.15),
            wipeFace1, .wait(forDuration: 0.15), wipeFace2, .wait(forDuration: 0.15),
            lowerPaw, .wait(forDuration: 0.25),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateYawn(completion: (() -> Void)?) {
        let openMouth = SKAction.run { [weak self] in
            self?.headContainer.run(SKAction.moveBy(x: 0, y: 2, duration: 0.25))
            self?.mouthNode.run(SKAction.scale(to: 1.8, duration: 0.25))
            self?.tongueNode.isHidden = false
            self?.leftEyeNode.run(SKAction.scaleY(to: 0.08, duration: 0.25))
            self?.rightEyeNode.run(SKAction.scaleY(to: 0.08, duration: 0.25))
        }
        let holdYawn = SKAction.wait(forDuration: 0.65)
        let closeMouth = SKAction.run { [weak self] in
            self?.headContainer.run(SKAction.moveTo(y: 9, duration: 0.25))
            self?.mouthNode.run(SKAction.scale(to: 1.0, duration: 0.25))
            self?.tongueNode.isHidden = true
            self?.leftEyeNode.run(SKAction.scaleY(to: 1.0, duration: 0.2))
            self?.rightEyeNode.run(SKAction.scaleY(to: 1.0, duration: 0.2))
        }

        let seq = SKAction.sequence([
            openMouth, holdYawn, closeMouth, .wait(forDuration: 0.2),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animatePounce(completion: (() -> Void)?) {
        let crouch = SKAction.run { [weak self] in
            self?.bodyContainer.run(SKAction.scaleY(to: 0.75, duration: 0.2))
            self?.headContainer.run(SKAction.moveTo(y: 5, duration: 0.2))
        }

        // Butt wiggle preparation
        let wiggleLeft = SKAction.rotate(toAngle: -0.07, duration: 0.07)
        let wiggleRight = SKAction.rotate(toAngle: 0.07, duration: 0.07)
        let buttWiggle = SKAction.repeat(SKAction.sequence([wiggleLeft, wiggleRight]), count: 4)

        let springForward = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.catRootNode.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 12, y: 8, duration: 0.16),
                    SKAction.scaleY(to: 1.15, duration: 0.16)
                ]),
                SKAction.group([
                    SKAction.moveBy(x: 12, y: -8, duration: 0.16),
                    SKAction.scaleY(to: 0.85, duration: 0.16)
                ]),
                SKAction.scaleY(to: 1.0, duration: 0.12)
            ]))
        }

        let seq = SKAction.sequence([
            crouch, .wait(forDuration: 0.2),
            buttWiggle,
            springForward, .wait(forDuration: 0.5),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateCurious(completion: (() -> Void)?) {
        let tiltHead = SKAction.run { [weak self] in
            self?.headContainer.run(SKAction.rotate(toAngle: 0.25, duration: 0.3))
            self?.leftPupilNode.run(SKAction.scale(to: 1.35, duration: 0.3))
            self?.rightPupilNode.run(SKAction.scale(to: 1.35, duration: 0.3))
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -5, y: -9), duration: 0.3))
        }
        let tapPaw = SKAction.sequence([
            SKAction.run { [weak self] in self?.frontLeftPawNode.run(SKAction.moveTo(y: -13, duration: 0.14)) },
            .wait(forDuration: 0.14),
            SKAction.run { [weak self] in self?.frontLeftPawNode.run(SKAction.moveTo(y: -9, duration: 0.14)) },
            .wait(forDuration: 0.14)
        ])

        let seq = SKAction.sequence([
            tiltHead, .wait(forDuration: 0.4),
            tapPaw, tapPaw,
            .wait(forDuration: 0.6),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animatePickedUp() {
        shadowNode.run(SKAction.group([
            SKAction.scale(to: 0.45, duration: 0.2),
            SKAction.fadeAlpha(to: 0.10, duration: 0.2),
            SKAction.moveTo(y: -26, duration: 0.2)
        ]))

        bodyContainer.run(SKAction.group([
            SKAction.scaleY(to: 1.15, duration: 0.25),
            SKAction.scaleX(to: 0.88, duration: 0.25)
        ]))
        headContainer.run(SKAction.moveTo(y: 12, duration: 0.25))

        leftPupilNode.run(SKAction.scale(to: 1.35, duration: 0.2))
        rightPupilNode.run(SKAction.scale(to: 1.35, duration: 0.2))

        let wiggle1 = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -9, y: -19), duration: 0.2))
            self.frontRightPawNode.run(SKAction.move(to: CGPoint(x: 6, y: -17), duration: 0.2))
            self.backLeftPawNode.run(SKAction.move(to: CGPoint(x: -13, y: -18), duration: 0.2))
            self.backRightPawNode.run(SKAction.move(to: CGPoint(x: 10, y: -20), duration: 0.2))
            self.catRootNode.run(SKAction.rotate(toAngle: -0.05, duration: 0.2))
        }
        let wiggle2 = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -6, y: -17), duration: 0.2))
            self.frontRightPawNode.run(SKAction.move(to: CGPoint(x: 9, y: -19), duration: 0.2))
            self.backLeftPawNode.run(SKAction.move(to: CGPoint(x: -10, y: -20), duration: 0.2))
            self.backRightPawNode.run(SKAction.move(to: CGPoint(x: 13, y: -18), duration: 0.2))
            self.catRootNode.run(SKAction.rotate(toAngle: 0.05, duration: 0.2))
        }

        let wiggleLoop = SKAction.repeatForever(SKAction.sequence([
            wiggle1, .wait(forDuration: 0.2),
            wiggle2, .wait(forDuration: 0.2)
        ]))
        catRootNode.run(wiggleLoop, withKey: Self.pawWiggleKey)

        tailBaseNode.run(SKAction.rotate(toAngle: -0.45, duration: 0.3))
        tailSegment1.run(SKAction.rotate(toAngle: -0.2, duration: 0.3))
    }

    private func animateLanding(completion: (() -> Void)?) {
        shadowNode.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.fadeAlpha(to: 0.24, duration: 0.15),
            SKAction.moveTo(y: -16, duration: 0.15)
        ]))

        spawnLandingPuff()

        let squash = SKAction.group([
            SKAction.scaleY(to: 0.74, duration: 0.12),
            SKAction.scaleX(to: 1.20, duration: 0.12),
            SKAction.moveBy(x: 0, y: -4, duration: 0.12)
        ])
        squash.timingMode = .easeOut

        let rebound = SKAction.group([
            SKAction.scaleY(to: 1.06, duration: 0.15),
            SKAction.scaleX(to: 0.95, duration: 0.15),
            SKAction.moveBy(x: 0, y: 5, duration: 0.15)
        ])
        rebound.timingMode = .easeInEaseOut

        let settle = SKAction.group([
            SKAction.scaleY(to: 1.0, duration: 0.12),
            SKAction.scaleX(to: 1.0, duration: 0.12),
            SKAction.moveBy(x: 0, y: -1, duration: 0.12)
        ])
        settle.timingMode = .easeInEaseOut

        let finish = SKAction.run { [weak self] in
            if let completion = completion {
                completion()
            } else {
                self?.play(.idle)
            }
        }

        catRootNode.run(SKAction.sequence([squash, rebound, settle, finish]), withKey: Self.catAnimKey)
    }

    private func animateJump() {
        bodyContainer.run(SKAction.group([
            SKAction.scaleY(to: 1.22, duration: 0.18),
            SKAction.scaleX(to: 0.86, duration: 0.18)
        ]))
        frontLeftPawNode.run(SKAction.moveTo(y: -9, duration: 0.18))
        frontRightPawNode.run(SKAction.moveTo(y: -9, duration: 0.18))
        backLeftPawNode.run(SKAction.moveTo(y: -19, duration: 0.18))
        backRightPawNode.run(SKAction.moveTo(y: -19, duration: 0.18))
        tailBaseNode.run(SKAction.rotate(toAngle: 0.45, duration: 0.18))
    }

    private func animateHappy(completion: (() -> Void)?) {
        let bounceUp = SKAction.moveBy(x: 0, y: 5, duration: 0.13)
        bounceUp.timingMode = .easeOut
        let bounceDown = bounceUp.reversed()
        bounceDown.timingMode = .easeIn
        let bounce = SKAction.sequence([bounceUp, bounceDown])

        animate3DTailWave(amplitude: 0.5, speed: 0.4)

        for i in 0..<3 {
            let delay = Double(i) * 0.22
            let spawn = SKAction.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in
                    guard let self = self else { return }
                    let heart = SKLabelNode(text: "💖")
                    heart.fontSize = 12
                    heart.position = CGPoint(x: CGFloat.random(in: -12...12), y: 18)
                    self.effectsContainer.addChild(heart)
                    let pop = SKAction.group([
                        SKAction.moveBy(x: 0, y: 16, duration: 0.8),
                        SKAction.fadeOut(withDuration: 0.8),
                        SKAction.scale(to: 1.3, duration: 0.8)
                    ])
                    heart.run(SKAction.sequence([pop, .removeFromParent()]))
                }
            ])
            effectsContainer.run(spawn)
        }

        let fourBounces = SKAction.repeat(bounce, count: 4)
        let finishAction = SKAction.run { [weak self] in
            if let completion = completion {
                completion()
            } else {
                self?.play(.idle)
            }
        }
        catRootNode.run(.sequence([fourBounces, finishAction]), withKey: Self.catAnimKey)
    }

    private func animateWake(completion: (() -> Void)?) {
        let openEyes = SKAction.run { [weak self] in
            self?.leftEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
            self?.rightEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
        }
        let shake = SKAction.sequence([
            openEyes,
            .moveBy(x: 0, y: 4, duration: 0.2),
            .moveBy(x: 0, y: -4, duration: 0.2)
        ])
        if let completion = completion {
            catRootNode.run(.sequence([shake, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(shake, withKey: Self.catAnimKey)
        }
    }

    private func animateThinking() {
        headContainer.run(.rotate(toAngle: 0.16, duration: 0.35))
        let thinkLabel = SKLabelNode(text: "💭")
        thinkLabel.fontSize = 13
        thinkLabel.position = CGPoint(x: 16, y: 22)
        effectsContainer.addChild(thinkLabel)

        let pulse = SKAction.sequence([
            .scale(to: 1.2, duration: 0.6),
            .scale(to: 0.9, duration: 0.6)
        ])
        thinkLabel.run(.repeatForever(pulse))
        loopingFelineBlink()
    }

    private func animateConcerned() {
        let shiver = SKAction.sequence([
            .rotate(toAngle: 0.04, duration: 0.08),
            .rotate(toAngle: -0.04, duration: 0.08)
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
        let jump = SKAction.moveBy(x: 0, y: 15, duration: 0.22)
        let jumpBack = jump.reversed()
        let action = SKAction.group([spin, .sequence([jump, jumpBack])])
        if let completion = completion {
            catRootNode.run(.sequence([action, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(action, withKey: Self.catAnimKey)
        }
    }

    // MARK: - Sinuous Multi-Joint Tail Physics Wave

    private func animate3DTailWave(amplitude: CGFloat, speed: TimeInterval) {
        let waveLeft1 = SKAction.rotate(toAngle: amplitude, duration: speed)
        waveLeft1.timingMode = .easeInEaseOut
        let waveRight1 = SKAction.rotate(toAngle: -amplitude * 0.7, duration: speed)
        waveRight1.timingMode = .easeInEaseOut
        tailBaseNode.run(.repeatForever(.sequence([waveLeft1, waveRight1])), withKey: Self.tailAnimKey)

        let waveLeft2 = SKAction.rotate(toAngle: amplitude * 0.8, duration: speed * 0.9)
        waveLeft2.timingMode = .easeInEaseOut
        let waveRight2 = SKAction.rotate(toAngle: -amplitude * 0.6, duration: speed * 0.9)
        waveRight2.timingMode = .easeInEaseOut
        tailSegment1.run(.repeatForever(.sequence([waveLeft2, waveRight2])), withKey: Self.tailAnimKey)

        let waveLeft3 = SKAction.rotate(toAngle: amplitude * 0.6, duration: speed * 0.8)
        waveLeft3.timingMode = .easeInEaseOut
        let waveRight3 = SKAction.rotate(toAngle: -amplitude * 0.5, duration: speed * 0.8)
        waveRight3.timingMode = .easeInEaseOut
        tailSegment2.run(.repeatForever(.sequence([waveLeft3, waveRight3])), withKey: Self.tailAnimKey)
    }

    // MARK: - Natural Feline Blinking (Slow affectionate blinks + quick blinks)

    private func loopingFelineBlink() {
        let quickClose = SKAction.scaleY(to: 0.08, duration: 0.05)
        let quickOpen = SKAction.scaleY(to: 1.0, duration: 0.05)
        let quickBlink = SKAction.sequence([quickClose, quickOpen])

        // Feline slow trust blink
        let slowClose = SKAction.scaleY(to: 0.10, duration: 0.25)
        let holdClosed = SKAction.wait(forDuration: 0.20)
        let slowOpen = SKAction.scaleY(to: 1.0, duration: 0.25)
        let slowBlink = SKAction.sequence([slowClose, holdClosed, slowOpen])

        let blinkRoutine = SKAction.sequence([
            .wait(forDuration: 3.5, withRange: 2.0),
            quickBlink,
            .wait(forDuration: 4.5, withRange: 2.0),
            slowBlink
        ])
        leftEyeNode.run(.repeatForever(blinkRoutine), withKey: Self.blinkAnimKey)
        rightEyeNode.run(.repeatForever(blinkRoutine), withKey: Self.blinkAnimKey)
    }

    private func oneShotBlink(then completion: (() -> Void)?) {
        let close = SKAction.scaleY(to: 0.08, duration: 0.05)
        let open = SKAction.scaleY(to: 1.0, duration: 0.05)
        let sequence = completion != nil
            ? SKAction.sequence([close, open, .run(completion!)])
            : SKAction.sequence([close, open])
        leftEyeNode.run(sequence, withKey: Self.blinkAnimKey)
        rightEyeNode.run(sequence, withKey: Self.blinkAnimKey)
    }
}


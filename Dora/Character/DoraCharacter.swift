//
//  DoraCharacter.swift
//  Dora
//
//  Dora the Cat: A rich, lifelike, 3D-styled procedural feline companion.
//  Features layered volumetric 3D shading, dynamic contact shadow, glossy eyes with
//  specular highlights, multi-segment smooth physics tail, animated paws with pads,
//  and ultra-smooth feline animations.
//

import AppKit
import SpriteKit

final class DoraCharacter: SKNode {

    /// Bounding size of the cat
    let size: CGSize

    private(set) var currentAnimation: DoraAnimation = .idle

    // MARK: - Root & Shadow
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

    // 3D Color Palette (Warm Golden Ginger / Amber Tabby)
    private static let furBase = NSColor(red: 0.98, green: 0.62, blue: 0.28, alpha: 1.0)
    private static let furHighlight = NSColor(red: 1.0, green: 0.78, blue: 0.48, alpha: 1.0)
    private static let furShadow = NSColor(red: 0.82, green: 0.46, blue: 0.18, alpha: 1.0)
    private static let furDark = NSColor(red: 0.65, green: 0.32, blue: 0.12, alpha: 1.0)
    private static let chestWhite = NSColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1.0)
    private static let innerEarPink = NSColor(red: 0.98, green: 0.68, blue: 0.76, alpha: 1.0)
    private static let pawPadPink = NSColor(red: 0.96, green: 0.55, blue: 0.65, alpha: 1.0)
    private static let eyeEmerald = NSColor(red: 0.20, green: 0.78, blue: 0.52, alpha: 1.0)
    private static let eyeGlow = NSColor(red: 0.35, green: 0.92, blue: 0.65, alpha: 1.0)
    private static let nosePink = NSColor(red: 0.95, green: 0.48, blue: 0.58, alpha: 1.0)

    init(animationManager: AnimationManager = .shared) {
        let catSize = CGSize(width: 84, height: 78)
        self.size = catSize

        // 0. 3D Soft Contact Shadow (on ground / surface)
        shadowNode = SKShapeNode(ellipseOf: CGSize(width: 68, height: 18))
        shadowNode.fillColor = NSColor(white: 0.0, alpha: 0.28)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -27)
        shadowNode.zPosition = -2

        // 1. Multi-Joint 3D Tail
        tailSegment1 = SKShapeNode(rectOf: CGSize(width: 10, height: 18), cornerRadius: 5)
        tailSegment1.fillColor = Self.furBase
        tailSegment1.strokeColor = Self.furShadow
        tailSegment1.lineWidth = 1.2
        tailSegment1.position = CGPoint(x: 0, y: 9)

        tailSegment2 = SKShapeNode(rectOf: CGSize(width: 9, height: 18), cornerRadius: 4.5)
        tailSegment2.fillColor = Self.furBase
        tailSegment2.strokeColor = Self.furShadow
        tailSegment2.lineWidth = 1.2
        tailSegment2.position = CGPoint(x: 0, y: 15)

        tailSegment3 = SKShapeNode(rectOf: CGSize(width: 8, height: 18), cornerRadius: 4)
        tailSegment3.fillColor = Self.furHighlight
        tailSegment3.strokeColor = Self.furShadow
        tailSegment3.lineWidth = 1.2
        tailSegment3.position = CGPoint(x: 0, y: 15)

        tailTipNode = SKShapeNode(circleOfRadius: 4.5)
        tailTipNode.fillColor = Self.chestWhite
        tailTipNode.strokeColor = .clear
        tailTipNode.position = CGPoint(x: 0, y: 10)

        tailSegment3.addChild(tailTipNode)
        tailSegment2.addChild(tailSegment3)
        tailSegment1.addChild(tailSegment2)
        tailBaseNode.addChild(tailSegment1)
        tailBaseNode.position = CGPoint(x: -24, y: -10)
        tailBaseNode.zPosition = -1

        // 2. 3D Back Paws
        backLeftPawNode = DoraCharacter.createPaw(width: 15, height: 12, isBack: true)
        backRightPawNode = DoraCharacter.createPaw(width: 15, height: 12, isBack: true)
        backLeftPawNode.position = CGPoint(x: -18, y: -24)
        backRightPawNode.position = CGPoint(x: 18, y: -24)
        backLeftPawNode.zPosition = 0
        backRightPawNode.zPosition = 0

        // 3. Volumetric 3D Body
        bodyNode = SKShapeNode(rectOf: CGSize(width: 60, height: 50), cornerRadius: 25)
        bodyNode.fillColor = Self.furBase
        bodyNode.strokeColor = Self.furShadow
        bodyNode.lineWidth = 2.0

        bodyHighlightNode = SKShapeNode(ellipseOf: CGSize(width: 44, height: 26))
        bodyHighlightNode.fillColor = Self.furHighlight.withAlphaComponent(0.45)
        bodyHighlightNode.strokeColor = .clear
        bodyHighlightNode.position = CGPoint(x: 0, y: 10)

        chestFluffNode = SKShapeNode(ellipseOf: CGSize(width: 34, height: 32))
        chestFluffNode.fillColor = Self.chestWhite
        chestFluffNode.strokeColor = .clear
        chestFluffNode.position = CGPoint(x: 0, y: -8)

        bodyContainer.position = CGPoint(x: 0, y: -6)
        bodyContainer.zPosition = 1
        bodyContainer.addChild(bodyNode)
        bodyContainer.addChild(bodyHighlightNode)
        bodyContainer.addChild(chestFluffNode)

        // 4. 3D Front Paws with cute toe pads
        frontLeftPawNode = DoraCharacter.createPaw(width: 14, height: 12, isBack: false)
        frontRightPawNode = DoraCharacter.createPaw(width: 14, height: 12, isBack: false)
        frontLeftPawNode.position = CGPoint(x: -11, y: -25)
        frontRightPawNode.position = CGPoint(x: 11, y: -25)
        frontLeftPawNode.zPosition = 4
        frontRightPawNode.zPosition = 4

        // 5. 3D Head & Dimensional Features
        headNode = SKShapeNode(ellipseOf: CGSize(width: 56, height: 46))
        headNode.fillColor = Self.furBase
        headNode.strokeColor = Self.furShadow
        headNode.lineWidth = 2.0

        headHighlightNode = SKShapeNode(ellipseOf: CGSize(width: 38, height: 22))
        headHighlightNode.fillColor = Self.furHighlight.withAlphaComponent(0.5)
        headHighlightNode.strokeColor = .clear
        headHighlightNode.position = CGPoint(x: 0, y: 10)

        // 3D Ears with Depth
        let leftEarPath = CGMutablePath()
        leftEarPath.move(to: CGPoint(x: -24, y: 10))
        leftEarPath.addLine(to: CGPoint(x: -20, y: 32))
        leftEarPath.addLine(to: CGPoint(x: -4, y: 18))
        leftEarPath.closeSubpath()
        leftEarNode = SKShapeNode(path: leftEarPath)
        leftEarNode.fillColor = Self.furBase
        leftEarNode.strokeColor = Self.furShadow
        leftEarNode.lineWidth = 2.0

        let leftInnerPath = CGMutablePath()
        leftInnerPath.move(to: CGPoint(x: -21, y: 12))
        leftInnerPath.addLine(to: CGPoint(x: -18, y: 27))
        leftInnerPath.addLine(to: CGPoint(x: -7, y: 17))
        leftInnerPath.closeSubpath()
        leftInnerEarNode = SKShapeNode(path: leftInnerPath)
        leftInnerEarNode.fillColor = Self.innerEarPink
        leftInnerEarNode.strokeColor = .clear

        leftEarTipNode = SKShapeNode(circleOfRadius: 2.5)
        leftEarTipNode.fillColor = Self.furDark
        leftEarTipNode.strokeColor = .clear
        leftEarTipNode.position = CGPoint(x: -20, y: 31)

        let rightEarPath = CGMutablePath()
        rightEarPath.move(to: CGPoint(x: 24, y: 10))
        rightEarPath.addLine(to: CGPoint(x: 20, y: 32))
        rightEarPath.addLine(to: CGPoint(x: 4, y: 18))
        rightEarPath.closeSubpath()
        rightEarNode = SKShapeNode(path: rightEarPath)
        rightEarNode.fillColor = Self.furBase
        rightEarNode.strokeColor = Self.furShadow
        rightEarNode.lineWidth = 2.0

        let rightInnerPath = CGMutablePath()
        rightInnerPath.move(to: CGPoint(x: 21, y: 12))
        rightInnerPath.addLine(to: CGPoint(x: 18, y: 27))
        rightInnerPath.addLine(to: CGPoint(x: 7, y: 17))
        rightInnerPath.closeSubpath()
        rightInnerEarNode = SKShapeNode(path: rightInnerPath)
        rightInnerEarNode.fillColor = Self.innerEarPink
        rightInnerEarNode.strokeColor = .clear

        rightEarTipNode = SKShapeNode(circleOfRadius: 2.5)
        rightEarTipNode.fillColor = Self.furDark
        rightEarTipNode.strokeColor = .clear
        rightEarTipNode.position = CGPoint(x: 20, y: 31)

        // 6. Glossy 3D Eyes with Depth & Reflections
        let eyeSize = CGSize(width: 15, height: 18)
        leftEyeNode = SKShapeNode(ellipseOf: eyeSize)
        rightEyeNode = SKShapeNode(ellipseOf: eyeSize)
        for eye in [leftEyeNode, rightEyeNode] {
            eye.fillColor = Self.eyeEmerald
            eye.strokeColor = Self.furDark
            eye.lineWidth = 1.0
        }
        leftEyeNode.position = CGPoint(x: -13, y: 3)
        rightEyeNode.position = CGPoint(x: 13, y: 3)

        // Pupils
        let pupilSize = CGSize(width: 7, height: 14)
        leftPupilNode = SKShapeNode(ellipseOf: pupilSize)
        rightPupilNode = SKShapeNode(ellipseOf: pupilSize)
        for pupil in [leftPupilNode, rightPupilNode] {
            pupil.fillColor = NSColor(white: 0.05, alpha: 1.0)
            pupil.strokeColor = .clear
        }
        leftEyeNode.addChild(leftPupilNode)
        rightEyeNode.addChild(rightPupilNode)

        // Specular Catchlights (Primary + Secondary for glassy 3D look)
        leftHighlight1 = SKShapeNode(circleOfRadius: 3.0)
        rightHighlight1 = SKShapeNode(circleOfRadius: 3.0)
        leftHighlight2 = SKShapeNode(circleOfRadius: 1.5)
        rightHighlight2 = SKShapeNode(circleOfRadius: 1.5)

        for h in [leftHighlight1, rightHighlight1, leftHighlight2, rightHighlight2] {
            h.fillColor = .white
            h.strokeColor = .clear
        }
        leftHighlight1.position = CGPoint(x: 2.5, y: 3.5)
        rightHighlight1.position = CGPoint(x: 2.5, y: 3.5)
        leftHighlight2.position = CGPoint(x: -2.5, y: -3.5)
        rightHighlight2.position = CGPoint(x: -2.5, y: -3.5)

        leftEyeNode.addChild(leftHighlight1)
        leftEyeNode.addChild(leftHighlight2)
        rightEyeNode.addChild(rightHighlight1)
        rightEyeNode.addChild(rightHighlight2)

        // 7. 3D Muzzle, Pink Nose, Mouth
        muzzleNode = SKShapeNode(ellipseOf: CGSize(width: 22, height: 14))
        muzzleNode.fillColor = Self.chestWhite.withAlphaComponent(0.95)
        muzzleNode.strokeColor = .clear
        muzzleNode.position = CGPoint(x: 0, y: -6)

        let nosePath = CGMutablePath()
        nosePath.move(to: CGPoint(x: -4, y: -2))
        nosePath.addLine(to: CGPoint(x: 4, y: -2))
        nosePath.addLine(to: CGPoint(x: 0, y: -6))
        nosePath.closeSubpath()
        noseNode = SKShapeNode(path: nosePath)
        noseNode.fillColor = Self.nosePink
        noseNode.strokeColor = .clear

        let mouthPath = CGMutablePath()
        mouthPath.move(to: CGPoint(x: -6, y: -9))
        mouthPath.addQuadCurve(to: CGPoint(x: 0, y: -6.5), control: CGPoint(x: -3, y: -11))
        mouthPath.addQuadCurve(to: CGPoint(x: 6, y: -9), control: CGPoint(x: 3, y: -11))
        mouthNode = SKShapeNode(path: mouthPath)
        mouthNode.strokeColor = Self.furDark
        mouthNode.lineWidth = 1.6
        mouthNode.lineCap = .round

        // 8. 3D Curved Whiskers
        let whiskerPath = CGMutablePath()
        // Left whiskers
        whiskerPath.move(to: CGPoint(x: -16, y: -3))
        whiskerPath.addQuadCurve(to: CGPoint(x: -36, y: 1), control: CGPoint(x: -26, y: 0))
        whiskerPath.move(to: CGPoint(x: -16, y: -6))
        whiskerPath.addQuadCurve(to: CGPoint(x: -37, y: -6), control: CGPoint(x: -26, y: -6))
        whiskerPath.move(to: CGPoint(x: -16, y: -9))
        whiskerPath.addQuadCurve(to: CGPoint(x: -35, y: -14), control: CGPoint(x: -26, y: -11))
        // Right whiskers
        whiskerPath.move(to: CGPoint(x: 16, y: -3))
        whiskerPath.addQuadCurve(to: CGPoint(x: 36, y: 1), control: CGPoint(x: 26, y: 0))
        whiskerPath.move(to: CGPoint(x: 16, y: -6))
        whiskerPath.addQuadCurve(to: CGPoint(x: 37, y: -6), control: CGPoint(x: 26, y: -6))
        whiskerPath.move(to: CGPoint(x: 16, y: -9))
        whiskerPath.addQuadCurve(to: CGPoint(x: 35, y: -14), control: CGPoint(x: 26, y: -11))

        whiskersNode = SKShapeNode(path: whiskerPath)
        whiskersNode.strokeColor = NSColor(white: 0.15, alpha: 0.75)
        whiskersNode.lineWidth = 1.3
        whiskersNode.lineCap = .round

        // Assembly of Head Container
        headContainer.position = CGPoint(x: 0, y: 15)
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
        headContainer.addChild(noseNode)
        headContainer.addChild(mouthNode)
        headContainer.addChild(whiskersNode)

        effectsContainer.zPosition = 30

        super.init()

        // Assemble Character hierarchy
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
    private static func createPaw(width: CGFloat, height: CGFloat, isBack: Bool) -> SKNode {
        let container = SKNode()
        let paw = SKShapeNode(ellipseOf: CGSize(width: width, height: height))
        paw.fillColor = chestWhite
        paw.strokeColor = furShadow.withAlphaComponent(0.6)
        paw.lineWidth = 1.2
        container.addChild(paw)

        // Cute mini toe bean on bottom
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
        effectsContainer.removeAllChildren()

        catRootNode.position = .zero
        catRootNode.zRotation = 0
        catRootNode.yScale = 1.0
        catRootNode.alpha = 1.0

        shadowNode.setScale(1.0)
        shadowNode.alpha = 0.28
        shadowNode.position = CGPoint(x: 0, y: -27)

        bodyContainer.position = CGPoint(x: 0, y: -6)
        bodyContainer.yScale = 1.0
        bodyContainer.xScale = 1.0
        bodyContainer.zRotation = 0

        headContainer.position = CGPoint(x: 0, y: 15)
        headContainer.zRotation = 0
        headContainer.yScale = 1.0

        leftEyeNode.yScale = 1.0
        rightEyeNode.yScale = 1.0
        leftPupilNode.isHidden = false
        rightPupilNode.isHidden = false
        leftPupilNode.setScale(1.0)
        rightPupilNode.setScale(1.0)

        frontLeftPawNode.position = CGPoint(x: -11, y: -25)
        frontRightPawNode.position = CGPoint(x: 11, y: -25)
        frontLeftPawNode.zRotation = 0
        frontRightPawNode.zRotation = 0

        backLeftPawNode.position = CGPoint(x: -18, y: -24)
        backRightPawNode.position = CGPoint(x: 18, y: -24)

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

    // MARK: - Ultra-Smooth 3D Animation Routines

    private func animateIdle() {
        // Continuous smooth sine breathing
        let breatheIn = SKAction.group([
            SKAction.scaleY(to: 1.04, duration: 1.2),
            SKAction.scaleX(to: 0.98, duration: 1.2),
            SKAction.moveBy(x: 0, y: 1.5, duration: 1.2)
        ])
        breatheIn.timingMode = .easeInEaseOut
        let breatheOut = SKAction.group([
            SKAction.scaleY(to: 0.98, duration: 1.2),
            SKAction.scaleX(to: 1.02, duration: 1.2),
            SKAction.moveBy(x: 0, y: -1.5, duration: 1.2)
        ])
        breatheOut.timingMode = .easeInEaseOut
        bodyContainer.run(.repeatForever(.sequence([breatheIn, breatheOut])), withKey: Self.breathingAnimKey)

        // Smooth multi-segment sine wave tail swish
        animate3DTailWave(amplitude: 0.28, speed: 1.4)

        loopingBlink()

        // Occasional realistic ear flick
        let flickLeft = SKAction.sequence([
            .rotate(toAngle: -0.16, duration: 0.07),
            .rotate(toAngle: 0.05, duration: 0.06),
            .rotate(toAngle: 0, duration: 0.07)
        ])
        let earFlick = SKAction.sequence([
            .wait(forDuration: 3.5, withRange: 2.0),
            flickLeft
        ])
        leftEarNode.run(.repeatForever(earFlick), withKey: Self.earAnimKey)
    }

    private func animateWalking() {
        // Fluid 4-paw stride & 3D body sway
        let stepDuration = 0.16

        let stepA = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.moveTo(y: -19, duration: stepDuration))
            self.frontRightPawNode.run(SKAction.moveTo(y: -26, duration: stepDuration))
            self.backLeftPawNode.run(SKAction.moveTo(y: -26, duration: stepDuration))
            self.backRightPawNode.run(SKAction.moveTo(y: -21, duration: stepDuration))
            self.bodyContainer.run(SKAction.rotate(toAngle: -0.04, duration: stepDuration))
            self.headContainer.run(SKAction.moveTo(y: 13, duration: stepDuration))
        }

        let stepB = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.moveTo(y: -26, duration: stepDuration))
            self.frontRightPawNode.run(SKAction.moveTo(y: -19, duration: stepDuration))
            self.backLeftPawNode.run(SKAction.moveTo(y: -21, duration: stepDuration))
            self.backRightPawNode.run(SKAction.moveTo(y: -26, duration: stepDuration))
            self.bodyContainer.run(SKAction.rotate(toAngle: 0.04, duration: stepDuration))
            self.headContainer.run(SKAction.moveTo(y: 16, duration: stepDuration))
        }

        let walkCycle = SKAction.sequence([
            stepA, .wait(forDuration: stepDuration),
            stepB, .wait(forDuration: stepDuration)
        ])
        catRootNode.run(.repeatForever(walkCycle), withKey: Self.catAnimKey)

        animate3DTailWave(amplitude: 0.45, speed: 0.7)
        loopingBlink()
    }

    private func animateSitting() {
        // Cozy 3D cat loaf
        bodyContainer.run(.group([
            SKAction.scaleY(to: 0.82, duration: 0.35),
            SKAction.scaleX(to: 1.08, duration: 0.35)
        ]))
        headContainer.run(.moveTo(y: 9, duration: 0.35))
        frontLeftPawNode.run(.moveTo(y: -23, duration: 0.35))
        frontRightPawNode.run(.moveTo(y: -23, duration: 0.35))

        // Curl tail tightly around body
        tailBaseNode.run(.rotate(toAngle: 0.55, duration: 0.4))
        tailSegment1.run(.rotate(toAngle: 0.4, duration: 0.4))
        tailSegment2.run(.rotate(toAngle: 0.3, duration: 0.4))
        tailSegment3.run(.rotate(toAngle: 0.2, duration: 0.4))

        loopingBlink()
    }

    private func animateSleeping() {
        // Deep sleep curled pose
        bodyContainer.run(.group([
            SKAction.scaleY(to: 0.76, duration: 0.4),
            SKAction.scaleX(to: 1.12, duration: 0.4)
        ]))
        headContainer.run(.moveTo(y: 6, duration: 0.4))
        frontLeftPawNode.run(.moveTo(y: -24, duration: 0.4))
        frontRightPawNode.run(.moveTo(y: -24, duration: 0.4))

        tailBaseNode.run(.rotate(toAngle: 0.75, duration: 0.4))
        tailSegment1.run(.rotate(toAngle: 0.5, duration: 0.4))
        tailSegment2.run(.rotate(toAngle: 0.4, duration: 0.4))

        // Closed sleepy crescent eyes
        leftEyeNode.yScale = 0.07
        rightEyeNode.yScale = 0.07

        // Slow deep sleep breathing rhythm
        let sleepBreathe = SKAction.sequence([
            SKAction.scaleY(to: 0.72, duration: 2.0),
            SKAction.scaleY(to: 0.78, duration: 2.0)
        ])
        bodyContainer.run(.repeatForever(sleepBreathe), withKey: Self.catAnimKey)

        // Soft floating Zzz particles with glow
        let spawnZzz = SKAction.run { [weak self] in
            guard let self = self else { return }
            let zLabel = SKLabelNode(text: "z")
            zLabel.fontSize = CGFloat.random(in: 11...14)
            zLabel.fontName = "HelveticaNeue-Bold"
            zLabel.fontColor = NSColor.systemIndigo.withAlphaComponent(0.85)
            zLabel.position = CGPoint(x: 16, y: 18)
            zLabel.alpha = 0
            self.effectsContainer.addChild(zLabel)

            let floatUp = SKAction.group([
                SKAction.fadeIn(withDuration: 0.3),
                SKAction.moveBy(x: CGFloat.random(in: 10...18), y: 22, duration: 1.8),
                SKAction.scale(to: 1.4, duration: 1.8)
            ])
            floatUp.timingMode = .easeOut
            let fadeOut = SKAction.fadeOut(withDuration: 0.4)
            zLabel.run(SKAction.sequence([floatUp, fadeOut, .removeFromParent()]))
        }

        let zzzLoop = SKAction.repeatForever(SKAction.sequence([spawnZzz, .wait(forDuration: 1.6)]))
        effectsContainer.run(zzzLoop)
    }

    /// Picked-up / dragging animation: cute dangling cat with wiggling paws and dangling tail
    private func animatePickedUp() {
        // Lifted off ground: shrink & blur contact shadow
        shadowNode.run(SKAction.group([
            SKAction.scale(to: 0.5, duration: 0.2),
            SKAction.fadeAlpha(to: 0.12, duration: 0.2),
            SKAction.moveTo(y: -42, duration: 0.2)
        ]))

        // Stretched dangling body
        bodyContainer.run(SKAction.group([
            SKAction.scaleY(to: 1.15, duration: 0.25),
            SKAction.scaleX(to: 0.88, duration: 0.25)
        ]))
        headContainer.run(SKAction.moveTo(y: 19, duration: 0.25))

        // Wide curious eyes
        leftPupilNode.run(SKAction.scale(to: 1.35, duration: 0.2))
        rightPupilNode.run(SKAction.scale(to: 1.35, duration: 0.2))

        // Cute paw dangling & squirming
        let wiggle1 = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -14, y: -30), duration: 0.2))
            self.frontRightPawNode.run(SKAction.move(to: CGPoint(x: 10, y: -27), duration: 0.2))
            self.backLeftPawNode.run(SKAction.move(to: CGPoint(x: -20, y: -29), duration: 0.2))
            self.backRightPawNode.run(SKAction.move(to: CGPoint(x: 16, y: -32), duration: 0.2))
            self.catRootNode.run(SKAction.rotate(toAngle: -0.06, duration: 0.2))
        }
        let wiggle2 = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -10, y: -27), duration: 0.2))
            self.frontRightPawNode.run(SKAction.move(to: CGPoint(x: 14, y: -30), duration: 0.2))
            self.backLeftPawNode.run(SKAction.move(to: CGPoint(x: -16, y: -32), duration: 0.2))
            self.backRightPawNode.run(SKAction.move(to: CGPoint(x: 20, y: -29), duration: 0.2))
            self.catRootNode.run(SKAction.rotate(toAngle: 0.06, duration: 0.2))
        }

        let wiggleLoop = SKAction.repeatForever(SKAction.sequence([
            wiggle1, .wait(forDuration: 0.2),
            wiggle2, .wait(forDuration: 0.2)
        ]))
        catRootNode.run(wiggleLoop, withKey: Self.pawWiggleKey)

        // Hanging tail
        tailBaseNode.run(SKAction.rotate(toAngle: -0.45, duration: 0.3))
        tailSegment1.run(SKAction.rotate(toAngle: -0.2, duration: 0.3))
    }

    /// Landing bounce after being dropped or completing a jump
    private func animateLanding(completion: (() -> Void)?) {
        shadowNode.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.fadeAlpha(to: 0.28, duration: 0.15),
            SKAction.moveTo(y: -27, duration: 0.15)
        ]))

        // Elastic landing squash & recover
        let squash = SKAction.group([
            SKAction.scaleY(to: 0.72, duration: 0.12),
            SKAction.scaleX(to: 1.22, duration: 0.12),
            SKAction.moveBy(x: 0, y: -6, duration: 0.12)
        ])
        squash.timingMode = .easeOut

        let rebound = SKAction.group([
            SKAction.scaleY(to: 1.08, duration: 0.16),
            SKAction.scaleX(to: 0.94, duration: 0.16),
            SKAction.moveBy(x: 0, y: 8, duration: 0.16)
        ])
        rebound.timingMode = .easeInEaseOut

        let settle = SKAction.group([
            SKAction.scaleY(to: 1.0, duration: 0.14),
            SKAction.scaleX(to: 1.0, duration: 0.14),
            SKAction.moveBy(x: 0, y: -2, duration: 0.14)
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
        // Stretched upward pose for leaps
        bodyContainer.run(SKAction.group([
            SKAction.scaleY(to: 1.25, duration: 0.2),
            SKAction.scaleX(to: 0.85, duration: 0.2)
        ]))
        frontLeftPawNode.run(SKAction.moveTo(y: -15, duration: 0.2))
        frontRightPawNode.run(SKAction.moveTo(y: -15, duration: 0.2))
        backLeftPawNode.run(SKAction.moveTo(y: -30, duration: 0.2))
        backRightPawNode.run(SKAction.moveTo(y: -30, duration: 0.2))
        tailBaseNode.run(SKAction.rotate(toAngle: 0.5, duration: 0.2))
    }

    private func animatePounce(completion: (() -> Void)?) {
        // Classic cat butt wiggle before pounce!
        let crouch = SKAction.run { [weak self] in
            self?.bodyContainer.run(SKAction.scaleY(to: 0.75, duration: 0.25))
            self?.headContainer.run(SKAction.moveTo(y: 8, duration: 0.25))
        }

        let wiggleLeft = SKAction.rotate(toAngle: -0.08, duration: 0.08)
        let wiggleRight = SKAction.rotate(toAngle: 0.08, duration: 0.08)
        let buttWiggle = SKAction.repeat(SKAction.sequence([wiggleLeft, wiggleRight]), count: 4)

        let springForward = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.catRootNode.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: 18, y: 12, duration: 0.18),
                    SKAction.scaleY(to: 1.15, duration: 0.18)
                ]),
                SKAction.group([
                    SKAction.moveBy(x: 18, y: -12, duration: 0.18),
                    SKAction.scaleY(to: 0.85, duration: 0.18)
                ]),
                SKAction.scaleY(to: 1.0, duration: 0.15)
            ]))
        }

        let seq = SKAction.sequence([
            crouch, .wait(forDuration: 0.25),
            buttWiggle,
            springForward, .wait(forDuration: 0.6),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateCurious(completion: (() -> Void)?) {
        // Head tilted curiously + paw tap
        let tiltHead = SKAction.run { [weak self] in
            self?.headContainer.run(SKAction.rotate(toAngle: 0.28, duration: 0.35))
            self?.leftPupilNode.run(SKAction.scale(to: 1.3, duration: 0.3))
            self?.rightPupilNode.run(SKAction.scale(to: 1.3, duration: 0.3))
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -8, y: -16), duration: 0.3))
        }
        let tapPaw = SKAction.sequence([
            SKAction.run { [weak self] in self?.frontLeftPawNode.run(SKAction.moveTo(y: -22, duration: 0.15)) },
            .wait(forDuration: 0.15),
            SKAction.run { [weak self] in self?.frontLeftPawNode.run(SKAction.moveTo(y: -16, duration: 0.15)) },
            .wait(forDuration: 0.15)
        ])

        let seq = SKAction.sequence([
            tiltHead, .wait(forDuration: 0.5),
            tapPaw, tapPaw,
            .wait(forDuration: 0.8),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateWake(completion: (() -> Void)?) {
        let openEyes = SKAction.run { [weak self] in
            self?.leftEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
            self?.rightEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
        }
        let stretch = SKAction.sequence([
            openEyes,
            .moveBy(x: 0, y: 6, duration: 0.25),
            .moveBy(x: 0, y: -6, duration: 0.25)
        ])
        if let completion = completion {
            catRootNode.run(.sequence([stretch, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(stretch, withKey: Self.catAnimKey)
        }
    }

    private func animateStretch(completion: (() -> Void)?) {
        // Feline morning yoga stretch
        let stretchFront = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(.moveBy(x: 10, y: -2, duration: 0.45))
            self.frontRightPawNode.run(.moveBy(x: 10, y: -2, duration: 0.45))
            self.headContainer.run(.moveBy(x: 6, y: -8, duration: 0.45))
            self.bodyContainer.run(.rotate(toAngle: -0.18, duration: 0.45))
            self.tailBaseNode.run(.rotate(toAngle: 0.55, duration: 0.45))
        }
        let hold = SKAction.wait(forDuration: 0.85)
        let recover = SKAction.run { [weak self] in
            guard let self = self else { return }
            self.frontLeftPawNode.run(.moveTo(y: -25, duration: 0.4))
            self.frontRightPawNode.run(.moveTo(y: -25, duration: 0.4))
            self.headContainer.run(.moveTo(y: 15, duration: 0.4))
            self.bodyContainer.run(.rotate(toAngle: 0, duration: 0.4))
            self.tailBaseNode.run(.rotate(toAngle: 0, duration: 0.4))
        }
        let seq = SKAction.sequence([
            stretchFront, hold, recover, .wait(forDuration: 0.3),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateGroom(completion: (() -> Void)?) {
        let raisePaw = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -8, y: 14), duration: 0.25))
            self?.headContainer.run(SKAction.rotate(toAngle: -0.12, duration: 0.25))
        }
        let lickWipe1 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(.moveBy(x: -4, y: 4, duration: 0.15))
        }
        let lickWipe2 = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(.moveBy(x: 4, y: -4, duration: 0.15))
        }
        let lowerPaw = SKAction.run { [weak self] in
            self?.frontLeftPawNode.run(SKAction.move(to: CGPoint(x: -11, y: -25), duration: 0.25))
            self?.headContainer.run(SKAction.rotate(toAngle: 0, duration: 0.25))
        }

        let seq = SKAction.sequence([
            raisePaw, .wait(forDuration: 0.25),
            lickWipe1, .wait(forDuration: 0.15), lickWipe2, .wait(forDuration: 0.15),
            lickWipe1, .wait(forDuration: 0.15), lickWipe2, .wait(forDuration: 0.15),
            lowerPaw, .wait(forDuration: 0.3),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateYawn(completion: (() -> Void)?) {
        let openMouth = SKAction.run { [weak self] in
            self?.headContainer.run(.moveBy(x: 0, y: 3, duration: 0.3))
            self?.mouthNode.run(.scale(to: 2.0, duration: 0.3))
            self?.leftEyeNode.run(.scaleY(to: 0.1, duration: 0.3))
            self?.rightEyeNode.run(.scaleY(to: 0.1, duration: 0.3))
        }
        let holdYawn = SKAction.wait(forDuration: 0.75)
        let closeMouth = SKAction.run { [weak self] in
            self?.headContainer.run(.moveTo(y: 15, duration: 0.3))
            self?.mouthNode.run(.scale(to: 1.0, duration: 0.3))
            self?.leftEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
            self?.rightEyeNode.run(.scaleY(to: 1.0, duration: 0.2))
        }

        let seq = SKAction.sequence([
            openMouth, holdYawn, closeMouth, .wait(forDuration: 0.2),
            .run { completion?() }
        ])
        catRootNode.run(seq, withKey: Self.catAnimKey)
    }

    private func animateHappy(completion: (() -> Void)?) {
        let bounceUp = SKAction.moveBy(x: 0, y: 8, duration: 0.14)
        bounceUp.timingMode = .easeOut
        let bounceDown = bounceUp.reversed()
        bounceDown.timingMode = .easeIn
        let bounce = SKAction.sequence([bounceUp, bounceDown])

        animate3DTailWave(amplitude: 0.6, speed: 0.5)

        for i in 0..<3 {
            let delay = Double(i) * 0.25
            let spawn = SKAction.sequence([
                .wait(forDuration: delay),
                .run { [weak self] in
                    guard let self = self else { return }
                    let heart = SKLabelNode(text: "💖")
                    heart.fontSize = 16
                    heart.position = CGPoint(x: CGFloat.random(in: -18...18), y: 30)
                    self.effectsContainer.addChild(heart)
                    let pop = SKAction.group([
                        SKAction.moveBy(x: 0, y: 24, duration: 0.9),
                        SKAction.fadeOut(withDuration: 0.9),
                        SKAction.scale(to: 1.4, duration: 0.9)
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

    private func animateThinking() {
        headContainer.run(.rotate(toAngle: 0.16, duration: 0.4))
        let thinkLabel = SKLabelNode(text: "💭")
        thinkLabel.fontSize = 18
        thinkLabel.position = CGPoint(x: 26, y: 36)
        effectsContainer.addChild(thinkLabel)

        let pulse = SKAction.sequence([
            .scale(to: 1.25, duration: 0.6),
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
        let jump = SKAction.moveBy(x: 0, y: 22, duration: 0.25)
        let jumpBack = jump.reversed()
        let action = SKAction.group([spin, .sequence([jump, jumpBack])])
        if let completion = completion {
            catRootNode.run(.sequence([action, .run(completion)]), withKey: Self.catAnimKey)
        } else {
            catRootNode.run(action, withKey: Self.catAnimKey)
        }
    }

    // MARK: - 3D Multi-Joint Tail Wave Helper

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

    // MARK: - Blinking Helpers

    private func loopingBlink() {
        let close = SKAction.scaleY(to: 0.08, duration: 0.06)
        let open = SKAction.scaleY(to: 1.0, duration: 0.06)
        let blink = SKAction.sequence([.wait(forDuration: 3.2, withRange: 2.2), close, open])
        leftEyeNode.run(.repeatForever(blink), withKey: Self.blinkAnimKey)
        rightEyeNode.run(.repeatForever(blink), withKey: Self.blinkAnimKey)
    }

    private func oneShotBlink(then completion: (() -> Void)?) {
        let close = SKAction.scaleY(to: 0.08, duration: 0.06)
        let open = SKAction.scaleY(to: 1.0, duration: 0.06)
        let sequence = completion != nil
            ? SKAction.sequence([close, open, .run(completion!)])
            : SKAction.sequence([close, open])
        leftEyeNode.run(sequence, withKey: Self.blinkAnimKey)
        rightEyeNode.run(sequence, withKey: Self.blinkAnimKey)
    }
}

//
//  DoraScene.swift
//  Dora
//
//  The SpriteKit scene that hosts Dora the Cat and the floating Speech Bubble.
//  Coordinates movement, speech bubble positioning, and screen-space hit testing.
//

import AppKit
import SpriteKit

final class DoraScene: SKScene {

    private(set) var dora: DoraCharacter?
    private(set) var speechBubble: SpeechBubbleNode?
    private var movementController: MovementController?
    private var lastUpdateTime: TimeInterval?

    private var suggestionTimer: TimeInterval = 0
    private var nextSuggestionInterval: TimeInterval = 25.0

    var onOpenChatRequested: ((NSPoint) -> Void)?

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

        let bubble = SpeechBubbleNode()
        addChild(bubble)
        self.speechBubble = bubble

        // Initial welcome bubble
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.speechBubble?.showMessage("Meow! Click me anytime to chat! 🐾", autoDismissAfter: 7.0)
        }
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

        // Keep speech bubble anchored above cat
        if let dora = dora, let bubble = speechBubble {
            bubble.position = CGPoint(
                x: dora.position.x,
                y: dora.position.y + dora.size.height / 2 + 16
            )
        }

        // Periodic proactive tips/suggestions (only while roaming/idle, not while sleeping)
        if movementController?.mode != .sleepingInCorner {
            suggestionTimer += deltaTime
            if suggestionTimer >= nextSuggestionInterval {
                suggestionTimer = 0
                nextSuggestionInterval = TimeInterval.random(in: 35...65)
                let tip = LLMService.shared.getRandomSuggestion()
                speechBubble?.showMessage(tip, autoDismissAfter: 7.0)
            }
        }
    }

    func userBecameIdle() {
        movementController?.handleUserBecameIdle()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.speechBubble?.showMessage("You took a break! Need any tips or a chat? 🐾", autoDismissAfter: 6.0)
        }
    }

    func userResumedWork() {
        speechBubble?.hideMessage()
        movementController?.handleUserResumedWork()
    }

    @discardableResult
    private func placeDoraNearBottom() -> DoraCharacter {
        let character = DoraCharacter()
        character.position = CGPoint(x: size.width * 0.5, y: 0)
        addChild(character)
        self.dora = character
        return character
    }

    private func currentWalkableBounds() -> CGRect {
        guard let window = view?.window, let screen = window.screen else {
            return CGRect(origin: .zero, size: size)
        }
        return ScreenCoordinator.walkableBounds(windowFrame: window.frame, screen: screen)
    }

    // MARK: - Hit-Testing & Interactive Screen Rects

    func getInteractiveScreenRects() -> [NSRect] {
        guard let window = view?.window else { return [] }
        var rects: [NSRect] = []

        // 1. Cat Bounding Rect in Screen Coordinates
        if let dora = dora {
            let catSceneFrame = CGRect(
                x: dora.position.x - dora.size.width / 2 - 10,
                y: dora.position.y - dora.size.height / 2 - 10,
                width: dora.size.width + 20,
                height: dora.size.height + 20
            )
            let catScreenRect = NSRect(
                x: window.frame.minX + catSceneFrame.minX,
                y: window.frame.minY + catSceneFrame.minY,
                width: catSceneFrame.width,
                height: catSceneFrame.height
            )
            rects.append(catScreenRect)
        }

        // 2. Speech Bubble Bounding Rect in Screen Coordinates
        if let bubble = speechBubble, !bubble.isHidden && bubble.alpha > 0 {
            let bubbleFrame = bubble.bubbleFrameInParent
            let bubbleScreenRect = NSRect(
                x: window.frame.minX + bubbleFrame.minX,
                y: window.frame.minY + bubbleFrame.minY,
                width: bubbleFrame.width,
                height: bubbleFrame.height
            )
            rects.append(bubbleScreenRect)
        }

        return rects
    }

    func catScreenPosition() -> NSPoint {
        guard let window = view?.window, let dora = dora else { return .zero }
        return NSPoint(
            x: window.frame.minX + dora.position.x,
            y: window.frame.minY + dora.position.y
        )
    }
}

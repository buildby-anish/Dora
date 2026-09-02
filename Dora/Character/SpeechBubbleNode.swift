//
//  SpeechBubbleNode.swift
//  Dora
//
//  A floating speech/thought bubble rendered in SpriteKit above the Cat.
//  Displays intelligent suggestions, reactions, and chat previews.
//

import AppKit
import SpriteKit

final class SpeechBubbleNode: SKNode {

    private let bubbleBackground: SKShapeNode
    private let textLabel: SKLabelNode
    private let dismissTimerKey = "speechDismissTimer"

    var onBubbleClicked: (() -> Void)?

    override init() {
        bubbleBackground = SKShapeNode()
        textLabel = SKLabelNode(fontNamed: "SF Pro Rounded")

        super.init()

        bubbleBackground.fillColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)
        bubbleBackground.strokeColor = NSColor.separatorColor
        bubbleBackground.lineWidth = 1.5
        bubbleBackground.zPosition = 100

        textLabel.fontSize = 13
        textLabel.fontColor = NSColor.labelColor
        textLabel.numberOfLines = 3
        textLabel.preferredMaxLayoutWidth = 200
        textLabel.verticalAlignmentMode = .center
        textLabel.horizontalAlignmentMode = .center
        textLabel.zPosition = 101

        addChild(bubbleBackground)
        addChild(textLabel)

        self.alpha = 0
        self.isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showMessage(_ text: String, autoDismissAfter: TimeInterval = 6.0) {
        removeAction(forKey: dismissTimerKey)

        textLabel.text = text

        // Compute bubble bounds based on label size
        let paddingX: CGFloat = 16
        let paddingY: CGFloat = 12
        let labelFrame = textLabel.frame
        let bubbleWidth = max(labelFrame.width + paddingX * 2, 80)
        let bubbleHeight = max(labelFrame.height + paddingY * 2, 38)

        let bubbleRect = CGRect(
            x: -bubbleWidth / 2,
            y: 0,
            width: bubbleWidth,
            height: bubbleHeight
        )

        // Create bubble path with little bottom arrow
        let path = CGMutablePath()
        path.addRoundedRect(
            in: bubbleRect,
            cornerWidth: 14,
            cornerHeight: 14
        )
        // Little tail pointer pointing to cat
        path.move(to: CGPoint(x: -6, y: 0))
        path.addLine(to: CGPoint(x: 0, y: -8))
        path.addLine(to: CGPoint(x: 6, y: 0))
        path.closeSubpath()

        bubbleBackground.path = path
        textLabel.position = CGPoint(x: 0, y: bubbleHeight / 2)

        self.isHidden = false
        self.setScale(0.7)
        self.alpha = 0

        let appear = SKAction.group([
            SKAction.fadeIn(withDuration: 0.2),
            SKAction.scale(to: 1.0, duration: 0.2)
        ])
        appear.timingMode = .easeOut
        run(appear)

        if autoDismissAfter > 0 {
            let wait = SKAction.wait(forDuration: autoDismissAfter)
            let hide = SKAction.run { [weak self] in
                self?.hideMessage()
            }
            run(SKAction.sequence([wait, hide]), withKey: dismissTimerKey)
        }
    }

    func hideMessage() {
        let disappear = SKAction.group([
            SKAction.fadeOut(withDuration: 0.25),
            SKAction.scale(to: 0.7, duration: 0.25)
        ])
        disappear.timingMode = .easeIn
        run(SKAction.sequence([disappear, SKAction.run { [weak self] in
            self?.isHidden = true
        }]))
    }

    var bubbleFrameInParent: CGRect {
        guard !isHidden && alpha > 0 else { return .zero }
        let labelFrame = textLabel.frame
        let paddingX: CGFloat = 16
        let paddingY: CGFloat = 12
        let bubbleWidth = max(labelFrame.width + paddingX * 2, 80)
        let bubbleHeight = max(labelFrame.height + paddingY * 2, 38)
        return CGRect(
            x: position.x - bubbleWidth / 2,
            y: position.y - 8,
            width: bubbleWidth,
            height: bubbleHeight + 8
        )
    }
}

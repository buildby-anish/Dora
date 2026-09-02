//
//  ChatWindowController.swift
//  Dora
//
//  A floating, translucent chat panel for communicating with Dora the Cat.
//  Subclasses NSPanel with canBecomeKey enabled so the text field accepts keyboard typing.
//

import AppKit

final class ChatPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

final class ChatWindowController: NSWindowController, NSTextFieldDelegate {

    private let chatPanel: ChatPanel
    private let visualEffectView: NSVisualEffectView
    private let titleLabel: NSTextField
    private let statusLabel: NSTextField
    private let closeButton: NSButton

    private let scrollView: NSScrollView
    private let messageStackView: NSStackView
    private let inputField: NSTextField
    private let sendButton: NSButton

    private let chipsStackView: NSStackView

    var onMessageSent: ((String) -> Void)?
    var onCatReaction: ((DoraAnimation) -> Void)?

    init() {
        let width: CGFloat = 340
        let height: CGFloat = 460
        let contentRect = NSRect(x: 100, y: 100, width: width, height: height)

        chatPanel = ChatPanel(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        chatPanel.isOpaque = false
        chatPanel.backgroundColor = .clear
        chatPanel.hasShadow = true
        chatPanel.level = .floating
        chatPanel.isFloatingPanel = true
        chatPanel.becomesKeyOnlyIfNeeded = false
        chatPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        visualEffectView = NSVisualEffectView(frame: NSRect(origin: .zero, size: contentRect.size))
        visualEffectView.material = .popover
        visualEffectView.state = .active
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.wantsLayer = true
        visualEffectView.layer?.cornerRadius = 16
        visualEffectView.layer?.masksToBounds = true
        visualEffectView.layer?.borderWidth = 1
        visualEffectView.layer?.borderColor = NSColor.separatorColor.cgColor

        // Header
        titleLabel = NSTextField(labelWithString: "Dora 🐱")
        titleLabel.font = NSFont.systemFont(ofSize: 15, weight: .bold)
        titleLabel.textColor = .labelColor

        statusLabel = NSTextField(labelWithString: "Desktop Companion • Ready")
        statusLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        statusLabel.textColor = .secondaryLabelColor

        closeButton = NSButton(title: "✕", target: nil, action: nil)
        closeButton.bezelStyle = .inline
        closeButton.isBordered = false
        closeButton.font = NSFont.systemFont(ofSize: 13, weight: .bold)
        closeButton.contentTintColor = .secondaryLabelColor

        // Message Stack & Scroll View
        messageStackView = NSStackView()
        messageStackView.orientation = .vertical
        messageStackView.alignment = .width
        messageStackView.spacing = 10
        messageStackView.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.translatesAutoresizingMaskIntoConstraints = false
        documentView.addSubview(messageStackView)

        NSLayoutConstraint.activate([
            messageStackView.topAnchor.constraint(equalTo: documentView.topAnchor, constant: 10),
            messageStackView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor, constant: 12),
            messageStackView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor, constant: -12),
            messageStackView.bottomAnchor.constraint(lessThanOrEqualTo: documentView.bottomAnchor, constant: -10),
            documentView.widthAnchor.constraint(equalToConstant: width)
        ])

        scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false
        scrollView.documentView = documentView
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Quick Suggestion Chips
        chipsStackView = NSStackView()
        chipsStackView.orientation = .horizontal
        chipsStackView.spacing = 6
        chipsStackView.alignment = .centerY
        chipsStackView.distribution = .fillEqually
        chipsStackView.translatesAutoresizingMaskIntoConstraints = false

        // Input Bar
        inputField = NSTextField()
        inputField.placeholderString = "Ask Dora or say hello..."
        inputField.font = NSFont.systemFont(ofSize: 13)
        inputField.focusRingType = .exterior
        inputField.isBezeled = true
        inputField.bezelStyle = .roundedBezel
        inputField.isEditable = true
        inputField.isSelectable = true
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton = NSButton(title: "Send", target: nil, action: nil)
        sendButton.bezelStyle = .rounded
        sendButton.keyEquivalent = "\r"
        sendButton.translatesAutoresizingMaskIntoConstraints = false

        super.init(window: chatPanel)

        inputField.delegate = self

        setupLayout()
        setupActions()
        setupChips()

        // Welcome greeting
        addBotMessage("Meow! I'm Dora, your desktop cat! 🐾 Ask me for coding tips, jokes, or just say hi!")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        guard let window = window else { return }
        window.contentView = visualEffectView

        let headerView = NSView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.addSubview(titleLabel)
        headerView.addSubview(statusLabel)
        headerView.addSubview(closeButton)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.addSubview(headerView)
        visualEffectView.addSubview(scrollView)
        visualEffectView.addSubview(chipsStackView)
        visualEffectView.addSubview(inputField)
        visualEffectView.addSubview(sendButton)

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: visualEffectView.topAnchor, constant: 14),
            headerView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 16),
            headerView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -16),
            headerView.heightAnchor.constraint(equalToConstant: 36),

            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            statusLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),

            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 24),
            closeButton.heightAnchor.constraint(equalToConstant: 24),

            scrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: chipsStackView.topAnchor, constant: -8),

            chipsStackView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
            chipsStackView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -12),
            chipsStackView.bottomAnchor.constraint(equalTo: inputField.topAnchor, constant: -8),
            chipsStackView.heightAnchor.constraint(equalToConstant: 24),

            inputField.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor, constant: 12),
            inputField.trailingAnchor.constraint(equalTo: sendButton.leadingAnchor, constant: -6),
            inputField.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor, constant: -12),
            inputField.heightAnchor.constraint(equalToConstant: 28),

            sendButton.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor, constant: -12),
            sendButton.centerYAnchor.constraint(equalTo: inputField.centerYAnchor),
            sendButton.widthAnchor.constraint(equalToConstant: 60)
        ])
    }

    private func setupActions() {
        closeButton.target = self
        closeButton.action = #selector(hidePanel)

        sendButton.target = self
        sendButton.action = #selector(handleSend)

        inputField.target = self
        inputField.action = #selector(handleSend)
    }

    private func setupChips() {
        let chipData: [(String, String)] = [
            ("💡 Tip", "Give me a productivity tip"),
            ("😹 Joke", "Tell me a funny cat joke"),
            ("🔍 Debug", "Give me a debugging suggestion"),
            ("💖 Pet", "Pet the cat")
        ]

        for (title, query) in chipData {
            let chip = NSButton(title: title, target: self, action: #selector(handleChipClick(_:)))
            chip.bezelStyle = .inline
            chip.font = NSFont.systemFont(ofSize: 11)
            chip.identifier = NSUserInterfaceItemIdentifier(query)
            chipsStackView.addArrangedSubview(chip)
        }
    }

    @objc private func handleChipClick(_ sender: NSButton) {
        guard let query = sender.identifier?.rawValue else { return }
        sendUserQuery(query)
    }

    @objc private func handleSend() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputField.stringValue = ""
        sendUserQuery(text)
    }

    private func sendUserQuery(_ text: String) {
        addUserMessage(text)
        onMessageSent?(text)

        if text.lowercased().contains("pet") {
            onCatReaction?(.happy)
        } else {
            onCatReaction?(.thinking)
        }

        statusLabel.stringValue = "Dora is thinking... 💭"

        LLMService.shared.sendMessage(text) { [weak self] reply in
            guard let self = self else { return }
            self.statusLabel.stringValue = "Desktop Companion • Ready"
            self.addBotMessage(reply)
            self.onCatReaction?(.idle)
        }
    }

    func addUserMessage(_ text: String) {
        let bubble = createMessageBubble(text: text, isUser: true)
        messageStackView.addArrangedSubview(bubble)
        scrollToBottom()
    }

    func addBotMessage(_ text: String) {
        let bubble = createMessageBubble(text: text, isUser: false)
        messageStackView.addArrangedSubview(bubble)
        scrollToBottom()
    }

    private func createMessageBubble(text: String, isUser: Bool) -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let bubble = NSView()
        bubble.wantsLayer = true
        bubble.layer?.cornerRadius = 12
        bubble.layer?.backgroundColor = isUser
            ? NSColor.systemBlue.withAlphaComponent(0.85).cgColor
            : NSColor.controlBackgroundColor.withAlphaComponent(0.85).cgColor
        bubble.translatesAutoresizingMaskIntoConstraints = false

        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 12.5)
        label.textColor = isUser ? .white : .labelColor
        label.cell?.wraps = true
        label.preferredMaxLayoutWidth = 220
        label.translatesAutoresizingMaskIntoConstraints = false

        bubble.addSubview(label)
        container.addSubview(bubble)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: bubble.topAnchor, constant: 8),
            label.leadingAnchor.constraint(equalTo: bubble.leadingAnchor, constant: 10),
            label.trailingAnchor.constraint(equalTo: bubble.trailingAnchor, constant: -10),
            label.bottomAnchor.constraint(equalTo: bubble.bottomAnchor, constant: -8),

            bubble.topAnchor.constraint(equalTo: container.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            bubble.widthAnchor.constraint(lessThanOrEqualToConstant: 240)
        ])

        if isUser {
            bubble.trailingAnchor.constraint(equalTo: container.trailingAnchor).isActive = true
        } else {
            bubble.leadingAnchor.constraint(equalTo: container.leadingAnchor).isActive = true
        }

        return container
    }

    private func scrollToBottom() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let documentView = self.scrollView.documentView {
                documentView.layoutSubtreeIfNeeded()
                let bottomPoint = NSPoint(x: 0, y: documentView.frame.height - self.scrollView.contentView.bounds.height)
                self.scrollView.contentView.scroll(to: NSPoint(x: 0, y: max(bottomPoint.y, 0)))
                self.scrollView.reflectScrolledClipView(self.scrollView.contentView)
            }
        }
    }

    func showNear(screenPoint: NSPoint) {
        guard let window = window, let screen = NSScreen.main else { return }

        var targetX = screenPoint.x + 50
        var targetY = screenPoint.y + 40

        let screenFrame = screen.visibleFrame
        if targetX + window.frame.width > screenFrame.maxX {
            targetX = screenPoint.x - window.frame.width - 50
        }
        if targetY + window.frame.height > screenFrame.maxY {
            targetY = screenFrame.maxY - window.frame.height - 20
        }

        window.setFrameOrigin(NSPoint(x: targetX, y: targetY))
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window.makeFirstResponder(inputField)
    }

    @objc func hidePanel() {
        window?.orderOut(nil)
    }

    var isPanelVisible: Bool {
        window?.isVisible ?? false
    }
}

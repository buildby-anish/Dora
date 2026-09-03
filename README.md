# 🐱 Dora — Intelligent 3D Desktop Cat Companion

**Dora** is a lifelike, autonomous 3D-styled procedural desktop feline companion built natively for macOS using **Swift**, **AppKit**, and **SpriteKit**. She lives seamlessly on your screen above all windows, reacting to your activity, roaming the desktop, taking naps in corners, and chatting with you whenever you need assistance, coding tips, or companionship.

---

## ✨ Features

- **🎨 Rich 3D Procedural Character**:
  - Volumetric fur shading with layered golden amber highlights and warm underbelly fluff.
  - Glossy 3D emerald eyes with specular reflections, pupil dilation, and eyelid animations.
  - Multi-joint 3D articulated tail with continuous physics-based sine wave swishing.
  - Dynamic contact shadow on the desktop that scales, fades, and moves during leaps, bounces, and dangling.
  - Cute paws equipped with soft pink toe beans.

- **🏃‍♂️ Full-Screen 2D Autonomous Roaming**:
  - When you step away or stay inactive for $\ge 1$ minute (`UserActivityMonitor`), Dora wakes up, stretches, and explores your **entire screen**.
  - Leaps across desktop regions in smooth parabolic physics arcs (`y = 4 * h * t * (1 - t)`).
  - Performs spontaneous cat behaviors: pouncing on imaginary bugs, curious head tilts with paw taps, face grooming, yawning, stretching, and cozy loafing.

- **💤 4-Corner Smart Sleeping**:
  - When user typing or mouse activity resumes, Dora gracefully travels to one of the 4 screen corners (or closest corner).
  - Curls up into a cozy ball and drifts into a deep sleep accompanied by soft floating `Zzz` bubbles.

- **🖐️ Pick & Drop (Drag-and-Drop) & Click-to-Chat**:
  - **Click / Tap**: Tap Dora anytime to open the translucent AI Chat panel and trigger happy reactions (`💖`).
  - **Click & Drag**: Pick up Dora directly from your screen if she is blocking your view. She enters a cute dangling state with wiggling paws, follows your cursor across displays, and lands gently with an elastic squash-and-bounce when dropped.

- **💬 Intelligent AI Chat & Proactive Suggestions**:
  - Floating translucent frosted-glass chat interface with quick suggestion chips (Tips, Jokes, Debugging, Petting).
  - Proactive floating speech bubbles with helpful context and productivity suggestions.
  - Clean non-blocking click-through transparency: 100% of your screen remains clickable when not hovering directly over Dora.

---

## 🏗️ Architecture

```
Dora/
├── Application/
│   ├── AppDelegate.swift            # NSApplication lifecycle management
│   ├── ApplicationCoordinator.swift  # Wires character, window, interaction & sensors
│   └── main.swift                   # Entry point (accessory activation policy)
├── Character/
│   ├── AnimationManager.swift       # Sprite asset caching & fallback coordinator
│   ├── DoraAnimation.swift          # Animation states (idle, walk, jump, pounce, etc.)
│   ├── DoraCharacter.swift          # 3D procedural cat model & animation routines
│   ├── DoraScene.swift              # SpriteKit scene hosting Dora & speech bubble
│   ├── MovementController.swift     # Full-screen 2D roaming & 4-corner sleep engine
│   └── SpeechBubbleNode.swift       # Floating proactive thought/speech bubble
├── Intelligence/
│   └── LLMService.swift             # AI chat engine and intelligent suggestion generator
├── Sensors/
│   └── UserActivityMonitor.swift    # System-wide HID idle and resume detection
└── Window/
    ├── ChatWindowController.swift   # Translucent macOS chat panel
    ├── DoraWindow.swift             # Borderless, transparent, floating overlay window
    ├── InteractionController.swift  # Click-through management & Drag-to-Drop detection
    └── ScreenCoordinator.swift      # Multi-monitor & screen boundary coordinate math
```

---

## 🚀 Building & Running

### Prerequisites
- macOS 13.0 or later
- Xcode Command Line Tools (`swiftc` / Swift 5.9+)

### 1. Compile from Terminal
You can compile Dora directly using `swiftc`:

```bash
mkdir -p .module_cache
swiftc -module-cache-path .module_cache $(find Dora -name "*.swift") -o DoraApp_bin
```

### 2. Launch Dora
Run the executable directly:

```bash
./DoraApp_bin &
```

Dora will appear floating on your desktop.

### 3. Terminate Dora
To stop the background process:

```bash
pkill -f DoraApp_bin
```

---

## 🎮 Controls & Interactions

| Action | Gesture / Trigger | Description |
| :--- | :--- | :--- |
| **Open Chat** | Single Click / Tap | Opens the AI Chat panel near Dora |
| **Pick & Drop** | Click & Drag | Picks up Dora (dangling paws) and repositions her anywhere |
| **User Idle** | Inactive for 60s | Dora wakes up, stretches, and roams the full screen |
| **User Working** | Keypress / Mouse move | Dora travels to a corner and curls up to sleep |
| **Quick Tips** | Automatic / Chips | Dora shares proactive suggestions via floating bubbles |

---

## 📦 Git Workflow & Contribution

To push and manage your changes:

```bash
# 1. Check status
git status

# 2. Stage modified files
git add .

# 3. Commit changes
git commit -m "feat: enhance 3D animations, full-screen roaming, corner sleeping, and pick-and-drop"

# 4. Push to remote
git push origin main
```

---

## 📄 License
MIT License. Created with ❤️ for desktop companionship.

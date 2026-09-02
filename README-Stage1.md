# Dora — Stage 1: Project Setup, Transparent Window, Placeholder Character

This delivers exactly Stage 1 from the build plan: app lifecycle, a
transparent borderless desktop overlay, SpriteKit integration, and a
placeholder Dora character near the bottom of the primary screen.

I don't have a macOS/Xcode toolchain available in this environment, so
this code has **not** been compiled here — I've written it carefully
against current AppKit/SpriteKit APIs, but you should treat "does it
build" as the first thing to verify, per the testing steps below.

## Files in this delivery

```
Dora/
├── Dora/
│   ├── Application/
│   │   ├── DoraApp.swift               (new)
│   │   ├── AppDelegate.swift           (new)
│   │   └── ApplicationCoordinator.swift(new)
│   ├── Window/
│   │   ├── DoraWindow.swift            (new)
│   │   ├── WindowController.swift      (new)
│   │   └── ScreenCoordinator.swift     (new)
│   ├── Character/
│   │   ├── DoraScene.swift             (new)
│   │   └── DoraCharacter.swift         (new)
│   └── Resources/
│       └── Info-additions.plist        (reference only, see below)
└── README-Stage1.md
```

No empty stub files were created for future stages — `Behavior/`,
`Sensors/`, `Communication/`, `Memory/`, `Intelligence/`, `Settings/`
don't exist yet because they have no Stage 1 content.

## 1. Create the Xcode project

Hand-writing a `.xcodeproj`/`.pbxproj` file is fragile and not how
real Xcode projects are made, so create the project shell in Xcode
itself and then drop these files in:

1. Xcode → **File → New → Project…**
2. **macOS → App**, click Next.
3. Product Name: `Dora`. Interface: **AppKit** (not SwiftUI — Stage 5
   onward adds a SwiftUI Settings window, but the app shell itself is
   AppKit). Language: **Swift**.
4. Uncheck "Use Core Data" / "Include Tests" (not needed yet).
5. Save it anywhere you like.

Xcode will generate its own `AppDelegate.swift` and a storyboard/
`Main.storyboard` — **delete both**, along with the generated
`ViewController.swift` if present. Dora builds and shows its window
entirely in code; it doesn't use Interface Builder.

## 2. Add these files

Drag the `Application/`, `Window/`, and `Character/` folders (with
their contents) from this delivery into the Xcode project navigator,
under the `Dora` target. Make sure "Copy items if needed" and "Add to
target: Dora" are both checked.

## 3. Configure the target

In the **Dora target → Info** tab (or **Signing & Capabilities**,
depending on Xcode version), add:

- `LSUIElement` = `YES` (Boolean) — hides Dora from the Dock/Cmd+Tab.
  See `Resources/Info-additions.plist` for the exact key/value.

In **General → Frameworks, Libraries, and Embedded Content**, confirm
`SpriteKit.framework` is linked — Xcode's App template usually needs
you to add it manually: click **+**, search "SpriteKit", add it.

You do **not** need any entitlements or special permissions for Stage
1 — no sandboxing, no battery/idle/accessibility access yet. Those
come in Stages 7–9.

## 4. Remove the default entry point conflict

Xcode's App template normally uses `@main` on an `AppDelegate` or a
SwiftUI `App` struct. This project uses a plain top-level
`DoraApp.swift` script (`NSApplication.shared`, `app.run()`) as the
entry point instead, so:

- Make sure there is **no** `@main` attribute anywhere in the project.
- Make sure there is **no** other file calling `NSApplicationMain` or
  constructing a second `NSApplication`.
- In **Build Settings**, confirm `Info.plist → Principal class` isn't
  overridden to something unexpected (default is fine).

If Xcode complains about a missing entry point, the simplest fix is:
Build Settings → search "Info.plist" → ensure **Generate Info.plist
File** is `Yes` and there's no explicit `Main` storyboard reference
left over (**Main Interface** setting should be blank).

## 5. Build and run

- Select the `Dora` scheme, choose "My Mac" as the run destination.
- **Cmd+R**.

## 6. What you should see

- No Dock icon, no menu bar app menu (because of `LSUIElement`).
- A fullscreen, invisible overlay window over your desktop — you
  won't see a window frame or background, only:
- A small teal rounded-rectangle "robot body" with two black oval
  eyes, sitting near the bottom-center of your primary screen.
- The body gently bobs up and down, and the eyes blink every couple
  of seconds — confirms SpriteKit's action/update loop is live, not a
  static image.
- In DEBUG builds, an FPS/node-count overlay in the corner (from
  `SKView.showsFPS`/`showsNodeCount`) — should read close to 60 FPS
  doing effectively nothing.

## 7. Known limitations (by design, for this stage)

- **Click-through is off.** The window currently intercepts mouse
  events everywhere on screen (not just over Dora), so e.g. clicking
  your Dock or other app windows underneath Dora's window may not
  work as expected right now. This is intentional for Stage 1 so you
  can confirm the window exists and is interactive; Stage 4 (Mouse
  Interaction) implements proximity-based click-through so only the
  area near Dora captures the mouse, as described in
  `DoraWindow.swift`'s doc comment.
- **No movement yet.** Dora is static except for the idle bob/blink.
  Autonomous roaming is Stage 3.
- **Single-monitor only for now.** `ScreenCoordinator` always resolves
  to `NSScreen.main`; multi-monitor support is a documented future
  seam, not implemented yet.
- **Placeholder art only.** The rounded-rectangle body is intended to
  be replaced by real sprite-sheet animation in Stage 2 without
  touching any other file — `DoraScene` and everything above it only
  depend on `DoraCharacter.size`/`.position`.

## 8. If it doesn't build

The most common first-build issues with this kind of project are:

- **"Cannot find 'NSApplication' "-type errors** → target platform
  isn't set to macOS, or you picked the iOS App template by mistake.
- **Duplicate `main` / entry point errors** → leftover generated
  `AppDelegate.swift` or `@main` from the Xcode template wasn't
  deleted (see step 4).
- **SpriteKit symbols not found** → framework not linked (see step 3).

Let me know what you see (working, or a specific build error) and
we'll fix it before moving to Stage 2 (Character architecture,
animation system, fallback assets), per the "confirm before
proceeding" workflow rule.

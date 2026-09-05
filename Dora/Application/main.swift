//
//  main.swift
//  Dora
//
//  Application entry point. Dora is an AppKit app (not a SwiftUI App
//  lifecycle) because it needs full control over a borderless,
//  transparent, always-on-top window that behaves like a desktop
//  overlay rather than a normal document/utility window.
//
//  This file exists purely to bootstrap NSApplication and hand off
//  control to AppDelegate, which builds the rest of the app.
//
//  IMPORTANT: this file must be named exactly "main.swift". Swift
//  only permits top-level executable statements (not wrapped in a
//  function/type) in a file with that exact name — in any other file,
//  the same statements are a compile error ("expressions are not
//  allowed at the top level"). If you rename this file, either rename
//  it back to main.swift or convert it to an @main-attributed type
//  instead (but not both — a target can only have one entry point).
//

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Dora is a background/accessory-style app (no Dock icon, no menu bar
// app menu) which suits a desktop companion. This is also set via
// LSUIElement = YES in Info.plist; setting it here too is harmless
// and makes the intent explicit in code.
app.setActivationPolicy(.accessory)

// Configure smooth animation runtime environment
UserDefaults.standard.register(defaults: [
    "NSApplicationCrashOnExceptions": true
])

#if DEBUG
print("🐱 [Dora] Initialized 3D Procedural Companion — Starting AppKit Loop")
#endif

app.run()

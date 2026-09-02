//
//  DoraApp.swift
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

import AppKit

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

// Dora is a background/accessory-style app (no Dock icon, no menu bar
// app menu) which suits a desktop companion. This is also set via
// LSUIElement = YES in Info.plist; setting it here too is harmless
// and makes the intent explicit in code.
app.setActivationPolicy(.accessory)

app.run()

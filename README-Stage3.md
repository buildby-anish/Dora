# Dora — Stage 3: Autonomous Movement, Screen Boundaries, Movement States

## What changed

**Files created:**

- `Character/MovementController.swift` — owns the movement data the
  spec calls for (`currentPosition`, `targetPosition`, `movementSpeed`,
  `facingDirection`) and a 3-state machine (`idle` / `walking` /
  `sitting`). Every frame it either waits out a timer (idle/sitting)
  or steps Dora smoothly toward a chosen destination (walking) — never
  by teleporting. Entirely deterministic; it has no dependency on the
  LLM or any AI system, per the architecture rules.

**Files modified:**

- `Window/ScreenCoordinator.swift` — added `walkableBounds(windowFrame:screen:)`,
  which converts a screen's visible frame (i.e. excluding the Dock and
  menu bar) into the window's local coordinate space. This is the only
  place in the app that talks to `NSScreen` for this purpose —
  `MovementController` just receives a plain `CGRect`.
- `Character/DoraScene.swift` — now computes Dora's real walkable
  rectangle from the actual screen on `didMove(to:)` and whenever the
  scene resizes, and drives `MovementController.update(deltaTime:)`
  once per frame from SpriteKit's own `update(_:)` callback. Frame
  delta is clamped to 0.25s so a stalled frame (display sleep, a
  debugger breakpoint) can't hand Dora a huge jump on the next frame —
  "avoid teleportation" is enforced at the timing layer, not just via
  position math.

**Deviation from the Stage 2 plan (explained, per the project's own
rule to explain before changing structure):** Stage 2's `DoraScene`
had a `DEBUG`-only timer that cycled Dora through all 12 animations,
with a note that it'd be removed once `BehaviorEngine` (Stage 5)
existed to drive real state changes. `MovementController` now drives
`idle`/`walking`(→ `walkLeft`/`walkRight`)/`sitting` for real, two
stages earlier than planned. Leaving the old demo running alongside it
would mean two independent timers both calling
`DoraCharacter.play(...)`, fighting for control of the same
animations — so it's removed now instead of at Stage 5. The other six
states (`sleep`, `wake`, `thinking`, `happy`, `concerned`, `charging`,
`celebrate` — that's seven, `blink` is the twelfth and is still driven
automatically by the idle placeholder) have no driver yet; they remain
fully working and reachable via `DoraCharacter.play(_:)` whenever a
sensor or `BehaviorEngine` starts calling them.

## How it behaves

Roughly, on a loop:

```
idle (3–8s, random)
  → 55% chance: pick a random point on the visible screen width,
    turn to face it, walk there at 90pt/s, then back to idle
  → 20% chance: sit for 4–10s, then stand back to idle
  → 25% chance: just re-roll the idle timer (stay put)
```

These probabilities and durations are placeholder tuning constants,
not final values — they exist so Dora feels alive today, and are
obvious candidates for the "Animation activity" setting in Stage 20,
or for `BehaviorEngine` to override based on mood in Stage 5.

Dora is always clamped to the screen's visible width (never walks
under the Dock or off either edge) and always stays on one ground
line just above the Dock/screen bottom.

## How to test

1. Add `MovementController.swift` to the Xcode project, and re-add the
   updated `ScreenCoordinator.swift` / `DoraScene.swift`. Build and
   run.
2. Watch for at least 30–60 seconds. You should see Dora:
   - Occasionally walk to a new random spot along the bottom of the
     screen, mirroring to face the direction she's walking, at a
     smooth constant speed (no snapping/jumping).
   - Occasionally sit for several seconds (squashed placeholder pose)
     before standing back up.
   - Occasionally just stay idle for a stretch without doing anything.
   - Never walk past the Dock or off either edge of the screen.
3. Resize behavior: move the app to a different display or change
   display resolution (System Settings → Displays) while Dora is
   walking or idle. She should stay within the new screen's bounds
   without jumping to an invalid position.
4. FPS should remain steady (Stage 1's debug overlay) — movement is a
   handful of arithmetic operations per frame, not per-frame
   allocation.

## Known limitations (by design, for this stage)

- Movement is horizontal-only, along one fixed ground line — no
  vertical movement, climbing, or jumping between elements.
- Destination choice is uniform-random across the whole visible width;
  there's no concept yet of "interesting" places to walk toward (e.g.
  the battery menu-bar icon in Stage 7, or the mouse cursor).
- No mouse interaction yet (Stage 4) — walking isn't interrupted by
  clicking or hovering.
- The 55/20/25 decision weights and idle/sit duration ranges are
  hardcoded constants in `MovementController`, not yet wired to
  Settings or mood.

Let me know if this builds and Dora roams the way you'd expect, and
I'll move on to Stage 4 (mouse interaction: hover, click, drag).

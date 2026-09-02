# Dora — Stage 2: Character Architecture, Animation System, Fallback Assets

## What changed

**Files created:**

- `Character/DoraAnimation.swift` — enum of all 12 animation states
  (`idle`, `blink`, `walkLeft`, `walkRight`, `sit`, `sleep`, `wake`,
  `thinking`, `happy`, `concerned`, `charging`, `celebrate`), each with
  its asset-atlas name, default frame duration, and whether it loops.
- `Character/AnimationManager.swift` — loads and **caches** texture
  atlases per animation (each atlas is only ever read from disk once),
  plays them at a **configurable frame rate**, and reports back
  whether real art existed so the caller can fall back gracefully.
- `Resources/DoraAssets/README.md` — documents the `<Name>.atlas`
  naming convention so real art can be dropped in later with **zero
  code changes**. No placeholder asset folders were created (they'd
  be empty until real art exists, which the project rules say to
  avoid) — this file is the seam instead.

**Files rewritten:**

- `Character/DoraCharacter.swift` — now has two visual layers: a
  (currently hidden) `SKSpriteNode` that `AnimationManager` drives
  once real frames exist, and a placeholder vector layer with a
  distinct hand-built reaction for **every one of the 12 states**
  (color, motion, and eye state all change per state). Exposes a
  single `play(_ animation:)` method; everything else about how a
  state looks is private to this file.
- `Character/DoraScene.swift` — places Dora as before, and in DEBUG
  builds only, cycles her through all 12 animations every 2.5s so you
  can see the whole system working without waiting for BehaviorEngine
  (Stage 5) to exist and actually decide states.

**Files unchanged:** everything under `Application/` and `Window/`.

## How the fallback system works

`DoraCharacter.play(.happy)` (for example) asks `AnimationManager` to
play the `Happy.atlas` frames on the sprite layer. If that atlas
doesn't exist yet, `AnimationManager` returns `false` and touches
nothing; `DoraCharacter` then hides the (empty) sprite layer, shows
the placeholder layer, and runs a placeholder-specific reaction — for
`.happy` that's a yellow tint and a repeating bounce. The moment you
add a real `Happy.atlas` folder (see
`Resources/DoraAssets/README.md`), the same call automatically uses
it instead — no code changes anywhere.

## How to test

1. Add the new/changed files to the Xcode project (same drag-in
   process as Stage 1) and build/run.
2. In a DEBUG build, Dora should now cycle through a different look
   every ~2.5 seconds, in this order: idle (teal, bobbing) → walk left
   (rocking, mirrored) → walk right (rocking) → sit (squashed) →
   thinking (indigo, tilting) → happy (yellow, bouncing) → concerned
   (orange, quick shake) → charging (green, pulsing) → sleep (dim,
   eyes shut, slow bob) → wake (eyes snap open) → celebrate (pink,
   spin + jump) → back to idle.
3. Confirm the FPS counter (from Stage 1) stays steady through all of
   these — nothing here should cause frame drops or leaks, since
   textures are cached and no per-frame allocation happens in the
   placeholder actions.
4. Optional: try adding a real `Idle.atlas` folder with a couple of
   test frames per `Resources/DoraAssets/README.md`, rebuild, and
   confirm Dora switches to the real frames for `idle` while every
   other state still shows its placeholder — this proves the
   per-animation fallback is independent per state, not all-or-nothing
   for the whole character.

## Known limitations (by design, for this stage)

- The debug animation-cycle demo is a temporary test harness, not real
  behavior — it's explicitly marked for removal once Stage 5
  (BehaviorEngine) exists to drive state changes for real reasons
  (mood, battery, idle time, etc.).
- Movement is still cosmetic only (rocking in place) — Dora doesn't
  actually travel anywhere yet; that's Stage 3.
- No mouse interaction yet (Stage 4) — you can't click/drag/hover to
  trigger these states manually.
- `walkLeft`/`walkRight` share one atlas and are distinguished only by
  horizontal mirroring (`xScale`), per the asset-structure note in
  `Resources/DoraAssets/README.md` — this was a deliberate scope
  decision to avoid doubling up frame art, not an oversight.

Let me know if this builds cleanly and the demo cycle looks right,
and I'll move on to Stage 3 (autonomous movement, screen boundaries,
movement states).

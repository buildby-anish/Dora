# DoraAssets — asset convention

No art files live here yet — this directory documents the convention
`AnimationManager` expects, so that adding real art later is a drop-in
operation with **zero code changes**.

## How to add real art for an animation

1. Create a folder named exactly `<AtlasName>.atlas` (the literal
   suffix `.atlas` is required — it's what tells Xcode/SpriteKit to
   treat the folder as a texture atlas at build time).
2. Put your numbered frame images inside it, e.g.:

   ```
   Idle.atlas/
   ├── idle_0.png
   ├── idle_1.png
   ├── idle_2.png
   └── idle_3.png
   ```

   Frame files just need to sort in playback order — `AnimationManager`
   loads `atlas.textureNames.sorted()`, so numeric zero-padding
   (`idle_00`, `idle_01`, …) is only necessary once you have 10+
   frames, to avoid `idle_10` sorting before `idle_2`.
3. Drag the `<AtlasName>.atlas` folder into the Xcode project as a
   **folder reference** (blue folder icon, not a yellow group) so it's
   copied into the app bundle as a real atlas rather than flattened.
4. Build and run. `AnimationManager` will find it automatically the
   next time that animation is requested — nothing else needs to
   change. Until then, `DoraCharacter` shows its built-in placeholder
   reaction for that state instead.

Atlas names, one per `DoraAnimation` case (see `DoraAnimation.swift`):

| Animation             | Atlas folder     |
|------------------------|------------------|
| idle                   | `Idle.atlas`     |
| blink                  | `Blink.atlas`    |
| walkLeft / walkRight   | `Walk.atlas` (shared — mirrored via horizontal flip, no separate left/right art needed) |
| sit                     | `Sit.atlas`      |
| sleep                   | `Sleep.atlas`    |
| wake                    | `Wake.atlas`     |
| thinking                | `Think.atlas`    |
| happy                   | `Happy.atlas`    |
| concerned               | `Concerned.atlas`|
| charging                | `Charging.atlas` |
| celebrate               | `Celebrate.atlas`|

## Alternative: Asset Catalog Sprite Atlas

Instead of a `.atlas` folder reference, you can also create a
**Sprite Atlas** inside `Assets.xcassets` named identically (e.g.
`Idle`) and add the same numbered images to it. `SKTextureAtlas(named:)`
resolves either form transparently — `AnimationManager` doesn't need
to know or care which one you used.

//
//  AnimationManager.swift
//  Dora
//
//  Loads, caches, and plays sprite-sheet animations for Dora.
//
//  Responsibilities (per Stage 2 requirements):
//    - Cache textures so each atlas is only ever loaded from disk once.
//    - Support a configurable frame rate per animation/per call.
//    - Report when an animation has no real art yet, so the caller
//      (DoraCharacter) can fall back to a placeholder reaction instead
//      of playing nothing or crashing.
//
//  This type knows nothing about *why* an animation is being played
//  (that's Behavior/BehaviorEngine's job, arriving in Stage 5) or what
//  Dora looks like when there's no real art (that's DoraCharacter's
//  placeholder logic). It only knows how to get frames onto a sprite
//  node efficiently.
//

import SpriteKit

final class AnimationManager {

    static let shared = AnimationManager()

    /// Keyed by atlas name (not by DoraAnimation) since walkLeft and
    /// walkRight intentionally share one atlas — caching by atlas
    /// name avoids loading "Walk.atlas" twice.
    private var textureCache: [String: [SKTexture]] = [:]
    private var missingAtlasWarningsIssued: Set<String> = []

    init() {}

    /// Whether real sprite-sheet frames currently exist for this
    /// animation. Safe to call before `play` to decide whether a
    /// caller even wants to attempt it, though `play`'s return value
    /// covers that too.
    func hasRealArt(for animation: DoraAnimation) -> Bool {
        !textures(for: animation).isEmpty
    }

    /// Returns the cached frame list for `animation`, loading and
    /// caching it from disk the first time it's requested. An empty
    /// result means no `.atlas` folder (or Sprite Atlas) named
    /// `animation.atlasName` exists yet — that's expected and normal
    /// before final art is added, not an error.
    func textures(for animation: DoraAnimation) -> [SKTexture] {
        let atlasName = animation.atlasName

        if let cached = textureCache[atlasName] {
            return cached
        }

        let atlas = SKTextureAtlas(named: atlasName)
        let frameNames = atlas.textureNames.sorted()
        let frames = frameNames.map { atlas.textureNamed($0) }
        frames.forEach { $0.filteringMode = .nearest }

        textureCache[atlasName] = frames

        if frames.isEmpty, !missingAtlasWarningsIssued.contains(atlasName) {
            missingAtlasWarningsIssued.insert(atlasName)
            #if DEBUG
            print("[AnimationManager] No frames found for \"\(atlasName).atlas\" — using placeholder for animations that use it.")
            #endif
        }

        return frames
    }

    /// Plays `animation` on `spriteNode` if real frames exist for it.
    ///
    /// - Returns: `true` if frames were found and the animation was
    ///   started; `false` if there's no real art for this animation
    ///   yet, in which case `spriteNode` is left untouched and the
    ///   caller is expected to run its own placeholder reaction.
    @discardableResult
    func play(
        _ animation: DoraAnimation,
        on spriteNode: SKSpriteNode,
        frameDuration: TimeInterval? = nil,
        key: String,
        completion: (() -> Void)? = nil
    ) -> Bool {
        let frames = textures(for: animation)
        guard !frames.isEmpty else { return false }

        spriteNode.removeAction(forKey: key)

        let duration = frameDuration ?? animation.defaultFrameDuration
        let animate = SKAction.animate(with: frames, timePerFrame: duration, resize: false, restore: false)

        let action: SKAction
        if animation.loops {
            action = .repeatForever(animate)
        } else if let completion {
            action = .sequence([animate, .run(completion)])
        } else {
            action = animate
        }

        spriteNode.run(action, withKey: key)
        return true
    }

    /// Drops all cached textures. Not needed in normal operation —
    /// exposed for development, e.g. re-checking for newly-added art
    /// without relaunching the app.
    func flushCache() {
        textureCache.removeAll()
        missingAtlasWarningsIssued.removeAll()
    }

    // MARK: - Procedural Spring & Easing Utilities

    /// Generates a natural spring overshoot SKAction for organic bounces
    static func springScale(to target: CGFloat, duration: TimeInterval = 0.3, damping: CGFloat = 0.15) -> SKAction {
        let overshoot = target + damping
        let step1 = SKAction.scale(to: overshoot, duration: duration * 0.55)
        step1.timingMode = .easeOut
        let step2 = SKAction.scale(to: target - (damping * 0.4), duration: duration * 0.25)
        step2.timingMode = .easeInEaseOut
        let step3 = SKAction.scale(to: target, duration: duration * 0.20)
        step3.timingMode = .easeOut
        return SKAction.sequence([step1, step2, step3])
    }

    /// Generates a smooth sine wave respiratory cycle
    static func breathingAction(scaleYRange: (CGFloat, CGFloat) = (0.98, 1.03), duration: TimeInterval = 1.4) -> SKAction {
        let inhale = SKAction.group([
            SKAction.scaleY(to: scaleYRange.1, duration: duration),
            SKAction.scaleX(to: 2.0 - scaleYRange.1, duration: duration)
        ])
        inhale.timingMode = .easeInEaseOut

        let exhale = SKAction.group([
            SKAction.scaleY(to: scaleYRange.0, duration: duration),
            SKAction.scaleX(to: 2.0 - scaleYRange.0, duration: duration)
        ])
        exhale.timingMode = .easeInEaseOut

        return SKAction.repeatForever(SKAction.sequence([inhale, exhale]))
    }

    /// Mathematical smooth-step interpolation
    static func smoothStep(from a: CGFloat, to b: CGFloat, t: CGFloat) -> CGFloat {
        let clampedT = max(0, min(1, t))
        let smoothT = clampedT * clampedT * (3 - 2 * clampedT)
        return a + (b - a) * smoothT
    }
}

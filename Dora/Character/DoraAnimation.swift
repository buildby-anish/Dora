//
//  DoraAnimation.swift
//  Dora
//
//  Identifies every animation Dora can play and the metadata
//  AnimationManager needs to play it correctly: which asset folder
//  its frames live in, how fast to play them by default, and whether
//  it loops.
//
//  This is deliberately a plain, independent enum rather than reusing
//  the future Behavior-layer `DoraState` (Stage 5) — animation and
//  behavior are different concerns with different lifecycles (e.g.
//  "walkLeft" vs "walkRight" only matter to the animation/character
//  layer; BehaviorEngine will just think in terms of "walking" plus a
//  facing direction). BehaviorEngine will map its states onto these
//  animation keys when it exists; this file doesn't need to change
//  when that happens.
//

import Foundation

enum DoraAnimation: String, CaseIterable {
    case idle
    case blink
    case walkLeft
    case walkRight
    case sit
    case sleep
    case wake
    case thinking
    case happy
    case concerned
    case charging
    case celebrate

    /// Name of the `.atlas` asset folder (see
    /// `Resources/DoraAssets/README.md`) this animation's frames
    /// should be loaded from. `walkLeft`/`walkRight` intentionally
    /// share one atlas — direction is expressed by mirroring the
    /// character horizontally rather than authoring two mirrored
    /// frame sets.
    var atlasName: String {
        switch self {
        case .idle: return "Idle"
        case .blink: return "Blink"
        case .walkLeft, .walkRight: return "Walk"
        case .sit: return "Sit"
        case .sleep: return "Sleep"
        case .wake: return "Wake"
        case .thinking: return "Think"
        case .happy: return "Happy"
        case .concerned: return "Concerned"
        case .charging: return "Charging"
        case .celebrate: return "Celebrate"
        }
    }

    /// Default seconds-per-frame when playing real sprite-sheet
    /// frames. Callers can override this per-call (e.g. a faster
    /// walk cycle for "running" later); this is just the sensible
    /// default for each state.
    var defaultFrameDuration: TimeInterval {
        switch self {
        case .blink: return 0.05
        case .walkLeft, .walkRight: return 0.08
        case .celebrate: return 0.07
        default: return 0.12
        }
    }

    /// Whether this animation should loop until explicitly changed,
    /// or play once and stop. One-shot animations (blink, wake,
    /// celebrate) are the natural place to hang a completion handler
    /// so a caller can chain back to `.idle` once BehaviorEngine
    /// exists to do that (Stage 5).
    var loops: Bool {
        switch self {
        case .blink, .wake, .celebrate:
            return false
        default:
            return true
        }
    }
}

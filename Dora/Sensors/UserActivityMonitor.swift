//
//  UserActivityMonitor.swift
//  Dora
//
//  Monitors system-wide user activity / idle time.
//  Detects when user has been idle for >= 1 minute (triggering Dora to wake and roam),
//  and when user resumes working (triggering Dora to return to her corner and sleep).
//

import AppKit
import CoreGraphics

final class UserActivityMonitor {

    enum ActivityLevel {
        case activeWork
        case microBreak
        case deepIdle
    }

    var idleThresholdSeconds: TimeInterval = 60.0 // 1 minute idle requirement
    var deepIdleThresholdSeconds: TimeInterval = 300.0 // 5 minutes deep idle

    var onUserBecameIdle: (() -> Void)?
    var onUserResumedActivity: (() -> Void)?
    var onActivityLevelChanged: ((ActivityLevel) -> Void)?

    private(set) var isUserCurrentlyIdle: Bool = false
    private(set) var currentActivityLevel: ActivityLevel = .activeWork
    private var timer: Timer?

    init() {
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    func startMonitoring() {
        timer?.invalidate()
        // Poll system-wide HID idle time every 1.0s
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdleState()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    /// Returns current system-wide idle seconds
    var currentIdleTime: TimeInterval {
        CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
    }

    private func checkIdleState() {
        let idleTime = currentIdleTime

        let newLevel: ActivityLevel
        if idleTime >= deepIdleThresholdSeconds {
            newLevel = .deepIdle
        } else if idleTime >= idleThresholdSeconds {
            newLevel = .microBreak
        } else {
            newLevel = .activeWork
        }

        if newLevel != currentActivityLevel {
            currentActivityLevel = newLevel
            DispatchQueue.main.async { [weak self] in
                self?.onActivityLevelChanged?(newLevel)
            }
        }

        if idleTime >= idleThresholdSeconds {
            if !isUserCurrentlyIdle {
                isUserCurrentlyIdle = true
                DispatchQueue.main.async { [weak self] in
                    self?.onUserBecameIdle?()
                }
            }
        } else if idleTime < 2.0 {
            if isUserCurrentlyIdle {
                isUserCurrentlyIdle = false
                DispatchQueue.main.async { [weak self] in
                    self?.onUserResumedActivity?()
                }
            }
        }
    }
}

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

    var idleThresholdSeconds: TimeInterval = 60.0 // 1 minute idle requirement

    var onUserBecameIdle: (() -> Void)?
    var onUserResumedActivity: (() -> Void)?

    private(set) var isUserCurrentlyIdle: Bool = false
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

    private func checkIdleState() {
        // CGEventSource measures seconds since last user input across the entire macOS system
        let idleTime = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)

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

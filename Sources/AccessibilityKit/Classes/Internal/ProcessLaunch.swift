//
//  ProcessLaunch.swift
//  AccessibilityKit
//

import Darwin
import Foundation

///
/// When this process started, so the kit can tell whether tracking started
/// at launch or later in the session.
///
enum ProcessLaunch {

    /// How soon after launch tracking must start to count as "at launch".
    static let window: TimeInterval = 10

    ///
    /// Whether iOS started the process ahead of the launch, to prewarm it.
    /// Its start time then says nothing about when the user launched it.
    ///
    static let isPrewarmed = ProcessInfo.processInfo.environment["ActivePrewarm"] == "1"

    /// The process's start time, or `nil` if the system does not report it.
    static let date: Date? = {
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        var name: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        guard sysctl(&name, u_int(name.count), &info, &size, nil, 0) == 0 else { return nil }

        let start = info.kp_proc.p_starttime
        return Date(timeIntervalSince1970: TimeInterval(start.tv_sec) + TimeInterval(start.tv_usec) / 1_000_000)
    }()
}

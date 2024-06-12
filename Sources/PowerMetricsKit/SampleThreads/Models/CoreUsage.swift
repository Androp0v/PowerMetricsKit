//
//  CoreUsage.swift
//
//
//  Created by Raúl Montón Pinillos on 26/5/24.
//

import Foundation
import SampleThreads

/// The usage (occupancy) of a single core.
public struct CoreUsage: Sendable, AdditiveArithmetic {
    /// Number of CPU ticks used at system-level.
    public var systemTicks: Int
    /// Number of CPU ticks used at user-level with application priority.
    public var userTicks: Int
    /// Number of CPU ticks used at user-level with nice priority.
    public var niceTicks: Int
    /// Number of idle CPU ticks.
    public var idleTicks: Int
    
    /// Proportion of non-idle vs total ticks. Ranges from 0 to 1.
    public var usage: Double {
        let nonIdleTicks = systemTicks + userTicks + niceTicks
        return Double(nonIdleTicks) / Double(nonIdleTicks + idleTicks)
    }
    /// Proportion of system ticks vs total ticks. Ranges from 0 to 1.
    public var systemUsage: Double {
        return Double(systemTicks) / Double(userTicks + niceTicks + idleTicks)
    }
    
    /// Initializes a `CoreUsage` object.
    public init(systemTicks: Int, userTicks: Int, niceTicks: Int, idleTicks: Int) {
        self.systemTicks = systemTicks
        self.userTicks = userTicks
        self.niceTicks = niceTicks
        self.idleTicks = idleTicks
    }
    
    init(_ core_usage: core_usage_t) {
        self.systemTicks = Int(core_usage.system_ticks)
        self.userTicks = Int(core_usage.user_ticks)
        self.niceTicks = Int(core_usage.nice_ticks)
        self.idleTicks = Int(core_usage.idle_ticks)
    }
    
    // MARK: - AdditiveArithmetic
    
    /// Zero element for ``AdditiveArithmetic``.
    public static let zero: CoreUsage = CoreUsage(systemTicks: 0, userTicks: 0, niceTicks: 0, idleTicks: 0)
    
    public static func + (lhs: CoreUsage, rhs: CoreUsage) -> CoreUsage {
        CoreUsage(
            systemTicks: lhs.systemTicks + rhs.systemTicks,
            userTicks: lhs.userTicks + rhs.userTicks,
            niceTicks: lhs.niceTicks + rhs.niceTicks,
            idleTicks: lhs.idleTicks + rhs.idleTicks
        )
    }
    
    public static func - (lhs: CoreUsage, rhs: CoreUsage) -> CoreUsage {
        CoreUsage(
            systemTicks: lhs.systemTicks - rhs.systemTicks,
            userTicks: lhs.userTicks - rhs.userTicks,
            niceTicks: lhs.niceTicks - rhs.niceTicks,
            idleTicks: lhs.idleTicks - rhs.idleTicks
        )
    }
}

// MARK: - Array

extension [CoreUsage] {
    init(_ rawBuffer: UnsafeBufferPointer<core_usage_t>) {
        self = [core_usage_t](rawBuffer).map {
            CoreUsage($0)
        }
    }
}

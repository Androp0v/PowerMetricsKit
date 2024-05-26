//
//  CPUUsage.swift
//
//
//  Created by Raúl Montón Pinillos on 26/5/24.
//

import Foundation

/// The information about the CPU usage at a given point in time, broken down by core.
public struct CPUUsage {
    /// The number of cores in the system.
    public let numberOfCores: Int
    /// The usage of each core.
    public let coreUsages: [CoreUsage]
}

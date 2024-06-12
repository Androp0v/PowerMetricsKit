//
//  CPUUsageManager.swift
//
//
//  Created by Raúl Montón Pinillos on 21/4/24.
//

import Foundation
import SampleThreads

/// Class used to retrieve the usage (occupancy) of each CPU core.
public class CPUUsageManager {
    
    private var results: RingBuffer<[CoreUsage]>
    
    // MARK: - Init
    
    nonisolated public init(config: PowerMetricsConfig = .default) {
        self.results = RingBuffer<[CoreUsage]>(length: config.numberOfStoredSamples)
    }
    
    // MARK: - Functions
    
    func getCPUUsage() -> CPUUsage? {
        
        let rawCPUUsage = get_cpu_usage()
        
        // This points directly to the C array.
        let rawCoreUsages = UnsafeBufferPointer(
            start: rawCPUUsage.core_usages,
            count: Int(rawCPUUsage.num_cores)
        )
        // This creates a Swift copy of the C array.
        let coreUsages = [CoreUsage](rawCoreUsages)
        
        // Free the memory allocated with malloc in get_cpu_usage.c, as we've
        // created a copy for Swift code.
        free(rawCPUUsage.core_usages)
        
        defer {
            results.add(element: coreUsages)
        }
        
        guard let previousResult = results.last else {
            return nil
        }
        
        var results = [CoreUsage]()
        for index in 0..<rawCPUUsage.num_cores {
            results.append(coreUsages[Int(index)] - previousResult[Int(index)])
        }
        return CPUUsage(
            numberOfCores: Int(rawCPUUsage.num_cores),
            coreUsages: results
        )
    }
}

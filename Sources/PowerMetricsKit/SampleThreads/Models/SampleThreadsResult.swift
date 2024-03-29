//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 3/2/24.
//

import Foundation

/// The processed results from sampling the threads.
public struct SampleThreadsResult: Identifiable {
    /// Unique identifier for the sample.
    public let id = UUID()
    /// The time at which the measurement was performed.
    public let time: Date
    /// The combined power used in the interval by all threads.
    public let allThreadsPower: CombinedPower
    
    public let threadSamples: [ThreadSample]
    
    /// Empty sample with zero power.
    public static var zero: SampleThreadsResult {
        return SampleThreadsResult(
            time: .now,
            allThreadsPower: .zero,
            threadSamples: [ThreadSample]()
        )
    }
}

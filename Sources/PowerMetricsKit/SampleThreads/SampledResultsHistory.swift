//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 3/2/24.
//

import Foundation

/// Historic power figures for the app.
///
/// Storing the samples is relatively low overhead, using a ring buffer. Reading them
/// triggers sorting of the sample array, which may be costly (but reading the samples
/// might be rare if not displaying the `PowerWidgetView`).
@SampleThreadsActor public class SampledResultsHistory {
    /// The maximum value for total power of any of the stored power samples.
    public var maxPower: Power = .zero
    /// The stored power samples.
    public var samples: [SampleThreadsResult] {
        return ringBuffer.sorted(by: { $0.time < $1.time })
    }
    
    private let numberOfStoredSamples: Int
    private var ringBuffer: [SampleThreadsResult]
    private var writeIndex: Int = 0
    private var displayableSamples: Int = 0
    
    init(numerOfStoredSamples: Int) {
        self.numberOfStoredSamples = numerOfStoredSamples
        self.ringBuffer = [SampleThreadsResult](repeating: .zero, count: numerOfStoredSamples)
    }
    
    func addSample(_ sample: SampleThreadsResult) {
        
        let overwrittenSample = ringBuffer[writeIndex]
        ringBuffer[writeIndex] = sample
        
        writeIndex += 1
        writeIndex = writeIndex % numberOfStoredSamples
                
        // Update max power used in the history
        if overwrittenSample.allThreadsPower.total == maxPower {
            recomputeMaxPower()
        } else if sample.allThreadsPower.total > maxPower {
            maxPower = sample.allThreadsPower.total
        }
    }
    
    private func recomputeMaxPower() {
        maxPower = ringBuffer.map({$0.allThreadsPower.total}).max() ?? .zero
    }
}

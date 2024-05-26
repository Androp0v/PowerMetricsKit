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
        return ringBuffer.elements
    }
    
    private let numberOfStoredSamples: Int
    private var ringBuffer: RingBuffer<SampleThreadsResult>
    private var writeIndex: Int = 0
    private var displayableSamples: Int = 0
    
    nonisolated init(numerOfStoredSamples: Int) {
        self.numberOfStoredSamples = numerOfStoredSamples
        self.ringBuffer = RingBuffer(length: numerOfStoredSamples)
    }
    
    func addSample(_ sample: SampleThreadsResult) {
        ringBuffer.add(element: sample)
        maxPower = ringBuffer.unsortedElements.map({$0.allThreadsPower.total}).max() ?? .zero
    }
}

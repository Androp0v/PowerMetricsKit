//
//  ThreadSample.swift
//  
//
//  Created by Raúl Montón Pinillos on 11/2/24.
//

import Foundation

/// The power used by a single thread.
public struct ThreadSample {
    /// The Mach thread ID.
    public let threadID: UInt64
    /// The date at which the sample was taken.
    public let sampleTime: Date
    /// The pthread name of the thread.
    public let pthreadName: String?
    /// The name for the Dispatch Queue of the thread.
    public let dispatchQueueName: String?
    /// The combined power used by this thread in the interval across all core types.
    public let power: CombinedPower
    /// The name of this thread when displayed in the UI. Matched the `pthreadName` (if available),
    /// defaults to the `threadID` otherwise.
    public var displayName: String {
        if let pthreadName {
            return pthreadName
        }
        return String("Thread \(threadCounter)")
    }
    
    private var threadCounter: Int
    
    init(
        threadID: UInt64,
        sampleTime: Date,
        pthreadName: String?,
        dispatchQueueName: String?,
        power: CombinedPower,
        threadCounter: Int
    ) {
        self.threadID = threadID
        self.sampleTime = sampleTime
        if let pthreadName, !pthreadName.isEmpty {
            self.pthreadName = pthreadName
        } else {
            self.pthreadName = nil
        }
        if let dispatchQueueName, !(dispatchQueueName.isEmpty || dispatchQueueName.hasPrefix("\n")) {
            self.dispatchQueueName = dispatchQueueName
        } else {
            self.dispatchQueueName = nil
        }
        self.power = power
        self.threadCounter = threadCounter
    }
}

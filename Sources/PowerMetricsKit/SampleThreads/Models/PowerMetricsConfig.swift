//
//  PowerMetricsConfig.swift
//
//
//  Created by Raúl Montón Pinillos on 29/3/24.
//

import Foundation

/// The configuration of the thread sampling.
public struct PowerMetricsConfig {
    /// The timespan between each sample.
    public let samplingTime: TimeInterval
    /// The number of samples kept in the power history.
    public let numberOfStoredSamples: Int
    /// Whether or not the name of the dispatch queue associated with each thread should
    /// be retrieved or not.
    public let retrieveDispatchQueueName: Bool
    /// Whether or not backtraces of the sampled threads should be retrieved.
    public let retrieveBacktraces: Bool
    
    /// Create a PowerMetricsKit configuration.
    public init(samplingTime: TimeInterval, numberOfStoredSamples: Int, retrieveDispatchQueueName: Bool, retrieveBacktraces: Bool) {
        self.samplingTime = samplingTime
        self.numberOfStoredSamples = numberOfStoredSamples
        self.retrieveDispatchQueueName = retrieveDispatchQueueName
        self.retrieveBacktraces = retrieveBacktraces
    }
    /// The default PowerMetricsKit configuration.
    public static let `default`: PowerMetricsConfig = {
        return PowerMetricsConfig(
            samplingTime: 0.5,
            numberOfStoredSamples: 60,
            retrieveDispatchQueueName: true,
            retrieveBacktraces: false
        )
    }()
}

//
//  SampleThreadsManager.swift
//  TestAppPower
//
//  Created by Raúl Montón Pinillos on 20/1/24.
//

import Foundation
import SampleThreads

/// The global actor used to access the `SampleThreadsManager` in a thread-safe way.
@globalActor public actor SampleThreadsActor {
    public static let shared = SampleThreadsActor()
}

/// The main class interfacing with the C code that retrieves the energy data.
@SampleThreadsActor public final class SampleThreadsManager {
    
    // MARK: - Public properties
    
    /// The configuration of the thread sampling.
    public let config: PowerMetricsConfig
    /// The total count of threads spawned by the app.
    public private(set) var currentThreadCount: Int = 1
    /// Total energy used by the app since launch, in Watts-hour.
    public private(set) var totalEnergyUsage: Energy = 0
    /// Historic power figures for the app.
    public let history: SampledResultsHistory
    
    // MARK: - Private properties
    
    private var samplingTask: Task<Void, Never>?
    private var continuousClock = ContinuousClock()
    private var lastSampleTime: ContinuousClock.Instant?
    private var previousRawSamples = [UInt64: sampled_thread_info_t]()
    /// Maps a unique thread ID with a counter that increases by `1` every time a new thread appears.
    private var threadIDToCounter = [UInt64: Int]()
    /// The last value of the counter used to map thread IDs to a monotonously increasing counter.
    private var lastCounter: Int = 0
    
    // MARK: - Init
    
    nonisolated public init(config: PowerMetricsConfig = .default) {
        self.config = config
        self.history = SampledResultsHistory(numerOfStoredSamples: config.numberOfStoredSamples)
    }
    
    // MARK: - Sampling
    
    /// Starts sampling CPU power used for the given PID.
    /// - Parameter pid: PID of the process to sample.
    public func startSampling(pid: Int32) {
        guard self.samplingTask == nil else {
            return
        }
        self.samplingTask = Task(priority: .high) { [weak self] in
            while !Task.isCancelled {
                guard let self else {
                    return
                }
                await self.sampleThreads(pid)
                try? await Task.sleep(
                    for: .seconds(config.samplingTime),
                    tolerance: .seconds(config.samplingTime * 0.01)
                )
            }
        }
    }
    
    /// Stop sampling threads.
    public func stopSampling() {
        self.samplingTask?.cancel()
    }
    
    /// Given the pid for a process, sample all the threads belonging to that process and
    /// return the `CombinedPower` used for that process.
    /// - Parameter pid: The pid of the process to inspect.
    /// - Returns: A `SampleThreadsResult` object.
    @discardableResult public func sampleThreads(_ pid: Int32) async -> SampleThreadsResult {
        let currentSampleTime = continuousClock.now
        // Invoke the C code in sample_threads.c that uses proc_pidinfo to retrieve
        // performance counters including energy usage.
        let result = sample_threads(pid, config.retrieveDispatchQueueName, config.retrieveBacktraces)
        // This points directly to the C array.
        let counters = UnsafeBufferPointer(start: result.cpu_counters, count: Int(result.thread_count))
        // This creates a Swift copy of the C array.
        let rawThreadSamples = [sampled_thread_info_t](counters.map({ $0.info }))
        
        let sampleTime = Date.now
        var combinedPPower = 0.0
        var combinedEPower = 0.0
        var threadSamples = [ThreadSample]()
        var threadEnergyChanges = [Energy]()
        for rawThreadSample in rawThreadSamples.sorted(by: { $0.thread_id < $1.thread_id }) {
            var threadCounter: Int
            if let counter = threadIDToCounter[rawThreadSample.thread_id] {
                threadCounter = counter
            } else {
                lastCounter += 1
                threadIDToCounter[rawThreadSample.thread_id] = lastCounter
                threadCounter = lastCounter
            }
            let pthreadName = withUnsafePointer(to: rawThreadSample.pthread_name) { ptr in
                let start = ptr.pointer(to: \.0)!
                return String(cString: start)
            }
            
            // Retrieve the queue name only if configured to do so
            var dispatchQueueName: String?
            if config.retrieveDispatchQueueName {
                dispatchQueueName = withUnsafePointer(to: rawThreadSample.dispatch_queue_name) { ptr in
                    let start = ptr.pointer(to: \.0)!
                    return String(cString: start)
                }
            }
            
            if let previousCounter = previousRawSamples[rawThreadSample.thread_id], let lastSampleTime {
                let performancePower = computePower(
                    previousTime: lastSampleTime,
                    currentTime: currentSampleTime,
                    previousCounters: previousCounter,
                    currentCounter: rawThreadSample,
                    type: .performance
                )
                let efficiencyPower = computePower(
                    previousTime: lastSampleTime,
                    currentTime: currentSampleTime,
                    previousCounters: previousCounter,
                    currentCounter: rawThreadSample,
                    type: .efficiency
                )
                combinedPPower += performancePower.power
                combinedEPower += efficiencyPower.power
                
                threadSamples.append(ThreadSample(
                    threadID: rawThreadSample.thread_id, 
                    sampleTime: sampleTime,
                    pthreadName: pthreadName,
                    dispatchQueueName: dispatchQueueName,
                    power: CombinedPower(
                        performance: performancePower.power,
                        efficiency: efficiencyPower.power
                    ),
                    threadCounter: threadCounter
                ))
                threadEnergyChanges.append(performancePower.energy + efficiencyPower.energy)
            }
        }
        
        // Reset previous counters with the latest samples
        self.previousRawSamples = [UInt64: sampled_thread_info_t]()
        for counter in rawThreadSamples {
            self.previousRawSamples[counter.thread_id] = counter
        }
        
        self.lastSampleTime = currentSampleTime
        self.currentThreadCount = Int(result.thread_count)
        let sampleResult = SampleThreadsResult(
            time: sampleTime,
            allThreadsPower: CombinedPower(
                performance: combinedPPower,
                efficiency: combinedEPower
            ), 
            threadSamples: threadSamples
        )
        
        self.history.addSample(sampleResult)
        self.totalEnergyUsage += sampleResult.allThreadsPower.total * config.samplingTime / 3600
        
        // Retrieve the backtraces only if configured to do so
        if config.retrieveBacktraces {
            // This creates a Swift copy of the backtraces.
            let backtraces = [Backtrace](counters.map { counter in
                let backtraceLength = counter.backtrace.length
                let rawBacktrace = UnsafeBufferPointer(
                    start: counter.backtrace.addresses,
                    count: Int(backtraceLength)
                )
                let backtrace = Backtrace(
                    addresses: [UInt64](rawBacktrace.map({ $0.address & UInt64(PAC_STRIPPING_BITMASK) })),
                    energy: nil
                )
                if counter.backtrace.length != 0 {
                    // Free the memory allocated with malloc in get_backtrace.c, as we've
                    // created a copy for Swift code.
                    free(counter.backtrace.addresses)
                }
                return backtrace
            })
            // Add power info to the backtraces
            let backtracesWithPower = zip(backtraces, threadEnergyChanges).map { (backtrace, energy) in
                return Backtrace(addresses: backtrace.addresses, energy: energy)
            }
            await SymbolicateBacktraces.shared.addToBacktraceGraph(backtracesWithPower)
        }
        
        // Free the memory allocated with malloc in sample_threads.c, as we've created
        // a copy for Swift code.
        free(result.cpu_counters)
        
        return sampleResult
    }
    
    // MARK: - Energy
    
    /// Reset the global count of energy used.
    public func resetEnergyUsed() {
        self.totalEnergyUsage = .zero
    }
    
    // MARK: - Private
    
    private struct ComputePowerResult {
        let energy: Energy
        let power: Power
    }
    
    private func computePower(
        previousTime: ContinuousClock.Instant,
        currentTime: ContinuousClock.Instant,
        previousCounters: sampled_thread_info_t,
        currentCounter: sampled_thread_info_t,
        type: CoreType
    ) -> ComputePowerResult {
        let energyChange: Double
        switch type {
        case .performance:
            energyChange = currentCounter.performance.energy - previousCounters.performance.energy
        case .efficiency:
            energyChange = currentCounter.efficiency.energy - previousCounters.efficiency.energy
        }
        if !energyChange.isZero {
            // The *power* used during a time interval is the *total* energy consumed
            // divided by the time between measurements. Using the counters' ptcd times
            // instead would NOT yield the correct result, as that excludes times where
            // the threads were not running.
            //
            // If the sampling could be guaranteed to be done with precise timing, one
            // could also divide by SampleThreadsManager.samplingTime, but anything that
            // messes with the schedule at which sampleThreads() is called is going to
            // give wrong results (ie: suspending the app, stopping at a breakpoint
            // while debugging...).
            let elapsedTime = currentTime - previousTime
            let elapsedSeconds = Double(elapsedTime.components.seconds) + Double(elapsedTime.components.attoseconds) * 1e-18
            let energyChangeInWattsHour = energyChange / 3600
            return ComputePowerResult(energy: energyChangeInWattsHour, power: energyChange / elapsedSeconds)
        } else {
            return ComputePowerResult(energy: .zero, power: .zero)
        }
    }
}

//
//  CallStackViewModel.swift
//  
//
//  Created by Raúl Montón Pinillos on 12/6/24.
//

import SwiftUI

/// Class to bridge the `SymbolicateBacktraces` to the UI.
@MainActor @Observable final class CallStackViewModel {
    
    let symbolicator = SymbolicateBacktraces.shared
    var expandedInfos = [BacktraceInfo]()
    var sortedGraphBacktraces = [BacktraceInfo]()
    var sortedFlatBacktraces = [SimpleBacktraceInfo]()
    
    init(sampleManager: SampleThreadsManager) {
        periodicRefresh(samplingTime: sampleManager.config.samplingTime)
    }
    
    @objc func update() {
        Task(priority: .high) {
            let sortedGraphBacktraces = if let lastExpanded = expandedInfos.last {
                lastExpanded.children
                    .sorted(by: { $0.energy > $1.energy })
            } else {
                await symbolicator.backtraceGraph.nodes
                    .sorted(by: { $0.energy > $1.energy })
            }
            let sortedFlatBacktraces = await symbolicator.flatBacktraces
                .sorted(by: { $0.energy > $1.energy })
            
            Task(priority: .high) { @MainActor in
                self.sortedGraphBacktraces = sortedGraphBacktraces
            }
        }
    }
    
    func periodicRefresh(samplingTime: TimeInterval) {
        #if os(macOS)
        let timer = Timer(timeInterval: samplingTime, repeats: true) { timer in
            MainActor.assumeIsolated {
                self.update()
            }
        }
        RunLoop.main.add(timer, forMode: RunLoop.Mode.common)
        #else
        let displayLink = CADisplayLink(
            target: self,
            selector: #selector(update)
        )
        displayLink.preferredFrameRateRange = .init(
            minimum: Float(1 / samplingTime),
            maximum: Float(1 / samplingTime)
        )
        displayLink.add(to: .current, forMode: .common)
        #endif
    }
}

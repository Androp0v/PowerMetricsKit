//
//  CoreUsageChart.swift
//
//
//  Created by Raúl Montón Pinillos on 21/4/24.
//

import SwiftUI

struct CoreUsageChart: View {
    
    let cpuUsageManager = CPUUsageManager.shared
    
    init() {}
    
    func numberOfRows(cpuUsage: CPUUsage) -> Int {
        let numberOfCores = cpuUsage.numberOfCores
        let fullRows = numberOfCores / 4
        let partialRows = numberOfCores % 4 == 0 ? 0 : 1
        return fullRows + partialRows
    }
    
    func numberOfColumns(row: Int, cpuUsage: CPUUsage) -> Int {
        let numberOfRows = numberOfRows(cpuUsage: cpuUsage)
        if row < (numberOfRows - 1) {
            return 4
        } else {
            if cpuUsage.numberOfCores % 4 == 0 {
                return 4
            } else {
                return cpuUsage.numberOfCores % 4
            }
        }
    }
    
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.5)) { _ in
            if let cpuUsage = cpuUsageManager.getCPUUsage() {
                Grid {
                    ForEach(0..<numberOfRows(cpuUsage: cpuUsage)) { rowIndex in
                        GridRow {
                            ForEach(0..<numberOfColumns(row: rowIndex, cpuUsage: cpuUsage)) { columnIndex in
                                CoreUsageMeter(
                                    usage: cpuUsage.coreUsages[rowIndex * 4 + columnIndex].usage,
                                    coreType: nil
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

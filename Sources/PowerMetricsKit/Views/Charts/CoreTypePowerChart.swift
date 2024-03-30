//
//  CPUPowerChart.swift
//
//
//  Created by Raúl Montón Pinillos on 4/2/24.
//

import Charts
import SwiftUI

struct CoreTypePowerChart: View {
    
    let sampleManager: SampleThreadsManager
    let info: PowerWidgetInfo
    let latestSampleTime: Date
    
    var body: some View {
        Chart(info.cpuPowerHistory) { measurement in
            AreaMark(
                x: .value("Time", measurement.time),
                y: .value("Power", measurement.allThreadsPower.efficiency)
            )
            .foregroundStyle(
                by: .value("Name", "Efficiency")
            )
            
            AreaMark(
                x: .value("Time", measurement.time),
                y: .value("Power (W)", measurement.allThreadsPower.performance)
            )
            .foregroundStyle(
                by: .value("Name", "Performance")
            )
        }
        .chartXAxisLabel("Time")
        .chartYAxisLabel(info.cpuMaxPower < 0.1 ? "Power (mW)" : "Power (W)")
        .chartXAxis(.hidden)
        .chartYAxis {
            if info.cpuMaxPower < 0.1 {
                AxisMarks(format: ChartPowerFormatStyle.Miliwatts())
            } else {
                AxisMarks(format: ChartPowerFormatStyle.Watts())
            }
        }
        .chartXScale(domain: [
            latestSampleTime - sampleManager.config.samplingTime * Double(sampleManager.config.numberOfStoredSamples),
            latestSampleTime
        ])
        .drawingGroup()
    }
}

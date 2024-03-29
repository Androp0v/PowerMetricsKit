//
//  ThreadPowerChart.swift
//
//
//  Created by Raúl Montón Pinillos on 4/2/24.
//

import Charts
import SwiftUI

@MainActor struct ThreadPowerChart: View {
    
    let info: PowerWidgetInfo
    let latestSampleTime: Date
    
    @State var model = ThreadPowerChartModel()
    @State var selectedThread: UInt64?
    
    @Environment(\.self) var environment
        
    var body: some View {
        VStack(spacing: .zero) {
            Chart(info.cpuPowerHistory) { measurement in
                
                ForEach(measurement.threadSamples, id: \.threadID) { threadSample in
                    AreaMark(
                        x: .value("Time", measurement.time),
                        y: .value("Power", threadSample.power.total)
                    )
                    .foregroundStyle(
                        by: .value("Thread name", "\(threadSample.displayName)")
                    )
                }
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
                latestSampleTime - SampleThreadsManager.samplingTime * Double(SampleThreadsManager.numberOfStoredSamples),
                latestSampleTime
            ])
            .chartForegroundStyleScale(mapping: { (displayName: String) in
                return model.colorForDisplayName(
                    displayName,
                    allDisplayNames: info.uniqueThreads.map({ $0.displayName }),
                    environment: environment
                )
            })
            .chartLegend(.hidden)
            .padding(.horizontal)
            .drawingGroup()
            
            Divider()
                .padding(.top, 12)
                .padding(.horizontal)
            
            ScrollView {
                VStack(alignment: .leading) {
                    ForEach(
                        info.uniqueThreads.sorted(by: { $0.threadID < $1.threadID }),
                        id: \.threadID
                    ) { thread in
                        ThreadPowerRow(
                            thread: thread,
                            threadColor: model.colorForDisplayName(
                                thread.displayName,
                                allDisplayNames: info.uniqueThreads.map({ $0.displayName }),
                                environment: environment
                            ),
                            hasUpToDatePower: thread.sampleTime == info.latestSampleTime, 
                            selectedThread: $selectedThread
                        )
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
    }
}

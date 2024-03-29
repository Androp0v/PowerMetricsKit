//
//  PowerWidgetView.swift
//  TestAppPower
//
//  Created by Raúl Montón Pinillos on 14/1/24.
//

import Charts
import SwiftUI

/// A `View` displaying the power consumption of the app.
@MainActor public struct PowerWidgetView: View {
    
    let pid = ProcessInfo.processInfo.processIdentifier
    let sampleManager = SampleThreadsManager.shared
    @State var viewModel = PowerWidgetViewModel()
    
    @AppStorage("chartType") var chartType: ChartType = .coreType
    @State var isResettingEnergy: Bool = false
    @State var showOptions: Bool = false
    /// Selected backtrace in CallStackView, if any.
    @State var selectedBacktrace: BacktraceInfo?
        
    var pidFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = false
        return numberFormatter
    }()
    
    var powerFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()
    
    public init() {}
    
    // MARK: - View body
    
    public var body: some View {
        VStack {
            Text("PID: \(pidFormatter.string(from: NSNumber(value: pid)) ?? "??")")
                .font(.largeTitle)
                .padding(.bottom, 4)
                .padding(.horizontal)
                
            let latestSampleTime = viewModel.info.cpuPowerHistory.last?.time ?? Date.now
            
            Text("CPU power: \(formatPower(power: viewModel.info.cpuPower))")
                .monospaced()
                .padding(.horizontal)
            HStack(spacing: 4) {
                Text("Total energy used: \(formatEnergy(energy: viewModel.info.cpuEnergy))")
                    .monospaced()
                resetEnergyButton
            }
            .padding(.horizontal)
            
            switch chartType {
            case .coreType:
                CoreTypePowerChart(info: viewModel.info, latestSampleTime: latestSampleTime)
                    .padding(.horizontal)
                    .padding(.bottom)
            case .thread:
                ThreadPowerChart(info: viewModel.info, latestSampleTime: latestSampleTime)
            case .callStack:
                CallStackView()
            }
        }
        .padding(.top)
        .background {
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(.regularMaterial)
        }
        .overlay(alignment: .topTrailing) {
            infoButton
        }
        .task {
            await sampleManager.startSampling(pid: pid)
        }
    }
    
    // MARK: - Subviews
    
    @ViewBuilder var resetEnergyButton: some View {
        Button(
            action: {
                withAnimation {
                    isResettingEnergy = true
                }
                Task { @MainActor in
                    await sampleManager.resetEnergyUsed()
                    withAnimation {
                        isResettingEnergy = false
                    }
                }
            },
            label: {
                Image(systemName: "arrow.uturn.left.circle")
            }
        )
        .foregroundStyle(.secondary)
        #if os(macOS)
        .buttonStyle(.plain)
        #endif
        .disabled(isResettingEnergy)
    }
    
    @ViewBuilder var infoButton: some View {
        Button(
            action: {
                showOptions.toggle()
            },
            label: {
                Image(systemName: "info.circle")
            }
        )
        #if os(macOS)
        .buttonStyle(.plain)
        .foregroundStyle(.blue)
        #endif
        .padding()
        .popover(isPresented: $showOptions) {
            PowerWidgetOptionsView(chartType: $chartType)
        }
    }
    
    // MARK: - Formatters
    
    func formatPower(power: Power) -> String {
        if power < 0.1 {
            let power = NSNumber(value: power * 1000)
            return (powerFormatter.string(from: power) ?? "?") + " mW"
        } else {
            let power = NSNumber(value: power)
            return (powerFormatter.string(from: power) ?? "?") + " W"
        }
    }
    
    func formatEnergy(energy: Energy) -> String {
        if energy < 0.1 {
            let energy = NSNumber(value: energy * 1000)
            return (powerFormatter.string(from: energy) ?? "?") + " mWh"
        } else {
            let energy = NSNumber(value: energy)
            return (powerFormatter.string(from: energy) ?? "?") + " Wh"
        }
    }
}

#Preview {
    PowerWidgetView()
}

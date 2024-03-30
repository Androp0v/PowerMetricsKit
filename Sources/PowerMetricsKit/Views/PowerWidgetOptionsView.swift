//
//  PowerWidgetOptionsView.swift
//
//
//  Created by Raúl Montón Pinillos on 4/2/24.
//

import SwiftUI

struct PowerWidgetOptionsView: View {
    
    let sampleManager: SampleThreadsManager
    @Environment(\.dismiss) var dismiss
    @Binding var chartType: ChartType
    
    var chartOptions: [ChartType] {
        return ChartType.allCases.filter {
            if !sampleManager.config.retrieveBacktraces, $0 == .callStack {
                return false
            }
            return true
        }
    }
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Picker("Chart type", selection: $chartType.animation()) {
                ForEach(chartOptions, id: \.self) {
                    Text($0.displayName)
                        .tag($0)
                }
            }
            
            #if os(macOS)
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .padding(.top, 24)
            }
            #endif
        }
        .padding()
    }
}

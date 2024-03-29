//
//  PowerWidgetOptionsView.swift
//
//
//  Created by Raúl Montón Pinillos on 4/2/24.
//

import SwiftUI

struct PowerWidgetOptionsView: View {
    
    @Environment(\.dismiss) var dismiss
    @Binding var chartType: ChartType
    
    var body: some View {
        
        VStack(alignment: .leading) {
            Picker("Chart type", selection: $chartType.animation()) {
                ForEach(ChartType.allCases, id: \.self) {
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

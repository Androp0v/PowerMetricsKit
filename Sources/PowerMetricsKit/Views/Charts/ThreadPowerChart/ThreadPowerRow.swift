//
//  ThreadPowerRow.swift
//
//
//  Created by Raúl Montón Pinillos on 10/2/24.
//

import SwiftUI

struct ThreadPowerRow: View {
    
    let thread: ThreadSample
    let threadColor: Color
    let hasUpToDatePower: Bool
    @Binding var selectedThread: UInt64?
    
    var isSelected: Bool {
        return selectedThread == thread.threadID
    }
        
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(threadColor)
                VStack {
                    HStack {
                        Text(thread.displayName)
                            .foregroundStyle(threadColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(formatPower(thread.power.total))
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .monospaced()
                    }
                    Text(thread.dispatchQueueName ?? "Unknown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation {
                    if isSelected {
                        selectedThread = nil
                    } else {
                        selectedThread = thread.threadID
                    }
                }
            }
            if isSelected {
                Group {
                    HStack {
                        Text("Performance:")
                        Spacer()
                        Text(formatPower(thread.power.performance))
                    }
                    HStack {
                        Text("Efficiency:")
                        Spacer()
                        Text(formatPower(thread.power.efficiency))
                    }
                }
                .font(.caption)
                .monospaced()
                .padding(.leading)
                .foregroundStyle(.secondary)
            }
        }
    }
        
        func formatPower(_ power: Power) -> String {
            if hasUpToDatePower {
                return "\(NumberFormatter.power.string(for: 1000 * power) ?? "??") mW"
            } else {
                return "- mW"
            }
        }
}

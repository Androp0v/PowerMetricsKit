//
//  BacktraceRowView.swift
//
//
//  Created by Raúl Montón Pinillos on 9/3/24.
//

import SwiftUI

struct BacktraceRowView: View {
    
    let backtraceInfo: BacktraceInfo
    let energy: Energy
    @Binding var expandedInfos: [BacktraceInfo]
    @Binding var showFullInfo: Bool
    
    var isExpanded: Bool {
        return expandedInfos.contains(where: { $0.id == backtraceInfo.id })
    }
    
    var body: some View {
        Button(
            action: {
                withAnimation {
                    if isExpanded {
                        expandedInfos = expandedInfos.dropLast()
                    } else {
                        expandedInfos.append(backtraceInfo)
                    }
                    showFullInfo = false
                }
            },
            label: {
                HStack {
                    Image(
                        systemName: isExpanded
                        ? "rectangle.compress.vertical"
                        : "rectangle.expand.vertical"
                    )
                    BacktraceRowContentView(
                        symbolInfo: backtraceInfo.info,
                        energy: backtraceInfo.energy
                    )
                }
                .contentShape(Rectangle())
            }
        )
        .buttonStyle(.plain)
    }
}

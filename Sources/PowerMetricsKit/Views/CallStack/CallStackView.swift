//
//  CallStackView.swift
//
//
//  Created by Raúl Montón Pinillos on 8/3/24.
//

import Foundation
import SwiftUI

@MainActor struct CallStackView: View {
    
    enum VisualizationMode: String {
        case graph
        case flat
    }
    
    let sampleManager: SampleThreadsManager
    @State var callStackViewModel: CallStackViewModel
    @State var showFullInfo: Bool = false
    @AppStorage("callstackVisualization") var visualizationMode: VisualizationMode = .graph
    
    init(sampleManager: SampleThreadsManager) {
        self.sampleManager = sampleManager
        self.callStackViewModel = CallStackViewModel(sampleManager: sampleManager)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .zero) {
            Divider()
            
            if visualizationMode == .graph {
                VStack(alignment: .leading, spacing: .zero) {
                    if let lastExpanded = callStackViewModel.expandedInfos.last {
                        VStack {
                            BacktraceRowView(
                                backtraceInfo: lastExpanded,
                                energy: lastExpanded.energy,
                                expandedInfos: $callStackViewModel.expandedInfos,
                                showFullInfo: $showFullInfo
                            )
                            if showFullInfo {
                                BacktraceInfoView(backtraceInfo: lastExpanded)
                            }
                        }
                        #if os(macOS)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        #else
                        .padding(.vertical, 12)
                        .padding(.horizontal, 12)
                        #endif
                        .background(.blue.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top, 4)
                    }

                    if !showFullInfo {
                        List(callStackViewModel.sortedGraphBacktraces, id: \.id) { backtraceInfo in
                            BacktraceRowView(
                                backtraceInfo: backtraceInfo,
                                energy: backtraceInfo.energy,
                                expandedInfos: $callStackViewModel.expandedInfos,
                                showFullInfo: $showFullInfo
                            )
                            .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            } else {
                List(callStackViewModel.sortedFlatBacktraces, id: \.address) { simpleBacktraceInfo in
                    BacktraceRowContentView(
                        symbolInfo: simpleBacktraceInfo.info,
                        energy: simpleBacktraceInfo.energy
                    )
                    .listRowBackground(Color.clear)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            
            Divider()
            
            HStack {
                Button(
                    action: {
                        if visualizationMode == .graph {
                            visualizationMode = .flat
                        } else {
                            visualizationMode = .graph
                        }
                    },
                    label: {
                        Image(systemName: visualizationMode == .flat
                              ? "list.bullet.indent"
                              : "list.bullet"
                        )
                    }
                )
                #if os(macOS)
                .buttonStyle(.plain)
                #endif
                
                Button(
                    action: {
                        withAnimation {
                            showFullInfo.toggle()
                        }
                    },
                    label: {
                        Image(systemName: showFullInfo
                              ? "eye.circle.fill"
                              : "eye.circle"
                        )
                    }
                )
                #if os(macOS)
                .buttonStyle(.plain)
                #endif
                .disabled(visualizationMode == .flat || callStackViewModel.expandedInfos.isEmpty)
            }
            .padding(.top, 8)
        }
        .padding()
    }
}

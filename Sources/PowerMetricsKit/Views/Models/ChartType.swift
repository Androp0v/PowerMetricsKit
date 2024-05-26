//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 4/2/24.
//

import Foundation

enum ChartType: String, CaseIterable {
    case coreType
    case thread
    case usage
    case callStack
    
    var displayName: String {
        switch self {
        case .coreType:
            return "Per core type"
        case .thread:
            return "Per thread"
        case .usage:
            return "CPU Usage"
        case .callStack:
            return "Callstack"
        }
    }
}

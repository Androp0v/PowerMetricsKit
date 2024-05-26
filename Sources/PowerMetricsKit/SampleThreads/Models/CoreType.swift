//
//  CoreType.swift
//  
//
//  Created by Raúl Montón Pinillos on 3/2/24.
//

import Foundation

enum CoreType {
    case performance
    case efficiency
    
    var name: String {
        switch self {
        case .performance:
            return "Performance"
        case .efficiency:
            return "Efficiency"
        }
    }
    
    var shortName: String {
        switch self {
        case .performance:
            return "P"
        case .efficiency:
            return "E"
        }
    }
}

//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 3/2/24.
//

import Foundation

/// A power measurement, always in watts.
public typealias Power = Double
/// An energy measurement, always in watts-hour.
public typealias Energy = Double

/// A combined power measurement composed of measurements for different core types.
public struct CombinedPower: Sendable, Equatable, Hashable, AdditiveArithmetic {
    /// Power used by the performance cores.
    public let performance: Power
    /// Power used by the efficiency cores.
    public let efficiency: Power
    /// Power used by all cores.
    var total: Power {
        return performance + efficiency
    }
    
    /// Zero power.
    public static var zero: CombinedPower {
        return CombinedPower(performance: .zero, efficiency: .zero)
    }
    
    public static func + (lhs: CombinedPower, rhs: CombinedPower) -> CombinedPower {
        return CombinedPower(
            performance: lhs.performance + rhs.performance,
            efficiency: lhs.efficiency + rhs.efficiency
        )
    }
    
    public static func - (lhs: CombinedPower, rhs: CombinedPower) -> CombinedPower {
        return CombinedPower(
            performance: lhs.performance - rhs.performance,
            efficiency: lhs.efficiency - rhs.efficiency
        )
    }
}

// MARK: - Formatting

extension NumberFormatter {
    static let power: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.maximumFractionDigits = 2
        numberFormatter.minimumFractionDigits = 2
        return numberFormatter
    }()
}

struct ChartPowerFormatStyle {
    
    struct Watts: FormatStyle {
        
        static let formatter: NumberFormatter = {
            let numberFormatter = NumberFormatter()
            numberFormatter.minimumFractionDigits = 1
            return numberFormatter
        }()
        
        func format(_ value: Power) -> String {
            let power = NSNumber(value: value)
            return Self.formatter.string(from: power) ?? "??"
        }
    }
    
    struct Miliwatts: FormatStyle {
        
        static let formatter: NumberFormatter = {
            let numberFormatter = NumberFormatter()
            numberFormatter.maximumFractionDigits = 0
            return numberFormatter
        }()
        
        func format(_ value: Power) -> String {
            let power = NSNumber(value: value * 1000)
            return Self.formatter.string(from: power) ?? "??"
        }
    }
}

//
//  Backtrace.swift
//
//
//  Created by Raúl Montón Pinillos on 8/3/24.
//

import Foundation

/// The memory address retrieved when unwinding the stack during a backtrace.
public typealias BacktraceAddress = UInt64
/// The full backtrace and the energy usage associated with it.
public struct Backtrace: Sendable, Hashable, Equatable {
    public var addresses: [BacktraceAddress]
    public var energy: Energy?
}
/// Symbol information of a backtrace, recovered using `dladdr`.
///
/// On iOS, `dladdr` may return `<redacted>` as the image and symbol names.
public struct SymbolicatedInfo: Sendable, Hashable {
    /// The name of the associated dylib that contains the address.
    public let imageName: String
    /// The offset of the address relative to the start of the dylib.
    public let addressInImage: UInt64
    /// The name of the symbol that contains the address.
    public let symbolName: String?
    /// The offset of the address relative to the start of the symbol.
    public let addressInSymbol: UInt64
    /// A formatted summary of the address information, similar to the lines printed in a crash report.
    public var displayName: String {
        return "0x\(String(format: "%llx", addressInImage)), \(imageName)"
    }
}
/// Minimal piece of information of a backtrace address.
public struct SimpleBacktraceInfo: Sendable {
    /// A specific address in the backtrace.
    public let address: BacktraceAddress
    /// Symbol information for the given address, recovered using `dladdr`.
    public let info: SymbolicatedInfo?
    /// The energy reported by the CLPC for the thread at the moment when the backtrace was
    /// sampled.
    public var energy: Energy
    
    init(address: BacktraceAddress, info: SymbolicatedInfo?, energy: Energy) {
        self.address = address
        self.energy = energy
        self.info = info
    }
}
/// Full backtrace information.
public struct BacktraceInfo: Sendable, Identifiable {
    /// A unique identifier for the backtrace information.
    public let id = UUID()
    /// A specific address in the backtrace.
    public let address: BacktraceAddress
    /// Symbol information for the given address, recovered using `dladdr`.
    public let info: SymbolicatedInfo?
    /// The energy reported by the CLPC for the thread at the moment when the backtrace was
    /// sampled.
    public let energy: Energy
    /// Backtrace address that were called from this `address`.
    public let children: [BacktraceInfo]
    
    public init(mutableBacktraceInfo: MutableBacktraceInfo) {
        self.address = mutableBacktraceInfo.address
        self.energy = mutableBacktraceInfo.energy
        self.info = mutableBacktraceInfo.info
        self.children = mutableBacktraceInfo.children.map {
            BacktraceInfo(mutableBacktraceInfo: $0)
        }
    }
    
    init(address: BacktraceAddress, info: SymbolicatedInfo?, energy: Energy, children: [BacktraceInfo]) {
        self.address = address
        self.energy = energy
        self.info = info
        self.children = children
    }
}
/// Full backtrace information.
public final class MutableBacktraceInfo: Identifiable {
    /// A unique identifier for the backtrace information.
    public let id = UUID()
    /// A specific address in the backtrace.
    public let address: BacktraceAddress
    /// Symbol information for the given address, recovered using `dladdr`.
    public let info: SymbolicatedInfo?
    /// The energy reported by the CLPC for the thread at the moment when the backtrace was
    /// sampled.
    public var energy: Energy
    /// Backtrace address that were called from this `address`.
    public var children: [MutableBacktraceInfo]
    
    init(address: BacktraceAddress, info: SymbolicatedInfo?, energy: Energy, children: [MutableBacktraceInfo]) {
        self.address = address
        self.energy = energy
        self.info = info
        self.children = children
    }
}

//
//  Backtrace.swift
//
//
//  Created by Raúl Montón Pinillos on 8/3/24.
//

import Foundation

public typealias BacktraceAddress = UInt64

public struct Backtrace: Hashable, Equatable {
    public var addresses: [BacktraceAddress]
    public var energy: Energy?
}

public struct SymbolicatedInfo: Hashable {
    public let imageName: String
    public let addressInImage: UInt64
    public let symbolName: String
    public let addressInSymbol: UInt64
    
    public var displayName: String {
        return "0x\(String(format: "%llx", addressInImage)), \(imageName)"
    }
}

public final class SimpleBacktraceInfo {
    let address: BacktraceAddress
    let info: SymbolicatedInfo?
    var energy: Energy
    
    init(address: BacktraceAddress, energy: Energy, info: SymbolicatedInfo?) {
        self.address = address
        self.energy = energy
        self.info = info
    }
}

public final class BacktraceInfo: Identifiable {
    public let id = UUID()
    public let address: BacktraceAddress
    public var energy: Energy
    public let info: SymbolicatedInfo?
    public var children: [BacktraceInfo]
    
    init(address: BacktraceAddress, energy: Energy, info: SymbolicatedInfo?, children: [BacktraceInfo]) {
        self.address = address
        self.energy = energy
        self.info = info
        self.children = children
    }
}

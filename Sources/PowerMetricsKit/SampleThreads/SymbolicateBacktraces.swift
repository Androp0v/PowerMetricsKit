//
//  SymbolicateBacktraces.swift
//
//
//  Created by Raúl Montón Pinillos on 9/3/24.
//

import Foundation
import SampleThreads

/// A class to interact to `dladdr` to retrieve information about the sampled backtraces.
public class SymbolicateBacktraces {
    
    public var backtraceGraph = BacktraceGraph()
    public var flatBacktraces = [SimpleBacktraceInfo]()
    private var addressToBacktrace = [BacktraceAddress: BacktraceInfo]()
        
    private init() {}
    public static let shared = SymbolicateBacktraces()
    
    public func symbolicatedInfo(for address: UInt64) -> SymbolicatedInfo? {
        var dlInfo = Dl_info()
        let addressPointer = UnsafeRawPointer(bitPattern: UInt(address))
        if dladdr(addressPointer, &dlInfo) != 0 {
            let imageName = (String(cString: dlInfo.dli_fname) as NSString).lastPathComponent
            let addressInImage = address - (unsafeBitCast(dlInfo.dli_fbase, to: UInt64.self))
            let symbolName = (String(cString: dlInfo.dli_sname) as NSString).lastPathComponent
            let addressInSymbol = address - (unsafeBitCast(dlInfo.dli_saddr, to: UInt64.self))
            return SymbolicatedInfo(
                imageName: imageName,
                addressInImage: addressInImage,
                symbolName: symbolName,
                addressInSymbol: addressInSymbol
            )
        } else {
            // dladdr returns 0 on error
            return nil
        }
    }
    
    func addToBacktraceGraph(_ backtraces: [Backtrace]) {
        for backtrace in backtraces {
            backtraceGraph.insertInGraph(newBacktrace: backtrace)
        }
        
        // Get the energy for every single memory address in all new backtraces
        for backtrace in backtraces {
            guard let energy = backtrace.energy else {
                // Backtrace doesn't contain any energy information...
                continue
            }
            // Add energies to backtrace flatmap
            for address in backtrace.addresses {
                if var existingInfo = flatBacktraces.first(where: { $0.address == address }) {
                    existingInfo.energy += energy
                } else {
                    flatBacktraces.append(SimpleBacktraceInfo(
                        address: address,
                        info: symbolicatedInfo(for: address),
                        energy: energy
                    ))
                }
            }
        }
    }
}

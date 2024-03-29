//
//  File.swift
//  
//
//  Created by Raúl Montón Pinillos on 10/3/24.
//

import Foundation

/// A graph containing the recorded backtrace information.
public final class BacktraceGraph {
    
    /// Top level nodes of the backtrace graph.
    ///
    /// These are the addresses from which all the function calls sampled come from.
    public var nodes = [BacktraceInfo]()
        
    private func insertInGraph(at insertionPoint: BacktraceInfo?, newInfo: BacktraceInfo) {
        if let insertionPoint {
            // precondition(addressToBacktrace.keys.contains(insertionPoint.address))
            insertionPoint.children.append(newInfo)
        } else {
            // print("New info not in graph, adding it as root element")
            nodes.append(newInfo)
        }
    }
    
    struct InsertionPointResult {
        let insertionPoint: BacktraceInfo?
        let remainingAddresses: [BacktraceAddress]
    }
    
    private func findInsertionPoint(for newBacktrace: Backtrace) throws -> InsertionPointResult {
        guard let outermostAddress = newBacktrace.addresses.last else {
            // Empty backtrace, move on...
            // print("Attempted to insert empty backtrace")
            throw BacktraceGraphError.emptyBacktrace
        }
        if let existingInfo = nodes.first(where: { $0.address == outermostAddress }) {
            
            // Add the energy information from the new backtrace to the outermost node
            existingInfo.energy += newBacktrace.energy ?? .zero
            
            var insertionPoint = existingInfo
            var remainingAddresses = newBacktrace.addresses.dropLast()
            var nextAddress = remainingAddresses.last
            while true {
                if nextAddress == nil {
                    // No more children in the backtrace, must be fully contained in graph
                    throw BacktraceGraphError.backtraceFullyContainedInGraph
                } else if insertionPoint.children.isEmpty {
                    // Existing backtrace doesn't contain any child
                    // print("Existing backtrace doesn't contain any other child")
                    return InsertionPointResult(
                        insertionPoint: insertionPoint,
                        remainingAddresses: Array(remainingAddresses)
                    )
                } else if let matchingChild = insertionPoint.children.first(where: { $0.address == nextAddress }) {
                    // Add the energy information from the new backtrace to the children
                    matchingChild.energy += newBacktrace.energy ?? .zero
                    // Existing backtrace info contains a child with the same address
                    insertionPoint = matchingChild
                    remainingAddresses = remainingAddresses.dropLast()
                    nextAddress = remainingAddresses.last
                } else {
                    // Existing backtrace doesn't contain this child in particular
                    /*
                    print(
                        """
                        Insertion point \(insertionPoint.info?.symbolName ?? "UNKNOWN") does not contain child \
                        \(SymbolicateBacktraces.shared.symbolicatedInfo(for: nextAddress ?? .zero)?.symbolName ?? "UNKNOWN")
                        """
                    )
                     */
                    return InsertionPointResult(
                        insertionPoint: insertionPoint,
                        remainingAddresses: Array(remainingAddresses)
                    )
                }
            }
        } else {
            // Doesn't exist, must be a new top-level backtrace
            // print("Insertion point not found, possible top-level element")
            return InsertionPointResult(
                insertionPoint: nil,
                remainingAddresses: newBacktrace.addresses
            )
        }
    }
        
    func insertInGraph(newBacktrace: Backtrace) {
        var newBacktrace = newBacktrace
        newBacktrace = sanitizedBacktrace(&newBacktrace)
        guard newBacktrace.addresses.last != nil else {
            // Empty backtrace, move on...
            // print("Attempted to insert empty backtrace")
            return
        }
        do {
            let insertionResult = try findInsertionPoint(for: newBacktrace)
            let newInfo = createBacktraceInfo(for: insertionResult.remainingAddresses)
            insertInGraph(at: insertionResult.insertionPoint, newInfo: newInfo)
        } catch {
            // No need to do anything
        }
    }
    
    // MARK: - Utils
    
    private func sanitizedBacktrace(_ backtrace: inout Backtrace) -> Backtrace {
        var addresses = backtrace.addresses
        while addresses.last == 0 {
            addresses = addresses.dropLast()
        }
        backtrace.addresses = addresses
        return backtrace
    }
    
    private func createBacktraceInfo(for addresses: [BacktraceAddress]) -> BacktraceInfo {
        if let outermostAddress = addresses.last {
            if outermostAddress == .zero {
                return createBacktraceInfo(for: addresses.dropLast())
            }
            let symbolicatedInfo = SymbolicateBacktraces.shared.symbolicatedInfo(for: outermostAddress)
            let backtraceInfo = BacktraceInfo(
                address: outermostAddress,
                energy: .zero,
                info: symbolicatedInfo,
                children: []
            )
            if addresses.count != 1 {
                backtraceInfo.children = [createBacktraceInfo(for: addresses.dropLast())]
            }
            return backtraceInfo
        } else {
            return BacktraceInfo(address: .zero, energy: .zero, info: nil, children: [])
        }
    }
}

// MARK: - Error

enum BacktraceGraphError: Error {
    case emptyBacktrace
    case backtraceFullyContainedInGraph
}

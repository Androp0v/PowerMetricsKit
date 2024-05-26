//
//  RingBuffer.swift
//
//
//  Created by Raúl Montón Pinillos on 26/5/24.
//

import Foundation

/// A ring buffer.
public struct RingBuffer<T> {
    
    private var array: [T?]
    private let length: Int
    private var index: Int
    private var isFull: Bool
    
    /// The last element added to the ring buffer.
    var last: T? {
        return array[index]
    }
    
    /// All the elements in the array, in the order they were added.
    var elements: [T] {
        guard isFull else {
            return Array(array.prefix(index)).compactMap { $0 }
        }
        if index == (length - 1) {
            return array.map { $0! }
        } else {
            let firstHalf = Array(array.suffix(length - index - 1)).map { $0! }
            let secondHalf = Array(array.prefix(index + 1)).map { $0! }
            return firstHalf + secondHalf
        }
    }
    
    /// All the elements in the array, in no particular order.
    ///
    /// This is faster than accessing ``elements`` as the ring buffer doesn't need to be sorted.
    var unsortedElements: [T] {
        if !isFull {
            return array.compactMap { $0 }
        } else {
            return array.map({ $0! })
        }
    }
    
    /// Initializes the ring buffer with a fixed capacity.
    public init(length: Int) {
        self.array = [T?](repeating: nil, count: length)
        self.length = length
        self.index = 0
        self.isFull = false
    }
    
    /// Adds a new element to the ring buffer.
    public mutating func add(element: T) {
        guard isFull else {
            var nextIndex = index + 1
            if nextIndex == length {
                isFull = true
                nextIndex = 0
            }
            self.index = nextIndex
            array[index] = element
            return
        }
        
        self.index = (index + 1) % length
        array[index] = element
    }
}

// MARK: - Array

extension Array {
    init<T>(_ ringBuffer: RingBuffer<T>) where Element == T {
        self = Array<Element>(ringBuffer.elements)
    }
}

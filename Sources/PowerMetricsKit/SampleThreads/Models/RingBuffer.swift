//
//  RingBuffer.swift
//
//
//  Created by Raúl Montón Pinillos on 26/5/24.
//

import Foundation

/// A ringbuffer.
public struct RingBuffer<T> {
    
    private var array: [T?]
    private let length: Int
    private var index: Int
    
    /// The last element added to the ring buffer.
    var last: T? {
        return array[index]
    }
    
    /// Initializes the ring buffer with a fixed capacity.
    public init(length: Int) {
        self.array = [T?](repeating: nil, count: length)
        self.length = length
        self.index = 0
    }
    
    /// Adds a new element to the ring buffer.
    public mutating func add(element: T) {
        self.index = (index + 1) % length
        array[index] = element
    }
}

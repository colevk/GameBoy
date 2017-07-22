//
//  AlignedArray.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/22/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class AlignedArray<T> {
    public let pointer: UnsafeMutableRawPointer
    public let count: Int
    public let alignment: Int
    public let bytes: Int

    private let memSize: Int

    public init(withCapacity capacity: Int, alignedTo: Int) {
        alignment = alignedTo
        count = capacity
        memSize = MemoryLayout<T>.size
        bytes = count * memSize - (count * memSize % alignment) + alignment
        var tempPtr: UnsafeMutableRawPointer? = UnsafeMutableRawPointer.allocate(bytes: bytes, alignedTo: alignment)
        posix_memalign(&tempPtr, alignment, bytes)
        pointer = tempPtr!
    }

    public subscript(index: Int) -> T {
        get {
            if (index >= count) { fatalError("Index out of range") }
            return pointer.load(fromByteOffset: index * memSize, as: T.self)
        }
        set {
            if (index >= count) { fatalError("Index out of range") }
            pointer.storeBytes(of: newValue, toByteOffset: index * memSize, as: T.self)
        }
    }
}

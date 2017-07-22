//
//  MemoryHelpers.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/15/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class MemoryHelper {
    fileprivate unowned let memory: Memory
    
    public init(onMemory memory: Memory) {
        self.memory = memory
    }
}

public class ByteAddress: MemoryHelper {
    public subscript(index: Int) -> UInt8 {
        get {
            return memory.readByte(fromAddress: index)
        }
        set {
            memory.writeByte(newValue, toAddress: index)
        }
    }

    public subscript(index: UInt16) -> UInt8 {
        get {
            return self[Int(index)]
        }
        set {
            self[Int(index)] = newValue
        }
    }
}

public class WordAddress: MemoryHelper {
    public subscript(index: Int) -> UInt16 {
        get {
            return memory.readWord(fromAddress: index)
        }
        set {
            memory.writeWord(newValue, toAddress: index)
        }
    }

    public subscript(index: UInt16) -> UInt16 {
        get {
            return self[Int(index)]
        }
        set {
            self[Int(index)] = newValue
        }
    }
}

public class Registers8Bit: MemoryHelper {
    public subscript(index: UInt8) -> UInt8 {
        get {
            switch index {
            case 0: return memory.b
            case 1: return memory.c
            case 2: return memory.d
            case 3: return memory.e
            case 4: return memory.h
            case 5: return memory.l
            case 6: return memory.addrHL
            case 7: return memory.a
            default: fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0: memory.b = newValue
            case 1: memory.c = newValue
            case 2: memory.d = newValue
            case 3: memory.e = newValue
            case 4: memory.h = newValue
            case 5: memory.l = newValue
            case 6: memory.addrHL = newValue
            case 7: memory.a = newValue
            default: fatalError("Index out of range")
            }
        }
    }
}

public class Registers16Bit: MemoryHelper {
    public subscript(index: UInt8) -> UInt16 {
        get {
            switch index {
            case 0: return memory.bc
            case 1: return memory.de
            case 2: return memory.hl
            case 3: return memory.sp
            default: fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0: memory.bc = newValue
            case 1: memory.de = newValue
            case 2: memory.hl = newValue
            case 3: memory.sp = newValue
            default: fatalError("Index out of range")
            }
        }
    }
}

public class Conditions: MemoryHelper {
    public subscript(index: UInt8) -> Bool {
        get {
            switch index {
            case 0: return !memory.flags.z
            case 1: return memory.flags.z
            case 2: return !memory.flags.c
            case 3: return memory.flags.c
            default: fatalError("Index out of range")
            }
        }
    }
}

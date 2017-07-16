//
//  Registers.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class Memory {
    public private(set) var bytes: ByteAddress! = nil
    public private(set) var words: WordAddress! = nil
    public private(set) var registers8: Registers8Bit! = nil
    public private(set) var registers16: Registers16Bit! = nil
    
    public init() {
        memory = [UInt8](repeating: 0, count: Int(UInt16.max))
        a = 0
        b = 0
        c = 0
        d = 0
        e = 0
        h = 0
        l = 0
        flags = Flags()
        pc = 0
        sp = 0
        
        bytes = ByteAddress(onMemory: self)
        words = WordAddress(onMemory: self)
        registers8 = Registers8Bit(onMemory: self)
        registers16 = Registers16Bit(onMemory: self)
    }
    
    
    // Memory
    
    private var memory: [UInt8]
    
    public func readByte(fromAddress addr: UInt16) -> UInt8 {
        return memory[Int(addr)]
    }
    
    public func readWord(fromAddress addr: UInt16) -> UInt16 {
        return UInt16(memory[Int(addr)]) + UInt16(memory[Int(addr) + 1]) << 8
    }
    
    public func writeByte(_ newValue: UInt8, toAddress addr: UInt16) {
        memory[Int(addr)] = newValue
    }
    
    public func writeWord(_ newValue: UInt16, toAddress addr: UInt16) {
        memory[Int(addr)] = UInt8(newValue & 0xFF)
        memory[Int(addr) + 1] = UInt8(newValue >> 8)
    }

    
    // 8-bit registers and flags
    
    public var a: UInt8
    public var b: UInt8
    public var c: UInt8
    public var d: UInt8
    public var e: UInt8
    public var h: UInt8
    public var l: UInt8
    
    public var flags: Flags
    public var f: UInt8 {
        get {
            return flags.uint8 & 0xF0
        }
        set {
            flags.uint8 = newValue & 0xF0
        }
    }
    
    public var addrHL: UInt8 {
        get {
            return readByte(fromAddress: hl)
        }
        set {
            writeByte(newValue, toAddress: hl)
        }
    }
    
    public var addrHLI: UInt8 {
        get {
            let value = addrHL
            hl += 1
            return value
        }
        set {
            addrHL = newValue
            hl += 1
        }
    }
    
    public var addrHLD: UInt8 {
        get {
            let value = addrHL
            hl -= 1
            return value
        }
        set {
            addrHL = newValue
            hl -= 1
        }
    }

    
    // 16-bit registers
    
    public var pc: UInt16
    public var sp: UInt16
    
    public var bc: UInt16 {
        get {
            return UInt16(b) << 8 + UInt16(c)
        }
        set {
            b = UInt8(newValue >> 8)
            c = UInt8(newValue & 0xFF)
        }
    }
    
    public var de: UInt16 {
        get {
            return UInt16(d) << 8 + UInt16(e)
        }
        set {
            d = UInt8(newValue >> 8)
            e = UInt8(newValue & 0xFF)
        }
    }
    
    public var hl: UInt16 {
        get {
            return UInt16(h) << 8 + UInt16(l)
        }
        set {
            h = UInt8(newValue >> 8)
            l = UInt8(newValue & 0xFF)
        }
    }
    
    public var af: UInt16 {
        get {
            return UInt16(a) << 8 + UInt16(f)
        }
        set {
            a = UInt8(newValue >> 8)
            f = UInt8(newValue & 0xFF)
        }
    }

}

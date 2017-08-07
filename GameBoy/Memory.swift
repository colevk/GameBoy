//
//  Registers.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class Memory {

    private unowned let gb: GameBoyRunner

    public var booting = true

    public private(set) var bytes: ByteAddress! = nil
    public private(set) var words: WordAddress! = nil
    public private(set) var registers8: Registers8Bit! = nil
    public private(set) var registers16: Registers16Bit! = nil
    public private(set) var conditions: Conditions! = nil

    public init(withParent parent: GameBoyRunner) {
        gb = parent

        eRAM = [UInt8](repeating: 0, count: 0x2000)
        wRAM = [UInt8](repeating: 0, count: 0x2000)
        zRAM = [UInt8](repeating: 0, count: 0x80)

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
        conditions = Conditions(onMemory: self)
    }

    public func reset() {
        booting = true
        pc = 0
    }

    public func skipStartup() {
        
    }


    // Memory

    public var cartridge: [UInt8]?
    private var eRAM: [UInt8]
    private var wRAM: [UInt8]
    private var zRAM: [UInt8]

    public func readByte(fromAddress addr: Int) -> UInt8 {
        switch addr {
        // BIOS address space and cartrige bank 0
        case 0x0000...0x00FF:
            if booting {
                return bios[addr]
            } else if let cart = cartridge {
                return cart[addr]
            } else {
                return 0xFF
            }
        case 0x0100...0x3FFF:
            if let cart = cartridge {
                return cart[addr]
            } else {
                return 0xFF
            }
        // Cartridge banks 1+
        case 0x4000...0x7FFF:
            if let cart = cartridge {
                return cart[addr]
            } else {
                return 0xFF
            }
        // Graphics RAM
        case 0x8000...0x9FFF:
            return gb.gpu.ram[addr - 0x8000]
        // Cartridge RAM
        case 0xA000...0xBFFF:
            return eRAM[addr - 0xA000]
        // Working RAM
        case 0xC000...0xDFFF:
            return wRAM[addr - 0xC000]
        // Copy of working RAM
        case 0xE000...0xFDFF:
            return wRAM[addr - 0xE000]
        // Object Attribute Memory
        case 0xFE00...0xFE9F:
            return gb.gpu.oam[addr - 0xFE00]
        // Zero-page RAM, for fast interactions with RAM
        case 0xFF80...0xFFFE:
            return zRAM[addr - 0xFF80]

        // 0xFF00 - 0xFF7F: I/O addresses
        case 0xFF0F:
            return gb.interrupts.interruptFlag
        case 0xFF40:
            return gb.gpu.lcdControl
        case 0xFF42:
            return gb.gpu.scrollY
        case 0xFF43:
            return gb.gpu.scrollX
        case 0xFF44:
            // fix this later
            return UInt8((gb.timer / 114) % 154)
        case 0xFF47:
            return gb.gpu.lcdControl
        case 0xFFFF:
            return gb.interrupts.interruptEnable
        case 0xFF00...0xFF7F,0xFFFF:
            print("Unsupported read from \(String(format: "0x%4X", addr))")
            return 0
        default:
            return 0
        }
    }

    public func writeByte(_ newValue: UInt8, toAddress addr: Int) {
        switch addr {
        case 0x0000...0x7FFF: // Read-only
            break
        // Graphics RAM
        case 0x8000...0x9FFF:
            gb.gpu.ram[addr - 0x8000] = newValue
        // Cartridge RAM
        case 0xA000...0xBFFF:
            eRAM[addr - 0xA000] = newValue
        // Working RAM
        case 0xC000...0xDFFF:
            wRAM[addr - 0xC000] = newValue
        // Copy of working RAM
        case 0xE000...0xFDFF:
            wRAM[addr - 0xE000] = newValue
        // Object Attribute Memory
        case 0xFE00...0xFE9F:
            gb.gpu.oam[addr - 0xFE00] = newValue
        // Zero-page RAM, for fast interactions with RAM
        case 0xFF80...0xFFFE:
            zRAM[addr - 0xFF80] = newValue

        // 0xFF00 - 0xFF7F: I/O addresses
        case 0xFF0F:
            gb.interrupts.interruptFlag = newValue
        case 0xFF40:
            gb.gpu.lcdControl = newValue
        case 0xFF42:
            gb.gpu.scrollY = newValue
        case 0xFF43:
            gb.gpu.scrollX = newValue
        case 0xFF47:
            gb.gpu.bgPalette = newValue
        case 0xFF50:
            if newValue == 1 {
                booting = false
            }
        case 0xFFFF:
            gb.interrupts.interruptEnable = newValue
        case 0xFF00...0xFF7F,0xFFFF:
            print("Unsupported write to \(String(format: "0x%04X", addr)): \(String(format: "0x%02X", newValue))")
        default:
            break
        }
    }

    public func readWord(fromAddress addr: Int) -> UInt16 {
        return UInt16(readByte(fromAddress: addr)) + UInt16(readByte(fromAddress: addr + 1)) << 8
    }

    public func writeWord(_ newValue: UInt16, toAddress addr: Int) {
        writeByte(UInt8(newValue & 0xFF), toAddress: addr)
        writeByte(UInt8(newValue >> 8), toAddress: addr + 1)
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
            return readByte(fromAddress: Int(hl))
        }
        set {
            writeByte(newValue, toAddress: Int(hl))
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

    public func pcByte() -> UInt8 {
        let value = bytes[Int(pc)]
        pc &+= 1
        return value
    }

    public func pcWord() -> UInt16 {
        let value = words[pc]
        pc &+= 2
        return value
    }

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

    private let bios: [UInt8] = [
        0x31, 0xFE, 0xFF, 0xAF, 0x21, 0xFF, 0x9F, 0x32, 0xCB, 0x7C, 0x20, 0xFB, 0x21, 0x26, 0xFF, 0x0E,
        0x11, 0x3E, 0x80, 0x32, 0xE2, 0x0C, 0x3E, 0xF3, 0xE2, 0x32, 0x3E, 0x77, 0x77, 0x3E, 0xFC, 0xE0,
        0x47, 0x11, 0x04, 0x01, 0x21, 0x10, 0x80, 0x1A, 0xCD, 0x95, 0x00, 0xCD, 0x96, 0x00, 0x13, 0x7B,
        0xFE, 0x34, 0x20, 0xF3, 0x11, 0xD8, 0x00, 0x06, 0x08, 0x1A, 0x13, 0x22, 0x23, 0x05, 0x20, 0xF9,
        0x3E, 0x19, 0xEA, 0x10, 0x99, 0x21, 0x2F, 0x99, 0x0E, 0x0C, 0x3D, 0x28, 0x08, 0x32, 0x0D, 0x20,
        0xF9, 0x2E, 0x0F, 0x18, 0xF3, 0x67, 0x3E, 0x64, 0x57, 0xE0, 0x42, 0x3E, 0x91, 0xE0, 0x40, 0x04,
        0x1E, 0x02, 0x0E, 0x0C, 0xF0, 0x44, 0xFE, 0x90, 0x20, 0xFA, 0x0D, 0x20, 0xF7, 0x1D, 0x20, 0xF2,
        0x0E, 0x13, 0x24, 0x7C, 0x1E, 0x83, 0xFE, 0x62, 0x28, 0x06, 0x1E, 0xC1, 0xFE, 0x64, 0x20, 0x06,
        0x7B, 0xE2, 0x0C, 0x3E, 0x87, 0xE2, 0xF0, 0x42, 0x90, 0xE0, 0x42, 0x15, 0x20, 0xD2, 0x05, 0x20,
        0x4F, 0x16, 0x20, 0x18, 0xCB, 0x4F, 0x06, 0x04, 0xC5, 0xCB, 0x11, 0x17, 0xC1, 0xCB, 0x11, 0x17,
        0x05, 0x20, 0xF5, 0x22, 0x23, 0x22, 0x23, 0xC9, 0xCE, 0xED, 0x66, 0x66, 0xCC, 0x0D, 0x00, 0x0B,
        0x03, 0x73, 0x00, 0x83, 0x00, 0x0C, 0x00, 0x0D, 0x00, 0x08, 0x11, 0x1F, 0x88, 0x89, 0x00, 0x0E,
        0xDC, 0xCC, 0x6E, 0xE6, 0xDD, 0xDD, 0xD9, 0x99, 0xBB, 0xBB, 0x67, 0x63, 0x6E, 0x0E, 0xEC, 0xCC,
        0xDD, 0xDC, 0x99, 0x9F, 0xBB, 0xB9, 0x33, 0x3E, 0x3C, 0x42, 0xB9, 0xA5, 0xB9, 0xA5, 0x42, 0x3C,
        0x21, 0x04, 0x01, 0x11, 0xA8, 0x00, 0x1A, 0x13, 0xBE, 0x20, 0xFE, 0x23, 0x7D, 0xFE, 0x34, 0x20,
        0xF5, 0x06, 0x19, 0x78, 0x86, 0x23, 0x05, 0x20, 0xFB, 0x86, 0x20, 0xFE, 0x3E, 0x01, 0xE0, 0x50,
    ]
}

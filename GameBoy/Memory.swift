//
//  Memory.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/7/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class Memory {

    unowned let gb: GameBoyRunner

    // External interface to bytes and words
    public var bytes: ByteAddress! = nil
    public var words: WordAddress! = nil

    // Stored on cartridge
    public var cartridge: [UInt8]? = nil
    public var externalRAM: [UInt8]? = nil

    // Video and sprite memory
    public var videoRAM: AlignedArray<UInt8>
    public var objectAttributeMemory: AlignedArray<UInt8>

    // Large, slow RAM
    public var workingRAM: [UInt8]

    // Small, fast RAM
    public var zeroPageRAM: [UInt8]

    // Sound wave pattern RAM
    public var wavePatternRAM: [UInt8]

    // I/O registers
    public var P1: UInt8 = 0   // FF00, joypad I/O

    public var DIV: UInt8 = 0  // FF04, increments 16384 times per second
    public var TIMA: UInt8 = 0 // FF05, timer
    public var TMA: UInt8 = 0  // FF06, timer modulo
    public var TAC: UInt8 = 0  // FF07, timer control

    public var IF: UInt8 = 0   // FF0F, interrupt flag

    public var NR10: UInt8 = 0 // FF10, sound mode 1, sweep
    public var NR11: UInt8 = 0 // FF11, sound mode 1, wave pattern
    public var NR12: UInt8 = 0 // FF12, sound mode 1, envelope
    public var NR13: UInt8 = 0 // FF13, sound mode 1, freq lo
    public var NR14: UInt8 = 0 // FF14, sound mode 1, freq hi

    public var NR21: UInt8 = 0 // FF16, sound mode 2, wave pattern
    public var NR22: UInt8 = 0 // FF17, sound mode 2, envelope
    public var NR23: UInt8 = 0 // FF18, sound mode 2, freq lo
    public var NR24: UInt8 = 0 // FF19, sound mode 2, freq hi

    public var NR30: UInt8 = 0 // FF1A, sound mode 3, on/off
    public var NR31: UInt8 = 0 // FF1B, sound mode 3, sound length
    public var NR32: UInt8 = 0 // FF1C, sound mode 3, output level
    public var NR33: UInt8 = 0 // FF1D, sound mode 3, freq lo
    public var NR34: UInt8 = 0 // FF1E, sound mode 3, freq hi

    public var NR41: UInt8 = 0 // FF20, sound mode 4, sound length
    public var NR42: UInt8 = 0 // FF21, sound mode 4, envelope
    public var NR43: UInt8 = 0 // FF22, sound mode 4, polynomial
    public var NR44: UInt8 = 0 // FF23, sound mode 4, selection

    public var NR50: UInt8 = 0 // FF24, sound channel control
    public var NR51: UInt8 = 0 // FF25, sound output selection
    public var NR52: UInt8 = 0 // FF26, sound on/off

    public var LCDC: UInt8 = 0 // FF40, LCD control
    public var STAT: UInt8 = 0 // FF41, LCD status
    public var SCY: UInt8 = 0  // FF42, scroll y
    public var SCX: UInt8 = 0  // FF43, scroll x
    public var LY: UInt8 = 0   // FF44, current line
    public var LYC: UInt8 = 0  // FF45, LY compare

    public var BGP: UInt8 = 0  // FF47, BG & window palette
    public var OBP0: UInt8 = 0 // FF48, object palette 0
    public var OBP1: UInt8 = 0 // FF49, object palette 1
    public var WY: UInt8 = 0   // FF4A, window y
    public var WX: UInt8 = 0   // FF4B, window x

    public var IE: UInt8 = 0   // FFFF, interrupt enable

    // Internal stuff
    var booting = true

    public init(withParent parent: GameBoyRunner) {
        gb = parent

        videoRAM = AlignedArray<UInt8>(withCapacity: 8192, alignedTo: 0x1000)
        objectAttributeMemory = AlignedArray<UInt8>(withCapacity: 160, alignedTo: 0x1000)
        workingRAM = [UInt8](repeating: 0, count: 8192)
        zeroPageRAM = [UInt8](repeating: 0, count: 127)
        wavePatternRAM = [UInt8](repeating: 0, count: 16)

        bytes = ByteAddress(onMemory: self)
        words = WordAddress(onMemory: self)
    }

    func readByte(_ index: Int) -> UInt8 {
        switch index {
        case 0x0000...0x00FF: // BIOS
            if booting {
                return bios[index]
            } else {
                fallthrough
            }
        case 0x0100...0x3FFF: // Cart ROM bank 0
            if let cart = cartridge {
                return cart[index]
            }
        case 0x4000...0x7FFF: // Cart ROM switchable
            if let cart = cartridge {
                return cart[index]
            }
        case 0x8000...0x9FFF: // Video RAM
            if gb.gpu.ramAccessible() {
                return videoRAM[index - 0x8000]
            }
        case 0xA000...0xBFFF: // Cartridge RAM
            if let ext = externalRAM {
                return ext[index - 0xA000]
            }
        case 0xC000...0xDFFF: // Working RAM
            return workingRAM[index - 0xC000]
        case 0xE000...0xFDFF: // Echo RAM, copy of working RAM
            return workingRAM[index - 0xE000]
        case 0xFE00...0xFE9F: // OAM
            if gb.gpu.oamAccessible() {
                return objectAttributeMemory[index - 0xFE00]
            }
        case 0xFF80...0xFFFE: // Zero-page RAM
            return zeroPageRAM[index - 0xFF80]

        // I/O registers
        case 0xFF00:
            return P1
        case 0xFF01:
            return gb.serialDevice.SB
        case 0xFF02:
            return gb.serialDevice.SC
        case 0xFF04:
            return DIV
        case 0xFF05:
            return TIMA
        case 0xFF06:
            return TMA
        case 0xFF07:
            return TAC
        case 0xFF0F:
            return IF

        case 0xFF40:
            return LCDC
        case 0xFF41:
            return STAT | 0b10000000
        case 0xFF42:
            return SCY
        case 0xFF43:
            return SCX
        case 0xFF44:
            return LY
        case 0xFF45:
            return LYC

        case 0xFF47:
            return BGP
        case 0xFF48:
            return OBP0
        case 0xFF49:
            return OBP1
        case 0xFF4A:
            return WY
        case 0xFF4B:
            return WX
        case 0xFFFF:
            return IE
        default:
            return 0xFF
        }
        return 0xFF
    }

    func writeByte(_ index: Int, _ newValue: UInt8) {
        switch index {
        case 0x0000...0x7FFF:
            break
        case 0x8000...0x9FFF: // Video RAM
            if gb.gpu.ramAccessible() {
                videoRAM[index - 0x8000] = newValue
            }
        case 0xA000...0xBFFF: // Cartridge RAM
            if var ext = externalRAM {
                ext[index - 0xA000] = newValue
            }
        case 0xC000...0xDFFF: // Working RAM
            workingRAM[index - 0xC000] = newValue
        case 0xE000...0xFDFF: // Echo RAM, copy of working RAM
            workingRAM[index - 0xE000] = newValue
        case 0xFE00...0xFE9F: // OAM
            if gb.gpu.oamAccessible() {
                objectAttributeMemory[index - 0xFE00] = newValue
            }
        case 0xFF80...0xFFFE: // Zero-page RAM
            zeroPageRAM[index - 0xFF80] = newValue

        // I/O registers
        case 0xFF00:
            P1 = newValue
        case 0xFF01:
            gb.serialDevice.SB = newValue
        case 0xFF02:
            gb.serialDevice.SC = newValue
        case 0xFF04:
            DIV = 0
        case 0xFF05:
            TIMA = newValue
        case 0xFF06:
            TMA = newValue
        case 0xFF07:
            TAC = newValue
        case 0xFF0F:
            IF = newValue

        case 0xFF40:
            LCDC = newValue
        case 0xFF41:
            STAT = (newValue & 0b11111000) | (STAT & 0b00000111)
        case 0xFF42:
            SCY = newValue
        case 0xFF43:
            SCX = newValue
        case 0xFF44:
            LY = 0
        case 0xFF45:
            LYC = newValue
        case 0xFF46:
            if gb.gpu.oamAccessible() {
                let start = 0x100 * Int(newValue)
                for idx in 0..<160 {
                    objectAttributeMemory[idx] = readByte(start + idx)
                }
            }
        case 0xFF47:
            BGP = newValue
        case 0xFF48:
            OBP0 = newValue
        case 0xFF49:
            OBP1 = newValue
        case 0xFF4A:
            WY = newValue
        case 0xFF4B:
            WX = newValue
        case 0xFF50:
            booting = false
        case 0xFFFF:
            IE = newValue
        default:
            break
        }
    }

    func readWord(_ index: Int) -> UInt16 {
        return UInt16(readByte(index)) + UInt16(readByte(index + 1)) << 8
    }

    func writeWord(_ index: Int, _ value: UInt16) {
        writeByte(index, UInt8(value & 0xFF))
        writeByte(index + 1, UInt8(value >> 8))
    }

    // Boot sequence
    public let bios: [UInt8] = [
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

public class MemoryHelper {
    unowned let memory: Memory

    public init(onMemory memory: Memory) {
        self.memory = memory
    }
}

public class ByteAddress: MemoryHelper {
    public subscript(index: Int) -> UInt8 {
        get { return memory.readByte(index) }
        set { memory.writeByte(index, newValue) }
    }

    public subscript(index: UInt16) -> UInt8 {
        get { return self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}

public class WordAddress: MemoryHelper {
    public subscript(index: Int) -> UInt16 {
        get { return memory.readWord(index) }
        set { memory.writeWord(index, newValue) }
    }

    public subscript(index: UInt16) -> UInt16 {
        get { return self[Int(index)] }
        set { self[Int(index)] = newValue }
    }
}


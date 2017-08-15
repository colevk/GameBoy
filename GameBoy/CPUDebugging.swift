//
//  CPUDebugging.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/11/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

/** Functions to pretty-print given instructions.
 */
extension CPU {
    private func byteAt(_ address: Int) -> String {
        return String(format: "$%02X", gb.memory.bytes[address])
    }

    private func wordAt(_ address: Int) -> String {
        return String(format: "$%04X", gb.memory.words[address])
    }

    public func instructionAt(address: UInt16) -> String {
        return instructionAt(address: Int(address))
    }

    public func instructionAt(address: Int) -> String {
        let opcode = Int(gb.memory.bytes[address])
        let r8Names = ["B", "C", "D", "E", "H", "L", "(HL)", "A"]
        let r16Names = ["BC", "DE", "HL", "SP"]
        let ccNames = ["NZ", "Z", "NC", "C"]

        switch opcode {
        case 0x00: return "NOP"
        case 0x08: return "LD (\(wordAt(address + 1))),SP"
        case 0x10: return "STOP 0"
        case 0x18: return "JR \(byteAt(address + 1))"
        case 0x20, 0x28, 0x30, 0x38: return "JR \(ccNames[(opcode - 0x20) / 8]),\(byteAt(address + 1))"
        case 0x01, 0x11, 0x21, 0x31: return "LD \(r16Names[(opcode - 0x01) / 16]),\(wordAt(address + 1))"
        case 0x09, 0x19, 0x29, 0x39: return "ADD HL,\(r16Names[(opcode - 0x09) / 16])"
        case 0x02: return "LD (BC),A"
        case 0x12: return "LD (DE),A"
        case 0x22: return "LDI (HL),A"
        case 0x32: return "LDD (HL),A"
        case 0x0A: return "LD A,(BC)"
        case 0x1A: return "LD A,(DE)"
        case 0x2A: return "LDI A,(HL)"
        case 0x3A: return "LDD A,(HL)"
        case 0x03, 0x13, 0x23, 0x33: return "INC \(r16Names[(opcode - 0x03) / 16])"
        case 0x0B, 0x1B, 0x2B, 0x3B: return "DEC \(r16Names[(opcode - 0x0B) / 16])"
        case 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C: return "INC \(r8Names[(opcode - 0x04) / 8])"
        case 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D: return "DEC \(r8Names[(opcode - 0x04) / 8])"
        case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E: return "LD \(r8Names[(opcode - 0x06) / 8]),\(byteAt(address + 1))"
        case 0x07: return "RLCA"
        case 0x0F: return "RRCA"
        case 0x17: return "RLA"
        case 0x1F: return "RRA"
        case 0x27: return "DAA"
        case 0x2F: return "CPL"
        case 0x37: return "SCF"
        case 0x3F: return "CCF"
        case 0x40...0x75, 0x77...0x7F: return "LD \(r8Names[(opcode - 0x40) / 8]),\(r8Names[opcode % 8])"
        case 0x76: return "HALT"
        case 0x80...0x87: return "ADD A,\(r8Names[opcode % 8])"
        case 0x88...0x8F: return "ADC A,\(r8Names[opcode % 8])"
        case 0x90...0x97: return "SUB \(r8Names[opcode % 8])"
        case 0x98...0x9F: return "SBC A,\(r8Names[opcode % 8])"
        case 0xA0...0xA7: return "AND \(r8Names[opcode % 8])"
        case 0xA8...0xAF: return "XOR \(r8Names[opcode % 8])"
        case 0xB0...0xB7: return "OR \(r8Names[opcode % 8])"
        case 0xB8...0xBF: return "CP \(r8Names[opcode % 8])"
        case 0xC6: return "ADD A,\(byteAt(address + 1))"
        case 0xCE: return "ADC A,\(byteAt(address + 1))"
        case 0xD6: return "SUB \(byteAt(address + 1))"
        case 0xDE: return "SBC A,\(byteAt(address + 1))"
        case 0xE6: return "AND \(byteAt(address + 1))"
        case 0xEE: return "XOR \(byteAt(address + 1))"
        case 0xF6: return "OR \(byteAt(address + 1))"
        case 0xFE: return "CP \(byteAt(address + 1))"
        case 0xC9: return "RET"
        case 0xC0, 0xC8, 0xD0, 0xD8: return "RET \(ccNames[(opcode - 0xC0) / 8])"
        case 0xD9: return "RETI"
        case 0xC1, 0xD1, 0xE1: return "POP \(r16Names[(opcode - 0xC1) / 16])"
        case 0xF1: return "POP AF"
        case 0xC5, 0xD5, 0xE5: return "PUSH \(r16Names[(opcode - 0xC5) / 16])"
        case 0xF5: return "PUSH AF"
        case 0xC3: return "JP \(wordAt(address + 1))"
        case 0xC2, 0xCA, 0xD2, 0xDA: return "JP \(ccNames[(opcode - 0xC2) / 8]),\(wordAt(address + 1))"
        case 0xE9: return "JP (HL)"
        case 0xCD: return "CALL \(wordAt(address + 1))"
        case 0xC4, 0xCC, 0xD4, 0xDC: return "CALL \(ccNames[(opcode - 0xC4) / 8]),\(wordAt(address + 1))"
        case 0xE8: return "ADD SP,\(byteAt(address + 1))"
        case 0xF8: return "LD HL,SP+\(byteAt(address + 1))"
        case 0xF9: return "LD SP,HL"
        case 0xE0: return "LDH (\(byteAt(address + 1))),A"
        case 0xF0: return "LDH A,(\(byteAt(address + 1)))"
        case 0xE2: return "LD (C),A"
        case 0xF2: return "LD A,(C)"
        case 0xEA: return "LD (\(byteAt(address + 1))),A"
        case 0xFA: return "LD A,(\(byteAt(address + 1)))"
        case 0xF3: return "DI"
        case 0xFB: return "EI"
        case 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF: return "RST $\(String(opcode - 0xC7, radix: 16))"
        case 0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB...0xED, 0xF4, 0xFC, 0xFD: return "Unused instruction"

        case 0xCB:
            let opcodeCB = Int(gb.memory.bytes[address + 1])
            switch opcodeCB {
            case 0x00...0x07: return "RLC \(r8Names[opcodeCB % 8])"
            case 0x08...0x0F: return "RRC \(r8Names[opcodeCB % 8])"
            case 0x10...0x17: return "RL \(r8Names[opcodeCB % 8])"
            case 0x18...0x1F: return "RR \(r8Names[opcodeCB % 8])"
            case 0x20...0x27: return "SLA \(r8Names[opcodeCB % 8])"
            case 0x28...0x2F: return "SRA \(r8Names[opcodeCB % 8])"
            case 0x30...0x3F: return "SWAP \(r8Names[opcodeCB % 8])"
            case 0x38...0x3F: return "SRL \(r8Names[opcodeCB % 8])"
            case 0x40...0x7F: return "BIT \((opcodeCB - 0x40) / 8),\(r8Names[opcodeCB % 8])"
            case 0x80...0xBF: return "RES \((opcodeCB - 0x80) / 8),\(r8Names[opcodeCB % 8])"
            case 0xC0...0xFF: return "SET \((opcodeCB - 0xC0) / 8),\(r8Names[opcodeCB % 8])"
            default: break
            }
        default: break
        }

        return "Missing case statement"
    }
}

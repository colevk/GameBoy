//
//  CPU.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import Cocoa

public class CPU {

    private unowned let gb: GameBoyRunner

    let ops: Ops
    var ime: Bool = true

    private var halt: Bool = false

    public init(withParent parent: GameBoyRunner) {
        gb = parent
        ops = Ops(withFlags: gb.memory.flags)
    }

    public func step() -> Int {
        return runOpcode(gb.memory.pcByte())
    }

    public func runOpcode(_ opcode: UInt8) -> Int {
        if halt {
            if ime {
                return 1
            } else {
                gb.memory.pc -= 1
                halt = false
            }
        }

        switch opcode {
        case 0x00: // NOP
            return 1

        case 0x08: // LD (nn),SP
            gb.memory.words[gb.memory.pcWord()] = gb.memory.sp
            return 5

        case 0x10: // STOP 0
            print("Unimplemented instruction: \(instructionAt(address: gb.memory.pc - 1))\n")
            NSApplication.shared.terminate(self)

        case 0x18: // JR n
            let e = gb.memory.pcByte()
            (gb.memory.pc, gb.memory.flags.h, gb.memory.flags.c) = UInt16.addRelativeWithFlags(gb.memory.pc, e)
            return 3
        case 0x20, 0x28, 0x30, 0x38: // JR cc,n
            let offset = (opcode - 0x20) / 8
            let e = gb.memory.pcByte()
            if gb.memory.conditions[offset] {
                (gb.memory.pc, gb.memory.flags.h, gb.memory.flags.c) = UInt16.addRelativeWithFlags(gb.memory.pc, e)
                return 3
            } else {
                return 2
            }

        case 0x01, 0x11, 0x21, 0x31: // LD rr,nn
            let offset = (opcode - 0x01) / 16
            gb.memory.registers16[offset] = gb.memory.pcWord()
            return 3

        case 0x09, 0x19, 0x29, 0x39: // ADD HL,rr
            let offset = (opcode - 0x09) / 16
            ops.add(to: &gb.memory.hl, from: gb.memory.registers16[offset])
            return 2

        case 0x02: // LD (BC),A
            gb.memory.bytes[gb.memory.bc] = gb.memory.a
            return 2
        case 0x12: // LD (DE),A
            gb.memory.bytes[gb.memory.de] = gb.memory.a
            return 2
        case 0x22: // LDI (HL),A
            gb.memory.addrHLI = gb.memory.a
            return 2
        case 0x32: // LDD (HL),A
            gb.memory.addrHLD = gb.memory.a
            return 2

        case 0x0A: // LD A,(BC)
            gb.memory.a = gb.memory.bytes[gb.memory.bc]
            return 2
        case 0x1A: // LD A,(DE)
            gb.memory.a = gb.memory.bytes[gb.memory.de]
            return 2
        case 0x2A: // LDI A,(HL)
            gb.memory.a = gb.memory.addrHLI
            return 2
        case 0x3A: // LDD A,(HL)
            gb.memory.a = gb.memory.addrHLD
            return 2

        case 0x03, 0x13, 0x23, 0x33: // INC rr
            let offset = (opcode - 0x03) / 16
            ops.inc(register: &gb.memory.registers16[offset])
            return 2

        case 0x0B, 0x1B, 0x2B, 0x3B: // DEC rr
            let offset = (opcode - 0x0B) / 16
            ops.dec(register: &gb.memory.registers16[offset])
            return 2

        case 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C: // INC r
            let offset = (opcode - 0x04) / 8
            ops.inc(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 1 : 3

        case 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D: // DEC r
            let offset = (opcode - 0x04) / 8
            ops.dec(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 1 : 3

        case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E: // LD r,n
            let offset = (opcode - 0x06) / 8
            gb.memory.registers8[offset] = gb.memory.pcByte()
            return (offset != 6) ? 2 : 3

        case 0x07: // RLCA
            ops.rlc(register: &gb.memory.a)
            gb.memory.flags.z = false
            return 1
        case 0x0F: // RRCA
            ops.rrc(register: &gb.memory.a)
            gb.memory.flags.z = false
            return 1
        case 0x17: // RLA
            ops.rl(register: &gb.memory.a)
            gb.memory.flags.z = false
            return 1
        case 0x1F: // RRA
            ops.rr(register: &gb.memory.a)
            gb.memory.flags.z = false
            return 1

        case 0x27: // DAA
            print("Unimplemented instruction: \(instructionAt(address: gb.memory.pc - 1))\n")
            NSApplication.shared.terminate(self)
        case 0x2F: // CPL
            gb.memory.a = ~gb.memory.a
            gb.memory.flags.n = true
            gb.memory.flags.h = true
            return 1
        case 0x37: // SCF
            gb.memory.flags.n = false
            gb.memory.flags.h = false
            gb.memory.flags.c = true
            return 1
        case 0x3F: // CCF
            gb.memory.flags.n = false
            gb.memory.flags.h = false
            gb.memory.flags.c = !gb.memory.flags.c
            return 1

        case 0x40...0x75, 0x77...0x7F: // LD r,r
            let srcOffset = opcode % 8
            let dstOffset = (opcode - 0x40) / 8
            gb.memory.registers8[dstOffset] = gb.memory.registers8[srcOffset]
            return (srcOffset != 6 && dstOffset != 6) ? 1 : 2

        case 0x76: // HALT
            halt = true
            return 1

        case 0x80...0x87: // ADD A,r
            let offset = opcode % 8
            ops.add(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0x88...0x8F: // ADC A,r
            let offset = opcode % 8
            ops.adc(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0x90...0x97: // SUB r
            let offset = opcode % 8
            ops.sub(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0x98...0x9F: // SBC A,r
            let offset = opcode % 8
            ops.sbc(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0xA0...0xA7: // AND r
            let offset = opcode % 8
            ops.and(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0xA8...0xAF: // XOR r
            let offset = opcode % 8
            ops.xor(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0xB0...0xB7: // OR r
            let offset = opcode % 8
            ops.or(to: &gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0xB8...0xBF: // CP r
            let offset = opcode % 8
            ops.cp(to: gb.memory.a, from: gb.memory.registers8[offset])
            return offset != 6 ? 1 : 2

        case 0xC6: // ADD A,n
            ops.add(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xCE: // ADC A,n
            ops.adc(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xD6: // SUB n
            ops.sub(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xDE: // SBC A,n
            ops.sbc(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xE6: // AND n
            ops.and(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xEE: // XOR n
            ops.xor(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xF6: // OR n
            ops.or(to: &gb.memory.a, from: gb.memory.pcByte())
            return 2
        case 0xFE: // CP n
            ops.cp(to: gb.memory.a, from: gb.memory.pcByte())
            return 2

        case 0xC9: // RET
            gb.memory.pc = gb.memory.words[gb.memory.sp]
            gb.memory.sp += 2
            return 4
        case 0xC0, 0xC8, 0xD0, 0xD8: // RET NZ
            let offset = (opcode - 0xC0) / 8
            if gb.memory.conditions[offset] {
                gb.memory.pc = gb.memory.words[gb.memory.sp]
                gb.memory.sp += 2
                return 5
            } else {
                return 2
            }

        case 0xD9: // RETI
            gb.memory.pc = gb.memory.words[gb.memory.sp]
            gb.memory.sp += 2
            ime = true
            return 4

        case 0xC1, 0xD1, 0xE1: // POP rr
            let offset = (opcode - 0xC1) / 16
            gb.memory.registers16[offset] = gb.memory.words[gb.memory.sp]
            gb.memory.sp += 2
            return 3
        case 0xF1: // POP AF
            gb.memory.af = gb.memory.words[gb.memory.sp]
            gb.memory.sp += 2
            return 3

        case 0xC5, 0xD5, 0xE5: // PUSH rr
            let offset = (opcode - 0xC5) / 16
            gb.memory.sp -= 2
            gb.memory.words[gb.memory.sp] = gb.memory.registers16[offset]
            return 4
        case 0xF5: // PUSH AF
            gb.memory.sp -= 2
            gb.memory.words[gb.memory.sp] = gb.memory.af
            return 4

        case 0xC3: // JP nn
            gb.memory.pc = gb.memory.pcWord()
            return 4
        case 0xC2, 0xCA, 0xD2, 0xDA: // JP cc,nn
            let offset = (opcode - 0xC2) / 8
            let addr = gb.memory.pcWord()
            if gb.memory.conditions[offset] {
                gb.memory.pc = addr
                return 4
            } else {
                return 3
            }
        case 0xE9: // JP (HL)
            gb.memory.pc = gb.memory.hl
            return 1

        case 0xCD: // CALL nn
            let addr = gb.memory.pcWord()
            gb.memory.sp -= 2
            gb.memory.words[gb.memory.sp] = gb.memory.pc
            gb.memory.pc = addr
            return 6
        case 0xC4, 0xCC, 0xD4, 0xDC: // CALL cc,nn
            let offset = (opcode - 0xC4) / 8
            let addr = gb.memory.pcWord()
            if gb.memory.conditions[offset] {
                gb.memory.sp -= 2
                gb.memory.words[gb.memory.sp] = gb.memory.pc
                gb.memory.pc = addr
                return 6
            } else {
                return 3
            }

        case 0xE8: // ADD SP,n
            (gb.memory.sp, gb.memory.flags.h, gb.memory.flags.c) = UInt16.addRelativeWithFlags(gb.memory.sp, gb.memory.pcByte())
            gb.memory.flags.z = false
            gb.memory.flags.n = false
            return 4

        case 0xF8: // LD HL,SP+n
            (gb.memory.hl, gb.memory.flags.h, gb.memory.flags.c) = UInt16.addRelativeWithFlags(gb.memory.sp, gb.memory.pcByte())
            gb.memory.flags.z = false
            gb.memory.flags.n = false
            return 3
        case 0xF9: // LD SP,HL
            gb.memory.sp = gb.memory.hl
            return 2

        case 0xE0: // LDH (n),A
            gb.memory.bytes[0xFF00 + UInt16(gb.memory.pcByte())] = gb.memory.a
            return 3
        case 0xF0: // LDH A,(n)
            gb.memory.a = gb.memory.bytes[0xFF00 + UInt16(gb.memory.pcByte())]
            return 3

        case 0xE2: // LD (C),A
            gb.memory.bytes[0xFF00 + UInt16(gb.memory.c)] = gb.memory.a
            return 2
        case 0xF2: // LD A,(C)
            gb.memory.a = gb.memory.bytes[0xFF00 + UInt16(gb.memory.c)]
            return 2

        case 0xEA: // LD (nn),A
            gb.memory.bytes[gb.memory.pcWord()] = gb.memory.a
            return 4
        case 0xFA: // LD A,(nn)
            gb.memory.a = gb.memory.bytes[gb.memory.pcWord()]
            return 4

        case 0xF3: // DI
            ime = false
            return 1
        case 0xFB: // EI
            ime = true
            return 1

        case 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF: // RST
            gb.memory.sp -= 2
            gb.memory.words[gb.memory.sp] = gb.memory.pc
            gb.memory.pc = UInt16(opcode - 0xC7)
            return 4

        case 0xCB:
            return runOpcodeCB(gb.memory.pcByte())

        case 0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB...0xED, 0xF4, 0xFC, 0xFD:
            print("Opcode \(String(format: "$%04X", opcode)) is unused")
            NSApplication.shared.terminate(self)

        default:
            print("Missing case statement for opcode \(String(format: "$%04X", opcode))")
            NSApplication.shared.terminate(self)
        }

        return 0
    }

    public func runOpcodeCB(_ opcode: UInt8) -> Int {
        switch opcode {
        case 0x00...0x07: // RLC r
            let offset = opcode % 8
            ops.rlc(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x08...0x0F: // RRC r
            let offset = opcode % 8
            ops.rrc(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x10...0x17: // RL r
            let offset = opcode % 8
            ops.rl(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x18...0x1F: // RR r
            let offset = opcode % 8
            ops.rr(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x20...0x27: // SLA r
            let offset = opcode % 8
            ops.sla(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x28...0x2F: // SRA r
            let offset = opcode % 8
            ops.sra(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x30...0x3F: // SWAP r
            let offset = opcode % 8
            gb.memory.registers8[offset] = gb.memory.registers8[offset] << 4 + gb.memory.registers8[offset] >> 4
            gb.memory.flags.z = gb.memory.registers8[offset] == 0
            gb.memory.flags.n = false
            gb.memory.flags.h = false
            gb.memory.flags.c = false
            return (offset != 6) ? 2 : 4

        case 0x38...0x3F: // SRL r
            let offset = opcode % 8
            ops.srl(register: &gb.memory.registers8[offset])
            return (offset != 6) ? 2 : 4

        case 0x40...0x7F: // BIT d,r
            let bitOffset = (opcode - 0x40) / 8
            let registerOffset = opcode % 8
            ops.bit(bitOffset, register: gb.memory.registers8[registerOffset])
            return (registerOffset != 6) ? 2 : 4

        case 0x80...0xBF: // RES d,r
            let bitOffset = (opcode - 0x80) / 8
            let registerOffset = opcode % 8
            ops.reset(bitOffset, register: &gb.memory.registers8[registerOffset])
            return (registerOffset != 6) ? 2 : 4

        case 0xC0...0xFF: // SET d,r
            let bitOffset = (opcode - 0xC0) / 8
            let registerOffset = opcode % 8
            ops.set(bitOffset, register: &gb.memory.registers8[registerOffset])
            return (registerOffset != 6) ? 2 : 4

        default: return 0
        }
    }

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

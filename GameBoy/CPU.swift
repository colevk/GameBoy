//
//  CPU.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class CPU {
    
    let mem: Memory
    let ops: Ops
    var timer: Int = 0
    
    public init() {
        mem = Memory()
        ops = Ops(withFlags: mem.flags)
    }
    
    func loadGame(fromFile file: String) {
        if let data = NSData(contentsOfFile: file) {
            data.getBytes(&mem.memory, range: NSRange(location: 256, length: 0x3FFF))
        }
    }
    
    public func step() {
        runOpcode(mem.pcByte())
    }
    
    public func runOpcode(_ opcode: UInt8) {
        switch opcode {
        case 0x00: // NOP
            timer += 1
            
        case 0x08: // LD (nn),SP
            mem.words[mem.pcWord()] = mem.sp
            timer += 5

        case 0x10: // STOP 0
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")

        case 0x18: // JR n
            (mem.pc, mem.flags.h, mem.flags.c) = UInt16.addRelativeWithFlags(mem.pc, mem.pcByte())
            timer += 3
        case 0x20, 0x28, 0x30, 0x38: // JR cc,n
            let offset = (opcode - 0x20) / 8
            let e = mem.pcByte()
            if mem.conditions[offset] {
                (mem.pc, mem.flags.h, mem.flags.c) = UInt16.addRelativeWithFlags(mem.pc, e)
                timer += 3
            } else {
                timer += 2
            }
            
        case 0x01, 0x11, 0x21, 0x31: // LD rr,nn
            let offset = (opcode - 0x01) / 16
            mem.registers16[offset] = mem.pcWord()
            timer += 3
            
        case 0x09, 0x19, 0x29, 0x39: // ADD HL,rr
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0x02: // LD (BC),A
            mem.bytes[mem.bc] = mem.a
            timer += 2
        case 0x12: // LD (DE),A
            mem.bytes[mem.de] = mem.a
            timer += 2
        case 0x22: // LDI (HL),A
            mem.addrHLI = mem.a
            timer += 2
        case 0x32: // LDD (HL),A
            mem.addrHLD = mem.a
            timer += 2
            
        case 0x0A: // LD A,(BC)
            mem.a = mem.bytes[mem.bc]
            timer += 2
        case 0x1A: // LD A,(DE)
            mem.a = mem.bytes[mem.de]
            timer += 2
        case 0x2A: // LDI A,(HL)
            mem.a = mem.addrHLI
            timer += 2
        case 0x3A: // LDD A,(HL)
            mem.a = mem.addrHLD
            timer += 2
            
        case 0x03, 0x13, 0x23, 0x33: // INC rr
            let offset = (opcode - 0x03) / 16
            ops.inc(register: &mem.registers16[offset])
            timer += 2
            
        case 0x0B, 0x1B, 0x2B, 0x3B: // DEC rr
            let offset = (opcode - 0x0B) / 16
            ops.dec(register: &mem.registers16[offset])
            timer += 2

        case 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C: // INC r
            let offset = (opcode - 0x04) / 8
            ops.inc(register: &mem.registers8[offset])
            timer += (offset != 6) ? 1 : 3

        case 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D: // DEC r
            let offset = (opcode - 0x04) / 8
            ops.inc(register: &mem.registers8[offset])
            timer += (offset != 6) ? 1 : 3

        case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E: // LD r,n
            let offset = (opcode - 0x06) / 8
            mem.registers8[offset] = mem.pcByte()
            timer += (offset != 6) ? 2 : 3
        
        case 0x07: // RLCA
            ops.rlc(register: &mem.a)
            mem.flags.z = false
            timer += 1
        case 0x0F: // RRCA
            ops.rrc(register: &mem.a)
            mem.flags.z = false
            timer += 1
        case 0x17: // RLA
            ops.rl(register: &mem.a)
            mem.flags.z = false
            timer += 1
        case 0x1F: // RRA
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")

        case 0x27: // DAA
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0x2F: // CPL
            mem.a = ~mem.a
            mem.flags.n = true
            mem.flags.h = true
            timer += 1
        case 0x37: // SCF
            mem.flags.n = false
            mem.flags.h = false
            mem.flags.c = true
            timer += 1
        case 0x3F: // CCF
            mem.flags.n = false
            mem.flags.h = false
            mem.flags.c = !mem.flags.c
            timer += 1
            
        case 0x40...0x75, 0x77...0x7F: // LD r,r
            let srcOffset = opcode % 8
            let dstOffset = (opcode - 0x40) / 8
            mem.registers8[dstOffset] = mem.registers8[srcOffset]
            timer += (srcOffset != 6 && dstOffset != 6) ? 1 : 2
            
        case 0x76: // HALT
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0x80...0x87: // ADD A,r
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0x88...0x8F: // ADC A,r
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0x90...0x97: // SUB r
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0x98...0x9F: // SBC A,r
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xA0...0xA7: // AND r
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xA8...0xAF: // XOR r
            let offset = opcode % 8
            mem.a = mem.a ^ mem.registers8[offset]
            mem.flags.z = mem.a == 0
            mem.flags.n = false
            mem.flags.h = false
            mem.flags.c = false
            timer += offset != 6 ? 1 : 2
            
        case 0xB0...0xB7: // OR r
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xB8...0xBF: // CP r
            let offset = opcode % 8
            ops.cp(to: mem.a, from: mem.registers8[offset])
            timer += offset != 6 ? 1 : 2
            
        case 0xC6: // ADD A,n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xCE: // ADC A,n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xD6: // SUB n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xDE: // SBC A,n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xE6: // AND n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xEE: // XOR n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xF6: // OR n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xFE: // CP n
            ops.cp(to: mem.a, from: mem.pcByte())
            timer += 2
            
        case 0xC9: // RET
            mem.pc = mem.words[mem.sp]
            mem.sp += 2
            timer += 4
        case 0xC0, 0xC8, 0xD0, 0xD8: // RET NZ
            let offset = (opcode - 0xC0) / 8
            if mem.conditions[offset] {
                mem.pc = mem.words[mem.sp]
                mem.sp += 2
                timer += 5
            } else {
                timer += 2
            }

        case 0xD9: // RETI
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xC1, 0xD1, 0xE1: // POP rr
            let offset = (opcode - 0xC1) / 16
            mem.registers16[offset] = mem.words[mem.sp]
            mem.sp += 2
            timer += 3
        case 0xF1: // POP AF
            mem.af = mem.words[mem.sp]
            mem.sp += 2
            timer += 3
            
        case 0xC5, 0xD5, 0xE5: // PUSH rr
            let offset = (opcode - 0xC5) / 16
            mem.sp -= 2
            mem.words[mem.sp] = mem.registers16[offset]
            timer += 4
        case 0xF5: // PUSH AF
            mem.sp -= 2
            mem.words[mem.sp] = mem.af
            timer += 4
            
        case 0xC3: // JP nn
            mem.pc = mem.pcWord()
            timer += 4
        case 0xC2, 0xCA, 0xD2, 0xDA: // JP cc,nn
            let offset = (opcode - 0xC2) / 8
            let addr = mem.pcWord()
            if mem.conditions[offset] {
                mem.pc = addr
                timer += 4
            } else {
                timer += 3
            }
        case 0xE9: // JP (HL)
            mem.pc = mem.hl
            timer += 1
            
        case 0xCD: // CALL nn
            let addr = mem.pcWord()
            mem.sp -= 2
            mem.words[mem.sp] = mem.pc
            mem.pc = addr
            timer += 6
        case 0xC4, 0xCC, 0xD4, 0xDC: // CALL cc,nn
            let offset = (opcode - 0xC4) / 8
            let addr = mem.pcWord()
            if mem.conditions[offset] {
                mem.sp -= 2
                mem.words[mem.sp] = mem.pc
                mem.pc = addr
                timer += 6
            } else {
                timer += 3
            }
            
        case 0xE8: // ADD SP,n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xF8: // LD HL,SP+n
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xF9: // LD SP,HL
            mem.sp = mem.hl
            timer += 2
            
        case 0xE0: // LDH (n),A
            mem.bytes[0xFF00 + UInt16(mem.pcByte())] = mem.a
            timer += 3
        case 0xF0: // LDH A,(n)
            mem.a = mem.bytes[0xFF00 + UInt16(mem.pcByte())]
            timer += 3
            
        case 0xE2: // LD (C),A
            mem.bytes[0xFF00 + UInt16(mem.c)] = mem.a
            timer += 2
        case 0xF2: // LD A,(C)
            mem.a = mem.bytes[0xFF00 + UInt16(mem.c)]
            timer += 2
            
        case 0xEA: // LD (nn),A
            mem.bytes[mem.pcWord()] = mem.a
            timer += 4
        case 0xFA: // LD A,(nn)
            mem.a = mem.bytes[mem.pcWord()]
            timer += 4
            
        case 0xF3: // DI
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
        case 0xFB: // EI
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF: // RST
            fatalError("Unimplemented instruction: \(nextInstruction(1))\n")
            
        case 0xCB:
            runOpcodeCB(mem.pcByte())

        case 0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB...0xED, 0xF4, 0xFC, 0xFD:
            fatalError("Unused opcode")

        default:
            fatalError("Unimplemented instruction")
        }
    }
    
    public func runOpcodeCB(_ opcode: UInt8) {
        switch opcode {
        case 0x00...0x07: // RLC r
            let offset = opcode % 8
            ops.rlc(register: &mem.registers8[offset])
            timer += (offset != 6) ? 2 : 4

        case 0x08...0x0F: // RRC r
            let offset = opcode % 8
            ops.rrc(register: &mem.registers8[offset])
            timer += (offset != 6) ? 2 : 4
            
        case 0x10...0x17: // RL r
            let offset = opcode % 8
            ops.rl(register: &mem.registers8[offset])
            timer += (offset != 6) ? 2 : 4
            
        case 0x18...0x1F: // RR r
            fatalError("Unimplemented instruction: \(nextInstruction(2))\n")
            
        case 0x20...0x27: // SLA r
            fatalError("Unimplemented instruction: \(nextInstruction(2))\n")
            
        case 0x28...0x2F: // SRA r
            fatalError("Unimplemented instruction: \(nextInstruction(2))\n")
            
        case 0x30...0x3F: // SWAP r
            fatalError("Unimplemented instruction: \(nextInstruction(2))\n")
            
        case 0x38...0x3F: // SRL r
            fatalError("Unimplemented instruction: \(nextInstruction(2))\n")
            
        case 0x40...0x7F: // BIT d,r
            let bitOffset = (opcode - 0x40) / 8
            let registerOffset = opcode % 8
            ops.bit(bitOffset, register: mem.registers8[registerOffset])
            timer += (registerOffset != 6) ? 2 : 4
            
        case 0x80...0xBF: // RES d,r
            let bitOffset = (opcode - 0x80) / 8
            let registerOffset = opcode % 8
            ops.reset(bitOffset, register: &mem.registers8[registerOffset])
            timer += (registerOffset != 6) ? 2 : 4
            
        case 0xC0...0xFF: // SET d,r
            let bitOffset = (opcode - 0xC0) / 8
            let registerOffset = opcode % 8
            ops.set(bitOffset, register: &mem.registers8[registerOffset])
            timer += (registerOffset != 6) ? 2 : 4

        default: break
        }
    }
    
    public func nextInstruction() -> String {
        return nextInstruction(0)
    }
    
    public func nextInstruction(_ byteOffset: UInt16) -> String {
        let opcode = Int(mem.bytes[mem.pc - byteOffset])
        let nextByte = String(format: "$%02X", mem.bytes[mem.pc + 1 - byteOffset])
        let nextWord = String(format: "$%04X", mem.words[mem.pc + 1 - byteOffset])
        let r8Names = ["B", "C", "D", "E", "H", "L", "(HL)", "A"]
        let r16Names = ["BC", "DE", "HL", "SP"]
        let ccNames = ["NZ", "Z", "NC", "C"]
        
        switch opcode {
        case 0x00: return "NOP"
        case 0x08: return "LD (\(nextWord)),SP"
        case 0x10: return "STOP 0"
        case 0x18: return "JR \(nextByte)"
        case 0x20, 0x28, 0x30, 0x38: return "JR \(ccNames[(opcode - 0x20) / 8]),\(nextByte)"
        case 0x01, 0x11, 0x21, 0x31: return "LD \(r16Names[(opcode - 0x01) / 16]),\(nextWord)"
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
        case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E: return "LD \(r8Names[(opcode - 0x06) / 8]),\(nextByte)"
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
        case 0xC6: return "ADD A,\(nextByte)"
        case 0xCE: return "ADC A,\(nextByte)"
        case 0xD6: return "SUB \(nextByte)"
        case 0xDE: return "SBC A,\(nextByte)"
        case 0xE6: return "AND \(nextByte)"
        case 0xEE: return "XOR \(nextByte)"
        case 0xF6: return "OR \(nextByte)"
        case 0xFE: return "CP \(nextByte)"
        case 0xC9: return "RET"
        case 0xC0, 0xC8, 0xD0, 0xD8: return "RET \(ccNames[(opcode - 0xC0) / 8])"
        case 0xD9: return "RETI"
        case 0xC1, 0xD1, 0xE1: return "POP \(r16Names[(opcode - 0xC1) / 16])"
        case 0xF1: return "POP AF"
        case 0xC5, 0xD5, 0xE5: return "PUSH \(r16Names[(opcode - 0xC5) / 16])"
        case 0xF5: return "PUSH AF"
        case 0xC3: return "JP \(nextWord)"
        case 0xC2, 0xCA, 0xD2, 0xDA: return "JP \(ccNames[(opcode - 0xC2) / 8]),\(nextWord)"
        case 0xE9: return "JP (HL)"
        case 0xCD: return "CALL \(nextWord)"
        case 0xC4, 0xCC, 0xD4, 0xDC: return "CALL \(ccNames[(opcode - 0xC4) / 8]),\(nextWord)"
        case 0xE8: return "ADD SP,\(nextByte)"
        case 0xF8: return "LD HL,SP+\(nextByte)"
        case 0xF9: return "LD SP,HL"
        case 0xE0: return "LDH (\(nextByte)),A"
        case 0xF0: return "LDH A,(\(nextByte))"
        case 0xE2: return "LD (C),A"
        case 0xF2: return "LD A,(C)"
        case 0xEA: return "LD (\(nextWord)),A"
        case 0xFA: return "LD A,(\(nextWord))"
        case 0xF3: return "DI"
        case 0xFB: return "EI"
        case 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF: return "RST $\(String(opcode - 0xC7, radix: 16))"
        case 0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB...0xED, 0xF4, 0xFC, 0xFD: return "Unused instruction"
            
        case 0xCB:
            let opcodeCB = Int(mem.bytes[mem.pc + 1])
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

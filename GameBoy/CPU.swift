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
    
    func update(pc: UInt16, timer: Int) {
        self.mem.pc += pc
        self.timer += timer
    }
    
    public func step() {
        runOpcode(mem.bytes[mem.pc])
    }
    
    public func runOpcode(_ opcode: UInt8) {
        switch opcode {
        case 0x00: // NOP
            update(pc: 1, timer: 1)
            
        case 0x08: // LD (nn),SP
            break

        case 0x10: // STOP 0
            break

        case 0x18: // JR n
            break
        case 0x20: // JR NZ,n
            break
        case 0x28: // JR Z,n
            break
        case 0x30: // JR NC,n
            break
        case 0x38: // JR C,n
            break
            
        case 0x01, 0x11, 0x21, 0x31: // LD rr,nn
            let offset = (opcode - 0x01) / 16
            mem.registers16[offset] = mem.words[mem.pc + 1]
            update(pc: 3, timer: 3)
            
        case 0x09, 0x19, 0x29, 0x39: // ADD HL,rr
            break
            
        case 0x02: // LD (BC),A
            mem.bytes[mem.bc] = mem.a
            update(pc: 1, timer: 2)
        case 0x12: // LD (DE),A
            mem.bytes[mem.de] = mem.a
            update(pc: 1, timer: 2)
        case 0x22: // LDI (HL),A
            mem.addrHLI = mem.a
            update(pc: 1, timer: 2)
        case 0x32: // LDD (HL),A
            mem.addrHLD = mem.a
            update(pc: 1, timer: 2)
            
        case 0x0A: // LD A,(BC)
            mem.a = mem.bytes[mem.bc]
            update(pc: 1, timer: 2)
        case 0x1A: // LD A,(DE)
            mem.a = mem.bytes[mem.de]
            update(pc: 1, timer: 2)
        case 0x2A: // LDI A,(HL)
            mem.a = mem.addrHLI
            update(pc: 1, timer: 2)
        case 0x3A: // LDD A,(HL)
            mem.a = mem.addrHLD
            update(pc: 1, timer: 2)
            
        case 0x03, 0x13, 0x23, 0x33: // INC rr
            let offset = (opcode - 0x03) / 16
            ops.inc(register: &mem.registers16[offset])
            update(pc: 1, timer: 2)
            
        case 0x0B, 0x1B, 0x2B, 0x3B: // DEC rr
            let offset = (opcode - 0x0B) / 16
            ops.dec(register: &mem.registers16[offset])
            update(pc: 1, timer: 2)

        case 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C: // INC r
            let offset = (opcode - 0x04) / 8
            ops.inc(register: &mem.registers8[offset])
            update(pc: 1, timer: (offset != 6) ? 1 : 3)

        case 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D: // DEC r
            let offset = (opcode - 0x04) / 8
            ops.inc(register: &mem.registers8[offset])
            update(pc: 1, timer: (offset != 6) ? 1 : 3)

        case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E: // LD r,n
            let offset = (opcode - 0x06) / 8
            mem.registers8[offset] = mem.bytes[mem.pc + 1]
            update(pc: 2, timer: (offset != 6) ? 2 : 3)
        
        case 0x07: // RLCA
            ops.rlc(register: &mem.a)
            mem.flags.z = false
            update(pc: 1, timer: 1)
        case 0x0F: // RRCA
            ops.rrc(register: &mem.a)
            mem.flags.z = false
            update(pc: 1, timer: 1)
        case 0x17: // RLA
            break
        case 0x1F: // RRA
            break

        case 0x27: // DAA
            break
        case 0x2F: // CPL
            break
        case 0x37: // SCF
            break
        case 0x3F: // CCF
            break
            
        case 0x40...0x75, 0x77...0x7F: // LD r,r
            let srcOffset = opcode % 8
            let dstOffset = (opcode - 0x40) / 8
            mem.registers8[dstOffset] = mem.registers8[srcOffset]
            update(pc: 1, timer: (srcOffset != 6 && dstOffset != 6) ? 1 : 2)
            
        case 0x76: // HALT
            break
            
        case 0x80...0x87: // ADD A,r
            break
            
        case 0x88...0x8F: // ADC A,r
            break
            
        case 0x90...0x97: // SUB r
            break
            
        case 0x98...0x9F: // SBC A,r
            break
            
        case 0xA0...0xA7: // AND r
            break
            
        case 0xA8...0xAF: // XOR r
            break
            
        case 0xB0...0xB7: // OR r
            break
            
        case 0xB8...0xBF: // CP r
            break
            
        case 0xC6: // ADD A,n
            break
        case 0xCE: // ADC A,n
            break
        case 0xD6: // SUB n
            break
        case 0xDE: // SBC A,n
            break
        case 0xE6: // AND n
            break
        case 0xEE: // XOR n
            break
        case 0xF6: // OR n
            break
        case 0xFE: // CP n
            break
            
        case 0xC9: // RET
            break
        case 0xD9: // RETI
            break
        case 0xC0: // RET NZ
            break
        case 0xC8: // RET Z
            break
        case 0xD0: // RET NC
            break
        case 0xD8: // RET C
            break
            
        case 0xC1, 0xD1, 0xE1: // POP rr
            break
        case 0xF1: // POP AF
            break
            
        case 0xC5, 0xD5, 0xE5: // PUSH rr
            break
        case 0xF5: // PUSH AF
            break
            
        case 0xC3: // JP nn
            break
        case 0xC2: // JP NZ,nn
            break
        case 0xCA: // JP Z,nn
            break
        case 0xD2: // JP NC,nn
            break
        case 0xDA: // JP C,nn
            break
        case 0xE9: // JP (HL)
            break
            
        case 0xCD: // CALL nn
            break
        case 0xC4: // CALL NZ,nn
            break
        case 0xCC: // CALL Z,nn
            break
        case 0xD4: // CALL NC,nn
            break
        case 0xDC: // CALL C,nn
            break
            
        case 0xE8: // ADD SP,n
            break
            
        case 0xF8: // LD HL,SP+n
            break
        case 0xF9: // LD SP,HL
            break
            
        case 0xE0: // LDH (n),A
            mem.bytes[0xFF00 + UInt16(mem.bytes[mem.pc + 1])] = mem.a
            update(pc: 2, timer: 3)
        case 0xF0: // LDH A,(n)
            mem.a = mem.bytes[0xFF00 + UInt16(mem.bytes[mem.pc + 1])]
            update(pc: 2, timer: 3)
            
        case 0xE2: // LD (C),A
            mem.bytes[0xFF00 + UInt16(mem.c)] = mem.a
            update(pc: 2, timer: 2)
        case 0xF2: // LD A,(C)
            mem.a = mem.bytes[0xFF00 + UInt16(mem.c)]
            update(pc: 2, timer: 2)
            
        case 0xEA: // LD (nn),A
            mem.bytes[mem.words[mem.pc + 1]] = mem.a
            update(pc: 3, timer: 4)
        case 0xFA: // LD A,(nn)
            mem.a = mem.bytes[mem.words[mem.pc + 1]]
            update(pc: 3, timer: 4)
            
        case 0xF3: // DI
            break
        case 0xFB: // EI
            break
            
        case 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF: // RST
            break
            
        case 0xCB:
            runOpcodeCB(mem.bytes[mem.pc + 1])

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
            update(pc: 2, timer: (offset == 6) ? 4 : 2)

        case 0x08...0x0F: // RRC r
            let offset = opcode % 8
            ops.rrc(register: &mem.registers8[offset])
            update(pc: 2, timer: (offset == 6) ? 4 : 2)
            
        case 0x10...0x17: // RL r
            break
            
        case 0x18...0x1F: // RR r
            break
            
        case 0x20...0x27: // SLA r
            break
            
        case 0x28...0x2F: // SRA r
            break
            
        case 0x30...0x3F: // SWAP r
            break
            
        case 0x38...0x3F: // SRL r
            break
            
        case 0x40...0x7F: // BIT d,r
            let bitOffset = (opcode - 0x40) / 8
            let registerOffset = opcode % 8
            ops.bit(bitOffset, register: mem.registers8[registerOffset])
            update(pc: 2, timer: (registerOffset == 6) ? 4 : 2)
            
        case 0x80...0xBF: // RES d,r
            let bitOffset = (opcode - 0x80) / 8
            let registerOffset = opcode % 8
            ops.reset(bitOffset, register: &mem.registers8[registerOffset])
            update(pc: 2, timer: (registerOffset == 6) ? 4 : 2)
            
        case 0xC0...0xFF: // SET d,r
            let bitOffset = (opcode - 0xC0) / 8
            let registerOffset = opcode % 8
            ops.set(bitOffset, register: &mem.registers8[registerOffset])
            update(pc: 2, timer: (registerOffset == 6) ? 4 : 2)

        default:
            fatalError("Unimplemented instruction")
        }
    }

}

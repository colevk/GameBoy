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

    unowned let gb: GameBoyRunner

    public var ime: Bool = true
    private var eiTimer = 0
    public var halt: Bool = false
    var haltBug: Bool = false

    public var PC: UInt16 = 0

    public func pcByte() -> UInt8 {
        PC += 1
        return gb.memory.bytes[PC - 1]
    }
    
    public func pcWord() -> UInt16 {
        PC &+= 2
        return gb.memory.words[PC &- 2]
    }

    public var reg8: Registers8Bit! = nil
    public var reg16: Registers16Bit! = nil

    public var SP: UInt16 = 0

    public var A: UInt8 = 0
    public var B: UInt8 = 0
    public var C: UInt8 = 0
    public var D: UInt8 = 0
    public var E: UInt8 = 0
    public var H: UInt8 = 0
    public var L: UInt8 = 0

    public var AF: UInt16 {
        get {
            return UInt16(A) << 8 + UInt16(F)
        }
        set {
            A = UInt8(newValue >> 8)
            F = UInt8(newValue & 0xFF)
        }
    }

    public var BC: UInt16 {
        get {
            return UInt16(B) << 8 + UInt16(C)
        }
        set {
            B = UInt8(newValue >> 8)
            C = UInt8(newValue & 0xFF)
        }
    }

    public var DE: UInt16 {
        get {
            return UInt16(D) << 8 + UInt16(E)
        }
        set {
            D = UInt8(newValue >> 8)
            E = UInt8(newValue & 0xFF)
        }
    }

    public var HL: UInt16 {
        get {
            return UInt16(H) << 8 + UInt16(L)
        }
        set {
            H = UInt8(newValue >> 8)
            L = UInt8(newValue & 0xFF)
        }
    }

    public var addrHL: UInt8 {
        get {
            return gb.memory.bytes[HL]
        }
        set {
            gb.memory.bytes[HL] = newValue
        }
    }

    private var flagZ: Bool = false
    private var flagN: Bool = false
    private var flagH: Bool = false
    private var flagC: Bool = false

    public var F: UInt8 {
        get {
            return
                (flagZ ? 0x80 : 0) +
                (flagN ? 0x40 : 0) +
                (flagH ? 0x20 : 0) +
                (flagC ? 0x10 : 0)
        }
        set {
            flagZ = newValue & 0x80 != 0
            flagN = newValue & 0x40 != 0
            flagH = newValue & 0x20 != 0
            flagC = newValue & 0x10 != 0
        }
    }


    public init(withParent parent: GameBoyRunner) {
        gb = parent
        reg8 = Registers8Bit(onCPU: self)
        reg16 = Registers16Bit(onCPU: self)
    }

    public func step() -> Int {
        if halt {
            return 1
        }
        let cycles = runOpcode(pcByte())
        if eiTimer == 1 {
            ime = true
        }
        if eiTimer > 0 {
            eiTimer -= 1
        }
        return cycles
    }

    public func runOpcode(_ opcode: UInt8) -> Int {
        if haltBug {
            PC &-= 1
            haltBug = false
        }

        switch opcode {
        case 0x00: // NOP
            return 1

        case 0x08: // LD (nn),SP
            gb.memory.words[pcWord()] = SP
            return 5

        case 0x10: // STOP 0
            print("Unimplemented instruction: \(instructionAt(address: PC &- 1))\n")
            NSApplication.shared.terminate(self)

        case 0x18: // JR n
            return jr(cond: true, offset: pcByte())
        case 0x20: // JR NZ,n
            return jr(cond: !flagZ, offset: pcByte())
        case 0x28: // JR Z,n
            return jr(cond: flagZ, offset: pcByte())
        case 0x30: // JR NC,n
            return jr(cond: !flagC, offset: pcByte())
        case 0x38: // JR C,n
            return jr(cond: flagC, offset: pcByte())

        case 0x01, 0x11, 0x21, 0x31: // LD rr,nn
            let offset = (opcode - 0x01) / 16
            reg16[offset] = pcWord()
            return 3

        case 0x09, 0x19, 0x29, 0x39: // ADD HL,rr
            let offset = (opcode - 0x09) / 16
            add(&HL, reg16[offset])
            return 2

        case 0x02: // LD (BC),A
            gb.memory.bytes[BC] = A
            return 2
        case 0x12: // LD (DE),A
            gb.memory.bytes[DE] = A
            return 2
        case 0x22: // LDI (HL),A
            addrHL = A
            HL &+= 1
            return 2
        case 0x32: // LDD (HL),A
            addrHL = A
            HL &-= 1
            return 2

        case 0x0A: // LD A,(BC)
            A = gb.memory.bytes[BC]
            return 2
        case 0x1A: // LD A,(DE)
            A = gb.memory.bytes[DE]
            return 2
        case 0x2A: // LDI A,(HL)
            A = addrHL
            HL &+= 1
            return 2
        case 0x3A: // LDD A,(HL)
            A = addrHL
            HL &-= 1
            return 2

        case 0x03, 0x13, 0x23, 0x33: // INC rr
            let offset = (opcode - 0x03) / 16
            inc(&reg16[offset])
            return 2

        case 0x0B, 0x1B, 0x2B, 0x3B: // DEC rr
            let offset = (opcode - 0x0B) / 16
            dec(&reg16[offset])
            return 2

        case 0x04, 0x0C, 0x14, 0x1C, 0x24, 0x2C, 0x34, 0x3C: // INC r
            let offset = (opcode - 0x04) / 8
            inc(&reg8[offset])
            return (offset != 6) ? 1 : 3

        case 0x05, 0x0D, 0x15, 0x1D, 0x25, 0x2D, 0x35, 0x3D: // DEC r
            let offset = (opcode - 0x04) / 8
            dec(&reg8[offset])
            return (offset != 6) ? 1 : 3

        case 0x06, 0x0E, 0x16, 0x1E, 0x26, 0x2E, 0x36, 0x3E: // LD r,n
            let offset = (opcode - 0x06) / 8
            reg8[offset] = pcByte()
            return (offset != 6) ? 2 : 3

        case 0x07: // RLCA
            rlc(&A)
            flagZ = false
            return 1
        case 0x0F: // RRCA
            rrc(&A)
            flagZ = false
            return 1
        case 0x17: // RLA
            rl(&A)
            flagZ = false
            return 1
        case 0x1F: // RRA
            rr(&A)
            flagZ = false
            return 1

        case 0x27: // DAA
            if flagN {
                if flagC {
                    A &-= 0x60
                }
                if flagH {
                    A &-= 0x06
                }
            } else {
                if flagC || A > 0x99 {
                    A &+= 0x60
                    flagC = true
                }
                if flagH || (A & 0x0F) > 0x09 {
                    A &+= 0x06
                }
            }
            flagZ = A == 0
            flagH = false
            return 1
        case 0x2F: // CPL
            A = ~A
            flagN = true
            flagH = true
            return 1
        case 0x37: // SCF
            flagN = false
            flagH = false
            flagC = true
            return 1
        case 0x3F: // CCF
            flagN = false
            flagH = false
            flagC = !flagC
            return 1

        case 0x40...0x75, 0x77...0x7F: // LD r,r
            let srcOffset = opcode % 8
            let dstOffset = (opcode - 0x40) / 8
            reg8[dstOffset] = reg8[srcOffset]
            return (srcOffset != 6 && dstOffset != 6) ? 1 : 2

        case 0x76: // HALT
            if ime || (gb.memory.IE & gb.memory.IF & 0x1F) == 0 {
                halt = true
            } else {
                haltBug = true
            }
            return 1

        case 0x80...0x87: // ADD A,r
            let offset = opcode % 8
            add(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0x88...0x8F: // ADC A,r
            let offset = opcode % 8
            adc(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0x90...0x97: // SUB r
            let offset = opcode % 8
            sub(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0x98...0x9F: // SBC A,r
            let offset = opcode % 8
            sbc(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0xA0...0xA7: // AND r
            let offset = opcode % 8
            and(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0xA8...0xAF: // XOR r
            let offset = opcode % 8
            xor(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0xB0...0xB7: // OR r
            let offset = opcode % 8
            or(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0xB8...0xBF: // CP r
            let offset = opcode % 8
            cp(reg8[offset])
            return offset != 6 ? 1 : 2

        case 0xC6: // ADD A,n
            add(pcByte())
            return 2
        case 0xCE: // ADC A,n
            adc(pcByte())
            return 2
        case 0xD6: // SUB n
            sub(pcByte())
            return 2
        case 0xDE: // SBC A,n
            sbc(pcByte())
            return 2
        case 0xE6: // AND n
            and(pcByte())
            return 2
        case 0xEE: // XOR n
            xor(pcByte())
            return 2
        case 0xF6: // OR n
            or(pcByte())
            return 2
        case 0xFE: // CP n
            cp(pcByte())
            return 2

        case 0xC9: // RET
            PC = pop()
            return 4
        case 0xC0: // RET NZ
            return ret(cond: !flagZ)
        case 0xC8: // RET Z
            return ret(cond: flagZ)
        case 0xD0: // RET NC
            return ret(cond: !flagC)
        case 0xD8: // RET C
            return ret(cond: flagC)
        case 0xD9: // RETI
            PC = pop()
            ime = true
            return 4

        case 0xC1, 0xD1, 0xE1: // POP rr
            let offset = (opcode - 0xC1) / 16
            reg16[offset] = pop()
            return 3
        case 0xF1: // POP AF
            AF = pop()
            return 3

        case 0xC5, 0xD5, 0xE5: // PUSH rr
            let offset = (opcode - 0xC5) / 16
            push(reg16[offset])
            return 4
        case 0xF5: // PUSH AF
            push(AF)
            return 4

        case 0xC3: // JP nn
            return jp(cond: true, addr: pcWord())
        case 0xC2: // JP NZ,nn
            return jp(cond: !flagZ, addr: pcWord())
        case 0xCA: // JP Z,nn
            return jp(cond: flagZ, addr: pcWord())
        case 0xD2: // JP NC,nn
            return jp(cond: !flagC, addr: pcWord())
        case 0xDA: // JP C,nn
            return jp(cond: flagC, addr: pcWord())
        case 0xE9: // JP (HL)
            PC = HL
            return 1

        case 0xCD: // CALL nn
            return call(cond: true, addr: pcWord())
        case 0xC4: // CALL NZ,nn
            return call(cond: !flagZ, addr: pcWord())
        case 0xCC: // CALL Z,nn
            return call(cond: flagZ, addr: pcWord())
        case 0xD4:
            return call(cond: !flagC, addr: pcWord())
        case 0xDC:
            return call(cond: flagC, addr: pcWord())

        case 0xE8: // ADD SP,n
            (SP, flagH, flagC) = UInt16.addRelativeWithFlags(SP, pcByte())
            flagZ = false
            flagN = false
            return 4

        case 0xF8: // LD HL,SP+n
            (HL, flagH, flagC) = UInt16.addRelativeWithFlags(SP, pcByte())
            flagZ = false
            flagN = false
            return 3
        case 0xF9: // LD SP,HL
            SP = HL
            return 2

        case 0xE0: // LDH (n),A
            gb.memory.bytes[0xFF00 + UInt16(pcByte())] = A
            return 3
        case 0xF0: // LDH A,(n)
            A = gb.memory.bytes[0xFF00 + UInt16(pcByte())]
            return 3

        case 0xE2: // LD (C),A
            gb.memory.bytes[0xFF00 + UInt16(C)] = A
            return 2
        case 0xF2: // LD A,(C)
            A = gb.memory.bytes[0xFF00 + UInt16(C)]
            return 2

        case 0xEA: // LD (nn),A
            gb.memory.bytes[pcWord()] = A
            return 4
        case 0xFA: // LD A,(nn)
            A = gb.memory.bytes[pcWord()]
            return 4

        case 0xF3: // DI
            ime = false
            return 1
        case 0xFB: // EI
            eiTimer = 2
            return 1

        case 0xC7, 0xCF, 0xD7, 0xDF, 0xE7, 0xEF, 0xF7, 0xFF: // RST
            push(PC)
            PC = UInt16(opcode - 0xC7)
            return 4

        case 0xCB:
            return runOpcodeCB(pcByte())

        case 0xD3, 0xDB, 0xDD, 0xE3, 0xE4, 0xEB...0xED, 0xF4, 0xFC, 0xFD:
            print("Opcode \(String(format: "$%04X", opcode)) is unused")
            return 1
        
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
            rlc(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x08...0x0F: // RRC r
            let offset = opcode % 8
            rrc(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x10...0x17: // RL r
            let offset = opcode % 8
            rl(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x18...0x1F: // RR r
            let offset = opcode % 8
            rr(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x20...0x27: // SLA r
            let offset = opcode % 8
            sla(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x28...0x2F: // SRA r
            let offset = opcode % 8
            sra(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x30...0x37: // SWAP r
            let offset = opcode % 8
            reg8[offset] = reg8[offset] << 4 + reg8[offset] >> 4
            flagZ = reg8[offset] == 0
            flagN = false
            flagH = false
            flagC = false
            return (offset != 6) ? 2 : 4

        case 0x38...0x3F: // SRL r
            let offset = opcode % 8
            srl(&reg8[offset])
            return (offset != 6) ? 2 : 4

        case 0x40...0x7F: // BIT d,r
            let bitOffset = (opcode - 0x40) / 8
            let registerOffset = opcode % 8
            bit(bitOffset, register: reg8[registerOffset])
            return (registerOffset != 6) ? 2 : 3

        case 0x80...0xBF: // RES d,r
            let bitOffset = (opcode - 0x80) / 8
            let registerOffset = opcode % 8
            reset(bitOffset, register: &reg8[registerOffset])
            return (registerOffset != 6) ? 2 : 4

        case 0xC0...0xFF: // SET d,r
            let bitOffset = (opcode - 0xC0) / 8
            let registerOffset = opcode % 8
            set(bitOffset, register: &reg8[registerOffset])
            return (registerOffset != 6) ? 2 : 4

        default: return 0
        }
    }

    public func inc(_ register: inout UInt8) {
        flagH = register & 0xF == 0xF
        register &+= 1
        flagZ = register == 0
        flagN = false
    }

    public func inc(_ register: inout UInt16) {
        register &+= 1
    }

    public func dec(_ register: inout UInt8) {
        flagH = register & 0xF == 0x0
        register &-= 1
        flagZ = register == 0
        flagN = true
    }

    public func dec(_ register: inout UInt16) {
        register &-= 1
    }

    public func rlc(_ register: inout UInt8) {
        register = register << 1 + register >> 7
        flagZ = register == 0
        flagN = false
        flagH = false
        flagC = register & 0x01 != 0
    }

    public func rl(_ register: inout UInt8) {
        (flagC, register) = (register & 0x80 == 0x80, register << 1 + (flagC ? 1 : 0))
        flagZ = register == 0
        flagN = false
        flagH = false
    }

    public func rrc(_ register: inout UInt8) {
        flagC = (register & 0x01) != 0
        register = register >> 1 + register << 7
        flagZ = register == 0
        flagN = false
        flagH = false
    }

    public func rr(_ register: inout UInt8) {
        (flagC, register) = (register & 0x01 == 0x01, register >> 1 + (flagC ? 0x80 : 0))
        flagZ = register == 0
        flagN = false
        flagH = false
    }

    public func sla(_ register: inout UInt8) {
        flagC = register.checkBit(7)
        register = register << 1
        flagZ = register == 0
        flagN = false
        flagH = false
    }

    public func sra(_ register: inout UInt8) {
        flagC = register.checkBit(0)
        register = (register >> 1) + (register.checkBit(7) ? 0x80 : 0)
        flagZ = register == 0
        flagN = false
        flagH = false
    }

    public func srl(_ register: inout UInt8) {
        flagC = register.checkBit(0)
        register = (register >> 1)
        flagZ = register == 0
        flagN = false
        flagH = false
    }

    public func add(_ value: UInt8) {
        (A, flagH, flagC) = UInt8.addWithFlags(A, value)
        flagN = false
        flagZ = A == 0
    }

    public func adc(_ value: UInt8) {
        if (flagC) {
            let (temp, h1, c1) = UInt8.addWithFlags(A, value)
            let (res, h2, c2) = UInt8.addWithFlags(temp, 1)
            A = res
            flagZ = A == 0
            flagN = false
            flagH = h1 || h2
            flagC = c1 || c2
        } else {
            add(value)
        }
    }

    public func sub(_ value: UInt8) {
        (A, flagH, flagC) = UInt8.subtractWithFlags(A, value)
        flagN = true
        flagZ = A == 0
    }

    public func sbc(_ value: UInt8) {
        if (flagC) {
            let (temp, h1, c1) = UInt8.subtractWithFlags(A, value)
            let (res, h2, c2) = UInt8.subtractWithFlags(temp, 1)
            A = res
            flagZ = A == 0
            flagN = true
            flagH = h1 || h2
            flagC = c1 || c2
        } else {
            sub(value)
        }
    }

    public func and(_ value: UInt8) {
        A &= value
        flagZ = A == 0
        flagN = false
        flagH = true
        flagC = false
    }

    public func or(_ value: UInt8) {
        A |= value
        flagZ = A == 0
        flagN = false
        flagH = false
        flagC = false
    }

    public func xor(_ value: UInt8) {
        A ^= value
        flagZ = A == 0
        flagN = false
        flagH = false
        flagC = false
    }

    public func cp(_ value: UInt8) {
        let result: UInt8
        (result, flagH, flagC) = UInt8.subtractWithFlags(A, value)
        flagN = true
        flagZ = result == 0
    }

    public func add(_ to: inout UInt16, _ from: UInt16) {
        (to, flagH, flagC) = UInt16.addWithFlags(to, from)
        flagN = false
    }

    public func bit(_ offset: UInt8, register: UInt8) {
        flagZ = register & (0x01 << offset) == 0
        flagN = false
        flagH = true
    }

    public func set(_ offset: UInt8, register: inout UInt8) {
        register |= (0x01 << offset)
    }

    public func reset(_ offset: UInt8, register: inout UInt8) {
        register &= ~(0x01 << offset)
    }

    public func push(_ value: UInt16) {
        SP &-= 2
        gb.memory.words[SP] = value
    }

    public func pop() -> UInt16 {
        SP &+= 2
        return gb.memory.words[SP &- 2]
    }

    public func jp(cond: Bool, addr: UInt16) -> Int {
        if cond {
            PC = addr
            return 4
        } else {
            return 3
        }
    }

    public func jr(cond: Bool, offset: UInt8) -> Int {
        if cond {
            PC = UInt16(Int(PC) + Int(Int8(bitPattern: offset)))
            return 3
        } else {
            return 2
        }
    }

    public func ret(cond: Bool) -> Int {
        if cond {
            PC = pop()
            return 5
        } else {
            return 2
        }
    }

    public func call(cond: Bool, addr: UInt16) -> Int {
        if cond {
            push(PC)
            PC = addr
            return 6
        } else {
            return 3
        }
    }
}

public class CPUHelper {
    unowned let cpu: CPU

    public init(onCPU cpu: CPU) {
        self.cpu = cpu
    }
}

public class Registers8Bit: CPUHelper {
    public subscript(index: UInt8) -> UInt8 {
        get {
            switch index {
            case 0: return cpu.B
            case 1: return cpu.C
            case 2: return cpu.D
            case 3: return cpu.E
            case 4: return cpu.H
            case 5: return cpu.L
            case 6: return cpu.addrHL
            case 7: return cpu.A
            default: fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0: cpu.B = newValue
            case 1: cpu.C = newValue
            case 2: cpu.D = newValue
            case 3: cpu.E = newValue
            case 4: cpu.H = newValue
            case 5: cpu.L = newValue
            case 6: cpu.addrHL = newValue
            case 7: cpu.A = newValue
            default: fatalError("Index out of range")
            }
        }
    }
}

public class Registers16Bit: CPUHelper {
    public subscript(index: UInt8) -> UInt16 {
        get {
            switch index {
            case 0: return cpu.BC
            case 1: return cpu.DE
            case 2: return cpu.HL
            case 3: return cpu.SP
            default: fatalError("Index out of range")
            }
        }
        set {
            switch index {
            case 0: cpu.BC = newValue
            case 1: cpu.DE = newValue
            case 2: cpu.HL = newValue
            case 3: cpu.SP = newValue
            default: fatalError("Index out of range")
            }
        }
    }
}

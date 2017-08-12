//
//  GameBoyRunner.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/6/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class GameBoyRunner {
    public private(set) var cpu: CPU!
    public private(set) var gpu: GPU!
    public private(set) var memory: Memory!
    public private(set) var interrupts: InterruptHandler!
    public var serialDevice: SerialDevice

    public var timer: Int

    public var skipBIOS: Bool

    public init() {
        timer = 0
        skipBIOS = false

        serialDevice = EmptySerialDevice()
        
        memory = Memory(withParent: self)
        cpu = CPU(withParent: self)
        gpu = GPU(withParent: self)
        interrupts = InterruptHandler(withParent: self)
    }

    public func step() {
        let cycles = cpu.step()
        timer += cycles
        for _ in 0..<cycles {
            gpu.step()
        }
        if cpu.ime {
            interrupts.handleInterrupts()
        }
    }

    public func advanceFrame() {
        if gpu.mode == .vBlank {
            while gpu.mode == .vBlank {
                step()
            }
        }
        while gpu.mode != .vBlank {
            step()
        }
    }

    public func reset() {
        timer = 0
        cpu.ime = true

        if skipBIOS {
            memory.booting = false
            cpu.PC = 0x100
            cpu.A = 0x01
            cpu.F = 0xB0
            cpu.BC = 0x0013
            cpu.DE = 0x00D8
            cpu.HL = 0x014D
            cpu.SP = 0xFFFE
            memory.bytes[0xFF05] = 0x00
            memory.bytes[0xFF06] = 0x00
            memory.bytes[0xFF07] = 0x00
            memory.bytes[0xFF10] = 0x80
            memory.bytes[0xFF11] = 0xBF
            memory.bytes[0xFF12] = 0xF3
            memory.bytes[0xFF14] = 0xBF
            memory.bytes[0xFF16] = 0x7F
            memory.bytes[0xFF17] = 0x00
            memory.bytes[0xFF19] = 0xBF
            memory.bytes[0xFF1A] = 0x7F
            memory.bytes[0xFF1B] = 0xFF
            memory.bytes[0xFF1C] = 0x9F
            memory.bytes[0xFF1E] = 0xBF
            memory.bytes[0xFF20] = 0xFF
            memory.bytes[0xFF21] = 0x00
            memory.bytes[0xFF22] = 0x00
            memory.bytes[0xFF23] = 0xBF
            memory.bytes[0xFF24] = 0x77
            memory.bytes[0xFF25] = 0xF3
            memory.bytes[0xFF26] = 0xF1
            memory.bytes[0xFF40] = 0x91
            memory.bytes[0xFF42] = 0x00
            memory.bytes[0xFF43] = 0x00
            memory.bytes[0xFF45] = 0x00
            memory.bytes[0xFF47] = 0xFC
            memory.bytes[0xFF48] = 0xFF
            memory.bytes[0xFF49] = 0xFF
            memory.bytes[0xFF4A] = 0x00
            memory.bytes[0xFF4B] = 0x00
            memory.bytes[0xFFFF] = 0x00
        } else {
            memory.booting = true
            memory.LCDC = 0x00
            cpu.PC = 0x00
        }
    }

    public func loadCartridge(withData data: Data) {
        memory.cartridge = [UInt8].init(repeating: 0, count: data.count)
        data.copyBytes(to: &memory.cartridge!, count: data.count)
        reset()
    }
}

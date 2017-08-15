//
//  GameBoyRunner.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/6/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import Cocoa

/** Holds all the component parts of the Game Boy and lets them access each other.
 */
public class GameBoyRunner {
    public private(set) var cpu: CPU!
    public private(set) var gpu: GPU!
    public private(set) var memory: Memory!
    public private(set) var timer: Timer!
    public private(set) var interrupts: InterruptHandler!
    public private(set) var joypad: Joypad
    public var serialDevice: SerialDevice

    public var skipBIOS: Bool

    public init() {
        skipBIOS = true

        joypad = Joypad()
        serialDevice = EmptySerialDevice()
        
        memory = Memory(withParent: self)
        cpu = CPU(withParent: self)
        gpu = GPU(withParent: self)
        timer = Timer(withParent: self)
        interrupts = InterruptHandler(withParent: self)
    }

    /** Run one CPU instruction and then check for interrupts and let the GPU and timer catch up.
     */
    public func step() {
        var cycles = cpu.step()
        var interrupted = false
        if cpu.ime || cpu.halt {
            interrupted = interrupts.handleInterrupts()
        }
        if interrupted {
            cycles += 3
        }
        for _ in 0 ..< cycles {
            gpu.step()
            timer.tick()
        }
    }

    /** Run the CPU until the next vblank.
     */
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

    /** Reset everything to a default state.
     */
    public func reset() {
        cpu.ime = true
        cpu.halt = false
        memory.IF = 0
        memory.IE = 0
        cpu.F = 0

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

    /** Load a cartridge and print some debug data.
     */
    public func loadCartridge(withData data: Data) {
        memory.cartridge = [UInt8](repeating: 0, count: data.count)

        let nameBytes = data[0x134...0x142].prefix { $0 != 0 }
        print("Internal name: \(String(data: nameBytes, encoding: .utf8)!)")
        print("Cartridge type: \(cartridgeType(data[0x147]))")
        print("ROM size: \(romSize(data[0x148]))")
        print("RAM size: \(ramSize(data[0x149]))")

        if supportedCartridgeTypes.contains(data[0x147]) {
            data.copyBytes(to: &memory.cartridge!, count: data.count)
            memory.externalRAM = [UInt8](repeating: 0, count: 8192)
            reset()
        } else {
            let alert = NSAlert()
            alert.messageText = "Could not load cartridge."
            alert.informativeText = "The cartridge type \(cartridgeType(data[0x147])) is not currently supported."
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    private let supportedCartridgeTypes: [UInt8] = [0x00, 0x08, 0x09]

    private func cartridgeType(_ byte: UInt8) -> String {
        switch byte {
        case 0x00: return "ROM ONLY"
        case 0x01: return "MBC1"
        case 0x02: return "MBC1+RAM"
        case 0x03: return "MBC1+RAM+BATTERY"
        case 0x05: return "MBC2"
        case 0x06: return "MBC2+BATTERY"
        case 0x08: return "ROM+RAM"
        case 0x09: return "ROM+RAM+BATTERY"
        case 0x0B: return "MMM01"
        case 0x0C: return "MMM01+RAM"
        case 0x0D: return "MMM01+RAM+BATTERY"
        case 0x0F: return "MBC3+TIMER+BATTERY"
        case 0x10: return "MBC3+TIMER+RAM+BATTERY"
        case 0x11: return "MBC3"
        case 0x12: return "MBC3+RAM"
        case 0x13: return "MBC3+RAM+BATTERY"
        case 0x19: return "MBC5"
        case 0x1A: return "MBC5+RAM"
        case 0x1B: return "MBC5+RAM+BATTERY"
        case 0x1C: return "MBC5+RUMBLE"
        case 0x1D: return "MBC5+RUMBLE+RAM"
        case 0x1E: return "MBC5+RUMBLE+RAM+BATTERY"
        case 0x20: return "MBC6"
        case 0x22: return "MBC7+SENSOR+RUMBLE+RAM+BATTERY"
        case 0xFC: return "POCKET CAMERA"
        case 0xFD: return "BANDAI TAMA5"
        case 0xFE: return "HuC3"
        case 0xFF: return "HuC1+RAM+BATTERY"
        default: return "UNKNOWN"
        }
    }

    private func romSize(_ byte: UInt8) -> Int {
        let numBanks: Int
        switch byte {
        case 0x00...0x08:
            numBanks = 2 << byte
        case 0x52:
            numBanks = 72
        case 0x53:
            numBanks = 80
        case 0x54:
            numBanks = 96
        default:
            numBanks = 0
        }
        return numBanks * 0x4000
    }

    private func ramSize(_ byte: UInt8) -> Int {
        switch byte {
        case 0x01:
            return 0x800
        case 0x02:
            return 0x2000
        case 0x03:
            return 0x8000
        case 0x04:
            return 0x20000
        case 0x05:
            return 0x10000
        default:
            return 0
        }
    }
}

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
    private let saveGameDirectory: URL

    public private(set) var cpu: CPU!
    public private(set) var gpu: GPU!
    public private(set) var memory: Memory!
    public private(set) var mbc: MemoryBankController
    public private(set) var timer: Timer!
    public private(set) var interrupts: InterruptHandler!
    public private(set) var joypad: Joypad
    public var serialDevice: SerialDevice

    private var filePath: String?

    public var skipBIOS: Bool

    public var stop: Bool = false

    public init() {
        let applicationSupport = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        saveGameDirectory = applicationSupport.appendingPathComponent("GameBoy", isDirectory: true)
        try! FileManager.default.createDirectory(at: saveGameDirectory, withIntermediateDirectories: true, attributes: [:])

        skipBIOS = true

        joypad = Joypad()
        serialDevice = EmptySerialDevice()

        mbc = NoCartridgeMBC()
        memory = Memory(withParent: self)
        cpu = CPU(withParent: self)
        gpu = GPU(withParent: self)
        timer = Timer(withParent: self)
        interrupts = InterruptHandler(withParent: self)
    }

    /** Run one CPU instruction and then check for interrupts and let the GPU and timer catch up.
     */
    public func step() {
        if !stop {
            var cycles = cpu.step()
            if cpu.ime || cpu.halt {
                if interrupts.handleInterrupts() {
                    cycles += 3
                }
            }
            timer.advanceBy(cycles: cycles)
            gpu.advanceBy(cycles: cycles)
        }
    }

    /** Run the CPU until the next vblank.
     */
    public func advanceFrame() {
        if gpu.mode == .vBlank {
            while gpu.mode == .vBlank && !stop {
                step()
            }
        }
        while gpu.mode != .vBlank && !stop {
            step()
        }
        mbc.save()
    }

    /** Reset everything to a default state.
     */
    public func reset() {
        cpu.ime = true
        cpu.halt = false
        stop = false
        interrupts.IF = 0
        interrupts.IE = 0
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

    /** Load a cartridge and print some debug data. Searches for save game data in the Application Support folder with the same name as the cartridge internal name.
     */
    public func loadCartridge(withData data: Data) {
        let name = String(data: data[0x134...0x142].prefix { $0 != 0 }, encoding: .utf8)!
        print("Internal name: \(name)")
        print("Cartridge type: \(cartridgeTypeNames[data[0x147]] ?? "UNKNOWN")")
        print("ROM size: \(romSize(data[0x148]))")
        print("RAM size: \(ramSize(data[0x149]))")

        var cartridge = [UInt8](repeating: 0, count: data.count)
        data.copyBytes(to: &cartridge, count: data.count)

        if let mbc = getMBC(cartridge: cartridge) {
            self.mbc = mbc
            reset()
        } else {
            let alert = NSAlert()
            alert.messageText = "Could not load cartridge."
            alert.informativeText = "The cartridge type \(cartridgeTypeNames[data[0x147]] ?? "UNKNOWN") is not currently supported."
            alert.alertStyle = .critical
            alert.runModal()
        }
    }

    private func getMBC(cartridge: [UInt8]) -> MemoryBankController? {
        let name = String(data: Data(bytes: cartridge[0x134...0x142].prefix { $0 != 0 }), encoding: .utf8)!
        let saveFileURL = saveGameDirectory
            .appendingPathComponent(name)
            .appendingPathExtension("sav")

        let ram: Data
        let manager = FileManager.default
        if manager.isReadableFile(atPath: saveFileURL.path) && manager.isWritableFile(atPath: saveFileURL.path) {
            ram = NSData(contentsOfFile: saveFileURL.path) as Data!
        } else {
            ram = Data(bytes: [UInt8](repeating: 0, count: ramSize(cartridge[0x149])))
        }

        switch cartridge[0x147] {
        case 0x00:
            return NoMBC(rom: cartridge, ram: nil, file: nil)
        case 0x01:
            return MBC1(rom: cartridge, ram: nil, file: nil)
        case 0x02:
            return MBC1(rom: cartridge, ram: ram, file: nil)
        case 0x03:
            return MBC1(rom: cartridge, ram: ram, file: saveFileURL)
        case 0x08:
            return NoMBC(rom: cartridge, ram: ram, file: nil)
        case 0x09:
            return NoMBC(rom: cartridge, ram: ram, file: saveFileURL)
        default:
            return nil
        }
    }

    private let cartridgeTypeNames: [UInt8: String] = [
        0x00: "ROM ONLY",
        0x01: "MBC1",
        0x02: "MBC1+RAM",
        0x03: "MBC1+RAM+BATTERY",
        0x05: "MBC2",
        0x06: "MBC2+BATTERY",
        0x08: "ROM+RAM",
        0x09: "ROM+RAM+BATTERY",
        0x0B: "MMM01",
        0x0C: "MMM01+RAM",
        0x0D: "MMM01+RAM+BATTERY",
        0x0F: "MBC3+TIMER+BATTERY",
        0x10: "MBC3+TIMER+RAM+BATTERY",
        0x11: "MBC3",
        0x12: "MBC3+RAM",
        0x13: "MBC3+RAM+BATTERY",
        0x19: "MBC5",
        0x1A: "MBC5+RAM",
        0x1B: "MBC5+RAM+BATTERY",
        0x1C: "MBC5+RUMBLE",
        0x1D: "MBC5+RUMBLE+RAM",
        0x1E: "MBC5+RUMBLE+RAM+BATTERY",
        0x20: "MBC6",
        0x22: "MBC7+SENSOR+RUMBLE+RAM+BATTERY",
        0xFC: "POCKET CAMERA",
        0xFD: "BANDAI TAMA5",
        0xFE: "HuC3",
        0xFF: "HuC1+RAM+BATTERY",
    ]

    private func romSize(_ byte: UInt8) -> Int {
        return 32768 << byte
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

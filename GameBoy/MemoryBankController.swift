//
//  MemoryBankController.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/15/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public protocol MemoryBankController {
    func readROM0(index: Int) -> UInt8
    func readROM1(index: Int) -> UInt8
    func readRAM(index: Int) -> UInt8

    func writeROM(index: Int, value newValue: UInt8)
    func writeRAM(index: Int, value newValue: UInt8)

    func save()
}

public class NoCartridgeMBC: MemoryBankController {
    public func readROM0(index: Int) -> UInt8 { return 0xFF }
    public func readROM1(index: Int) -> UInt8 { return 0xFF }
    public func readRAM(index: Int) -> UInt8 { return 0xFF }
    public func writeROM(index: Int, value newValue: UInt8) { }
    public func writeRAM(index: Int, value newValue: UInt8) { }
    public func save() { }
}

public class NoMBC: MemoryBankController {
    private var rom: [UInt8]
    private var ram: Data?
    private var fileURL: URL?
    private var updated: Bool = false

    public init(rom: [UInt8], ram: Data?, file: URL?) {
        self.rom = rom
        self.ram = ram
        self.fileURL = file
    }

    public func readROM0(index: Int) -> UInt8 {
        return rom[index]
    }

    public func readROM1(index: Int) -> UInt8 {
        return rom[index + 0x4000]
    }

    public func readRAM(index: Int) -> UInt8 {
        if ram != nil && index < ram!.count {
            return ram![index]
        }
        return 0xFF
    }

    public func writeROM(index: Int, value newValue: UInt8) { }

    public func writeRAM(index: Int, value newValue: UInt8) {
        if ram != nil && index < ram!.count {
            ram![index] = newValue
            updated = true
        }
    }

    public func save() {
        if updated {
            if let url = fileURL, let ram = ram {
                _ = try? ram.write(to: url)
                updated = false
            }
        }
    }
}

public class MBC1: MemoryBankController {
    private var rom: [UInt8]
    private var ram: Data?
    private let fileURL: URL?
    private var updated: Bool = false

    private var romBank = 1
    private var otherBank = 0
    private var romOffset = 0x4000
    private var ramOffset = 0
    private var bankingMode: BankingMode = .rom
    private var ramEnable: Bool = false

    public init(rom: [UInt8], ram: Data?, file: URL?) {
        self.rom = rom
        self.ram = ram
        self.fileURL = file
    }

    private func setBankingMode(_ mode: BankingMode) {
        bankingMode = mode
        switch bankingMode {
        case .rom:
            romOffset = (romBank + otherBank << 5) * 0x4000
            ramOffset = 0
        case .ram:
            romOffset = romBank * 0x4000
            ramOffset = otherBank * 0x2000
        }
    }

    private func setRomBank(_ bank: UInt8) {
        romBank = Int(bank)
        switch bankingMode {
        case .rom:
            romOffset = (romBank + otherBank << 5) * 0x4000
        case .ram:
            romOffset = romBank * 0x4000
        }
    }

    private func setOtherBank(_ bank: UInt8) {
        otherBank = Int(bank)
        switch bankingMode {
        case .rom:
            romOffset = (romBank + otherBank << 5) * 0x4000
        case .ram:
            ramOffset = otherBank * 0x2000
        }
    }

    public func readROM0(index: Int) -> UInt8 {
        return rom[index]
    }

    public func readROM1(index: Int) -> UInt8 {
        return rom[index + romOffset]
    }

    public func readRAM(index: Int) -> UInt8 {
        if ram != nil && ramEnable && index + ramOffset < ram!.count {
            return ram![index + ramOffset]
        }
        return 0xFF
    }

    public func writeROM(index: Int, value newValue: UInt8) {
        switch index {
        case 0x0000...0x1FFF:
            if newValue & 0x0F == 0x0A {
                ramEnable = true
            } else {
                ramEnable = false
            }
        case 0x2000...0x3FFF:
            let newBank = newValue & 0b11111
            setRomBank(newBank != 0 ? newBank : 1)
        case 0x4000...0x5FFF:
            setOtherBank(newValue & 0b11)
        case 0x6000...0x7FFF:
            setBankingMode(newValue == 0 ? .rom : .ram)
        default:
            break
        }
    }

    public func writeRAM(index: Int, value newValue: UInt8) {
        if ram != nil && ramEnable && index + ramOffset < ram!.count {
            ram![index + ramOffset] = newValue
            updated = true
        }
    }

    public func save() {
        if updated {
            if let url = fileURL, let ram = ram {
                _ = try? ram.write(to: url)
                updated = false
            }
        }
    }

    private enum BankingMode {
        case rom
        case ram
    }
}

//
//  MBC3.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/17/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class MBC3: MemoryBankController {
    private var rom: [UInt8]
    private var ram: Data?
    private let fileURL: URL?
    private var updated: Bool = false

    private var ramEnable: Bool = false
    private var romOffset: Int = 0x4000
    private var ramOffset: Int = 0

    public init(rom: [UInt8], ram: Data?, file: URL?) {
        self.rom = rom
        self.ram = ram
        self.fileURL = file
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
            let newBank = newValue & 0b1111111
            romOffset = Int(newBank) * 0x4000
            if romOffset == 0 {
                romOffset = 0x4000
            }
        case 0x4000...0x5FFF:
            ramOffset = Int(newValue & 0b11) * 0x2000
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
}

//
//  NoMBC.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/17/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

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


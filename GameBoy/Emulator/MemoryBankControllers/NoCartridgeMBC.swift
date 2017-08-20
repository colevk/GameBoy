//
//  NoCartridgeMBC.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/17/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class NoCartridgeMBC: MemoryBankController {
    public func readROM0(index: Int) -> UInt8 { return 0xFF }
    public func readROM1(index: Int) -> UInt8 { return 0xFF }
    public func readRAM(index: Int) -> UInt8 { return 0xFF }
    public func writeROM(index: Int, value newValue: UInt8) { }
    public func writeRAM(index: Int, value newValue: UInt8) { }
    public func save() { }
}


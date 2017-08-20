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

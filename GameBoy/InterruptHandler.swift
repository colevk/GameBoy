//
//  InterruptHandler.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/6/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class InterruptHandler {

    public unowned let gb: GameBoyRunner

    public let IE_VBLANK: UInt8 = 0x01
    public let IE_STAT: UInt8   = 0x02
    public let IE_TIMER: UInt8  = 0x04
    public let IE_SERIAL: UInt8 = 0x08
    public let IE_BUTTON: UInt8 = 0x10

    public init(withParent parent: GameBoyRunner) {
        gb = parent
    }

    public func handleInterrupts() {
        let activeFlags = gb.memory.IF & gb.memory.IE & 0x1F
        if activeFlags != 0 {
            if gb.cpu.ime {
                let address: UInt16
                if activeFlags & IE_VBLANK != 0 {
                    address = 0x0040
                    gb.memory.IF ^= IE_VBLANK
                } else if activeFlags & IE_STAT != 0 {
                    address = 0x0048
                    gb.memory.IF ^= IE_STAT
                } else if activeFlags & IE_TIMER != 0 {
                    address = 0x0050
                    gb.memory.IF ^= IE_TIMER
                } else if activeFlags & IE_SERIAL != 0 {
                    address = 0x0058
                    gb.memory.IF ^= IE_SERIAL
                } else {
                    address = 0x0060
                    gb.memory.IF ^= IE_BUTTON
                }
                gb.cpu.ime = false
                gb.cpu.push(gb.cpu.PC)
                gb.cpu.PC = address
            }
            gb.cpu.halt = false
        }
    }
}

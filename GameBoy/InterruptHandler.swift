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
    public let IE_LCDC: UInt8   = 0x02
    public let IE_TIMER: UInt8  = 0x04
    public let IE_SERIAL: UInt8 = 0x08
    public let IE_BUTTON: UInt8 = 0x10

    public var interruptEnable: UInt8 = 0
    public var interruptFlag: UInt8 = 0

    public init(withParent parent: GameBoyRunner) {
        gb = parent
    }

    public func handleInterrupts() {
        let activeFlags = interruptFlag & interruptEnable
        if activeFlags != 0 {
            let address: UInt16
            if activeFlags & IE_VBLANK != 0 {
                address = 0x0040
                interruptFlag ^= IE_VBLANK
            } else if activeFlags & IE_LCDC != 0 {
                address = 0x0048
                interruptFlag ^= IE_LCDC
            } else if activeFlags & IE_TIMER != 0 {
                address = 0x0050
                interruptFlag ^= IE_TIMER
            } else if activeFlags & IE_SERIAL != 0 {
                address = 0x0058
                interruptFlag ^= IE_SERIAL
            } else {
                address = 0x0060
                interruptFlag ^= IE_BUTTON
            }
            gb.cpu.ime = false
            gb.cpu.push(gb.cpu.PC)
            gb.cpu.PC = address
        }
    }
}

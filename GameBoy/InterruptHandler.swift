//
//  InterruptHandler.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/6/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

/** Handles checking for interrupts and the jumps necessary if triggered.
 */
public class InterruptHandler {
    public unowned let gb: GameBoyRunner

    public let IE_VBLANK: UInt8 = 0b00000001
    public let IE_STAT: UInt8   = 0b00000010
    public let IE_TIMER: UInt8  = 0b00000100
    public let IE_SERIAL: UInt8 = 0b00001000
    public let IE_BUTTON: UInt8 = 0b00010000

    public init(withParent parent: GameBoyRunner) {
        gb = parent
    }

    public func triggerInterrupt(_ interrupt: Interrupt) {
        switch interrupt {
        case .vblank:
            gb.memory.IF |= IE_VBLANK
        case .stat:
            gb.memory.IF |= IE_STAT
        case .timer:
            gb.memory.IF |= IE_TIMER
        case .serial:
            gb.memory.IF |= IE_SERIAL
        case .button:
            gb.memory.IF |= IE_BUTTON
        }
    }

    /** Checks if any active interrupts have been triggered, jumping to the interrupt address if so and returning true.
     */
    public func handleInterrupts() -> Bool {
        let activeFlags = gb.memory.IF & gb.memory.IE & 0x1F
        if activeFlags != 0 {
            if gb.cpu.ime {
                let address: UInt16
                if activeFlags & IE_VBLANK != 0 {
                    address = 0x40
                    gb.memory.IF &= ~IE_VBLANK
                } else if activeFlags & IE_STAT != 0 {
                    address = 0x48
                    gb.memory.IF &= ~IE_STAT
                } else if activeFlags & IE_TIMER != 0 {
                    address = 0x50
                    gb.memory.IF &= ~IE_TIMER
                } else if activeFlags & IE_SERIAL != 0 {
                    address = 0x58
                    gb.memory.IF &= ~IE_SERIAL
                } else {
                    address = 0x60
                    gb.memory.IF &= ~IE_BUTTON
                }
                gb.cpu.ime = false
                _ = gb.cpu.call(cond: true, addr: address)
            }
            gb.cpu.halt = false
            return true
        }
        return false
    }
}

public enum Interrupt {
    case vblank
    case stat
    case timer
    case serial
    case button
}

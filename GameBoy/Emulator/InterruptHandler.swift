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

    private var vblankEnable: Bool = false
    private var statEnable: Bool = false
    private var timerEnable: Bool = false
    private var serialEnable: Bool = false
    private var buttonEnable: Bool = false

    private var vblankFlag: Bool = false
    private var statFlag: Bool = false
    private var timerFlag: Bool = false
    private var serialFlag: Bool = false
    private var buttonFlag: Bool = false

    public var IF: UInt8 {
        get {
            return
                UInt8(vblankFlag ? 0x01 : 0) +
                UInt8(statFlag ? 0x02: 0) +
                UInt8(timerFlag ? 0x04 : 0) +
                UInt8(serialFlag ? 0x08 : 0) +
                UInt8(buttonFlag ? 0x10 : 0)
        }
        set {
            vblankFlag = newValue & 0x01 != 0
            statFlag = newValue & 0x02 != 0
            timerFlag = newValue & 0x04 != 0
            serialFlag = newValue & 0x08 != 0
            buttonFlag = newValue & 0x10 != 0
        }
    }
    public var IE: UInt8 {
        get {
            return
                UInt8(vblankEnable ? 0x01 : 0) +
                UInt8(statEnable ? 0x02: 0) +
                UInt8(timerEnable ? 0x04 : 0) +
                UInt8(serialEnable ? 0x08 : 0) +
                UInt8(buttonEnable ? 0x10 : 0)
        }
        set {
            vblankEnable = newValue & 0x01 != 0
            statEnable = newValue & 0x02 != 0
            timerEnable = newValue & 0x04 != 0
            serialEnable = newValue & 0x08 != 0
            buttonEnable = newValue & 0x10 != 0
        }
    }

    public init(withParent parent: GameBoyRunner) {
        gb = parent
    }

    public func triggerInterrupt(_ interrupt: Interrupt) {
        switch interrupt {
        case .vblank:
            vblankFlag = true
        case .stat:
            statFlag = true
        case .timer:
            timerFlag = true
        case .serial:
            serialFlag = true
        case .button:
            buttonFlag = true
        }
    }

    /** Checks if any active interrupts have been triggered, jumping to the interrupt address if so and returning true.
     */
    public func handleInterrupts() -> Bool {
        if vblankFlag && vblankEnable {
            callInterrupt(address: 0x40, flag: &vblankFlag)
            return true
        }
        if statFlag && statEnable {
            callInterrupt(address: 0x48, flag: &statFlag)
            return true
        }
        if timerFlag && timerEnable {
            callInterrupt(address: 0x50, flag: &timerFlag)
            return true
        }
        if serialFlag && serialEnable {
            callInterrupt(address: 0x58, flag: &serialFlag)
            return true
        }
        if buttonFlag && buttonEnable {
            callInterrupt(address: 0x60, flag: &buttonFlag)
            return true
        }
        return false
    }

    private func callInterrupt(address: UInt16, flag: inout Bool) {
        if gb.cpu.ime {
            gb.cpu.ime = false
            flag = false
            _ = gb.cpu.call(cond: true, addr: address)
        }
        gb.cpu.halt = false
    }
}

public enum Interrupt {
    case vblank
    case stat
    case timer
    case serial
    case button
}

//
//  Timer.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/11/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

/** Store timing information, including the DIV, TAC, TIMA, and TMA registers.
 */
public class Timer {
    unowned let gb: GameBoyRunner

    private var divider: UInt16 = 0
    private var timer: UInt16 = 0
    private var timerUpdate: UInt16 = 0
    private var timerModulo: UInt16 = 0
    private var rawTimerControl: UInt8 = 0

    public var DIV: UInt8 {
        get { return UInt8(divider >> 8) }
        set { divider = 0 }
    }

    public var TIMA: UInt8 {
        get { return UInt8(timer >> 8) }
        set { timer = timer & 0x00FF + UInt16(newValue) << 8 }
    }

    public var TAC: UInt8 {
        get { return rawTimerControl }
        set {
            rawTimerControl = newValue
            if rawTimerControl.checkBit(2) {
                switch rawTimerControl & 0x03 {
                case 0b00: timerUpdate = 1
                case 0b01: timerUpdate = 64
                case 0b10: timerUpdate = 16
                case 0b11: timerUpdate = 4
                default: break
                }
            } else {
                timerUpdate = 0
            }
        }
    }

    public var TMA: UInt8 {
        get { return UInt8(timerModulo >> 8) }
        set { timerModulo = UInt16(timerModulo) << 8 }
    }

    public init(withParent parent: GameBoyRunner) {
        gb = parent
    }

    public func advanceBy(cycles: Int) {
        divider &+= UInt16(4 * cycles)

        let overflow: ArithmeticOverflow
        (timer, overflow) = timer.addingReportingOverflow(timerUpdate * UInt16(cycles))

        if overflow == .overflow {
            timer += timerModulo
            gb.interrupts.triggerInterrupt(.timer)
        }
    }
}

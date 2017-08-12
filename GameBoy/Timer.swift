//
//  Timer.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/11/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class Timer {

    unowned let gb: GameBoyRunner

    public init(withParent parent: GameBoyRunner) {
        gb = parent
    }

    public var timer: Int = 0

    public func tick() {
        timer += 1
        timer %= 256
        if timer % 64 == 0 {
            gb.memory.DIV &+= 1
        }
        if gb.memory.TAC & 0x04 != 0 {
            let interval: Int
            switch gb.memory.TAC & 0x03 {
            case 0b00: interval = 256
            case 0b01: interval = 4
            case 0b10: interval = 16
            case 0b11: interval = 64
            default: return
            }
            if timer % interval == 0 {
                gb.memory.TIMA &+= 1
            }
            if gb.memory.TIMA == 0 {
                gb.memory.TIMA = gb.memory.TMA
                gb.memory.IF |= gb.interrupts.IE_TIMER
            }
        }
    }
}

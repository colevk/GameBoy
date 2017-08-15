//
//  Joypad.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class Joypad {
    public var pressedRight: Bool = false
    public var pressedLeft: Bool = false
    public var pressedUp: Bool = false
    public var pressedDown: Bool = false
    public var pressedA: Bool = false
    public var pressedB: Bool = false
    public var pressedSelect: Bool = false
    public var pressedStart: Bool = false

    public var port14: Bool = false
    public var port15: Bool = false

    public var P1: UInt8 {
        get {
            return (((pressedRight && port14) || (pressedA && port15)) ? 0x00 : 0x01) +
                (((pressedLeft && port14) || (pressedB && port15)) ? 0x00 : 0x02) +
                (((pressedUp && port14) || (pressedSelect && port15)) ? 0x00 : 0x04) +
                (((pressedDown && port14) || (pressedStart && port15)) ? 0x00 : 0x08) +
                (port14 ? 0x00 : 0x10) + (port15 ? 0x00 : 0x20)
        }
        set {
            port14 = newValue & 0x10 == 0
            port15 = newValue & 0x20 == 0
        }
    }
}

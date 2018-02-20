//
//  Joypad.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

/** Controls the P1 register based on the current button states.
 */
public class Joypad {
    public enum Button {
        case right
        case left
        case up
        case down
        case a
        case b
        case select
        case start
    }

    public enum ButtonState {
        case up
        case down
    }

    public var keyRight: Bool = false
    public var keyLeft: Bool = false
    public var keyUp: Bool = false
    public var keyDown: Bool = false
    public var keyA: Bool = false
    public var keyB: Bool = false
    public var keySelect: Bool = false
    public var keyStart: Bool = false

    private var port10: Bool { get { return (keyRight && port14) || (keyA && port15) }}
    private var port11: Bool { get { return (keyLeft && port14) || (keyB && port15) }}
    private var port12: Bool { get { return (keyUp && port14) || (keySelect && port15) }}
    private var port13: Bool { get { return (keyDown && port14) || (keyStart && port15) }}

    private var port14: Bool = false
    private var port15: Bool = false

    public var P1: UInt8 {
        get {
            return
                (port10 ? 0 : 1) +
                (port11 ? 0 : 2) +
                (port12 ? 0 : 4) +
                (port13 ? 0 : 8) +
                (port14 ? 0 : 16) +
                (port15 ? 0 : 32)
        }
        set {
            port14 = newValue & 0x10 == 0
            port15 = newValue & 0x20 == 0
        }
    }
}


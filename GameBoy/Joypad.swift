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
                (port10 ? 0x00 : 0x01) +
                (port11 ? 0x00 : 0x02) +
                (port12 ? 0x00 : 0x04) +
                (port13 ? 0x00 : 0x08) +
                (port14 ? 0x00 : 0x10) +
                (port15 ? 0x00 : 0x20)
        }
        set {
            port14 = newValue & 0x10 == 0
            port15 = newValue & 0x20 == 0
        }
    }
}

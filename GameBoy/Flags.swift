//
//  Flags.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public class Flags {
    public var uint8: UInt8 = 0
    
    private func getFlag(withMask mask: UInt8) -> Bool {
        return (uint8 & mask) != 0
    }

    private func setFlag(_ newValue: Bool, withMask mask: UInt8) {
        if newValue {
            uint8 |= mask
        } else {
            uint8 &= ~mask
        }
    }

    public var z: Bool {
        get {
            return getFlag(withMask: 0x80)
        }
        set {
            setFlag(newValue, withMask: 0x80)
        }
    }

    public var n: Bool {
        get {
            return getFlag(withMask: 0x40)
        }
        set {
            setFlag(newValue, withMask: 0x40)
        }
    }

    public var h: Bool {
        get {
            return getFlag(withMask: 0x20)
        }
        set {
            setFlag(newValue, withMask: 0x20)
        }
    }

    public var c: Bool {
        get {
            return getFlag(withMask: 0x10)
        }
        set {
            setFlag(newValue, withMask: 0x10)
        }
    }
}

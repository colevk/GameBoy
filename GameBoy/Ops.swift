//
//  Ops.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

public struct Ops {
    let flags: Flags

    public init(withFlags flags: Flags) {
        self.flags = flags
    }

    public func inc(register: inout UInt8) {
        flags.h = register & 0xF == 0xF
        register &+= 1
        flags.z = register == 0
        flags.n = false
    }

    public func inc(register: inout UInt16) {
        register &+= 1
    }

    public func dec(register: inout UInt8) {
        flags.h = (register & 0xF == 0x0)
        register &-= 1
        flags.z = register == 0
        flags.n = true
    }

    public func dec(register: inout UInt16) {
        register &-= 1
    }

    public func rlc(register: inout UInt8) {
        register = register << 1 + register >> 7
        flags.z = register == 0
        flags.n = false
        flags.h = false
        flags.c = (register & 0x01) != 0
    }

    public func rl(register: inout UInt8) {
        (flags.c, register) = (register & 0x80 == 0x80, register << 1 + (flags.c ? 1 : 0))
        flags.z = register == 0
        flags.n = false
        flags.h = false
    }

    public func rrc(register: inout UInt8) {
        flags.c = (register & 0x01) != 0
        register = register >> 1 + register << 7
        flags.z = register == 0
        flags.n = false
        flags.h = false
    }

    public func rr(register: inout UInt8) {
        (flags.c, register) = (register & 0x01 == 0x01, register >> 1 + (flags.c ? 0x80 : 0))
        flags.z = register == 0
        flags.n = false
        flags.h = false
    }

    public func sla(register: inout UInt8) {
        flags.c = register.checkBit(7)
        register = register << 1
        flags.z = register == 0
        flags.n = false
        flags.h = false
    }

    public func sra(register: inout UInt8) {
        flags.c = register.checkBit(0)
        register = (register >> 1) + (register.checkBit(7) ? 0x80 : 0)
        flags.z = register == 0
        flags.n = false
        flags.h = false
    }

    public func srl(register: inout UInt8) {
        flags.c = register.checkBit(0)
        register = register >> 1
        flags.z = register == 0
        flags.n = false
        flags.h = false
    }

    public func add(to: inout UInt8, from: UInt8) {
        (to, flags.h, flags.c) = UInt8.addWithFlags(to, from)
        flags.n = false
        flags.z = to == 0
    }

    public func adc(to: inout UInt8, from: UInt8) {
        if (flags.c) {
            let (temp, h1, c1) = UInt8.addWithFlags(to, from)
            let (res, h2, c2) = UInt8.addWithFlags(temp, 1)
            to = res
            flags.z = to == 0
            flags.n = false
            flags.h = h1 || h2
            flags.c = c1 || c2
        } else {
            add(to: &to, from: from)
        }
    }

    public func sub(to: inout UInt8, from: UInt8) {
        (to, flags.h, flags.c) = UInt8.subtractWithFlags(to, from)
        flags.n = true
        flags.z = to == 0
    }

    public func sbc(to: inout UInt8, from: UInt8) {
        if (flags.c) {
            let (temp, h1, c1) = UInt8.subtractWithFlags(to, from)
            let (res, h2, c2) = UInt8.subtractWithFlags(temp, 1)
            to = res
            flags.z = to == 0
            flags.n = true
            flags.h = h1 || h2
            flags.c = c1 || c2
        } else {
            sub(to: &to, from: from)
        }
    }

    public func and(to: inout UInt8, from: UInt8) {
        to = to & from
        flags.z = to == 0
        flags.n = false
        flags.h = true
        flags.c = false
    }

    public func or(to: inout UInt8, from: UInt8) {
        to = to | from
        flags.z = to == 0
        flags.n = false
        flags.h = false
        flags.c = false
    }

    public func xor(to: inout UInt8, from: UInt8) {
        to = to ^ from
        flags.z = to == 0
        flags.n = false
        flags.h = false
        flags.c = false
    }

    public func cp(to: UInt8, from: UInt8) {
        let result: UInt8
        (result, flags.h, flags.c) = UInt8.subtractWithFlags(to, from)
        flags.n = true
        flags.z = result == 0
    }

    public func add(to: inout UInt16, from: UInt16) {
        (to, flags.h, flags.c) = UInt16.addWithFlags(to, from)
        flags.n = false
    }

    public func bit(_ offset: UInt8, register: UInt8) {
        flags.z = register & (0x01 << offset) == 0
        flags.n = false
        flags.h = true
    }

    public func set(_ offset: UInt8, register: inout UInt8) {
        register |= (0x01 << offset)
    }

    public func reset(_ offset: UInt8, register: inout UInt8) {
        register &= ~(0x01 << offset)
    }
}


infix operator &+=
infix operator &-=
infix operator &*=

extension UInt8 {
    func checkBit(_ bit: Int) -> Bool {
        return (self >> bit) & 1 == 1
    }

    static func addWithFlags(_ lhs: UInt8, _ rhs: UInt8) -> (UInt8, Bool, Bool) {
        let halfCarry = (((lhs & 0xF) + (rhs & 0xF)) & 0x10) == 0x10
        let (result, carry) = lhs.addingReportingOverflow(rhs)
        return (result, halfCarry, carry == .overflow)
    }

    static func subtractWithFlags(_ lhs: UInt8, _ rhs: UInt8) -> (UInt8, Bool, Bool) {
        let halfCarry = (lhs & 0xF) < (rhs & 0xF)
        let (result, carry) = lhs.subtractingReportingOverflow(rhs)
        return (result, halfCarry, carry == .overflow)
    }

    static func &+= (_ left: inout UInt8, _ right: UInt8) {
        left = left &+ right
    }

    static func &-= (_ left: inout UInt8, _ right: UInt8) {
        left = left &- right
    }

    static func &*= (_ left: inout UInt8, _ right: UInt8) {
        left = left &* right
    }
}

extension UInt16 {
    public static func addWithFlags(_ lhs: UInt16, _ rhs: UInt16) -> (UInt16, Bool, Bool) {
        let halfCarry = ((lhs & 0xFFF) + (rhs & 0xFFF)) & 0x1000 == 0x1000
        let (result, carry) = lhs.addingReportingOverflow(rhs)
        return (result, halfCarry, carry == .overflow)
    }

    public static func subtractWithFlags(_ lhs: UInt16, _ rhs: UInt16) -> (UInt16, Bool, Bool) {
        let halfCarry = (lhs & 0xFFF) < (rhs & 0xFFF)
        let (result, carry) = lhs.subtractingReportingOverflow(rhs)
        return (result, halfCarry, carry == .overflow)
    }

    public static func addRelativeWithFlags(_ lhs: UInt16, _ rhs: UInt8) -> (UInt16, Bool, Bool) {
        let rhsExtended = UInt16(rhs) + ((rhs & 0x80 == 0x80) ? 0xFF00 : 0)
        return UInt16.addWithFlags(lhs, rhsExtended)
    }

    static func &+= (_ left: inout UInt16, _ right: UInt16) {
        left = left &+ right
    }

    static func &-= (_ left: inout UInt16, _ right: UInt16) {
        left = left &- right
    }

    static func &*= (_ left: inout UInt16, _ right: UInt16) {
        left = left &* right
    }
}


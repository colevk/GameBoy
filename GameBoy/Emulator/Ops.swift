//
//  Ops.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

infix operator &+=
infix operator &-=
infix operator &*=

/** Helper functions that record whether half-carry happened.
 */
extension UInt8 {
    func checkBit(_ bit: Int) -> Bool {
        return (self >> bit) & 1 == 1
    }

    static func addWithFlags(_ lhs: UInt8, _ rhs: UInt8) -> (UInt8, Bool, Bool) {
        let halfCarry = (((lhs & 0xF) + (rhs & 0xF)) & 0x10) != 0
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

/** Helper functions that record whether half-carry happened.
 */
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
        let (_, halfCarry, carry) = UInt8.addWithFlags(UInt8(lhs & 0xFF), rhs)
        let rhsExtended = UInt16(rhs) + ((rhs & 0x80 != 0) ? 0xFF00 : 0)
        return (lhs &+ rhsExtended, halfCarry, carry)
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


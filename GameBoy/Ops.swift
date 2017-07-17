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
        (register, flags.z) = UInt8.addWithOverflow(register, 1)
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

    public func add(to: inout UInt8, from: UInt8) {
        flags.h = (((to & 0xF) + (from & 0xF)) & 0x10) == 0x10
        (to, flags.c) = UInt8.addWithOverflow(to, from)
        flags.n = false
    }
    
    public func add(to: inout UInt16, from: UInt16) {
        flags.h = (((to & 0xFFF) + (from & 0xFFF)) & 0x1000) == 0x1000
        (to, flags.c) = UInt16.addWithOverflow(to, from)
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

func &+=<T: Integer>(_ left: inout T, _ right: T) {
    left = left &+ right
}

func &-=<T: Integer>(_ left: inout T, _ right: T) {
    left = left &- right
}

func &*=<T: Integer>(_ left: inout T, _ right: T) {
    left = left &* right
}

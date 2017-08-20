//
//  SerialDevice.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/11/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation

/** The Game Boy serial port reads/writes one byte at a time, with one control byte.
 */
public protocol SerialDevice {
    var SB: UInt8 { get set }
    var SC: UInt8 { get set }
}

/** Responds to serial I/O as if nothing is attached.
 */
public class EmptySerialDevice: SerialDevice {
    public var SB: UInt8 {
        get {
            return 0xFF
        }
        set { }
    }
    public var SC: UInt8 = 0
}

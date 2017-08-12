//
//  TestROMSerialDevice.swift
//  GameBoyTests
//
//  Created by Cole van Krieken on 8/11/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import GameBoy

public class TestROMSerialDevice: SerialDevice {
    public var receivedBytes: [UInt8] = []

    public func results() -> String {
        return String(data: Data(bytes: receivedBytes), encoding: .utf8)!
    }

    public var SB: UInt8 {
        get {
            return 0xFF
        }
        set {
            receivedBytes.append(newValue)
        }
    }

    public var SC: UInt8 {
        get {
            return 0xFF
        }
        set { }
    }


}

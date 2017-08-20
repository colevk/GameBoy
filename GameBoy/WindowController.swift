//
//  WindowController.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/19/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import Cocoa

public class WindowController: NSWindowController {

    override public func windowDidLoad() {
        (NSApp.delegate! as! AppDelegate).windowController = self
    }

    private let modifierKeyCodes: [UInt16: NSEvent.ModifierFlags] = [
        55: .command,
        56: .shift,
        57: .capsLock,
        58: .option,
        59: .control,
        63: .function,
    ]

    public var keyCodes: [UInt16: Joypad.Button] = [
        0:   .a,      // A
        1:   .b,      // S
        36:  .start,  // Return
        56:  .select, // D
        123: .left,   // Left
        124: .right,  // Right
        125: .down,   // Down
        126: .up,     // Up
    ]

    override public func keyDown(with event: NSEvent) {
        if let button = keyCodes[event.keyCode] {
            if !event.isARepeat {
                (contentViewController as! GameViewController).gameBoy.keyChanged(button, .down)
            }
        } else {
            super.keyDown(with: event)
        }
    }

    override public func keyUp(with event: NSEvent) {
        if let button = keyCodes[event.keyCode] {
            (contentViewController as! GameViewController).gameBoy.keyChanged(button, .up)
        } else {
            super.keyUp(with: event)
        }
    }

    override public func flagsChanged(with event: NSEvent) {
        if let button = keyCodes[event.keyCode], let modifier = modifierKeyCodes[event.keyCode] {
            if event.modifierFlags.contains(modifier) {
                (contentViewController as! GameViewController).gameBoy.keyChanged(button, .down)
            } else {
                (contentViewController as! GameViewController).gameBoy.keyChanged(button, .up)
            }
        }
        super.flagsChanged(with: event)
    }
}


//
//  View.swift
//  GameBoy
//
//  Created by Cole van Krieken on 8/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import Cocoa
import MetalKit

public class View : MTKView {
    /** Return true when controller handles events, to avoid beep. Probably a better way to arrange this.
     */
    override public func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let controller = self.delegate as? GameViewController {
            if controller.canHandleKeyEvent(with: event) {
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}


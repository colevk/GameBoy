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
    override public func performKeyEquivalent(with event: NSEvent) -> Bool {
        if let controller = self.delegate as? GameViewController {
            if controller.canHandleKeyEvent(with: event) {
                return true
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}


//
//  GPU.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/20/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import MetalKit

public class GPU {
    public var ram: AlignedArray<UInt8>
    public var oam: AlignedArray<UInt8>
    public var lineAttributes: AlignedArray<UInt8>

    private let numAttributes: Int = 8

    public init() {
        ram = AlignedArray<UInt8>(withCapacity: 0x2000, alignedTo: 0x1000)
        oam = AlignedArray<UInt8>(withCapacity: 0xA0, alignedTo: 0x1000)
        lineAttributes = AlignedArray<UInt8>(withCapacity: numAttributes * 144, alignedTo: 0x1000)
    }

    public func reset() {
        lcdControl = 0
        scrollY = 0
        scrollX = 0
        bgPalette = 0
    }

    public var lcdControl: UInt8 = 0
    public var scrollY: UInt8 = 0
    public var scrollX: UInt8 = 0
    public var spritePalette0: UInt8 = 0
    public var spritePalette1: UInt8 = 0
    public var windowY: UInt8 = 0
    public var windowX: UInt8 = 0
    public var bgPalette: UInt8 = 0

    public func storeLineAttributes(line: Int) {
        if line >= 144 { return }
        lineAttributes[line * numAttributes + 0] = lcdControl
        lineAttributes[line * numAttributes + 1] = scrollY
        lineAttributes[line * numAttributes + 2] = scrollX
        lineAttributes[line * numAttributes + 3] = spritePalette0
        lineAttributes[line * numAttributes + 4] = spritePalette1
        lineAttributes[line * numAttributes + 5] = windowY
        lineAttributes[line * numAttributes + 6] = windowX
        lineAttributes[line * numAttributes + 7] = bgPalette
    }
}

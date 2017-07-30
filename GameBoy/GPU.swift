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

    private let numAttributes: Int = 4

    public init() {
        ram = AlignedArray<UInt8>(withCapacity: 0x2000, alignedTo: 0x1000)
        oam = AlignedArray<UInt8>(withCapacity: 0xA0, alignedTo: 0x1000)
        lineAttributes = AlignedArray<UInt8>(withCapacity: numAttributes * 144, alignedTo: 0x1000)
    }

    public func reset() {
        controlBits = 0
        scy = 0
        scx = 0
        palette = 0
    }

    public var controlBits: UInt8 = 0
    public var scy: UInt8 = 0
    public var scx: UInt8 = 0
    public var palette: UInt8 = 0

    public func storeLineAttributes(line: Int) {
        if line >= 144 { return }
        lineAttributes[line * numAttributes] = controlBits
        lineAttributes[line * numAttributes + 1] = scy
        lineAttributes[line * numAttributes + 2] = scx
        lineAttributes[line * numAttributes + 3] = palette
    }
}

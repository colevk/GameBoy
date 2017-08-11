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

    private unowned let gb: GameBoyRunner

    private let STAT_MODE = 0x03
    private let STAT_COINCIDENCE = 0x04

    public var lineAttributes: AlignedArray<UInt8>

    public var timer: Int = 0

    public var mode: GPUMode = .readingOAM

    private let numAttributes: Int = 8

    public init(withParent parent: GameBoyRunner) {
        gb = parent

        lineAttributes = AlignedArray<UInt8>(withCapacity: numAttributes * 144, alignedTo: 0x1000)
    }

    public func storeLineAttributes(line: Int) {
        if line >= 144 { return }
        lineAttributes[line * numAttributes + 0] = gb.memory.LCDC
        lineAttributes[line * numAttributes + 1] = gb.memory.SCY
        lineAttributes[line * numAttributes + 2] = gb.memory.SCX
        lineAttributes[line * numAttributes + 3] = gb.memory.OBP0
        lineAttributes[line * numAttributes + 4] = gb.memory.OBP1
        lineAttributes[line * numAttributes + 5] = gb.memory.WY
        lineAttributes[line * numAttributes + 6] = gb.memory.WX
        lineAttributes[line * numAttributes + 7] = gb.memory.BGP
    }

    public func step() {
        timer += 1
        if timer >= 114 {
            timer = 0
            gb.memory.LY = (gb.memory.LY + 1) % 154
        }

        switch gb.memory.LY {
        case 0...143:
            switch timer {
            case 0:
                mode = .readingOAM
                readOAM()
            case 20:
                mode = .readingVRAM
                readVRAM()
            case 63:
                mode = .hBlank
                storeLineAttributes(line: Int(gb.memory.LY))
            default:
                break
            }
        case 144:
            if timer == 0 {
                mode = .vBlank
                gb.interrupts.interruptFlag |= gb.interrupts.IE_VBLANK
            }
        default:
            break
        }
    }

    private func readOAM() {

    }

    private func readVRAM() {

    }
}

public enum GPUMode {
    case hBlank
    case vBlank
    case readingOAM
    case readingVRAM
}

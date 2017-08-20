//
//  GPU.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/20/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import Foundation
import MetalKit

/** Control graphics. Current setup is a cheat, reading video RAM and OAM only at vblank, rather than at their proper times. Graphics-relevant registers are also only stored per-line, rather than per-pixel. This is to offload most of the graphics work to the GPU.
 */
public class GPU {
    private unowned let gb: GameBoyRunner

    public var lineAttributes: AlignedArray<UInt8>
    public var spritePriorityOrder: AlignedArray<UInt8>

    public var timer: Int = 0
    public var mode: GPUMode = .readingOAM

    private var line: UInt8 = 0
    private var statLineInterrupt: Bool = false
    private var statOAMInterrupt: Bool = false
    private var statVBlankInterrupt: Bool = false
    private var statHBlankInterrupt: Bool = false
    private var statCoincidence: Bool = false
    private var modeBits: UInt8 = 0

    public var STAT: UInt8 {
        get {
            return modeBits +
                (statLineInterrupt ? 0x40 : 0) +
                (statOAMInterrupt ? 0x20 : 0) +
                (statVBlankInterrupt ? 0x10 : 0) +
                (statHBlankInterrupt ? 0x08 : 0) +
                (statCoincidence ? 0x04 : 0)
        }
        set {
            statLineInterrupt = newValue & 0x40 != 0
            statOAMInterrupt = newValue & 0x20 != 0
            statVBlankInterrupt = newValue & 0x10 != 0
            statHBlankInterrupt = newValue & 0x08 != 0
        }
    }

    public var LY: UInt8 {
        get { return line }
        set {
            line = newValue
            statCoincidence = newValue == LYC
            if statLineInterrupt && statCoincidence {
                gb.interrupts.triggerInterrupt(.stat)
            }
        }
    }

    public var LYC: UInt8 = 0

    public func ramAccessible() -> Bool {
        return mode != .readingVRAM || !gb.memory.LCDC.checkBit(7)
    }

    public func oamAccessible() -> Bool {
        return (mode != .readingOAM && mode != .readingVRAM) || !gb.memory.LCDC.checkBit(7)
    }

    private func setMode(_ newValue: GPUMode) {
        mode = newValue
        switch newValue {
        case .hBlank:
            modeBits = 0b00
            if statHBlankInterrupt {
                gb.interrupts.triggerInterrupt(.stat)
            }
        case .vBlank:
            modeBits = 0b01
            if gb.memory.LCDC.checkBit(7) {
                gb.interrupts.triggerInterrupt(.vblank)
            }
            if statVBlankInterrupt {
                gb.interrupts.triggerInterrupt(.stat)
            }
        case .readingOAM:
            modeBits = 0b10
            if statOAMInterrupt {
                gb.interrupts.triggerInterrupt(.stat)
            }
        case .readingVRAM:
            modeBits = 0b11
        }
    }

    private let numAttributes: Int = 8

    public init(withParent parent: GameBoyRunner) {
        gb = parent

        lineAttributes = AlignedArray<UInt8>(withCapacity: numAttributes * 144, alignedTo: 0x1000)
        spritePriorityOrder = AlignedArray<UInt8>(withCapacity: 40, alignedTo: 0x1000)
    }

    /** Save relevant registers to a buffer for the GPU.
     */
    public func storeLineAttributes(line: Int) {
        if line >= 144 { return }
        lineAttributes[line * numAttributes + 0] = gb.memory.LCDC
        lineAttributes[line * numAttributes + 1] = gb.memory.SCY
        lineAttributes[line * numAttributes + 2] = gb.memory.SCX
        lineAttributes[line * numAttributes + 3] = gb.memory.OBP0
        lineAttributes[line * numAttributes + 4] = gb.memory.OBP1
        if line == 0 {
            lineAttributes[5] = gb.memory.WY
        } else {
            lineAttributes[line * numAttributes + 5] = lineAttributes[5]
        }
        lineAttributes[line * numAttributes + 6] = gb.memory.WX
        lineAttributes[line * numAttributes + 7] = gb.memory.BGP
    }

    public func advanceBy(cycles: Int) {
        for _ in 0..<cycles {
            step()
        }
    }

    /** Increment the GPU by one cycle.
     */
    public func step() {
        switch line {
        case 0...143:
            switch timer {
            case 0:
                setMode(.readingOAM)
            case 20:
                setMode(.readingVRAM)
            case 63:
                setMode(.hBlank)
                storeLineAttributes(line: Int(line))
            default:
                break
            }
        case 144:
            if timer == 0 {
                setMode(.vBlank)
                getSpritePriority()
            }
        default:
            break
        }

        timer += 1
        if timer >= 114 {
            timer = 0
            LY = (LY + 1) % 154
        }
    }

    /** Get sprite indices in order of on-screen priority (first x-coords, then index), so the GPU doesn't have to sort them.
      */
    private func getSpritePriority() {
        let xCoords = (0..<40).map { gb.memory.objectAttributeMemory[$0 * 4 + 1] }
        let indices = xCoords.enumerated().sorted {
            $0.element != $1.element ? $0.element > $1.element : $0.offset > $1.offset
        }
        for idx in 0..<40 {
            spritePriorityOrder[idx] = UInt8(indices[idx].offset)
        }
    }
}

public enum GPUMode {
    case hBlank
    case vBlank
    case readingOAM
    case readingVRAM
}

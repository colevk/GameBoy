//
//  CPUInstructionTests.swift
//  CPUInstructionTests
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright © 2017 Cole van Krieken. All rights reserved.
//

import XCTest
@testable import GameBoy

class CPUInstructionTests: XCTestCase {
    var gameBoy: GameBoyRunner! = nil
    var serialDevice: TestROMSerialDevice! = nil

    let bundle = Bundle(for: CPUInstructionTests.self)
    let frameTimeout = 3600 // 1 minute of Game Boy time

    override func setUp() {
        super.setUp()

        gameBoy = GameBoyRunner()
        gameBoy.skipBIOS = true

        serialDevice = TestROMSerialDevice()
        gameBoy.serialDevice = serialDevice
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func runTestROM(romName: String, endLoopAddress: UInt16) {
        if let filePath = bundle.path(forResource: romName, ofType: "gb"),
           let data = NSData(contentsOfFile: filePath) as Data?
        {
            gameBoy.loadCartridge(withData: data)
        } else {
            XCTFail("Cound not load ROM")
            return
        }
        
        gameBoy.skipBIOS = true
        gameBoy.reset()

        var timer = 0

        while gameBoy.cpu.PC != endLoopAddress && timer < frameTimeout {
            gameBoy.advanceFrame()
            timer += 1
        }

        let expected = "\(romName)\n\n\nPassed\n"
        let actual = serialDevice.results()

        if actual != expected {
            XCTFail(actual)
        }
    }

    func testSpecial() {
        runTestROM(romName: "01-special", endLoopAddress: 51154)
    }

    func testInterrupts() {
        runTestROM(romName: "02-interrupts", endLoopAddress: 51188)
    }

    func testStack() {
        runTestROM(romName: "03-op sp,hl", endLoopAddress: 52036)
    }

    func testImmediate() {
        runTestROM(romName: "04-op r,imm", endLoopAddress: 52021)
    }

    func test16BitArithmetic() {
        runTestROM(romName: "05-op rp", endLoopAddress: 52017)
    }

    func testLoads() {
        runTestROM(romName: "06-ld r,r", endLoopAddress: 52319)
    }

    func testBranch() {
        runTestROM(romName: "07-jr,jp,call,ret,rst", endLoopAddress: 52144)
    }

    func testMisc() {
        runTestROM(romName: "08-misc instrs", endLoopAddress: 52113)
    }

    func test8BitArithmetic() {
        runTestROM(romName: "09-op r,r", endLoopAddress: 52839)
    }

    func testBitOps() {
        runTestROM(romName: "10-bit ops", endLoopAddress: 53080)
    }

    func testAddressOps() {
        runTestROM(romName: "11-op a,(hl)", endLoopAddress: 52322)
    }

    func testInstructionTiming() {
        runTestROM(romName: "instr_timing", endLoopAddress: 51376)
    }
}

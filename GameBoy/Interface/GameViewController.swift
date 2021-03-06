//
//  GameViewController.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

import Cocoa
import MetalKit

class GameViewController: NSViewController, MTKViewDelegate {

    var running: Bool = true

    var gameBoy: GameBoyRunner! = nil

    var device: MTLDevice! = nil

    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil

    var graphicsRAMBuffer: MTLBuffer! = nil
    var graphicsOAMBuffer: MTLBuffer! = nil
    var graphicsSpriteOrderBuffer: MTLBuffer! = nil
    var graphicsAttributesBuffer: MTLBuffer! = nil

    override func viewDidLoad() {
        super.viewDidLoad()

        device = MTLCreateSystemDefaultDevice()
        guard device != nil else { // Fallback to a blank NSView, an application could also fallback to OpenGL here.
            print("Metal is not supported on this device")
            self.view = NSView(frame: self.view.frame)
            return
        }

        // setup view properties
        let view = self.view as! MTKView
        view.delegate = self
        view.device = device
        view.preferredFramesPerSecond = 60

        gameBoy = GameBoyRunner()

        loadAssets()
    }

    func loadAssets() {
        // MTK boilerplate
        let view = self.view as! MTKView
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"

        let defaultLibrary = device.makeDefaultLibrary()!
        let vertexProgram = defaultLibrary.makeFunction(name: "passThroughVertex")!
        let fragmentProgram = defaultLibrary.makeFunction(name: "gameBoyPixelFragment")!

        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        pipelineStateDescriptor.sampleCount = view.sampleCount

        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }

        // Create a triangle large enough to cover screen
        let vertexData:[Float] = [-5, -5, 0, 1, -5, 5, 0, 1, 5, 0, 0, 1]
        vertexBuffer = device.makeBuffer(bytes: vertexData, length: vertexData.count * MemoryLayout<Float>.size, options: [])
        vertexBuffer.label = "vertices"

        // All work is done in fragment shader based on screen position
        graphicsRAMBuffer = device.makeBuffer(bytesNoCopy: gameBoy.memory.videoRAM.pointer, length: gameBoy.memory.videoRAM.bytes, options: [], deallocator: nil)
        graphicsRAMBuffer.label = "graphics ram"

        graphicsOAMBuffer = device.makeBuffer(bytesNoCopy: gameBoy.memory.objectAttributeMemory.pointer, length: gameBoy.memory.objectAttributeMemory.bytes, options: [], deallocator: nil)
        graphicsOAMBuffer.label = "graphics oam"

        graphicsSpriteOrderBuffer = device.makeBuffer(bytesNoCopy: gameBoy.gpu.spritePriorityOrder.pointer, length: gameBoy.gpu.spritePriorityOrder.bytes, options: [], deallocator: nil)
        graphicsOAMBuffer.label = "graphics sprite order"

        graphicsAttributesBuffer = device.makeBuffer(bytesNoCopy: gameBoy.gpu.lineAttributes.pointer, length: gameBoy.gpu.lineAttributes.bytes, options: [], deallocator: nil)
        graphicsAttributesBuffer.label = "graphics line attributes"
    }

    func update() {
        if !gameBoy.stop {
            gameBoy.advanceFrame()
        }
    }

    func draw(in view: MTKView) {
        if running {
            self.update()
        }

        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Frame command buffer"

        if let renderPassDescriptor = view.currentRenderPassDescriptor,
            let currentDrawable = view.currentDrawable
        {
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "render encoder"

            renderEncoder?.setRenderPipelineState(pipelineState)

            renderEncoder?.setFragmentBuffer(graphicsRAMBuffer, offset: 0, index: 0)
            renderEncoder?.setFragmentBuffer(graphicsOAMBuffer, offset: 0, index: 1)
            renderEncoder?.setFragmentBuffer(graphicsSpriteOrderBuffer, offset: 0, index: 2)
            renderEncoder?.setFragmentBuffer(graphicsAttributesBuffer, offset: 0, index: 3)
            renderEncoder?.setFragmentBytes(&gameBoy.stop, length: 1, index: 4)


            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)

            renderEncoder?.endEncoding()

            commandBuffer?.present(currentDrawable)
        }

        commandBuffer?.commit()
    }

    @IBAction func toggleBIOS(_ sender: NSMenuItem) {
        if sender.state == .off {
            sender.state = .on
            gameBoy.skipBIOS = true
        } else {
            sender.state = .off
            gameBoy.skipBIOS = false
        }
    }

    @IBAction func pause(_ sender: NSMenuItem) {
        running = !running
    }

    @IBAction func restart(_ sender: NSMenuItem) {
        gameBoy.reset()
        running = true
    }

    public func openFile(_ path: String) -> Bool {
        if let data = NSData(contentsOfFile: path) as Data? {
            gameBoy.loadCartridge(withData: data)
            return true
        }
        return false
    }

    @IBAction func openDocument(_ sender: Any?) {
        let wasRunning = running
        running = false

        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == NSApplication.ModalResponse.OK,
            let url = panel.url
        {
            print("Loading file \"\(url.lastPathComponent)\"")
            if openFile(url.path) {
                NSDocumentController.shared.noteNewRecentDocumentURL(url)
                running = true
            } else {
                running = wasRunning
            }
        } else {
            running = wasRunning
        }
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {

    }
}


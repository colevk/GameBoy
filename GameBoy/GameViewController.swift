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
    var memory: Memory! = nil
    var cpu: CPU! = nil
    var gpu: GPU! = nil
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var pixelBuffer: MTLBuffer! = nil

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
        view.sampleCount = 4
        view.preferredFramesPerSecond = 60
        
        memory = Memory()
        cpu = CPU(withMemory: memory)
        memory.cpu = cpu
        gpu = GPU(withMemory: memory)
        memory.gpu = gpu
        
        loadAssets()
    }
    
    func loadAssets() {
        
        // load any resources required for rendering
        let view = self.view as! MTKView
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main command queue"
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "passThroughFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "passThroughVertex")!
        
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
        pixelBuffer = device.makeBuffer(bytesNoCopy: gpu.screen.pointer, length: gpu.screen.count, options: [], deallocator: nil)
        pixelBuffer.label = "pixels"
    }
    
    func update() {
        for _ in 0..<154 {
            let startTimer = cpu.timer - (cpu.timer % 114)
            while cpu.timer - startTimer < 20 {
                cpu.step()
            }
            while cpu.timer - startTimer < 63 {
                cpu.step()
            }
            gpu.renderLine()
            while cpu.timer - startTimer < 114 {
                cpu.step()
            }
        }
}
    
    func draw(in view: MTKView) {
        self.update()
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Frame command buffer"

        if let renderPassDescriptor = view.currentRenderPassDescriptor,
           let currentDrawable = view.currentDrawable
        {
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "render encoder"

            renderEncoder?.setRenderPipelineState(pipelineState)
            renderEncoder?.setFragmentBuffer(pixelBuffer, offset: 0, index: 0)
            
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            
            renderEncoder?.endEncoding()

            commandBuffer?.present(currentDrawable)
        }

        commandBuffer?.commit()
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}

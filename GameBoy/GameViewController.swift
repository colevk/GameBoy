//
//  GameViewController.swift
//  GameBoy
//
//  Created by Cole van Krieken on 7/14/17.
//  Copyright (c) 2017 Cole van Krieken. All rights reserved.
//

import Cocoa
import MetalKit

let MaxBuffers = 3
let ConstantBufferSize = 1024*1024

let vertexData:[Float] =
[
    -5.0, -5.0, 0.0, 1.0,
    -5.0,  5.0, 0.0, 1.0,
    5.0, 0, 0.0, 1.0,
    
    1.0, -1.0, 0.0, 1.0,
    -1.0,  1.0, 0.0, 1.0,
    1.0,  1.0, 0.0, 1.0,
    
    -0.0, 0.25, 0.0, 1.0,
    -0.25, -0.25, 0.0, 1.0,
    0.25, -0.25, 0.0, 1.0
]

class GameViewController: NSViewController, MTKViewDelegate {
    var memory: Memory! = nil
    var cpu: CPU! = nil
    var gpu: GPU! = nil
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var vertexColorBuffer: MTLBuffer! = nil
    var pixelBuffer: MTLBuffer! = nil
    
    let inflightSemaphore = DispatchSemaphore(value: MaxBuffers)
    var bufferIndex = 0
    
    // offsets used in animation
    var xOffset:[Float] = [ -1.0, 1.0, -1.0 ]
    var yOffset:[Float] = [ 1.0, 0.0, -1.0 ]
    var xDelta:[Float] = [ 0.002, -0.001, 0.003 ]
    var yDelta:[Float] = [ 0.001,  0.002, -0.001 ]

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
        gpu = GPU(withMemory: memory)
        
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
        
        // generate a large enough buffer to allow streaming vertices for 3 semaphore controlled frames
        vertexBuffer = device.makeBuffer(length: vertexData.count * MemoryLayout<Float>.size, options: [])
        vertexBuffer.label = "vertices"
        
        pixelBuffer = device.makeBuffer(bytes: gpu.screen, length: gpu.screen.count, options: [])
        pixelBuffer.label = "pixels"
    }
    
    func update() {
        for line: UInt8 in 0..<154 {
            let startTimer = cpu.timer - (cpu.timer % 114)
            while cpu.timer - startTimer < 154 {
                cpu.step()
            }
            memory.bytes[0xFF44] = line
            gpu.renderLine()
        }
        
        
        // vData is pointer to the MTLBuffer's Float data contents
        let pData = vertexBuffer.contents()
        let capacity = 256 / MemoryLayout<Float>.size
        let vData = UnsafeMutableBufferPointer<Float>(start: (pData + 256 * bufferIndex).bindMemory(to: Float.self, capacity:capacity ), count: capacity)

        // reset the vertices to default before adding animated offsets
        _ = vData.initialize(from: vertexData)

        // Animate triangle offsets
        let lastTriVertex = 24
        let vertexSize = 4
        for j in 0..<3 {
            // update the animation offsets
            xOffset[j] += xDelta[j]

            if(xOffset[j] >= 1.0 || xOffset[j] <= -1.0) {
                xDelta[j] = -xDelta[j]
                xOffset[j] += xDelta[j]
            }

            yOffset[j] += yDelta[j]

            if(yOffset[j] >= 1.0 || yOffset[j] <= -1.0) {
                yDelta[j] = -yDelta[j]
                yOffset[j] += yDelta[j]
            }

            // Update last triangle position with updated animated offsets
            let pos = lastTriVertex + j*vertexSize
            vData[pos] = xOffset[j]
            vData[pos+1] = yOffset[j]
        }
    }
    
    func draw(in view: MTKView) {
        
        // use semaphore to encode 3 frames ahead
        let _ = inflightSemaphore.wait(timeout: DispatchTime.distantFuture)
        
        self.update()
        
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "Frame command buffer"

        // use completion handler to signal the semaphore when this frame is completed allowing the encoding of the next frame to proceed
        // use capture list to avoid any retain cycles if the command buffer gets retained anywhere besides this stack frame
        commandBuffer?.addCompletedHandler{ [weak self] commandBuffer in
            if let strongSelf = self {
                strongSelf.inflightSemaphore.signal()
            }
            return
        }

        if let renderPassDescriptor = view.currentRenderPassDescriptor,
           let currentDrawable = view.currentDrawable
        {
            let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
            renderEncoder?.label = "render encoder"

            renderEncoder?.pushDebugGroup("draw morphing triangle")
            renderEncoder?.setRenderPipelineState(pipelineState)
            renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder?.setFragmentBuffer(pixelBuffer, offset: 0, index: 0)
            renderEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1)
            
            renderEncoder?.popDebugGroup()
            renderEncoder?.endEncoding()

            commandBuffer?.present(currentDrawable)
        }

        // bufferIndex matches the current semaphore controled frame index to ensure writing occurs at the correct region in the vertex buffer
        bufferIndex = (bufferIndex + 1) % MaxBuffers

        commandBuffer?.commit()
    }
    
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
}

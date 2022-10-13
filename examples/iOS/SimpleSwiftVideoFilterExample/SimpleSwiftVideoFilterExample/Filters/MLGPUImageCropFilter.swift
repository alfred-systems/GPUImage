//
//  GPUImageCropFilter+mantal.swift
//  alfred
//
//  Created by Hongten Ko on 2022/10/5.
//  Copyright © 2022 Alfred Labs Inc. All rights reserved.
//

import UIKit
import Metal
import GPUImage

// swiftlint:disable all

struct Vertex {
    var position: vector_float4
    var texCoords: packed_float2
}

class MLGPUImageCropFilter: GPUImageFilter {

    var commandQueue: MTLCommandQueue?
    var rps: MTLRenderPipelineState?
    var vertexData: [Vertex]?
    var vertexBuffer: MTLBuffer?
    var firstInputFramebuffer: GPUImageFramebuffer?
    var renderPassDescriptor: MTLRenderPassDescriptor?

    override func setInputFramebuffer(_ newInputFramebuffer: GPUImageFramebuffer!, at textureIndex: Int) {
        firstInputFramebuffer = newInputFramebuffer
        firstInputFramebuffer?.lock()
    }

    override func newFrameReady(at frameTime: CMTime, at textureIndex: Int) {
        self.drawTo()
        self.firstInputFramebuffer?.unlock()
    }

    @objc
    func doinit() {
        let device = GPUImageContext.sharedImageProcessing().metalDevice
        commandQueue = device?.makeCommandQueue()

        let vertexData = [Vertex(position: [-1.0, -1.0, 0.0, 1.0], texCoords: [0.0, 1.0]),
                          Vertex(position: [-1.0,  1.0, 0.0, 1.0], texCoords: [0.0, 0.0]),
                          Vertex(position: [ 1.0, -1.0, 0.0, 1.0], texCoords: [1.0, 1.0]),
                          Vertex(position: [ 1.0, -1.0, 0.0, 1.0], texCoords: [1.0, 1.0]),
                          Vertex(position: [-1.0,  1.0, 0.0, 1.0], texCoords: [0.0, 0.0]),
                          Vertex(position: [ 1.0,  1.0, 0.0, 1.0], texCoords: [1.0, 0.0])]

        let dataSize = 6 * MemoryLayout<Vertex>.stride
        vertexBuffer = device!.makeBuffer(bytes: vertexData, length: dataSize, options: [])
        self.vertexData = vertexData
        let library = device!.makeDefaultLibrary()!
        let vertex_func = library.makeFunction(name: "vertex_func")
        let frag_func = library.makeFunction(name: "fragment_func")
        let rpld = MTLRenderPipelineDescriptor()
        rpld.vertexFunction = vertex_func
        rpld.fragmentFunction = frag_func
        rpld.colorAttachments[0].pixelFormat = .rgba8Unorm
        do {
            try rps = device!.makeRenderPipelineState(descriptor: rpld)
        } catch let error {
            print("\(error)")
//            self.printView("\(error)")
        }

        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 1, blue: 0, alpha: 1)
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].storeAction = .store
            //rgba8Uint
        self.renderPassDescriptor = renderPassDescriptor
    }

    @objc
    func drawTo() {
        guard let firstInputFramebuffer = firstInputFramebuffer else {
            return
        }
        if let rpd = self.renderPassDescriptor, let rps = rps {
            rpd.colorAttachments[0].texture = firstInputFramebuffer.metalTexture;
            let commandBuffer = commandQueue!.makeCommandBuffer()
            let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: rpd)
            commandEncoder?.label = "test"
            commandEncoder?.pushDebugGroup("DrawMesh")
            commandEncoder?.setRenderPipelineState(rps)
            commandEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            commandEncoder?.setFragmentTexture(firstInputFramebuffer.metalTexture, index: 0)
            commandEncoder?.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
            commandEncoder?.popDebugGroup()
            commandEncoder?.endEncoding()
            commandBuffer?.commit()
        }
    }
}

//
//  VideoProcessor+Filters.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/04.
//

import AVFoundation
import MetalPerformanceShaders
import CoreImage

protocol MetalVideoFilter {
    
    func process(commandBuffer: MTLCommandBuffer,
                 sourceTexture: MTLTexture,
                 destinationTexture: MTLTexture,
                 at time: CMTime) throws
}

enum MetalVideoFilters {}

extension MetalVideoFilters {
    
    struct ComputeKernelFilter: MetalVideoFilter {
        
        var computePipelineState: MTLComputePipelineState
        
        func process(commandBuffer: MTLCommandBuffer,
                     sourceTexture: MTLTexture,
                     destinationTexture: MTLTexture,
                     at time: CMTime) throws {

            guard let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
                return
            }
            
            commandEncoder.setComputePipelineState(computePipelineState)
            commandEncoder.setTexture(sourceTexture, index: 0)
            commandEncoder.setTexture(destinationTexture, index: 1)
            
            let width = computePipelineState.threadExecutionWidth
            let height = computePipelineState.maxTotalThreadsPerThreadgroup / width
            let threadsPerThreadgroup = MTLSize(width: width, height: height, depth: 1)
            
            let gridSize = MTLSize(width: sourceTexture.width, height: sourceTexture.height, depth: 1)
            
            var time = Float(time.seconds)
            commandEncoder.setBytes(&time, length: MemoryLayout<Float>.stride, index: 0)
            
            commandEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadsPerThreadgroup)
            commandEncoder.endEncoding()
        }
    }
    
    struct GaussianBlurFilter: MetalVideoFilter {
        
        var device: MTLDevice
        
        func process(commandBuffer: MTLCommandBuffer,
                     sourceTexture: MTLTexture,
                     destinationTexture: MTLTexture,
                     at time: CMTime) throws {
            
            let filter = MPSImageGaussianBlur(device: device, sigma: 10.0)
            filter.edgeMode = .clamp
            
            filter.encode(commandBuffer: commandBuffer,
                          sourceTexture: sourceTexture,
                          destinationTexture: destinationTexture)
        }
    }
}

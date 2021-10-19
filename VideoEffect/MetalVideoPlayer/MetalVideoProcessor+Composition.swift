//
//  MetalVideoProcessor+Compositor.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/30.
//

import AVFoundation

extension MetalVideoProcessor {
    
    final class Compositor: NSObject, AVVideoCompositing {
        
        private let lock = NSLock()
        
        private var pendingRequests = Set<AVAsynchronousVideoCompositionRequest>()
        
        let sourcePixelBufferAttributes: [String : Any]? = [
            kCVPixelBufferPixelFormatTypeKey as String: [
                kCVPixelFormatType_32BGRA,
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            ]
        ]
        
        let requiredPixelBufferAttributesForRenderContext: [String : Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        
        func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext) {
            
        }
        
        func startRequest(_ asyncVideoCompositionRequest: AVAsynchronousVideoCompositionRequest) {
            
            guard let instruction = asyncVideoCompositionRequest.videoCompositionInstruction as? Instruction else {
                fatalError("Unsupported instruction type.")
            }
            
            instruction.completionHandler = { [weak self, weak asyncVideoCompositionRequest] in
                guard let self = self,
                      let request = asyncVideoCompositionRequest else {
                     return
                }
                self.lock.lock()
                self.pendingRequests.remove(request)
                self.lock.unlock()
            }
            
            self.lock.lock()
            self.pendingRequests.insert(asyncVideoCompositionRequest)
            self.lock.unlock()
            
            instruction.handleRequest(asyncVideoCompositionRequest)
        }
        
        func cancelAllPendingVideoCompositionRequests() {
            self.lock.lock()
            self.pendingRequests.forEach { $0.finishCancelledRequest() }
            self.pendingRequests.removeAll(keepingCapacity: true)
            self.lock.unlock()
        }
    }
}

extension MetalVideoProcessor {
    
    final class Instruction: NSObject, AVVideoCompositionInstructionProtocol {
        
        typealias Handler = (AVAsynchronousVideoCompositionRequest) throws -> Void
        
        let timeRange: CMTimeRange
        
        let enablePostProcessing: Bool = false
        
        var containsTweening: Bool = true
        
        var requiredSourceTrackIDs: [NSValue]? = nil
        
        var passthroughTrackID: CMPersistentTrackID = kCMPersistentTrackID_Invalid
        
        var filter: MetalVideoFilter?
        
        var completionHandler: (() -> Void)?
        
        private let handler: Handler
        
        init(timeRange: CMTimeRange,
             filter: MetalVideoFilter?,
             handler: @escaping Handler) {
            
            self.timeRange = timeRange
            self.filter = filter
            self.handler = handler
        }
        
        func handleRequest(_ request: AVAsynchronousVideoCompositionRequest)  {
            
            do {
                try handler(request)
            } catch {
                request.finish(with: error)
            }
            
            completionHandler?()
        }
    }
}

//
//  MetalVideoProcessor+CIHelper.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/10/08.
//

import CoreImage
import CoreMedia

struct AnyCoreImageVideoFilter {
    
    var context: CIContext
    
    var handler: (CIImage, CMTime) throws -> CIImage
    
    func process(sourcePixelBuffer: CVPixelBuffer,
                 destinationPixelBuffer: CVPixelBuffer,
                 at time: CMTime) throws {
        
        let sourceImage = CIImage(cvPixelBuffer: sourcePixelBuffer)
        
        let destination = CIRenderDestination(pixelBuffer: destinationPixelBuffer)
        
        let image = try self.handler(sourceImage, time)
        
        let task = try context.startTask(toRender: image, to: destination)
        
        try task.waitUntilCompleted()
    }
}

extension CIImage {
    
    func moved(to point: CGPoint) -> CIImage {
        
        let delta: CGPoint = CGPoint(x: point.x - extent.origin.x,
                                     y: point.y - extent.origin.y)
        
        return self.transformed(by: CGAffineTransform(translationX: delta.x, y: delta.y))
    }
    
    func verticallyFlipped() -> CIImage {
        
        return self
            .transformed(by: .init(scaleX: 1, y: -1))
            .moved(to: .zero)
    }
}

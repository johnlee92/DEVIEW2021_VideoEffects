//
//  CoreImageFilter.swift
//  VideoEffect
//
//  Created by 이재현 on 2021/09/27.
//

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreMedia

protocol CoreImageVideoFilter {
   
   func process(image: CIImage, at time: CMTime) throws -> CIImage
}

enum CoreImageVideoFilters {}

extension CoreImageVideoFilters {
    
    struct GaussianBlurFilter: CoreImageVideoFilter {
        
        var radius: Float = 8.0
        
        func process(image: CIImage, at time: CMTime) throws -> CIImage {
            
            let blurFilter = CIFilter.gaussianBlur()
            
            blurFilter.radius = radius
            blurFilter.inputImage = image.clampedToExtent()
            
            return blurFilter.outputImage?.cropped(to: image.extent) ?? image
        }
    }
    
    struct GrayscaleColorFilter: CoreImageVideoFilter {
        
        func process(image: CIImage, at time: CMTime) throws -> CIImage {
            
            let colorControlsFilter = CIFilter.colorControls()
            
            colorControlsFilter.saturation = 0
            
            colorControlsFilter.inputImage = image
            
            return colorControlsFilter.outputImage ?? image
        }
    }
    
    struct InvertColorFilter: CoreImageVideoFilter {
        
        func process(image: CIImage, at time: CMTime) throws -> CIImage {
            
            let invertFilter = CIFilter.colorInvert()
            
            invertFilter.inputImage = image
            
            return invertFilter.outputImage ?? image
        }
    }
}

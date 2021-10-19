//
//  Shaders.metal
//  VideoEffect
//
//  Created by 이재현 on 2021/09/24.
//

#include <metal_stdlib>
using namespace metal;

constant half3 kRec709LumaCoefficients = half3(0.2126, 0.7152, 0.0722);

kernel void grayscaleAnimationFilter(texture2d<half, access::read> inputTexture [[texture(0)]],
                                     texture2d<half, access::write> outputTexture [[texture(1)]],
                                     constant float &time [[buffer(0)]],
                                     uint2 gid [[thread_position_in_grid]])
{
    const half4 inputColor = inputTexture.read(gid);
    
    // Luminance
    const half luminanceColor = dot(inputColor.rgb, kRec709LumaCoefficients);
    
    const auto ramp = sin(time * 2.0) * 0.5 + 0.5;
    
    const half4 outputColor = mix(inputColor, luminanceColor, ramp);
    
    outputTexture.write(outputColor, gid);
}

kernel void pixellateAnimationFilter(texture2d<half, access::read> inputTexture [[texture(0)]],
                                     texture2d<half, access::write> outputTexture [[texture(1)]],
                                     constant float &time [[buffer(0)]],
                                     uint2 gid [[thread_position_in_grid]])
{
    const auto ramp = sin(time * 2.0) * 0.5 + 0.5;
    
    const int pixelSize = max(1, int(ramp * 64.0));
    
    const auto pixelGid = uint2((gid.x / pixelSize) * pixelSize, (gid.y / pixelSize) * pixelSize);
    
    const half4 pixelColor = inputTexture.read(pixelGid);
    
    outputTexture.write(pixelColor, gid);
}

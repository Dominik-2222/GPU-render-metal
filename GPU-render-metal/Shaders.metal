//
//  Shaders.metal
//  GPU-render-metal
//
//  Created by MotionVFX on 26/02/2024.
//

// File for Metal kernel and shader functions

#include <metal_stdlib>
#include <simd/simd.h>

// Including header shared between this Metal shader code and Swift/C code executing Metal API commands
#import "ShaderTypes.h"
/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Metal vertex and fragment shaders.
*/

using namespace metal;



#pragma mark -

#pragma mark - Shaders for simple pipeline used to render triangle to renderable texture

// Vertex shader outputs and fragment shader inputs for simple pipeline
struct SimplePipelineRasterizerData
{
    float4 position [[position]];
    float4 color;
    float2 pos;
};

// Vertex shader which passes position and color through to rasterizer.
vertex SimplePipelineRasterizerData
simpleVertexShader(const uint vertexID [[ vertex_id ]],
                   const device AAPLSimpleVertex *vertices [[ buffer(AAPLVertexInputIndexVertices) ]])
{
    SimplePipelineRasterizerData out;

    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);
    out.position.xy = vertices[vertexID].position.xy;

    out.color = vertices[vertexID].color;
    out.pos=vertices[vertexID].position.xy;
    return out;
}

// Fragment shader that just outputs color passed from rasterizer.
fragment float4 simpleFragmentShader2(SimplePipelineRasterizerData in [[stage_in]])
{
    return in.color;
}
fragment float4 simpleFragmentShader(SimplePipelineRasterizerData in [[stage_in]])
{
   

        float2 pos = in.pos.xy;
        pos.x *= 8.0;
        pos.y *= 8.0;

       // float2 rotatedPos = float2(pos.y, pos.x);
    
    float2 gridPos = floor(pos);
    
 float  checker=0.5;
    
    
    for(float end_y=3.0, end_x=-3.0;end_y>-3.0;end_y--, end_x++){
        float i=-end_x;
        while (i<end_x){
            if(pos.x>(end_x+i) && pos.y>end_y){
                checker = step(0.0, fmod(-gridPos.y - gridPos.x,2.0));//prawa gora
                
            }else{
                checker = step(0.0, fmod(gridPos.y + gridPos.x,2.0));//lewa dol
                
            }
            i++;
            
        }
            
     
    }
    
     
    
    //checker = step(0.0, fmod(gridPos.y - gridPos.x,2.0));//prawa dol
   // checker = step(0.0, fmod(gridPos.x - gridPos.y,2.0));//lewa gora
    
    

    //}
        
         
   
     
        return float4(checker, checker, checker, 1.0);

}

#pragma mark -

#pragma mark Shaders for pipeline used texture from renderable texture when rendering to the drawable.

// Vertex shader outputs and fragment shader inputs for texturing pipeline.
struct TexturePipelineRasterizerData
{
    float4 position [[position]];
    float2 texcoord;
};

// Vertex shader which adjusts positions by an aspect ratio and passes texture
// coordinates through to the rasterizer.
vertex TexturePipelineRasterizerData
textureVertexShader(const uint vertexID [[ vertex_id ]],
                    const device AAPLTextureVertex *vertices [[ buffer(AAPLVertexInputIndexVertices) ]],
                    constant float &aspectRatio [[ buffer(AAPLVertexInputIndexAspectRatio) ]])
{
    TexturePipelineRasterizerData out;

    out.position = vector_float4(0.0, 0.0, 0.0, 1.0);

    out.position.x = vertices[vertexID].position.x * aspectRatio;
    out.position.y = vertices[vertexID].position.y;

    out.texcoord = vertices[vertexID].texcoord;

    return out;
}
// Fragment shader that samples a texture and outputs the sampled color.
fragment float4 textureFragmentShader(TexturePipelineRasterizerData in      [[stage_in]],
                                      texture2d<float>              colorMap [[texture(AAPLTextureInputIndexColor)]])
{
    sampler simpleSampler;

    // Sample data from the texture.
    float4 colorSample = colorMap.sample(simpleSampler, in.texcoord);

    // Return the color sample as the final color.
    return colorSample;
}

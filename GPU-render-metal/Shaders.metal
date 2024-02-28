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
fragment float4 simpleFragmentShader(SimplePipelineRasterizerData in [[stage_in]])
{
    return in.color;
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
fragment float4 chess_board_generator(SimplePipelineRasterizerData in [[stage_in]])
{
    float l_kol=8.0;
    float  checker=step(0.0,sin(2*M_PI_2_F*l_kol*in.pos.x)*sin(2*M_PI_2_F*l_kol*in.pos.y));
        return float4(checker, checker, checker, 1.0);
}
float4 gauss2x(texture2d<float> colorMap,  sampler colorSampler,TexturePipelineRasterizerData in){
    
    float radius;
    float weightsum=0.0;
    float sigma =15.0;
    radius=3*sigma;
    float4 col=0.0;
    float y=-radius;
    for(float x=-radius;x<=radius;x++){
        float exponent = exp(-(x*x)/(2.0*sigma*sigma));
        weightsum+=exponent;
        float2 offset=float2(x/colorMap.get_width(),y/colorMap.get_width());
        float4 sample = colorMap.sample(colorSampler,in.position.xy+offset);
        col+= sample.rgba *exponent;
        
    }
    
    col/=weightsum;
    return col;
    
    
}

float4 gauss2y(texture2d<float> colorMap,  sampler colorSampler,TexturePipelineRasterizerData in){
    
    float radius;
    float weightsum=0.0;
    float sigma =15.0;
    radius=3*sigma;
    float4 col=0.0;
    float x=-radius;
    for(float y=-radius;y<=radius;y++){
        float exponent = exp(-(x*x)/(2.0*sigma*sigma));
        weightsum+=exponent;
        float2 offset=float2(x/colorMap.get_width(),y/colorMap.get_width());
        float4 sample = colorMap.sample(colorSampler,in.position.xy+offset);
        col+= sample.rgba *exponent;
        
    }
    col/=weightsum;
    return col;
}


fragment float4 textureFragmentShader(TexturePipelineRasterizerData in      [[stage_in]],
                                      texture2d<float>              colorMap [[texture(AAPLTextureInputIndexColor)]])
{
    sampler simpleSampler;

    // Sample data from the texture.
    float4 colorSample = colorMap.sample(simpleSampler, in.texcoord);
   // colorSample=  gauss2x( colorMap, simpleSampler, in);
    // Return the color sample as the final color.
    return colorSample;
}

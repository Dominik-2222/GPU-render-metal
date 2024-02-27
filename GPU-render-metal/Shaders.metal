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

using namespace metal;

typedef struct
{
    float3 position [[attribute(VertexAttributePosition)]];
    float2 texCoord [[attribute(VertexAttributeTexcoord)]];
} Vertex;

typedef struct
{
    float4 position [[position]];
    float2 texCoord;
} ColorInOut;

//funkcje--------------filtry

half4 grayscale(half4 colorSmaple){

   half gray2 = colorSmaple.r *  0.21 + colorSmaple.g *  0.71 + colorSmaple.b *  0.07;
    colorSmaple.r=gray2;
    colorSmaple.g=gray2;
    colorSmaple.b=gray2;
   
    return colorSmaple;
   
}
half4 negative(half4 colorSmaple2){

    colorSmaple2.r=(1-colorSmaple2.r);
    colorSmaple2.g=(1-colorSmaple2.g);
    colorSmaple2.b=(1-colorSmaple2.b);
   
    return colorSmaple2;
   
}

vertex ColorInOut vertexShader(Vertex in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]])
{
    ColorInOut out;

    float4 position = float4(in.position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * position;
    out.texCoord = in.texCoord;

    return out;
}


half4 gauss(texture2d<half> colorMap,  sampler colorSampler,ColorInOut in){
    
    float radius;
    float weightsum=0.0;
    float sigma =15.0;
    radius=3*sigma;
    half4 col=0.0;
    for(float y=-radius;y<=radius;y++){
        for(float x=-radius;x<=radius;x++){
            float exponent = exp(-(x*x+y*y)/(2.0*sigma*sigma));
            weightsum+=exponent;
            float2 offset=float2(x/colorMap.get_width(),y/colorMap.get_height());
            half4 sample = colorMap.sample(colorSampler,in.texCoord.xy+offset);
            col+= sample.rgba *exponent;
            
        }
    }
    col/=weightsum;
    return col;
}
half4 gauss2x(texture2d<half> colorMap,  sampler colorSampler,ColorInOut in){
    
    float radius;
    float weightsum=0.0;
    float sigma =15.0;
    radius=3*sigma;
    half4 col=0.0;
    float y=-radius;
    for(float x=-radius;x<=radius;x++){
        float exponent = exp(-(x*x)/(2.0*sigma*sigma));
        weightsum+=exponent;
        float2 offset=float2(x/colorMap.get_width(),y/colorMap.get_width());
        half4 sample = colorMap.sample(colorSampler,in.texCoord.xy+offset);
        col+= sample.rgba *exponent;
        
    }
    
    col/=weightsum;
    return col;
    
    
}

half4 gauss2y(texture2d<half> colorMap,  sampler colorSampler,ColorInOut in){
    
    float radius;
    float weightsum=0.0;
    float sigma =15.0;
    radius=3*sigma;
    half4 col=0.0;
    float x=-radius;
    for(float y=-radius;y<=radius;y++){
        float exponent = exp(-(x*x)/(2.0*sigma*sigma));
        weightsum+=exponent;
        float2 offset=float2(x/colorMap.get_width(),y/colorMap.get_width());
        half4 sample = colorMap.sample(colorSampler,in.texCoord.xy+offset);
        col+= sample.rgba *exponent;
        
    }
    col/=weightsum;
    return col;
}



fragment float4 fragmentShader(ColorInOut in [[stage_in]],
                               constant Uniforms & uniforms [[ buffer(BufferIndexUniforms) ]],
                               texture2d<half> colorMap     [[ texture(TextureIndexColor) ]],
                               constant float &testValue[[buffer(3)]])
{
  
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);

    
    half4 colorSample = colorMap.sample(colorSampler, in.texCoord.xy) * testValue;

    //colorSample=grayscale(colorSample);//filtr szarosci
    //colorSample=negative(colorSample);//negatyw
   // colorSample=gauss( colorMap,   colorSampler, in);//gauss

  
        colorSample=gauss2x( colorMap,   colorSampler, in);//gauss 2 przebiegowy
 
        colorSample=gauss2y( colorMap,   colorSampler, in);//gauss 2 przebiegowy

   
    
    
    
    
    return float4(colorSample);
}



//
//  ShaderTypes.h
//  GPU-render-metal
//
//  Created by MotionVFX on 26/02/2024.
//

//
//  Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
//
#ifndef ShaderTypes_h
#define ShaderTypes_h
#ifdef __METAL_VERSION__
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
typedef metal::int32_t EnumBackingType;
#else
#import <Foundation/Foundation.h>
typedef NSInteger EnumBackingType;
#endif
#include <simd/simd.h>

typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices    = 0,
    AAPLVertexInputIndexAspectRatio = 1,
} AAPLVertexInputIndex;

typedef enum AAPLTextureInputIndex
{
    AAPLTextureInputIndexColor = 0,
} AAPLTextureInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float4 color;
} AAPLSimpleVertex;
typedef NS_ENUM(EnumBackingType, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
};
typedef struct
{
    vector_float2 position;
    vector_float2 texcoord;
} AAPLTextureVertex;

#endif /* ShaderTypes_h */


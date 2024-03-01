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
using namespace simd;

typedef enum AAPLVertexInputIndex
{
    AAPLVertexInputIndexVertices    = 0,
    AAPLVertexInputIndexAspectRatio = 1,
    Iterator=2,
    projectionMatrix=3
} AAPLVertexInputIndex;

typedef enum AAPLTextureInputIndex
{
    AAPLTextureInputIndexColor = 0,
} AAPLTextureInputIndex;

typedef struct
{
    float3 position;
    float4 color;
} AAPLSimpleVertex;
typedef NS_ENUM(EnumBackingType, VertexAttribute)
{
    VertexAttributePosition  = 0,
    VertexAttributeTexcoord  = 1,
};
typedef struct option{
    unsigned short gauss1przebieg;
    unsigned short gauss2przebieg;
    unsigned short kwase;
    bool gray_scale;
    bool negative;
}option;


typedef struct AAPLTextureVertex
{
    float2 position;
    float2 texcoord;
    float4 perpectiveMatrix;
} AAPLTextureVertex;
typedef struct AAPLTextureVertex3D
{
    float4 position;
    float2 texcoord;
    float4 perpectiveMatrix;
} AAPLTextureVertex3D;
//typedef struct TransformationData{
//    float4x4 modelMatrix;
//    float4x4 viewMatrix;
//    float4x4 perspectiveMatrix;
//}TransformationData;
#endif /* ShaderTypes_h */


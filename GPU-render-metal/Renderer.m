//
//  Renderer.m
//  GPU-render-metal
//
//  Created by MotionVFX on 26/02/2024.
//

#import <simd/simd.h>
#import <ModelIO/ModelIO.h>

#import "Renderer.h"

// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "ShaderTypes.h"

static const NSUInteger kMaxBuffersInFlight = 3;


@implementation Renderer
{
    // Texture to render to and then sample from.
    id<MTLTexture> _renderTargetTexture;
    id<MTLTexture> _renderTargetTexture2;

    id<MTLTexture> _renderTargetTexture3;

    // Render pass descriptor to draw to the texture
    MTLRenderPassDescriptor* _renderToTextureRenderPassDescriptor;
    MTLRenderPassDescriptor* _renderToTextureRenderPassDescriptor2;
    MTLRenderPassDescriptor* _renderToTextureRenderPassDescriptor3;

    // A pipeline object to render to the offscreen texture.
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline;
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline2;
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline3;

    // A pipeline object to render to the screen.
    id<MTLRenderPipelineState> _drawableRenderPipeline;
    id<MTLRenderPipelineState> _drawableRenderPipeline2;

    // Ratio of width to height to scale positions in the vertex shader.
    float _aspectRatio;

    id<MTLDevice> _device;

    id<MTLCommandQueue> _commandQueue;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
    self = [super init];
    if(self)
    {
        NSError *error;

        _device = mtkView.device;

        mtkView.clearColor = MTLClearColorMake(0.0, 1.0, 0.0, 1.0);

        _commandQueue = [_device newCommandQueue];

        // Set up a texture for rendering to and sampling from
        MTLTextureDescriptor *texDescriptor = [MTLTextureDescriptor new];
        texDescriptor.textureType = MTLTextureType2D;
        texDescriptor.width = 512;
        texDescriptor.height = 512;
        texDescriptor.pixelFormat = MTLPixelFormatRGBA8Unorm;
        texDescriptor.usage = MTLTextureUsageRenderTarget |
                              MTLTextureUsageShaderRead;
  

        _renderTargetTexture = [_device newTextureWithDescriptor:texDescriptor];
        _renderTargetTexture2 = [_device newTextureWithDescriptor:texDescriptor];
        _renderTargetTexture3 = [_device newTextureWithDescriptor:texDescriptor];

        // Set up a render pass descriptor for the render pass to render into
        // _renderTargetTexture.

        _renderToTextureRenderPassDescriptor = [MTLRenderPassDescriptor new];

        _renderToTextureRenderPassDescriptor.colorAttachments[0].texture = _renderTargetTexture;

        _renderToTextureRenderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderToTextureRenderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);

        _renderToTextureRenderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        _renderToTextureRenderPassDescriptor2 = [MTLRenderPassDescriptor new];

        _renderToTextureRenderPassDescriptor2.colorAttachments[0].texture = _renderTargetTexture2;

        _renderToTextureRenderPassDescriptor2.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderToTextureRenderPassDescriptor2.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
        _renderToTextureRenderPassDescriptor2.colorAttachments[0].storeAction = MTLStoreActionStore;

        _renderToTextureRenderPassDescriptor3 = [MTLRenderPassDescriptor new];

        _renderToTextureRenderPassDescriptor3.colorAttachments[0].texture = _renderTargetTexture3;

        _renderToTextureRenderPassDescriptor3.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderToTextureRenderPassDescriptor3.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 1, 1);
        _renderToTextureRenderPassDescriptor3.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];

        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Drawable Render Pipeline";
        pipelineStateDescriptor.rasterSampleCount = mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"textureVertexShader"];
        pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:@"textureFragmentShader2"];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.vertexBuffers[AAPLVertexInputIndexVertices].mutability = MTLMutabilityImmutable;
        _drawableRenderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_drawableRenderPipeline, @"Failed to create pipeline state to render to screen: %@", error);

        // Set up pipeline for rendering to the offscreen texture. Reuse the
        // descriptor and change properties that differ.
        pipelineStateDescriptor.label = @"Offscreen Render Pipeline";
        pipelineStateDescriptor.rasterSampleCount = 1;
        pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"simpleVertexShader"];
        pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:@"chess_board_generator"];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture2.pixelFormat;
        _renderToTextureRenderPipeline2 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_renderToTextureRenderPipeline2, @"Failed to create pipeline state to render to texture: %@", error);
        
        
        
        pipelineStateDescriptor.label = @"Offscreen Render Pipeline2";
        pipelineStateDescriptor.rasterSampleCount = 1;
        pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"simpleVertexShader"];
        pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:@"gaussx"];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture3.pixelFormat;
        _renderToTextureRenderPipeline3 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_renderToTextureRenderPipeline3, @"Failed to create pipeline state to render to texture: %@", error);
    }
    return self;
}

- (void)_loadMetalWithView:(nonnull MTKView *)view;
{


    
    
}

- (void)_loadAssets
{
}

- (void)_updateDynamicBufferState
{
    /// Update the state of our uniform buffers before rendering

}

- (void)_updateGameState
{

    
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Command Buffer";

    {
        static const AAPLSimpleVertex triVertices[] =
        {
            // Positions     ,  Colors
            { {  0.5,  -0.5 },  { 1.0, 0.0, 0.0, 1.0 } },//czerwony
            { { -0.5,  -0.5 },  { 0.0, 1.0, 0.0, 1.0 } },//zielony
            { {  0.5,   0.5 },  { 0.0, 0.0, 1.0, 1.0 } },//niebieski
            { {  -0.5,  0.5 },  { 1.0, 0.0, 0.0, 1.0 } },//czerwony
            { { 0.5,  0.5 },  { 0.0, 1.0, 0.0, 1.0 } },//zielony
            { {  -0.5,   -0.5 },  { 0.0, 0.0, 1.0, 1.0 } },//niebieski
        };

        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_renderToTextureRenderPassDescriptor2];
    renderEncoder.label = @"Offscreen Render Pass";
    [renderEncoder setRenderPipelineState:_renderToTextureRenderPipeline2];

    [renderEncoder setVertexBytes:&triVertices
                           length:sizeof(triVertices)
                          atIndex:AAPLVertexInputIndexVertices];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:6];

    // End encoding commands for this render pass.
    [renderEncoder endEncoding];
    
    }
    
//---- _renderTargetTexture
    
    //_renderTargetTexture -> _renderTargetTexture2;
   // [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:AAPLTextureInputIndexColor];

 
    
    //---------------------------
    MTLRenderPassDescriptor *drawableRenderPassDescriptor = view.currentRenderPassDescriptor;
    if(drawableRenderPassDescriptor != nil)
    {
        static const AAPLTextureVertex quadVertices[] =
        {
            // Positions     , Texture coordinates
            { {  1,  -1 },  { 1.0, 1.0 } },//trojkat arena 2
            { { -1,  -1 },  { 0.0, 1.0 } },
            { { -1,   1 },  { 0.0, 0.0 } },

            { {  1,  -1 },  { 1.0, 1.0 } },//trojkat arena 1
            { { -1,   1 },  { 0.0, 0.0 } },
            { {  1,   1 },  { 1.0, 0.0 } },
        };
        id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:drawableRenderPassDescriptor];
        renderEncoder.label = @"Drawable Render Pass";

        [renderEncoder setRenderPipelineState:_drawableRenderPipeline];

        [renderEncoder setVertexBytes:&quadVertices
                               length:sizeof(quadVertices)
                              atIndex:AAPLVertexInputIndexVertices];

        [renderEncoder setVertexBytes:&_aspectRatio
                               length:sizeof(_aspectRatio)
                              atIndex:AAPLVertexInputIndexAspectRatio];

        // Set the offscreen texture as the source texture.
        [renderEncoder setFragmentTexture:_renderTargetTexture2 atIndex:AAPLTextureInputIndexColor];

        // Draw quad with rendered texture.
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];

        [renderEncoder endEncoding];

    }
    
    [commandBuffer presentDrawable:view.currentDrawable];

    [commandBuffer commit];
}

#pragma mark - MetalKit View Delegate
- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _aspectRatio =  (float)size.height / (float)size.width;
}


@end

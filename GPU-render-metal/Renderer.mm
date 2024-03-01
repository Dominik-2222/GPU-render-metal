#import <simd/simd.h>
#import <ModelIO/ModelIO.h>
#import "Renderer.hpp"
// Include header shared between C code here, which executes Metal API commands, and .metal files
#import "ShaderTypes.hpp"
static const NSUInteger kMaxBuffersInFlight = 3;

@implementation Renderer
{
    // Texture to render to and then sample from.
    id<MTLTexture> _renderTargetTexture;
   // id<MTLTexture> _renderTargetTexture2;
    id<MTLTexture> _textureFromFile;
    
    // Render pass descriptor to draw to the texture
    MTLRenderPassDescriptor* _PassDescriptor_FBO;
    MTLRenderPassDescriptor* _PassDescriptor_second;
    
    // A pipeline object to render to the offscreen texture.
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline;
    id<MTLRenderPipelineState> _RenderPipeline_second;
    id<MTLRenderPipelineState> _RenderPipeline2;
    // A pipeline object to render to the screen.
    id<MTLRenderPipelineState> _drawableRenderPipeline;

    // Ratio of width to height to scale positions in the vertex shader.
    float _aspectRatio;

    id<MTLDevice> _device;
    
    id<MTLCommandQueue> _commandQueue;
    option option;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
#pragma mark select filter start
    
    option.gauss1przebieg=0;
    option.gauss2przebieg=0;
    option.gray_scale=0;
    option.kwase=1;
    option.negative=0;
    NSString* tekstur1=@"";
    NSString* tekstur2=@"";
    if(option.kwase>=1){
        tekstur1=@"kawase";
        tekstur2=@"kawase";
    }
    if(option.gauss2przebieg>=1){
        tekstur1=@"textureFragmentShader_gauss2_przebiegi";
        tekstur2=@"textureFragmentShader_gauss2_przebiegi";
    }
#pragma mark select filter end

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
      //  _renderTargetTexture2 = [_device newTextureWithDescriptor:texDescriptor];
    
        // Set up a render pass descriptor for the render pass to render into
        // _renderTargetTexture.

        _PassDescriptor_FBO = [MTLRenderPassDescriptor new];
        _PassDescriptor_FBO.colorAttachments[0].texture     = _renderTargetTexture;
        _PassDescriptor_FBO.colorAttachments[0].loadAction  = MTLLoadActionClear;
        _PassDescriptor_FBO.colorAttachments[0].clearColor  = MTLClearColorMake(0, 0, 0, 0);
        _PassDescriptor_FBO.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        _PassDescriptor_second = [MTLRenderPassDescriptor new];
        _PassDescriptor_second.colorAttachments[0].texture     = _renderTargetTexture;
        _PassDescriptor_second.colorAttachments[0].loadAction  = MTLLoadActionLoad;
        _PassDescriptor_second.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        #pragma.pipeline mark pipeline
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label                           = @"Drawable Render Pipeline";
        pipelineStateDescriptor.rasterSampleCount               = mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction                  =  [defaultLibrary newFunctionWithName:@"textureVertexShader"];
        pipelineStateDescriptor.fragmentFunction                =  [defaultLibrary newFunctionWithName:tekstur1];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.vertexBuffers[AAPLVertexInputIndexVertices].mutability = MTLMutabilityImmutable;
        _drawableRenderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_drawableRenderPipeline, @"Failed to create pipeline state to render to screen: %@", error);

        #pragma.pipeline mark pipeline 2
        pipelineStateDescriptor.label               = @"Offscreen Render Pipeline";
        pipelineStateDescriptor.rasterSampleCount   = 1;
        pipelineStateDescriptor.vertexFunction      = [defaultLibrary newFunctionWithName:@"textureVertexShader"];
        pipelineStateDescriptor.fragmentFunction    = [defaultLibrary newFunctionWithName:tekstur2];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture.pixelFormat;
        _RenderPipeline2 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_RenderPipeline2, @"Failed to create pipeline state to render to texture: %@", error);
        
        #pragma.pipeline mark chessboard generator
        pipelineStateDescriptor.label                = @"Offscreen Render Pipeline2";
        pipelineStateDescriptor.rasterSampleCount    = 1;
        pipelineStateDescriptor.vertexFunction       =  [defaultLibrary newFunctionWithName:@"simpleVertexShader"];
        pipelineStateDescriptor.fragmentFunction     =  [defaultLibrary newFunctionWithName:@"chess_board_generator"];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture.pixelFormat;
        _RenderPipeline_second = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_RenderPipeline_second, @"Failed to create pipeline state to render to texture: %@", error);
                
    }
    return self;
}

#pragma mark _load Assets

- (void)_loadAssets
{
//    NSError *error;
//    MTKTextureLoader* textureLoader = [[MTKTextureLoader alloc] initWithDevice:_device];
//
//    NSDictionary *textureLoaderOptions =
//    @{
//      MTKTextureLoaderOptionTextureUsage       : @(MTLTextureUsageShaderRead),
//      MTKTextureLoaderOptionTextureStorageMode : @(MTLStorageModePrivate)
//      };
//
//    _renderTargetTexture = [textureLoader newTextureWithName:@"new_texture"
//                                      scaleFactor:1.0
//                                           bundle:nil
//                                          options:textureLoaderOptions
//                                            error:&error];
//    NSURL *url = [NSURL fileURLWithPath:@"/Users/motionvfx/Documents/chessboard.png"];
//         MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:_device];
//         NSDictionary *options =
//         @{
//             MTKTextureLoaderOptionSRGB:                 @(false),
//             MTKTextureLoaderOptionGenerateMipmaps:      @(false),
//             MTKTextureLoaderOptionTextureUsage:         @(MTLTextureUsageShaderRead),
//             MTKTextureLoaderOptionTextureStorageMode:   @(MTLStorageModePrivate)
//         };
//         _textureFromFile = [loader newTextureWithContentsOfURL:url options:options error:nil];
//         if(!_textureFromFile)
//         {
//             NSLog(@"Failed to create the texture from %@", url.absoluteString);
//         }
}
matrix_float4x4 matrix_perspective_right_hand(float fovyRadians,
                                     float aspect, float nearZ,float farZ){
    float ys = 1 / tanf(fovyRadians * 0.5);
    float xs = ys / aspect;
    float zs = farZ / (nearZ - farZ);
    matrix_float4x4 table_perspective;
    table_perspective.columns[0].x = xs;
    table_perspective.columns[1].y = ys;
    table_perspective.columns[2].z = zs;
    table_perspective.columns[2].w = nearZ * zs;
    table_perspective.columns[3].z = -1;
    return table_perspective;
}

- (void)drawInMTKView:(nonnull MTKView *)view
{
    //pierwszy kwadrat
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    commandBuffer.label = @"Command Buffer";
    {//3D object
        {
            static const AAPLSimpleVertex triVertices[] =
            {
                // Positions     ,  Colors
                { {   1.0, -1.0 },  { 1.0, 0.0, 0.0, 1.0 } },//czerwony
                { {  -1.0, -1.0 },  { 0.0, 1.0, 0.0, 1.0 } },//zielony
                { {   1.0,  1.0 },  { 0.0, 0.0, 1.0, 1.0 } },//niebieski
                
//                { {  -1.0,  1.0 },  { 1.0, 0.0, 0.0, 1.0 } },//czerwony
//                { {   1.0,  1.0 },  { 0.0, 1.0, 0.0, 1.0 } },//zielony
//                { {  -1.0, -1.0 },  { 0.0, 0.0, 1.0, 1.0 } },//niebieski
           
                
            };
            
            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_PassDescriptor_FBO];
            renderEncoder.label = @"3D render texture";
            [renderEncoder setRenderPipelineState:_RenderPipeline_second];
            [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:0];
            [renderEncoder setVertexBytes:&triVertices
                                   length:sizeof(triVertices)
                                  atIndex:AAPLVertexInputIndexVertices];
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                              vertexStart:0
                              vertexCount:12];
            [renderEncoder endEncoding];
        }
        static const AAPLTextureVertex3D quadVertices[] =
        {
            // Positions     , Texture coordinates
            { {  0.5,  -0.5 ,1.0 ,1},  { 1.0, 1.0 } },//trojkat arena 2
            { { -0.5,  -0.5 ,1.0 ,1},  { 1.0, 1.0 } },
            { { -0.5,   0.5 ,1.0 ,1},  { 1.0, 1.0 } },
            //   x  ,     y  ,z   ,w
            { {  0.5,  -0.5 ,1.0 ,1},  { 1.0, 1.0 } },//trojkat arena 1
            { { 0.5,   0.5 ,1.0 ,1},  { 1.0, 1.0 } },
            { {  -0.5,  0.5 ,1.0 ,1},  { 1.0, 0.0 } },
            
            { {  0.5,  -0.5 ,0.0 ,1},  { 1.0, 1.0 } },//trojkat arena 2
            { { -0.5,  -0.5 ,0.0 ,1},  { 1.0, 1.0 } },
            { { -0.5,   0.5 ,0.0 ,1},  { 1.0, 1.0 } },
            //   x  ,     y  ,0.0 ,w
            { {  0.5,  -0.5 ,0.0 ,1},  { 1.0, 1.0 } },//trojkat arena 1
            { { 0.5,   0.5 , 0.0 ,1},  { 1.0, 1.0 } },
            { {  -0.5,  0.5 ,0.0 ,1},  { 1.0, 0.0 } },
        };
        id<MTLRenderCommandEncoder> renderEncoder =
        [commandBuffer renderCommandEncoderWithDescriptor:_PassDescriptor_second];
        renderEncoder.label = @"3D render view";
        [renderEncoder setRenderPipelineState:_RenderPipeline2];
        [renderEncoder setFragmentTexture:_renderTargetTexture
                                  atIndex:1];
        [renderEncoder setVertexBytes:&quadVertices
                               length:sizeof(quadVertices)
                              atIndex:AAPLVertexInputIndexVertices];
        
        [renderEncoder setVertexBytes:&_aspectRatio
                               length:sizeof(_aspectRatio)
                              atIndex:AAPLVertexInputIndexAspectRatio];
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:12];
        [renderEncoder endEncoding];
        
        MTLRenderPassDescriptor *drawableRenderPassDescriptor = view.currentRenderPassDescriptor;
        if(drawableRenderPassDescriptor != nil)
        {
            id<MTLRenderCommandEncoder> renderEncoder =
            [commandBuffer renderCommandEncoderWithDescriptor:drawableRenderPassDescriptor];
            renderEncoder.label = @"second render";
            [renderEncoder setRenderPipelineState:_drawableRenderPipeline];
            [renderEncoder setVertexBytes:&quadVertices
                                   length:sizeof(quadVertices)
                                  atIndex:AAPLVertexInputIndexVertices];
            
            [renderEncoder setVertexBytes:&_aspectRatio
                                   length:sizeof(_aspectRatio)
                                  atIndex:AAPLVertexInputIndexAspectRatio];
            // Set the offscreen texture as the source texture.
            [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:1];
            // Draw quad with rendered texture.
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                              vertexStart:0
                              vertexCount:6];
            [renderEncoder endEncoding];
        }
    }
    
//    {
//        {
//            static const AAPLSimpleVertex triVertices[] =
//            {
//                // Positions     ,  Colors
//                { {   1.0, -1.0 },  { 1.0, 0.0, 0.0, 1.0 } },//czerwony
//                { {  -1.0, -1.0 },  { 0.0, 1.0, 0.0, 1.0 } },//zielony
//                { {   1.0,  1.0 },  { 0.0, 0.0, 1.0, 1.0 } },//niebieski
//                
//                { {  -1.0,  1.0 },  { 1.0, 0.0, 0.0, 1.0 } },//czerwony
//                { {   1.0,  1.0 },  { 0.0, 1.0, 0.0, 1.0 } },//zielony
//                { {  -1.0, -1.0 },  { 0.0, 0.0, 1.0, 1.0 } },//niebieski
//              
//            };
//            
//            id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:_PassDescriptor_second];
//            renderEncoder.label = @"Offscreen Render Pass";
//            [renderEncoder setRenderPipelineState:_RenderPipeline_second];
//            [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:0];
//            [renderEncoder setVertexBytes:&triVertices
//                                   length:sizeof(triVertices)
//                                  atIndex:AAPLVertexInputIndexVertices];
//            
//            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
//                              vertexStart:0
//                              vertexCount:9];
//            [renderEncoder endEncoding];
//        }
//        static const AAPLTextureVertex quadVertices[] =
//        {
//            // Positions     , Texture coordinates
//            { {  1.0, -1.0 },  { 1.0, 1.0 } },//trojkat arena 2
//            { { -1.0, -1.0 },  { 0.0, 1.0 } },
//            { { -1.0,  1.0 },  { 0.0, 0.0 } },
//            
//            { {  1.0, -1.0 }, { 1.0, 1.0 } },//trojkat arena 1
//            { { -1.0,  1.0 }, { 0.0, 0.0 } },
//            { {  1.0,  1.0 }, { 1.0, 0.0 } },
//        };
//        id<MTLRenderCommandEncoder> renderEncoder =
//        [commandBuffer renderCommandEncoderWithDescriptor:_PassDescriptor_second];
//        renderEncoder.label = @"First render";
//        [renderEncoder setRenderPipelineState:_RenderPipeline2];
//        [renderEncoder setFragmentTexture:_renderTargetTexture
//                                  atIndex:1];
//        [renderEncoder setVertexBytes:&quadVertices
//                               length:sizeof(quadVertices)
//                              atIndex:AAPLVertexInputIndexVertices];
//        
//        [renderEncoder setVertexBytes:&_aspectRatio
//                               length:sizeof(_aspectRatio)
//                              atIndex:AAPLVertexInputIndexAspectRatio];
//        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
//                          vertexStart:0
//                          vertexCount:6];
//        [renderEncoder endEncoding];
//        
//        MTLRenderPassDescriptor *drawableRenderPassDescriptor = view.currentRenderPassDescriptor;
//        if(drawableRenderPassDescriptor != nil)
//        {
//            id<MTLRenderCommandEncoder> renderEncoder =
//            [commandBuffer renderCommandEncoderWithDescriptor:drawableRenderPassDescriptor];
//            renderEncoder.label = @"second render";
//            [renderEncoder setRenderPipelineState:_drawableRenderPipeline];
//            [renderEncoder setVertexBytes:&quadVertices
//                                   length:sizeof(quadVertices)
//                                  atIndex:AAPLVertexInputIndexVertices];
//            
//            [renderEncoder setVertexBytes:&_aspectRatio
//                                   length:sizeof(_aspectRatio)
//                                  atIndex:AAPLVertexInputIndexAspectRatio];
//            // Set the offscreen texture as the source texture.
//            [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:1];
//            // Draw quad with rendered texture.
//            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
//                              vertexStart:0
//                              vertexCount:6];
//            [renderEncoder endEncoding];
//        }
//    }
   
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _aspectRatio =  (float)size.height / (float)size.width;
}
@end

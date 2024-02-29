
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
   // id<MTLTexture> _renderTargetTexture2;
    id<MTLTexture> _textureFromFile;
    
    
    // Render pass descriptor to draw to the texture
    MTLRenderPassDescriptor* _renderToTextureRenderPassDescriptor_FBO;
    MTLRenderPassDescriptor* _renderToTextureRenderPassDescriptor_second;
    MTLRenderPassDescriptor* _renderToTextureRenderPassDescriptor3;
    
    // A pipeline object to render to the offscreen texture.
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline;
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline_second;
    id<MTLRenderPipelineState> _renderToTextureRenderPipeline2;
    
    
    // A pipeline object to render to the screen.
    id<MTLRenderPipelineState> _drawableRenderPipeline;

    
    // Ratio of width to height to scale positions in the vertex shader.
    float _aspectRatio;
    id<MTLDevice> _device;
    float kawase_iterator;
    id<MTLCommandQueue> _commandQueue;
    
    option option;
    
    
    
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView *)mtkView
{
#pragma mark select filter start
    
    option.gauss1przebieg=0;
    option.gauss2przebieg=10;
    option.gray_scale=0;
    option.kwase=0;
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

    kawase_iterator=6;
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

        _renderToTextureRenderPassDescriptor_FBO = [MTLRenderPassDescriptor new];
        _renderToTextureRenderPassDescriptor_FBO.colorAttachments[0].texture = _renderTargetTexture;
        _renderToTextureRenderPassDescriptor_FBO.colorAttachments[0].loadAction = MTLLoadActionClear;
        _renderToTextureRenderPassDescriptor_FBO.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0);
        _renderToTextureRenderPassDescriptor_FBO.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        _renderToTextureRenderPassDescriptor_second = [MTLRenderPassDescriptor new];
        _renderToTextureRenderPassDescriptor_second.colorAttachments[0].texture = _renderTargetTexture;
        _renderToTextureRenderPassDescriptor_second.colorAttachments[0].loadAction=MTLLoadActionLoad;
        _renderToTextureRenderPassDescriptor_second.colorAttachments[0].storeAction = MTLStoreActionStore;

        id<MTLLibrary> defaultLibrary = [_device newDefaultLibrary];
        #pragma.pipeline mark pipeline
        MTLRenderPipelineDescriptor *pipelineStateDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
        pipelineStateDescriptor.label = @"Drawable Render Pipeline";
        pipelineStateDescriptor.rasterSampleCount = mtkView.sampleCount;
        pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"textureVertexShader"];
        pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:tekstur1];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = mtkView.colorPixelFormat;
        pipelineStateDescriptor.vertexBuffers[AAPLVertexInputIndexVertices].mutability = MTLMutabilityImmutable;
        _drawableRenderPipeline = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_drawableRenderPipeline, @"Failed to create pipeline state to render to screen: %@", error);

        #pragma.pipeline mark pipeline 2
        pipelineStateDescriptor.label = @"Offscreen Render Pipeline";
        pipelineStateDescriptor.rasterSampleCount = 1;
        pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"textureVertexShader"];
        pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:tekstur2];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture.pixelFormat;
        _renderToTextureRenderPipeline2 = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_renderToTextureRenderPipeline2, @"Failed to create pipeline state to render to texture: %@", error);
        
        #pragma.pipeline mark chessboard generator
        pipelineStateDescriptor.label = @"Offscreen Render Pipeline2";
        pipelineStateDescriptor.rasterSampleCount = 1;
        pipelineStateDescriptor.vertexFunction =  [defaultLibrary newFunctionWithName:@"simpleVertexShader"];
        pipelineStateDescriptor.fragmentFunction =  [defaultLibrary newFunctionWithName:@"chess_board_generator"];
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = _renderTargetTexture.pixelFormat;
        _renderToTextureRenderPipeline_second = [_device newRenderPipelineStateWithDescriptor:pipelineStateDescriptor error:&error];
        NSAssert(_renderToTextureRenderPipeline_second, @"Failed to create pipeline state to render to texture: %@", error);
                
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
    NSURL *url = [NSURL fileURLWithPath:@"/Users/motionvfx/Documents/chessboard.png"];
         MTKTextureLoader *loader = [[MTKTextureLoader alloc] initWithDevice:_device];
         NSDictionary *options =
         @{
             MTKTextureLoaderOptionSRGB:                 @(false),
             MTKTextureLoaderOptionGenerateMipmaps:      @(false),
             MTKTextureLoaderOptionTextureUsage:         @(MTLTextureUsageShaderRead),
             MTKTextureLoaderOptionTextureStorageMode:   @(MTLStorageModePrivate)
         };
         _textureFromFile = [loader newTextureWithContentsOfURL:url options:options error:nil];
         if(!_textureFromFile)
         {
             NSLog(@"Failed to create the texture from %@", url.absoluteString);
         }
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
        [commandBuffer renderCommandEncoderWithDescriptor:_renderToTextureRenderPassDescriptor_FBO];
    renderEncoder.label = @"Offscreen Render Pass";
    [renderEncoder setRenderPipelineState:_renderToTextureRenderPipeline_second];
        [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:0];
    [renderEncoder setVertexBytes:&triVertices
                           length:sizeof(triVertices)
                          atIndex:AAPLVertexInputIndexVertices];
 
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                      vertexStart:0
                      vertexCount:6];
    [renderEncoder endEncoding];
    
    }
    //generowanie 2 buforow
    float n=1;
    if(option.kwase>=1){
        n=option.kwase;
    }
    
    
    
    
    for (float i=0;i<n;i++){ 
            if(option.gauss2przebieg>=1){
                i=option.gauss2przebieg;
            }
        {
           
            static const AAPLTextureVertex triVertices[] =
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
            [commandBuffer renderCommandEncoderWithDescriptor:_renderToTextureRenderPassDescriptor_second];
        renderEncoder.label = @"First render";
        [renderEncoder setRenderPipelineState:_renderToTextureRenderPipeline2];

            [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:1];
            
         
            [renderEncoder setVertexBytes:&triVertices
                                   length:sizeof(triVertices)
                                  atIndex:AAPLVertexInputIndexVertices];
            
            [renderEncoder setVertexBytes:&_aspectRatio
                                   length:sizeof(_aspectRatio)
                                  atIndex:AAPLVertexInputIndexAspectRatio];
            [renderEncoder setFragmentBytes:&i
                                     length:sizeof(i)
                                    atIndex:Iterator];

        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                          vertexStart:0
                          vertexCount:6];
        [renderEncoder endEncoding];
        }
        if(option.gauss2przebieg==1){
            i++;
        }
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
            renderEncoder.label = @"second render";

            [renderEncoder setRenderPipelineState:_drawableRenderPipeline];

            [renderEncoder setVertexBytes:&quadVertices
                                   length:sizeof(quadVertices)
                                  atIndex:AAPLVertexInputIndexVertices];
            
            [renderEncoder setVertexBytes:&_aspectRatio
                                   length:sizeof(_aspectRatio)
                                  atIndex:AAPLVertexInputIndexAspectRatio];
            [renderEncoder setFragmentBytes:&i
                                     length:sizeof(i)
                                    atIndex:Iterator];

            // Set the offscreen texture as the source texture.
            [renderEncoder setFragmentTexture:_renderTargetTexture atIndex:1];

            // Draw quad with rendered texture.
            [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle
                              vertexStart:0
                              vertexCount:6];
            [renderEncoder endEncoding];

        }
    }
   
    [commandBuffer presentDrawable:view.currentDrawable];

    [commandBuffer commit];
}

- (void)mtkView:(nonnull MTKView *)view drawableSizeWillChange:(CGSize)size
{
    _aspectRatio =  (float)size.height / (float)size.width;
}


@end

//
//  SecondViewController.m
//  BatteryDemo
//
//  Created by leo on 2023/4/19.
//

#import "SecondViewController.h"
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>

@interface SecondViewController ()
@property (nonatomic, strong) id<MTLDevice> device;
@property (nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property (nonatomic, strong) id<MTLComputePipelineState> computePipelineState;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
        
    self.device = MTLCreateSystemDefaultDevice();
    self.commandQueue = [self.device newCommandQueue];
    
    // Define your compute shader code
    NSString *shaderCode = @"\
    #include <metal_stdlib>\n\
    using namespace metal;\n\
    kernel void computeShader(texture2d<half, access::write> output [[texture(0)]], uint2 gid [[thread_position_in_grid]])\n\
    {\n\
        // Intensive computation\n\
        for (int i = 0; i < 1000000; i++)\n\
        {\n\
            float value = 1.0;\n\
            value = value * 2.0;\n\
        }\n\
        half4 color = half4(1.0);\n\
        output.write(color, gid);\n\
    }\n\
    ";
    
    NSError *error = nil;
    id<MTLLibrary> library = [self.device newLibraryWithSource:shaderCode options:nil error:&error];
    if (error != nil) {
        NSLog(@"Error creating library: %@", error);
        return;
    }
    
    id<MTLFunction> computeFunction = [library newFunctionWithName:@"computeShader"];
    
    id<MTLComputePipelineState> computePipelineState = [self.device newComputePipelineStateWithFunction:computeFunction error:&error];
    if (error != nil || computePipelineState == nil) {
        NSLog(@"Error creating compute pipeline state: %@", error);
        return;
    }
    
    self.computePipelineState = computePipelineState;
    
    [NSTimer scheduledTimerWithTimeInterval:0.16 repeats:YES block:^(NSTimer * _Nonnull timer) {
        MTKView *metalView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.device];
        metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
        metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
        [self.view addSubview:metalView];
        
        id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
        
        id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];
        [computeEncoder setComputePipelineState:self.computePipelineState];
        
        MTLSize threadgroupSize = MTLSizeMake(8, 8, 1);
        MTLSize threadgroupCount = MTLSizeMake(metalView.drawableSize.width / threadgroupSize.width,
                                               metalView.drawableSize.height / threadgroupSize.height, 1);
        [computeEncoder dispatchThreadgroups:threadgroupCount threadsPerThreadgroup:threadgroupSize];
        
        [computeEncoder endEncoding];
        
        [commandBuffer presentDrawable:metalView.currentDrawable];
        [commandBuffer commit];
    }];

}

@end

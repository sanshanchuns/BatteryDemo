//
//  TestLayer.m
//  BatteryDemo
//
//  Created by leo on 2023/6/1.
//

#import "TestLayer.h"

@implementation TestLayer

-(void)drawInContext:(CGContextRef)ctx
{
    
    //绘制矩形
    CGContextAddRect(ctx, CGRectMake(0, 0, 50, 50));
    
    
    //第一种设置颜色方式：
    //设置颜色空间(选择配色方案:RGB,红、绿、蓝)
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGContextSetStrokeColorSpace(ctx, colorspace);
    
//数组中四个内容：前三个分别为红绿蓝颜色值,后一个为透明度
    CGFloat components[4] = {0.0,1.0,0.0,1.0};
    CGContextSetStrokeColor(ctx, components);
    
    
    //这是另一种比较简单的设置颜色的方式
    //CGContextSetStrokeColorWithColor(ctx, [[UIColor greenColor]CGColor]);
    
    
    //绘制描边路径
    CGContextDrawPath(ctx, kCGPathStroke);
    
    //释放create出的属性,防止内存泄露
    CGColorSpaceRelease(colorspace);
    
}

@end

//
//  ViewController+Sensitive.m
//  BatteryDemo
//
//  Created by leo on 2023/12/22.
//

#import "ViewController+Sensitive.h"

@implementation ViewController (Sensitive)

+ (NSString *)logTypeDescription:(NSInteger)type {
    static dispatch_once_t onceToken;
    static NSDictionary *map;
    dispatch_once(&onceToken, ^{
        map =  @{
            @(1) : @"/usr/lib/system/libxpc.dylib",
            @(2) : @"xpc_connection_create_mach_service",
            @(3) : @"xpc_connection_set_event_handler",
            @(4) : @"xpc_connection_resume",
            @(5) : @"xpc_dictionary_create",
            @(6) : @"xpc_dictionary_set_string",
            @(7) : @"xpc_connection_send_message_with_reply_sync",
        };
    });
    return map[@(type)];
}

@end

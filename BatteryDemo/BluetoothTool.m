//
//  BluetoothTool.m
//  BatteryDemo
//
//  Created by leo on 2023/6/6.
//

#import "BluetoothTool.h"
#import <IOKit/IOKitLib.h>

@implementation BluetoothTool

CFStringRef copy_bluetooth_mac_address() {
    io_service_t service;
    CFDataRef macaddrData;
    CFStringRef macaddr;
    unsigned char macaddrBytes[6];
    
    service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceNameMatching("bluetooth"));
    if(!service) {
        printf("unable to find bluetooth service\n");
        return NULL;
    }
    
    macaddrData= IORegistryEntryCreateCFProperty(service, CFSTR("local-mac-address"), kCFAllocatorDefault, 0);
    if(macaddrData == NULL) {
        printf("bluetooth local-mac-address not found\n");
        IOObjectRelease(service);
        return NULL;
    }
    CFDataGetBytes(macaddrData, CFRangeMake(0,6), macaddrBytes);
    
    macaddr = CFStringCreateWithFormat(kCFAllocatorDefault,
                                        NULL,
                                        CFSTR("%02x:%02x:%02x:%02x:%02x:%02x"),
                                        macaddrBytes[0],
                                        macaddrBytes[1],
                                        macaddrBytes[2],
                                        macaddrBytes[3],
                                        macaddrBytes[4],
                                        macaddrBytes[5]);

    return macaddr;
}

@end

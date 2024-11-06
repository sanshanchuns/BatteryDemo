//
//  ViewController.m
//  BatteryDemo
//
//  Created by leo on 2023/4/19.
//

#import "ViewController.h"

#import <Aspects/Aspects.h>
#import <MJRefresh/MJRefresh.h>

#import "Person.h"

#import <mach-o/dyld.h>
#import <objc/runtime.h>

// 类已经初始化了
#define RW_INITIALIZED      (1<<29)
// data pointer
#define FAST_DATA_MASK      0x00007ffffffffff8UL
#define ISA_MASK            0x0000000ffffffff8ULL

typedef uint32_t mask_t;
typedef uintptr_t cache_key_t;

struct ksp_bucket_t {
    cache_key_t _key;
    IMP _imp;
};

struct ksp_cache_t {
    struct ksp_bucket_t *_buckets;
    mask_t _mask;
    mask_t _occupied;
};

struct ksp_class_rw_t {
    uint32_t flags;
    uint16_t witness;
    uintptr_t ro_or_rw_ext;

    Class firstSubclass;
    Class nextSiblingClass;
};

struct ksp_class_data_bits_t {
    uintptr_t bits;
};

/* OC对象 */
struct ksp_objc_object {
    void *isa;
};


/* 类对象 */
struct ksp_objc_class {
    void *isa;
    Class superclass;
    struct ksp_cache_t cache;
    struct ksp_class_data_bits_t bits;
};

BOOL leo_isInitializedClass(Class class) {
    struct ksp_objc_class *objc_class = (__bridge struct ksp_objc_class *)class;
    struct ksp_objc_class *objc_meta_class =  (struct ksp_objc_class *)((long long)objc_class->isa & ISA_MASK);
    struct ksp_class_data_bits_t bits = objc_meta_class->bits;
    struct ksp_class_rw_t *rw = (struct ksp_class_rw_t *)(bits.bits & FAST_DATA_MASK);
    return (rw->flags & RW_INITIALIZED);
}

NSString* leo_convertToJsonData(NSArray* array) {
     NSError *error;
     NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:NSJSONWritingPrettyPrinted error:&error];
     NSString *jsonString = nil;

     if (!jsonData) {
         NSLog(@"%@",error);
     } else {
         jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
     }
     return jsonString;
 }

NSString* leo_writeToFile(NSString* jsonString) {
     NSArray *paths  = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
     NSString *filePath = [[paths firstObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"pinduoduo_userfulclass.json"]];
     [jsonString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
     return filePath;
 }

void leo_reportUsefulClasses(void) {
    static dispatch_queue_t reportQueue;
    static NSMutableSet<NSString *> *reportedUsefulClasses = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        reportQueue = dispatch_queue_create("com.pinduoduo.app.useful.classes.queue", DISPATCH_QUEUE_SERIAL);
        reportedUsefulClasses = [NSMutableSet setWithCapacity:10000];
    });
    
    dispatch_async(reportQueue, ^{
        NSMutableArray<NSString *> *usefulClasses = [NSMutableArray arrayWithCapacity:10000];
        unsigned int imageCount = _dyld_image_count();
        for (int i=0; i<imageCount; i++) {
            const char *cstring = _dyld_get_image_name(i);
            NSString *imageName = [NSString stringWithUTF8String:cstring];
            if (![imageName hasPrefix:[NSBundle mainBundle].bundlePath]) {
                continue;
            }
            unsigned int classCount = 0;
            const char **classes = objc_copyClassNamesForImage(cstring, &classCount);
            NSMutableArray<NSString *> *imageClasses = [NSMutableArray arrayWithCapacity:classCount];
            for (int index = 0; index < classCount; index++) {
                [imageClasses addObject:@""];
            }
            dispatch_apply(classCount, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t index) {
                NSString *className = [NSString stringWithCString:classes[index] encoding:NSUTF8StringEncoding];
                Class class = NSClassFromString(className);
                BOOL isInitialized = leo_isInitializedClass(class);
                if (isInitialized) {
                    imageClasses[index] = className;
                    NSLog(@"%@", className);
                }
            });
            [usefulClasses addObjectsFromArray:imageClasses];
            if (classes) {
                free(classes);
            }
        }
        
        NSMutableArray<NSString *> *targetClasses = [NSMutableArray array];
        for (NSString *className in usefulClasses) {
            if ([className length] > 0) {
                [targetClasses addObject:className];
            }
        }
        
        NSArray* clz = [targetClasses copy];
        leo_writeToFile(leo_convertToJsonData(clz));
    });
}

@interface ViewController ()

@property (nonatomic, strong) NSMutableArray* list;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
}

@end

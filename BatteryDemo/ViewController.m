//
//  ViewController.m
//  BatteryDemo
//
//  Created by leo on 2023/4/19.
//

#import "ViewController.h"

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/AFNetworking.h>
#import <YYModel/YYModel.h>
#import <SDWebImage/SDWebImage.h>
#import <ZipArchive.h>
#import <CoreLocation/CoreLocation.h>

#import "SecondViewController.h"

#define ResourceURLDomain(path) [NSString stringWithFormat:@"%@%@", @"https://cdnfile.corp.kuaishou.com/bs2/gtrm/", path]

static void BDLog(NSString *content) {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[BatteryDemo] %@", content);
        UIViewController* rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootVC.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [NSString stringWithFormat:@"%@", content];
        [hud hideAnimated:YES afterDelay:1];
    });
}

@interface ViewController () <CLLocationManagerDelegate, UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, weak) MBProgressHUD *hud;
@property (nonatomic, copy) NSString* diskCachePath;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic,strong) UIImagePickerController *imagePicker; //声明全局的UIImagePickerController
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fileManager = [NSFileManager defaultManager];
    self.locationManager = [[CLLocationManager alloc] init];
    self.diskCachePath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Library/Caches/AwemeHeaders"];
    
    BDLog(self.diskCachePath);
}

- (IBAction)highCPU:(id)sender {
    BDLog(@"CPU start");
    for (int i = 0; i < 3; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSUInteger size = [self totalSize];
            NSUInteger count = [self totalCount];
            BDLog([NSString stringWithFormat:@"total count %lu, size %lu", count, size]);
        });
    }
}

- (IBAction)highGPU:(id)sender {
    BDLog(@"GPU start");
    SecondViewController* vc = [SecondViewController new];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)highGPS:(id)sender {
    BOOL enabled = [CLLocationManager locationServicesEnabled];
    if (!enabled) {
        //跳转权限页面
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:^(BOOL success) {
                
        }];
    } else {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            self.locationManager.distanceFilter = 1.0f;
            self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
            [self.locationManager requestWhenInUseAuthorization];
            self.locationManager.delegate = self;
            self.locationManager.pausesLocationUpdatesAutomatically = NO;
            [self.locationManager startUpdatingLocation];
        });
    }
}

- (IBAction)highNetwork:(id)sender {
    [self downloadSmallFileWithHighFrequency];
    [self downloadLargeFile];
    BDLog(@"network start");
}

- (IBAction)highIO:(id)sender {
    [self unzipToSandbox];
}

- (IBAction)highScreenRefresh:(id)sender {
    NSUInteger sourceType = 0;
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerController.delegate = self; //设置代理
        imagePickerController.allowsEditing = YES;
        imagePickerController.sourceType = sourceType; //图片来源
        //拍照
        sourceType = UIImagePickerControllerSourceTypeCamera;
        imagePickerController.sourceType = sourceType;
        [self presentViewController:imagePickerController animated:YES completion:nil];
        BDLog(@"launch camera");
    }else {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.sourceType = sourceType;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (void)downloadSmallFileWithHighFrequency {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (int i = 702187047; i < 702197359; i++) {
            [self downloadSingleFile:[NSString stringWithFormat:@"64092679853_%@_aweme_feed_list.json", @(i)]];
        }
    });
}

- (void)downloadLargeFile {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [self downloadSingleFile:@"com_kwai_gif-11.3.30_tti.ipa"];
    });
}

- (void)downloadSingleFile:(NSString*)fileName {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];

    NSURL *URL = [NSURL URLWithString:ResourceURLDomain(fileName)];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
//        BDLog([NSString stringWithFormat:@"File is downloading %.2f", downloadProgress.completedUnitCount * 1.0 / downloadProgress.totalUnitCount]);
    } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        return [documentsDirectoryURL URLByAppendingPathComponent:[response suggestedFilename]];
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
//        BDLog([NSString stringWithFormat:@"File downloaded to: %@", filePath]);
    }];
    [downloadTask resume];
}

- (void)unzipToSandbox {
    NSString* zipPath = [[NSBundle mainBundle] pathForResource:@"AwemeHeaders" ofType:@"zip"];
    NSString* unzipPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Library/Caches/AwemeHeaders"];
    BDLog([NSString stringWithFormat:@"copy file from %@ to %@", zipPath, unzipPath]);
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        //如果目标路径不存在，则创建目录，同步解压到目录路径下; 否则，覆盖同名文件
        [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            BDLog(@"unzip done");
        });
    });
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
        NSDictionary<NSString *, id> *attrs = [self.fileManager attributesOfItemAtPath:filePath error:nil];
        size += [attrs fileSize];
    }
    return size;
}

- (NSUInteger)totalCount {
    NSUInteger count = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    count = fileEnumerator.allObjects.count;
    return count;
}

#pragma mark -
#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations {
    for(CLLocation *loc in locations){
        //CLLocation 就是一次经纬度 , 方向 海拔 等信息
        //loc.coordinate就是取的经纬度
        CLLocationCoordinate2D l = loc.coordinate;
        CLLocationDegrees lat = l.latitude;
        CLLocationDegrees lng = l.longitude;
        CLLocationDistance altitude = loc.altitude;//海拔
        BDLog([NSString stringWithFormat:@"GPS (%f, %f, %f)", lat, lng, altitude]);
    }
}
@end

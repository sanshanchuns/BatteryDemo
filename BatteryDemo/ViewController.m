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
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

#import "SecondViewController.h"

#define DLog(fmt, ...) NSLog((@"[DEBUG] %s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#define ResourceURLDomain(path) [NSString stringWithFormat:@"%@%@", @"https://cdnfile.corp.kuaishou.com/bs2/gtrm/", path]

static void BDLog(NSString* format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"[DEBUG] %@ [Line %d]", message, __LINE__);
        UIViewController* rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:rootVC.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.label.text = [NSString stringWithFormat:@"%@", message];
        [hud hideAnimated:YES afterDelay:1];
    });
}

@interface ViewController () <CLLocationManagerDelegate, UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, strong) NSFileManager *fileManager;
@property (weak, nonatomic) IBOutlet UIButton *screenBrightnessBtn;
@property (nonatomic, weak) MBProgressHUD *hud;
@property (nonatomic, copy) NSString* diskCachePath;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property(nonatomic,strong) UIImagePickerController *imagePicker; //声明全局的UIImagePickerController
@property (weak, nonatomic) IBOutlet UIButton *speakBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.fileManager = [NSFileManager defaultManager];
    self.locationManager = [[CLLocationManager alloc] init];
    self.diskCachePath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Library/Caches/AwemeHeaders"];
    
    BDLog(self.diskCachePath);
    
    CGFloat brightness = [UIScreen mainScreen].brightness;
    [self.screenBrightnessBtn setTitle:[NSString stringWithFormat:@"当前屏幕亮度%.2f", brightness] forState:UIControlStateNormal];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    CGFloat systemVolume = audioSession.outputVolume;
    [self.speakBtn setTitle:[NSString stringWithFormat:@"当前音量%.2f", systemVolume] forState:UIControlStateNormal];
}

- (IBAction)highCPU:(id)sender {
    BDLog(@"Constant CPU start 6");
    for (int i = 0; i < 6; i++) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            for (int j = 0; j < 400; j++) {
                @autoreleasepool {
                    [self totalSize];
                    [self totalCount];
                }
            }
            BDLog(@"High CPU Done");
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

- (IBAction)launchCamera:(id)sender {
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
    } else {
        sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        imagePickerController.sourceType = sourceType;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

- (IBAction)highSpeak:(id)sender {
    [self setSystemVolume:1];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    CGFloat systemVolume = audioSession.outputVolume;
    [self.speakBtn setTitle:[NSString stringWithFormat:@"当前音量%.2f", systemVolume] forState:UIControlStateNormal];
    
    // 定义播放器对象
    AVAudioPlayer *audioPlayer;

    // 获取音频文件路径
    NSString *audioFilePath = [[NSBundle mainBundle] pathForResource:@"audioFileName" ofType:@"mp3"];
    // 初始化播放器
    NSError *error;
    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:audioFilePath] error:&error];

    // 判断初始化是否成功
    if (error) {
        NSLog(@"初始化失败，错误信息：%@", error.localizedDescription);
    } else {
        // 设置音量
        audioPlayer.volume = 1.0;
        // 循环播放
        audioPlayer.numberOfLoops = -1;
        // 准备播放
        [audioPlayer prepareToPlay];
        // 播放音频
        [audioPlayer play];
    }
}

- (IBAction)highScreenBrightness:(id)sender {
    //屏幕亮度设置为1
    CGFloat brightness = [UIScreen mainScreen].brightness;
    if (brightness == 1) {
        [UIScreen mainScreen].brightness = 0;
        [self.screenBrightnessBtn setTitle:[NSString stringWithFormat:@"当前屏幕亮度%.2f", 0.0] forState:UIControlStateNormal];
    } else {
        brightness += 0.1;
        [UIScreen mainScreen].brightness = brightness;
        [self.screenBrightnessBtn setTitle:[NSString stringWithFormat:@"当前屏幕亮度%.2f", brightness] forState:UIControlStateNormal];
    }
}

#pragma mark -
#pragma mark - Helper

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
    //unzip file to dir
//    NSString* zipPath = [[NSBundle mainBundle] pathForResource:@"AwemeHeaders" ofType:@"zip"];
//    NSString* unzipPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Library/Caches/"];
//    BDLog(@"unzip file from %@ to %@AwemeHeaders", zipPath, unzipPath);
//    dispatch_async(dispatch_get_global_queue(0, 0), ^{
//        //如果目标路径不存在，则创建目录，同步解压到目录路径下; 否则，覆盖同名文件
//        [SSZipArchive unzipFileAtPath:zipPath toDestination:unzipPath];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            BDLog(@"unzip done");
//        });
//    });
    
    //copy file from dir to dir
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSString* sourcePath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Library/Caches/AwemeHeaders"];
        NSString* copyPath = [NSString stringWithFormat:@"%@/%@", NSHomeDirectory(), @"Library/Caches/AwemeHeaders2"];
        BDLog(@"copy file from %@ to %@", sourcePath, copyPath);

        
        [self deleteFolderAtPath:copyPath];
        [self copyFolderFromPath:sourcePath toPath:copyPath];
        
    });
    
}

- (void)copyFolderFromPath:(NSString *)sourceFolderPath toPath:(NSString *)destinationFolderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // 检查源目录是否存在
    if (![fileManager fileExistsAtPath:sourceFolderPath]) {
        NSLog(@"源目录不存在");
        return;
    }

    // 创建目标目录
    if (![fileManager createDirectoryAtPath:destinationFolderPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSLog(@"创建目标目录失败：%@", error.localizedDescription);
        return;
    }

    // 获取源目录下的所有文件和子目录
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:sourceFolderPath error:&error];
    if (error) {
        NSLog(@"获取源目录内容失败：%@", error.localizedDescription);
        return;
    }

    // 复制文件和子目录到目标目录
    for (NSString *fileOrFolderName in contents) {
        NSString *sourcePath = [sourceFolderPath stringByAppendingPathComponent:fileOrFolderName];
        NSString *destinationPath = [destinationFolderPath stringByAppendingPathComponent:fileOrFolderName];
        BOOL isDirectory = NO;
        if ([fileManager fileExistsAtPath:sourcePath isDirectory:&isDirectory]) {
            if (isDirectory) {
                [self copyFolderFromPath:sourcePath toPath:destinationPath];
            } else {
                if (![fileManager copyItemAtPath:sourcePath toPath:destinationPath error:&error]) {
                    NSLog(@"复制文件失败：%@", error.localizedDescription);
                }
            }
        }
    }
}

- (void)deleteFolderAtPath:(NSString *)folderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:folderPath]) {
        return;
    }

    NSError *error = nil;
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:folderPath error:&error];
    if (error) {
        NSLog(@"Failed to get contents of directory %@: %@", folderPath, error.localizedDescription);
        return;
    }

    for (NSString *fileOrFolderName in contents) {
        NSString *filePath = [folderPath stringByAppendingPathComponent:fileOrFolderName];
        BOOL isDirectory = NO;
        if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory]) {
            if (isDirectory) {
                [self deleteFolderAtPath:filePath];
            } else {
                if (![fileManager removeItemAtPath:filePath error:&error]) {
                    NSLog(@"Failed to delete file %@: %@", filePath, error.localizedDescription);
                }
            }
        }
    }

    if (![fileManager removeItemAtPath:folderPath error:&error]) {
        NSLog(@"Failed to delete folder %@: %@", folderPath, error.localizedDescription);
    }
}

- (NSUInteger)totalSize {
    NSUInteger size = 0;
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
    for (NSString *fileName in fileEnumerator) {
        @autoreleasepool {
            NSString *filePath = [self.diskCachePath stringByAppendingPathComponent:fileName];
            NSDictionary<NSString *, id> *attrs = [self.fileManager attributesOfItemAtPath:filePath error:nil];
            size += [attrs fileSize];
        }
    }
    return size;
}

- (NSUInteger)totalCount {
    NSUInteger count = 0;
    @autoreleasepool {
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtPath:self.diskCachePath];
        count = fileEnumerator.allObjects.count;
    }
    return count;
}

// 修改系统音量值
- (void)setSystemVolume:(float)volume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    UISlider *volumeSlider;
    for (UIView *view in volumeView.subviews) {
        if ([view isKindOfClass:[UISlider class]]) {
            volumeSlider = (UISlider *)view;
            break;
        }
    }
    [volumeSlider setValue:volume animated:NO];
    [volumeSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
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
        BDLog(@"GPS (%f, %f, %f)", lat, lng, altitude);
    }
}
@end

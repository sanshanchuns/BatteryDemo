//
//  SecondViewController.m
//  BatteryDemo
//
//  Created by leo on 2023/4/19.
//

#import "SecondViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

@interface SecondViewController ()
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@end

@implementation SecondViewController

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation)) {
        // 将AVPlayerLayer的frame设置为横屏方向的屏幕尺寸
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        self.playerLayer.frame = CGRectMake(0, 0, MAX(screenSize.width, screenSize.height), MIN(screenSize.width, screenSize.height));
    } else {
        
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    NSURL *videoURL = [[NSBundle mainBundle] URLForResource:@"pexels_westarmoney" withExtension:@"mp4"];
    AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
    self.player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    
    // 2. 创建显示视频的layer
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.playerLayer];
    
    // 3. 监听播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.player.currentItem];
    
    // 4. 播放视频
    [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    // 播放完成后，将播放进度归零，并重新播放
    AVPlayerItem *playerItem = [notification object];
    [playerItem seekToTime:kCMTimeZero];
    [self.player play];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end

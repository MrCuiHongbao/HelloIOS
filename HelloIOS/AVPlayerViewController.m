//
//  AVPlayerViewController.m
//  HelloIOS
//
//  Created by sethmao on 2017/2/10.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "AVPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PlayerView.h"

@interface AVPlayerViewController ()
{
	BOOL _played;
	NSString *_totalTime;
	NSDateFormatter *_dateFormatter;
}

@property (nonatomic ,strong) AVPlayer *player;
@property (nonatomic ,strong) AVPlayerItem *playerItem;
@property (nonatomic ,strong) PlayerView *playerView;
@property (nonatomic ,strong) UIButton *stateButton;
@property (nonatomic ,strong) UILabel *timeLabel;
@property (nonatomic ,strong) id playbackTimeObserver;
@property (nonatomic ,strong) UISlider *videoSlider;
@property (nonatomic ,strong) UIProgressView *videoProgress;

@end

@implementation AVPlayerViewController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
	self.view = container;
	
	self.playerView = ({
		PlayerView *playerView = [[PlayerView alloc] initWithFrame:CGRectMake(0, 10, 375, 200)];
		[playerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
		[container addSubview:playerView];
		playerView;
	});
	
	self.stateButton = ({
		UIButton *stateButton = [UIButton buttonWithType:UIButtonTypeCustom];
		[stateButton setTitle:@"Play" forState:UIControlStateNormal];
		[stateButton addTarget:self action:@selector(stateButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
		[stateButton setFrame:CGRectMake(20, 364, 55, 30)];
		[stateButton setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:1]];
		[container addSubview:stateButton];
		stateButton;
	});
	
	self.timeLabel = ({
		UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 364, 120, 30)];
		[timeLabel setTextColor:[UIColor darkTextColor]];
		[container addSubview:timeLabel];
		timeLabel;
	});
	
	self.videoProgress = ({
		UIProgressView *videoProgress = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		[videoProgress setFrame:CGRectMake(20, 412, 300, 1)];
		[container addSubview:videoProgress];
		videoProgress;
	});
	
	self.videoSlider = ({
		UISlider *videoSlider = [[UISlider alloc] initWithFrame:CGRectMake(20, 405, 300, 15)];
		[videoSlider setMinimumTrackTintColor:[UIColor colorWithWhite:0 alpha:1]];
		[videoSlider setMinimumValue:0];
		[videoSlider setMaximumValue:1];
		[videoSlider addTarget:self action:@selector(videoSlierChangeValue:) forControlEvents:UIControlEventValueChanged];
		[videoSlider addTarget:self action:@selector(videoSlierChangeValueEnd:) forControlEvents:UIControlEventTouchUpInside];
		[container addSubview:videoSlider];
		videoSlider;
	});
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	NSURL *videoUrl = [NSURL URLWithString:@"https://cdn.mp.qq.com/qqstocdnd?filekey=f91326f93f9fd6718d97e6216c189dd1&fileid=30570201030450304e020100040751514d505f313002037a1afd02042016a3b40204588c9c380420663931333236663933663966643637313864393765363231366331383964643102010002020900020300c3540201000400&bid=10009&setnum=50004&authkey=3041020101043a3038020101020101020203e802037a1afd02041916a3b402041916a3b402037a1db9020450fd03b7020445fd03b7020458a56a6a02044da56ec60400&filetype=2304"];
	self.playerItem = [AVPlayerItem playerItemWithURL:videoUrl];
	[self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];// 监听status属性
	[self.playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];// 监听loadedTimeRanges属性
	self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
	self.playerView.player = _player;
	[self.playerView setVideoFillMode:AVLayerVideoGravityResizeAspectFill];
	self.stateButton.enabled = NO;
	
	// 添加视频播放结束通知
	[[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)monitoringPlayback:(AVPlayerItem *)playerItem {
	
	__weak typeof(self) weakSelf = self;
	self.playbackTimeObserver = [self.playerView.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
		CGFloat currentSecond = playerItem.currentTime.value/playerItem.currentTime.timescale;// 计算当前在第几秒
		[weakSelf.videoSlider setValue:currentSecond animated:YES];
		NSString *timeString = [self convertTime:currentSecond];
		weakSelf.timeLabel.text = [NSString stringWithFormat:@"%@/%@",timeString,_totalTime];
	}];
}

// KVO方法
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	AVPlayerItem *playerItem = (AVPlayerItem *)object;
	if ([keyPath isEqualToString:@"status"]) {
		if ([playerItem status] == AVPlayerStatusUnknown) {
			NSLog(@"AVPlayerStatusUnknown");
		} else if ([playerItem status] == AVPlayerStatusReadyToPlay) {
			NSLog(@"AVPlayerStatusReadyToPlay");
			self.stateButton.enabled = YES;
			CMTime duration = self.playerItem.duration;// 获取视频总长度
			CGFloat totalSecond = playerItem.duration.value / playerItem.duration.timescale;// 转换成秒
			_totalTime = [self convertTime:totalSecond];// 转换成播放时间
			[self customVideoSlider:duration];// 自定义UISlider外观
			NSLog(@"movie total duration:%f",CMTimeGetSeconds(duration));
			[self monitoringPlayback:self.playerItem];// 监听播放状态
		} else if ([playerItem status] == AVPlayerStatusFailed) {
			NSLog(@"AVPlayerStatusFailed");
		}
	} else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
		NSTimeInterval timeInterval = [self availableDuration];// 计算缓冲进度
		NSLog(@"Time Interval:%f",timeInterval);
		CMTime duration = _playerItem.duration;
		CGFloat totalDuration = CMTimeGetSeconds(duration);
		[self.videoProgress setProgress:timeInterval / totalDuration animated:YES];
	}
}

- (NSTimeInterval)availableDuration {
	NSArray *loadedTimeRanges = [[self.playerView.player currentItem] loadedTimeRanges];
	CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
	float startSeconds = CMTimeGetSeconds(timeRange.start);
	float durationSeconds = CMTimeGetSeconds(timeRange.duration);
	NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
	return result;
}

- (void)customVideoSlider:(CMTime)duration {
	self.videoSlider.maximumValue = CMTimeGetSeconds(duration);
	UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
	UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	[self.videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
	[self.videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
}

- (IBAction)stateButtonTouched:(id)sender {
	if (!_played) {
		[self.playerView.player play];
		[self.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
	} else {
		[self.playerView.player pause];
		[self.stateButton setTitle:@"Play" forState:UIControlStateNormal];
	}
	_played = !_played;
}

- (IBAction)videoSlierChangeValue:(id)sender {
	UISlider *slider = (UISlider *)sender;
	NSLog(@"value change:%f",slider.value);
	
	if (slider.value == 0.000000) {
		__weak typeof(self) weakSelf = self;
		[self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
			[weakSelf.playerView.player play];
		}];
	}
}

- (IBAction)videoSlierChangeValueEnd:(id)sender {
	UISlider *slider = (UISlider *)sender;
	NSLog(@"value end:%f",slider.value);
	CMTime changedTime = CMTimeMakeWithSeconds(slider.value, 1);
	
	__weak typeof(self) weakSelf = self;
	[self.playerView.player seekToTime:changedTime completionHandler:^(BOOL finished) {
		[weakSelf.playerView.player play];
		[weakSelf.stateButton setTitle:@"Stop" forState:UIControlStateNormal];
	}];
}

- (void)updateVideoSlider:(CGFloat)currentSecond {
	[self.videoSlider setValue:currentSecond animated:YES];
}


- (void)moviePlayDidEnd:(NSNotification *)notification {
	NSLog(@"Play end");
	
	__weak typeof(self) weakSelf = self;
	[self.playerView.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
		[weakSelf.videoSlider setValue:0.0 animated:YES];
		[weakSelf.stateButton setTitle:@"Play" forState:UIControlStateNormal];
	}];
}

- (NSString *)convertTime:(CGFloat)second{
	NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
	if (second/3600 >= 1) {
		[[self dateFormatter] setDateFormat:@"HH:mm:ss"];
	} else {
		[[self dateFormatter] setDateFormat:@"mm:ss"];
	}
	NSString *showtimeNew = [[self dateFormatter] stringFromDate:d];
	return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
	if (!_dateFormatter) {
		_dateFormatter = [[NSDateFormatter alloc] init];
	}
	return _dateFormatter;
}

- (void)dealloc {
	[self.playerItem removeObserver:self forKeyPath:@"status" context:nil];
	[self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges" context:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
	[self.playerView.player removeTimeObserver:self.playbackTimeObserver];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end

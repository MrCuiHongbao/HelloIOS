//
//  VideoRecordSettings.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/30.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "VideoRecordSettings.h"

@interface VideoRecordSettings ()

@property (nonatomic) CGSize rr;

@end

@implementation VideoRecordSettings

+ (VideoRecordSettings*)shareInstance
{
	static VideoRecordSettings* g_VideoRecordSettings = nil;
	static dispatch_once_t predicate;
	if (g_VideoRecordSettings == nil)
	{
		dispatch_once(&predicate, ^{
			g_VideoRecordSettings = [VideoRecordSettings new];
		});
	}
	return g_VideoRecordSettings;
}

- (id)init
{
	if (self = [super init])
	{
	}
	
	return self;
}

- (void)setRecordResolution:(CGSize)rr {
	self.rr = rr;
}

- (CGSize)recordResolution {
	return self.rr;
}

- (NSDictionary*) videoSettings {
	// CoreImage wants BGRA pixel format
	if (!_videoSettings) {
		_videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
	}
	
	return _videoSettings;
}

- (NSDictionary*) adaptorSettings {
	if (!_adaptorSettings) {
		CGSize size = [self recordResolution];
		
		//宽高是视频帧的宽高
		_adaptorSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
							 (id)kCVPixelBufferWidthKey: @(size.width),
							 (id)kCVPixelBufferHeightKey: @(size.height),
							 @"IOSurfaceOpenGLESTextureCompatibility": @YES,
							 @"IOSurfaceOpenGLESFBOCompatibility": @YES,};
	}
	
	return _adaptorSettings;
}

- (NSDictionary *)videoCompressionSettings {
	if (!_videoCompressionSettings) {
		//写入视频大小
		CGSize size = [self recordResolution];
		NSInteger numPixels = size.width * size.height;
		
		//每像素比特
		CGFloat bitsPerPixel = 12.0;
		NSInteger bitsPerSecond = numPixels * bitsPerPixel;
		
		// 码率和帧率设置
		NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
												 AVVideoExpectedSourceFrameRateKey : @(30),
												 AVVideoMaxKeyFrameIntervalKey : @(30),
												 AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
		
		//视频属性
		_videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
									   AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
									   AVVideoWidthKey : @(size.width - ((int)size.width % 2)),
									   AVVideoHeightKey : @(size.height - ((int)size.height % 2)),
									   AVVideoCompressionPropertiesKey : compressionProperties };
	}
	
	return _videoCompressionSettings;
}

- (NSDictionary *)audioCompressionSettings {
	if (!_audioCompressionSettings) {
		_audioCompressionSettings = @{ AVEncoderBitRateStrategyKey : AVAudioBitRateStrategy_Variable,
									   AVEncoderBitRateKey : @(64000),
									   AVFormatIDKey : @(kAudioFormatMPEG4AAC),
									   AVNumberOfChannelsKey : @(1),
									   AVSampleRateKey : @(44100) };
	}
	
	return _audioCompressionSettings;
}

- (NSDictionary *)videoTrackOutputSetting {
	if (!_videoTrackOutputSetting) {
		_videoTrackOutputSetting = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
	}
	
	return _videoTrackOutputSetting;
}

@end

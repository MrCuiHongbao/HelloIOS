//
//  VideoRecordSettings.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/30.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface VideoRecordSettings : NSObject

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) NSDictionary *adaptorSettings;
@property (nonatomic, strong) NSDictionary *videoTrackOutputSetting;
@property (nonatomic, strong) NSDictionary *audioTrackOutputSetting;

+ (VideoRecordSettings*)shareInstance;

- (void)setRecordResolution:(CGSize)rr;

@end

//
//  SplitRecordViewController.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/2.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreMedia/CoreMedia.h>
#import <Accelerate/Accelerate.h>
#import <AssetsLibrary/AssetsLibrary.h>

typedef NS_ENUM(NSInteger, FMRecordState) {
	FMRecordStateInit = 0,
	FMRecordStatePrepareRecording,
	FMRecordStateRecording,
	FMRecordStateFinish,
	FMRecordStateFail,
};

@protocol VideoDelegate
- (void)processVideoFrame:(CVImageBufferRef)cameraFrame;
- (void)didStopReading:(AVAssetReaderStatus)status;
@end

@interface SplitRecordViewController : UIViewController

@property(nonatomic, weak) id<VideoDelegate> delegate;

@end

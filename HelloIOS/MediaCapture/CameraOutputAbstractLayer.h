//
//  CameraOutputAbstractLayer.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/30.
//  Copyright © 2017年 younger. All rights reserved.
//
//	视频帧输出抽象层，向下对接各种摄像头输出组件
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol CameraOutputAbstractLayerDelegate <NSObject>

- (void) onCaptureVideoSampleBuffer:(CMSampleBufferRef) sampleBuffer;

- (void) onCatureAudioSampleBuffer:(CMSampleBufferRef) sampleBuffer;

@end

@interface CameraOutputAbstractLayer : NSObject

// 摄像头位置
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;

// 摄像头输出规格
@property (nonatomic, strong) NSString *captureSessionPreset;

// 是否需要音频输出
@property (nonatomic) BOOL needAudio;

@property (nonatomic, weak) id<CameraOutputAbstractLayerDelegate> delegate;

- (void)setupCapture;

- (void)uninstallCapture;

- (void)switchCamera;

@end

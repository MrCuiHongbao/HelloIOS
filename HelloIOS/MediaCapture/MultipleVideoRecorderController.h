//
//  MultipleVideoRecorderController.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/8.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#import <CoreFoundation/CoreFoundation.h>

typedef NS_ENUM(NSInteger, MultiRecordState) {
	MultiRecordStateUnknown = 0,
	MultiRecordStateInit,				// 初始化摄像头等
	MultiRecordStateReady,				// 可以开始录制
	MultiRecordStateRecording,			// 录制中
	MultiRecordStateFinish,				// 录制完成，还可以删除
	MultiRecordStateExported,			// 视频已导出，不能再删除和录制
	MultiRecordStateFail,				// 录制失败
};

@interface GLKViewWithBounds : GLKView

@property (nonatomic, assign) CGRect viewBounds;

@end

@protocol MultipleVideoRecorderControllerDelegate <NSObject>

- (void)recordStateChanged:(MultiRecordState)state lastState:(MultiRecordState)lastState;

- (void)progressUpdate:(CGFloat)current duration:(CGFloat)duration;

@end

@interface MultipleVideoRecorderController : NSObject

// 最长录制时间，分屏录制时等于源视频的时长，全屏录制时默认是30s
@property (nonatomic) CGFloat maxRecordDuration;

@property (nonatomic, weak) id<MultipleVideoRecorderControllerDelegate> delegate;

- (instancetype)init;

- (instancetype)initWithSingle:(BOOL)isSingle;

// 是否是单屏录制
- (void)singleRecord:(BOOL)isSingle;

// 安装摄像头设备
- (void)setupCapture;

// 卸载摄像头
- (void)uninstallCapture;

// 切换摄像头
- (void)switchCamera;

// 安装渲染设备
- (GLKViewWithBounds *)setupRenderWidth:(CGRect)frame;

- (void)setupSourceVideo:(NSString *)sourceVideo;

// 录制操作
- (void)toggleRecord;

// 删除分段
// 返回值：0成功；-1失败
- (int)deleteLastSplit;

// 生成录制视频
- (void)exportVideo:(void(^)(NSString *))exportResult;

// 视频可录制时长
- (CGFloat)recordDuration;

// 视频已录制时长
- (CGFloat)currentDuration;

@end

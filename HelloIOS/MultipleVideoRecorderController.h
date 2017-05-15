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
	MultiRecordStatePrepareRecording,	// 准备录制的相关组件
	MultiRecordStateRecording,			// 录制中
	MultiRecordStateFinish,				// 录制完成
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

@property (nonatomic, weak) id<MultipleVideoRecorderControllerDelegate> delegate;

- (instancetype)init;

// 安装摄像头设备
- (void)setupCapture;

// 安装渲染设备
- (GLKViewWithBounds *)setupRenderWidth:(CGRect)frame;

- (void)setupSourceVideo:(NSString *)sourceVideo;

// 创建录制会话，准备开始录制
- (void)createRecordSession;

// 销毁录制会话，回收资源
- (void)destroyRecordSession;

// 录制操作
- (void)toggleRecord;

// 开始录制分段
- (BOOL)startRecord;

// 停止录制分段
- (void)stopRecord;

// 删除分段
// 返回值：0成功；-1失败
- (int)deleteLastSplit;

- (CGFloat)recordDuration;

- (CGFloat)currentDuration;

@end

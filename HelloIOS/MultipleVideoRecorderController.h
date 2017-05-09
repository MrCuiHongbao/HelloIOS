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

typedef NS_ENUM(NSInteger, MultiRecordState) {
	MultiRecordStateUnknown = 0,
	MultiRecordStateInit,				// 初始化摄像头等
	MultiRecordStateReady,				// 初始化完成，可以开始录制
	MultiRecordStatePrepareRecording,	// 准备录制的相关组件
	MultiRecordStateRecording,			// 录制中
	MultiRecordStateWillDeleteSplit,	// 删除分段确认阶段
	MultiRecordStateFinish,				// 录制完成
	MultiRecordStateFail,
};

@interface GLKViewWithBounds : GLKView

@property (nonatomic, assign) CGRect viewBounds;

@end

@protocol MultipleVideoRecorderControllerDelegate <NSObject>

- (void)lastSplitDeleted;

- (void)recordFinished;

@end

@interface MultipleVideoRecorderController : NSObject

@property (nonatomic, weak) id<MultipleVideoRecorderControllerDelegate> delegate;

- (instancetype)init;

// 安装摄像头设备
- (void)setupCapture;

// 安装渲染设备
- (GLKViewWithBounds *)setupRenderWidth:(int)width height:(int)height;

- (void)setupSourceVideo:(NSString *)sourceVideo;

// 创建录制会话，准备开始录制
- (void)createRecordSession;

// 销毁录制会话，回收资源
- (void)destroyRecordSession;

// 开始录制分段
- (BOOL)startRecord;

// 停止录制分段
- (void)stopRecord;

//- (BOOL)canDeleteSplitLast;

// 删除录制分段
- (BOOL)deleteLastSplit;

@end

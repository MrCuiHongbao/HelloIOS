//
//  CaptureToolKit.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/1.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define DEVICE_BOUNDS [[UIScreen mainScreen] applicationFrame]
#define DEVICE_SIZE [[UIScreen mainScreen] bounds].size
#define DEVICE_OS_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

#define color(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

#define VIDEO_FOLDER @"Videos"

@interface CaptureToolKit : NSObject

+ (void)setView:(UIView *)view toSizeWidth:(CGFloat)width;
+ (void)setView:(UIView *)view toOriginX:(CGFloat)x;
+ (void)setView:(UIView *)view toOriginY:(CGFloat)y;
+ (void)setView:(UIView *)view toOrigin:(CGPoint)origin;

+ (BOOL)createVideoFolderIfNotExist;
+ (NSString *)getVideoSaveFilePathString;
+ (NSString *)getVideoMergeFilePathString;
+ (NSString *)getVideoSaveFolderPathString;

+ (void)writeVideoToPhotoLibrary:(NSURL *)url;

@end

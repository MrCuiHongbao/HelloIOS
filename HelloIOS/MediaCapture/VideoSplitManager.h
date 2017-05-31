//
//  VideoSplitManager.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/31.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoSplitManager : NSObject

+ (VideoSplitManager*)shareInstance;

- (void)clear;

- (BOOL)canDelete;

- (void)pushSplit:(NSString *)path;

- (NSString *)popSplit;

- (NSString *)allocNewSplit;

- (NSArray *)getAllSplits;

@end

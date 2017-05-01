//
//  UISegmentProgressBar.h
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/1.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum
{
	ProgressBarProgressStyleNormal,
	ProgressBarProgressStyleDelete,
} ProgressBarProgressStyle;

@interface UISegmentProgressBar : UIView

+ (UISegmentProgressBar *)getInstance;

- (void)setLastProgressToStyle:(ProgressBarProgressStyle)style;
- (void)setLastProgressToWidth:(CGFloat)width;

- (void)deleteLastProgress;
- (void)addProgressView;

- (void)stopShining;
- (void)startShining;

@end

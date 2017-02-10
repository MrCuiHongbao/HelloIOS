//
//  PlayerView.h
//  HelloIOS
//
//  Created by sethmao on 2017/2/10.
//  Copyright © 2017年 younger. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface PlayerView : UIView

@property (nonatomic ,strong) AVPlayer *player;

- (void)setVideoFillMode:(NSString *)fillMode;

@end

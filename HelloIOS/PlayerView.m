//
//  PlayerView.m
//  HelloIOS
//
//  Created by sethmao on 2017/2/10.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "PlayerView.h"

@implementation PlayerView

- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		// Initialization code
	}
	return self;
}

+ (Class)layerClass {
	return [AVPlayerLayer class];
}

- (AVPlayer *)player {
	return [(AVPlayerLayer *)[self layer] player];
}

- (void)setPlayer:(AVPlayer *)player {
	[(AVPlayerLayer *)[self layer] setPlayer:player];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
	AVPlayerLayer *playerLayer = (AVPlayerLayer *)[self layer];
	playerLayer.videoGravity = fillMode;
	
#if TARGET_OS_IPHONE
	[self sizeToFit];
#endif
}

/*
 // Only override drawRect: if you perform custom drawing.
 // An empty implementation adversely affects performance during animation.
 - (void)drawRect:(CGRect)rect
 {
 // Drawing code
 }
 */

@end

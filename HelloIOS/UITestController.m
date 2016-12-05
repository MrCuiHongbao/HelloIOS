//
//  UITestController.m
//  HelloIOS
//
//  Created by sethmao on 2016/11/18.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "UITestController.h"

@interface UITestController ()

@property (nonatomic, strong) UIButton *button;
@property (nonatomic, strong) UIImageView *imageView;

@end

@implementation UITestController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
	self.view = container;
	
	self.button = ({
		UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
		[button setFrame:CGRectMake(100, 200, 100, 20)];
		[button setImage:[UIImage imageNamed:@"icon2"] forState:UIControlStateNormal];
		
		[button setImageEdgeInsets:UIEdgeInsetsMake(0, -3, 0, 0)];
		[button setTitle:@"播放完整视频" forState:UIControlStateNormal];
		[button setTitleEdgeInsets:UIEdgeInsetsMake(-1, 0, 0, -3)];
		[button.titleLabel setTextAlignment:NSTextAlignmentCenter];
		button.titleLabel.font = [UIFont systemFontOfSize:12];
		[button setTitleColor:[UIColor colorWithWhite:1 alpha:1] forState:UIControlStateNormal];
		[button setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.6]];
		//[button setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:1 alpha:1]];
		button.layer.cornerRadius = CGRectGetHeight(button.frame) / 2;
		button.layer.masksToBounds = YES;
		[container addSubview:button];
		[button setEnabled:NO];
		button.adjustsImageWhenDisabled = NO;
		button;
	});
	
	self.imageView = ({
		UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 50, 50)];
		[image setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
		[image setImage:[UIImage imageNamed:@"icon2"]];
		[image setContentMode:UIViewContentModeCenter];
		[container addSubview:image];
		image;
	});
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self performSelector:@selector(action) withObject:nil afterDelay:4];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
	NSLog(@"[%s], animated=%d", __FUNCTION__, animated);
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self];
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(action) object:nil];
}

- (void)dealloc
{
	NSLog(@"%s", __FUNCTION__);
}

- (void)action
{
	NSLog(@"%s", __FUNCTION__);
	
	[self.button setHidden:NO];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

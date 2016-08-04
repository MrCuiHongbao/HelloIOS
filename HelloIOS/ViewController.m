//
//  ViewController.m
//  HelloIOS
//
//  Created by sethmao on 16/4/16.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "ViewController.h"
#import "UICircleView.h"
#import "MainViewController.h"

@interface ViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIButton *btnView;

@end

@implementation ViewController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
	self.view = container;
	
	_btnView = [UIButton buttonWithType:UIButtonTypeSystem];
	[_btnView setFrame:CGRectMake(100, 100, 200, 60)];
	[_btnView setBackgroundColor:[UIColor redColor]];
	[_btnView addTarget:self action:@selector(clickBtn) forControlEvents:UIControlEventTouchUpInside];
	[_btnView setTitle:@"MainViewController" forState:UIControlStateNormal];
	[container addSubview:_btnView];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Root";
	[self.navigationController.navigationBar setBarTintColor:[UIColor purpleColor]];
	
}

- (void)clickBtn
{
	NSLog(@"Click btn.");
	
	MainViewController *main = [[MainViewController alloc] init];
	[self.navigationController pushViewController:main animated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
	
}

- (void)viewDidAppear:(BOOL)animated
{
	
}

@end

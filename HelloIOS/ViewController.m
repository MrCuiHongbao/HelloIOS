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
	[_btnView addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
	[_btnView setTitle:@"Next" forState:UIControlStateNormal];
	[container addSubview:_btnView];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Root";
	[self.navigationController.navigationBar setBarTintColor:[UIColor purpleColor]];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(clickBtn:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(clickBtn:)];
	[self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
}

- (void)clickBtn:(id)sender
{
	if (sender == self.navigationItem.leftBarButtonItem)
	{
		NSLog(@"Click left.");
	}
	else if (sender == self.navigationItem.rightBarButtonItem)
	{
		NSLog(@"Click right.");
	}
	else
	{
		NSLog(@"Click btn.");
		
		MainViewController *main = [[MainViewController alloc] init];
		[self.navigationController pushViewController:main animated:YES];
	}
}

- (void)viewWillAppear:(BOOL)animated
{
	
}

- (void)viewDidAppear:(BOOL)animated
{
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	
}

- (void)viewDidDisappear:(BOOL)animated
{
	
}

@end

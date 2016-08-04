//
//  MainViewController.m
//  HelloIOS
//
//  Created by sethmao on 16/8/4.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "MainViewController.h"

@implementation MainViewController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
	self.view = container;
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"MainViewController";
}

@end

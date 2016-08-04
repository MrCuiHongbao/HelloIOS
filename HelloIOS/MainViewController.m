//
//  MainViewController.m
//  HelloIOS
//
//  Created by sethmao on 16/8/4.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) UIButton *showAlertBtn1;
@property (nonatomic, strong) UIButton *showAlertBtn2;
@property (nonatomic, strong) UIButton *showAlertBtn3;

@end

@implementation MainViewController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
	self.view = container;
	
	_showAlertBtn1 = [UIButton buttonWithType:UIButtonTypeSystem];
	[_showAlertBtn1 setFrame:CGRectMake(100, 100, 200, 60)];
	[_showAlertBtn1 setBackgroundColor:[UIColor redColor]];
	[_showAlertBtn1 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
	[_showAlertBtn1 setTitle:@"showAlert1" forState:UIControlStateNormal];
	[container addSubview:_showAlertBtn1];
	
	_showAlertBtn2 = [UIButton buttonWithType:UIButtonTypeSystem];
	[_showAlertBtn2 setFrame:CGRectMake(100, 180, 200, 60)];
	[_showAlertBtn2 setBackgroundColor:[UIColor redColor]];
	[_showAlertBtn2 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
	[_showAlertBtn2 setTitle:@"showAlert2" forState:UIControlStateNormal];
	[container addSubview:_showAlertBtn2];
	
	_showAlertBtn3 = [UIButton buttonWithType:UIButtonTypeSystem];
	[_showAlertBtn3 setFrame:CGRectMake(100, 260, 200, 60)];
	[_showAlertBtn3 setBackgroundColor:[UIColor redColor]];
	[_showAlertBtn3 addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
	[_showAlertBtn3 setTitle:@"showAlert3" forState:UIControlStateNormal];
	[container addSubview:_showAlertBtn3];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"MainViewController";
}

- (void)clickBtn:(id)sender
{
	if (sender == _showAlertBtn1)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"title" message:@"message" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"ok", nil];
		[alert show];
	}
	else if (sender == _showAlertBtn2)
	{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"title" message:@"message" preferredStyle:UIAlertControllerStyleAlert];
		[alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action){
			NSLog(@"点击取消");
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action){
			NSLog(@"点击确定");
		}]];
		[self presentViewController:alert animated:YES completion:nil];
	}
	else if (sender == _showAlertBtn3)
	{
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"title" message:@"message" preferredStyle:UIAlertControllerStyleActionSheet];
		[alert addAction:[UIAlertAction actionWithTitle:@"cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *_Nonnull action){
			NSLog(@"点击取消");
		}]];
		[alert addAction:[UIAlertAction actionWithTitle:@"ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action){
			NSLog(@"点击确定");
		}]];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSLog(@"alertView index %ld", buttonIndex);
}

@end

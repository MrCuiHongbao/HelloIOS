//
//  UISegmentProgressBarViewController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/1.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "UISegmentProgressBarViewController.h"
#import "UISegmentProgressBar.h"

#define TIMER_INTERVAL 0.033f
#define MAX_RECORD	15
#define MIN_RECORD	3

@interface UISegmentProgressBarViewController ()

@property (nonatomic, retain, getter=actionBtn) UIButton *mActionBtn;

@property (nonatomic, retain, getter=deleteBtn) UIButton *mDeleteBtn;

@property (nonatomic, retain, getter=resetBtn) UIButton *mResetBtn;

@property (nonatomic, retain, getter=segmentBar) UISegmentProgressBar *mSegmentBar;

@property (strong, nonatomic, getter=recordTimer) NSTimer *mRecordTimer;

@property (nonatomic, assign) int sw;
@property (nonatomic, assign) int sh;

@property (nonatomic, assign) BOOL mIsRecording;

@property (nonatomic, assign) BOOL mIsCanDelete;

@property (nonatomic, assign) CGFloat mDuration;
@property (nonatomic, assign) CGFloat mTotalDuration;

@end

@implementation UISegmentProgressBarViewController

- (UIButton *)actionBtn
{
	if (!_mActionBtn)
	{
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		[btn setFrame:CGRectMake(0, 0, 50, 50)];
		[btn setCenter:CGPointMake(self.sw/2, self.sh*2/3)];
		[btn setTitle:@"Action" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_mActionBtn = btn;
	}
	
	return _mActionBtn;
}

- (UIButton *)deleteBtn
{
	if (!_mDeleteBtn)
	{
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		[btn setFrame:CGRectMake(0, 0, 50, 50)];
		[btn setCenter:CGPointMake(self.sw/2 - 70, self.sh*2/3)];
		[btn setTitle:@"Delete" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_mDeleteBtn = btn;
	}
	
	return _mDeleteBtn;
}

- (UIButton *)resetBtn
{
	if (!_mResetBtn)
	{
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		[btn setFrame:CGRectMake(0, 0, 50, 50)];
		[btn setCenter:CGPointMake(self.sw/2 + 70, self.sh*2/3)];
		[btn setTitle:@"Reset" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_mResetBtn = btn;
	}
	
	return _mResetBtn;
}

- (UISegmentProgressBar *)segmentBar
{
	if (!_mSegmentBar)
	{
		UISegmentProgressBar *bar = [UISegmentProgressBar getInstance];
		[bar setCenter:CGPointMake(self.sw/2, 50)];
		_mSegmentBar = bar;
	}
	
	return _mSegmentBar;
}

- (void)onClickBtn:(id)sender
{
	if (sender == self.mActionBtn)
	{
		if (!self.mIsRecording)
		{
			if (self.mIsCanDelete)
			{
				self.mIsCanDelete = NO;
				[self.mSegmentBar setLastProgressToStyle:ProgressBarProgressStyleNormal];
			}
			
			self.mDuration = 0;
			self.mIsRecording = YES;
			[self.mSegmentBar addProgressView];
			[self.mSegmentBar stopShining];
			self.mRecordTimer = [NSTimer scheduledTimerWithTimeInterval:TIMER_INTERVAL target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
		}
		else
		{
			if (self.mDuration < MIN_RECORD && self.mTotalDuration < MAX_RECORD)
			{
				return;
			}
			
			self.mIsRecording = NO;
			[self.mRecordTimer invalidate];
			self.mRecordTimer = nil;
			
			if (self.mTotalDuration < MAX_RECORD)
			{
				[self.mSegmentBar startShining];
			}
		}
	}
	else if (sender == self.mDeleteBtn)
	{
		if (!self.mIsRecording)
		{
			if (!self.mIsCanDelete)
			{
				self.mIsCanDelete = YES;
				[self.mSegmentBar setLastProgressToStyle:ProgressBarProgressStyleDelete];
			}
			else
			{
				self.mIsCanDelete = NO;
				[self.mSegmentBar deleteLastProgress];
				self.mTotalDuration -= self.mDuration;
			}
		}
	}
	else if (sender == self.mResetBtn)
	{
		
	}
}

- (void)onTimer:(NSTimer *)timer
{
	if (self.mTotalDuration >= MAX_RECORD)
	{
		[self onClickBtn:self.mActionBtn];
	}
	else
	{
		self.mDuration += 0.03;
		self.mTotalDuration += 0.03;
		CGFloat barWidth = self.mDuration * CGRectGetWidth(self.mSegmentBar.frame) / MAX_RECORD;
		[self.mSegmentBar setLastProgressToWidth:barWidth];
	}
}

- (void)loadView
{
	[super loadView];
	
	self.sw = [[UIScreen mainScreen] bounds].size.width;
	self.sh = [[UIScreen mainScreen] bounds].size.height;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	[self.view addSubview:self.mActionBtn];
	[self.view addSubview:self.mDeleteBtn];
	[self.view addSubview:self.mResetBtn];
	[self.view addSubview:self.mSegmentBar];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	[self.mSegmentBar startShining];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

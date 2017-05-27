//
//  SingleRecordViewController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/27.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "SingleRecordViewController.h"
#import "SplitRecordViewController.h"

@interface SingleRecordViewController ()

@end

@implementation SingleRecordViewController

- (void)loadView {
	[super loadView];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	SplitRecordViewController *cvc = [[SplitRecordViewController alloc] init];
	cvc.isSingle = YES;
	[self displayContentController:cvc];
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

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (CGRect)frameForContentController {
	return self.view.frame;
}

- (void) displayContentController: (UIViewController*) content {
	[self addChildViewController:content];
	content.view.frame = [self frameForContentController];
	[self.view addSubview:content.view];
	[content didMoveToParentViewController:self];
}

- (void) hideContentController: (UIViewController*) content {
	[content willMoveToParentViewController:nil];
	[content.view removeFromSuperview];
	[content removeFromParentViewController];
}


@end

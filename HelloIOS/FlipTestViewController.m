//
//  FlipTestViewController.m
//  HelloIOS
//
//  Created by JuliusZhou on 15/05/2017.
//  Copyright © 2017 younger. All rights reserved.
//

#import "FlipTestViewController.h"

@interface FlipTestViewController ()

@property (strong, nonatomic) IBOutlet UIImageView *imageVC;
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIView *container;

@property (nonatomic, assign) BOOL front;

@end

@implementation FlipTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image2.jpg"]];
    }
    return _backgroundImageView;
}

//- (UIImageView *)imageVC {
//	if (_imageVC) {
//		_imageVC = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"image1"]];
//	}
//	return _imageVC;
//}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)flip:(UITapGestureRecognizer *)sender {
	self.backgroundImageView.frame = self.imageVC.frame;
	[UIView transitionFromView:self.front ? self.backgroundImageView : self.imageVC
						toView:self.front ? self.imageVC : self.backgroundImageView duration:0.4 options:UIViewAnimationOptionTransitionFlipFromLeft
					completion:^(BOOL finished) {
						if (finished) {
							self.front = !self.front;
						}
						
//        [self.container addSubview:self.backgroundImageView];
    }];
}

@end

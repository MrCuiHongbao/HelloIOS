//
//  BiggerTableViewCell.h
//  TableViewTest
//
//  Created by JuliusZhou on 8/8/16.
//  Copyright © 2016 JuliusZhou. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BiggerTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *backgroundContent;

@property (nonatomic, strong) UIImageView *playerView;
@property (nonatomic, strong) UIView *cover;
@property (nonatomic, strong) UIView *mask;

@property (nonatomic, strong) UILabel *topLabel;
@property (nonatomic, strong) UILabel *bottomLabel;

- (void)setupUI;

@end

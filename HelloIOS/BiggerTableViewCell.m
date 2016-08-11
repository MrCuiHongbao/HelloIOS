//
//  BiggerTableViewCell.m
//  TableViewTest
//
//  Created by JuliusZhou on 8/8/16.
//  Copyright © 2016 JuliusZhou. All rights reserved.
//

#import "BiggerTableViewCell.h"

@implementation BiggerTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupUI
{
//    self.contentView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:self.backgroundContent];
//    self.contentView.contentMode = UIViewContentModeScaleAspectFit;
//    self.contentMode = UIViewContentModeScaleAspectFit;
    self.contentView.superview.clipsToBounds = NO;
//    self.backgroundContent.frame = self.contentView.bounds;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.backgroundColor = [UIColor clearColor];
//    self.contentView.frame = CGRectOffset(self.contentView.frame, 0, -50);
//    self.contentView.superview.clipsToBounds = NO;
}

@end

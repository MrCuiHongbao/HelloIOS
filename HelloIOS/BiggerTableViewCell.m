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

- (UIImageView *)playerView
{
	if (!_playerView) {
		_playerView = [[UIImageView alloc] init];
//		_playerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	}
	return _playerView;
}

- (UIView *)cover
{
	if (!_cover) {
		_cover = [[UIView alloc] init];
		_cover.userInteractionEnabled = NO;
	}
	return _cover;
}

- (UIView *)mask {
	if (!_mask) {
		_mask = [[UIView alloc] init];
		_mask.userInteractionEnabled = NO;
	}
	return _mask;
}

- (UILabel *)topLabel {
	if (!_topLabel) {
		_topLabel = [[UILabel alloc] init];
		_topLabel.font = [UIFont systemFontOfSize:11];
		_topLabel.textColor = [UIColor whiteColor];
	}
	return _topLabel;
}

- (UILabel *)bottomLabel {
	if (!_bottomLabel) {
		_bottomLabel = [[UILabel alloc] init];
		_bottomLabel.font = [UIFont systemFontOfSize:11];
        _bottomLabel.textColor = [UIColor whiteColor];
	}
	return _bottomLabel;
}

- (void)setupUI
{
//    self.contentView.backgroundColor = [UIColor blackColor];
    [self.contentView addSubview:self.backgroundContent];
	
	self.contentView.backgroundColor = UIColor.clearColor;
	self.playerView.image = [UIImage imageNamed:@"image1"];
	self.playerView.frame = self.contentView.bounds;
	self.playerView.backgroundColor = [UIColor clearColor];
	[self.contentView addSubview:self.playerView];
//	self.playerView.alpha = 0.5;
	
	self.cover.frame = CGRectMake(0, -30, self.contentView.bounds.size.width, CGRectGetHeight(self.contentView.bounds) + 60);
//	self.mask.frame = self.contentView.bounds;
//	[self.contentView addSubview:self.cover];
//	self.cover.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4];
	self.cover.backgroundColor = [UIColor clearColor];
	
	if (!self.maskView) {
		self.maskView = [[UIView alloc] init];
	}
	self.maskView.frame = self.contentView.bounds;
	[self.contentView addSubview:self.maskView];
	self.maskView.backgroundColor = [UIColor blackColor];
	self.maskView.alpha = 0.7;
	
	self.topLabel.frame = CGRectMake(10, 5, 0, 0);
	[self.topLabel sizeToFit];
	[self.cover addSubview:self.topLabel];
	
	self.bottomLabel.frame = CGRectMake(10, 30 + self.contentView.bounds.size.height + 5, 0, 0);
	[self.bottomLabel sizeToFit];
	[self.cover addSubview:self.bottomLabel];
	
	self.clipsToBounds = NO;
	self.contentView.clipsToBounds = NO;
	
//	self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
//	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView
//																 attribute:NSLayoutAttributeTop
//																 relatedBy:NSLayoutRelationEqual
//																	toItem:self.contentView
//																 attribute:NSLayoutAttributeTop
//																multiplier:1.0f
//																  constant:0.0f]];
//	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView
//																 attribute:NSLayoutAttributeBottom
//																 relatedBy:NSLayoutRelationEqual
//																	toItem:self.contentView
//																 attribute:NSLayoutAttributeBottom
//																multiplier:1.0f
//																  constant:0.0f]];
//	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView
//																 attribute:NSLayoutAttributeLeading
//																 relatedBy:NSLayoutRelationEqual
//																	toItem:self.contentView
//																 attribute:NSLayoutAttributeLeading
//																multiplier:1.0f
//																  constant:0.0f]];
//	[self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.playerView
//																 attribute:NSLayoutAttributeTrailing
//																 relatedBy:NSLayoutRelationEqual
//																	toItem:self.contentView
//																 attribute:NSLayoutAttributeTrailing
//																multiplier:1.0f
//																  constant:0.0f]];
	
//	self.playerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	
//	self.playerView.backgroundColor = [UIColor lightGrayColor];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
	self.playerView.frame = self.contentView.bounds;
    self.backgroundColor = [UIColor clearColor];
//    self.contentView.frame = CGRectOffset(self.contentView.frame, 0, -50);
//    self.contentView.superview.clipsToBounds = NO;
}

@end

//
//  TableViewCell.m
//  HelloIOS
//
//  Created by JuliusZhou on 8/8/16.
//  Copyright © 2016 younger. All rights reserved.
//

#import "TableViewCell.h"

@implementation TableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (UIView *)backgroundContentView
{
	if (!_backgroundContentView) {
		_backgroundContentView = [[UIView alloc] init];
	}
	return _backgroundContentView;
}


@end

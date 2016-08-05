//
//  EntryCell.m
//  HelloIOS
//
//  Created by sethmao on 16/8/5.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "EntryCell.h"

#define CELL_HEIGHT (80)

@implementation EntryCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self)
	{
		
	}
	
	return self;
}

+ (int)cellHeight
{
	return CELL_HEIGHT;
}

@end

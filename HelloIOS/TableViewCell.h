//
//  TableViewCell.h
//  HelloIOS
//
//  Created by JuliusZhou on 8/8/16.
//  Copyright © 2016 younger. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *backgroundContentView;

- (void)setOuterView;

@end

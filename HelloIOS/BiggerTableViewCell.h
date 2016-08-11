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

- (void)setupUI;

@end

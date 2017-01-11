//
//  UITableViewEnhanced.h
//  HelloIOS
//
//  Created by sethmao on 2016/12/9.
//  Copyright © 2016年 younger. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol UITableViewDataSourcePrefetching1 <UITableViewDataSourcePrefetching>

@end

@interface UITableView1 : UITableView

@property (nonatomic, weak, nullable) id <UITableViewDataSource> dataSource1;
@property (nonatomic, weak, nullable) id <UITableViewDataSourcePrefetching> dataSourcePrefetch1;
@property (nonatomic, weak, nullable) id <UITableViewDelegate> delegate1;

@end

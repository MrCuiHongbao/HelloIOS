//
//  UITableViewEnhancedController.m
//  HelloIOS
//
//  Created by sethmao on 2016/12/9.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "UITableViewEnhancedController.h"
#import "UITableView1.h"
#import "EntryCell.h"

@interface UITableViewEnhancedController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView1 *entryTable;
@property (nonatomic, strong) NSArray *entryList;

@end

@implementation UITableViewEnhancedController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
	self.view = container;
	
	self.entryTable = [[UITableView1 alloc] initWithFrame:container.bounds style:UITableViewStylePlain];
	self.entryTable.delegate1 = self;
	self.entryTable.dataSource1 = self;
	// _entryTable.pagingEnabled = YES;
	[container addSubview:self.entryTable];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"UITableViewEnhancedController";
	
	int capacity = 100;
	NSMutableArray<NSString *> *entryList = [NSMutableArray arrayWithCapacity:capacity];
	for (int i=0; i<capacity; i++)
	{
		[entryList addObject:[NSString stringWithFormat:@"XOXOXOXOXOXOXOXXOXOXO%d", i]];
	}
	self.entryList = entryList;
}

- (void)viewWillAppear:(BOOL)animated
{
	
}

- (void)viewDidAppear:(BOOL)animated
{
	
}

- (void)viewWillDisappear:(BOOL)animated
{
	
}

- (void)viewDidDisappear:(BOOL)animated
{
	
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return [_entryList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *entryCellId = @"entryId";
	
	EntryCell *cell = [tableView dequeueReusableCellWithIdentifier:entryCellId];
	if (!cell)
	{
		cell = [[EntryCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:entryCellId];
	}
	
	cell.textLabel.text = [_entryList objectAtIndex:indexPath.row];
	
	return cell;
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 200;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	NSLog(@"%s", __FUNCTION__);
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
	
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
}

@end

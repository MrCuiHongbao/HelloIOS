//
//  PinTableViewController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/8/16.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "PinTableViewController.h"
#import "EntryCell.h"

@interface PinTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *entryTable;
@property (nonatomic, strong) NSMutableArray *entryList;
@property (nonatomic, strong) UIButton *addButton;

@end

@implementation PinTableViewController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
	self.view = container;
	
	self.entryTable = [[UITableView alloc] initWithFrame:container.bounds style:UITableViewStylePlain];
	self.entryTable.delegate = self;
	self.entryTable.dataSource = self;
	[container addSubview:self.entryTable];
	
	self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
	[self.addButton setFrame:CGRectMake(100, 100, 200, 50)];
	[self.addButton setTitle:@"增加数据" forState:UIControlStateNormal];
	[self.addButton addTarget:self action:@selector(onClick) forControlEvents:UIControlEventTouchUpInside];
	[container addSubview:self.addButton];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"PinTableViewController";
	
	self.entryList = [NSMutableArray array];
	
	[self.entryList addObject:@"xxoo"];
	[self.entryList addObject:@"xxoo"];
	[self.entryList addObject:@"xxoo"];
	[self.entryList addObject:@"xxoo"];
	[self.entryList addObject:@"xxoo"];
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

- (void)onClick {
	NSIndexPath *indexPath = [NSIndexPath indexPathForRow:1 inSection:0];
	[_entryTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
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
	
	cell.textLabel.text = [NSString stringWithFormat:@"%@,%p", [_entryList objectAtIndex:indexPath.row], cell];
	
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

//
//  ViewController.m
//  HelloIOS
//
//  Created by sethmao on 16/4/16.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "ViewController.h"
#import "MainViewController.h"
#import "EntryCell.h"
#import "UITableView1.h"

@interface ViewController () <UIGestureRecognizerDelegate, UITableViewDelegate, UITableViewDataSource>

//@property (nonatomic, strong) UIButton *btnView;
@property (nonatomic, strong) UITableView1 *entryTable;
@property (nonatomic, strong) NSArray *entryList;

@end

@implementation ViewController

- (void)loadView
{
	CGSize size = [UIScreen mainScreen].bounds.size;
	
	UIView *container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
	[container setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
	self.view = container;
	
//	_btnView = [UIButton buttonWithType:UIButtonTypeSystem];
//	[_btnView setFrame:CGRectMake(100, 100, 200, 60)];
//	[_btnView setBackgroundColor:[UIColor redColor]];
//	[_btnView addTarget:self action:@selector(clickBtn:) forControlEvents:UIControlEventTouchUpInside];
//	[_btnView setTitle:@"Next" forState:UIControlStateNormal];
//	[container addSubview:_btnView];
	
	_entryTable = [[UITableView1 alloc] initWithFrame:container.bounds style:UITableViewStylePlain];
	_entryTable.delegate1 = self;
	_entryTable.dataSource1 = self;
	// _entryTable.pagingEnabled = YES;
	[container addSubview:_entryTable];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	self.title = @"Root";
	[self.navigationController.navigationBar setBarTintColor:[UIColor purpleColor]];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(clickBtn:)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(clickBtn:)];
	[self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
	
	_entryList = @[@"MainViewController",
				   @"UITestController",
				   @"UITableViewEnhancedController",
				   @"AVPlayerViewController",
				   @"RecordController",
				   @"VideoCompositionController",
				   @"UISegmentProgressBarViewController",
				   @"SplitRecordViewController"];
}

- (void)clickBtn:(id)sender
{
	if (sender == self.navigationItem.leftBarButtonItem)
	{
		NSLog(@"Click left.");
	}
	else if (sender == self.navigationItem.rightBarButtonItem)
	{
		NSLog(@"Click right.");
	}
	else
	{
		NSLog(@"Click btn.");
		
		MainViewController *main = [[MainViewController alloc] init];
		[self.navigationController pushViewController:main animated:YES];
	}
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
	return [EntryCell cellHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:NO];
	NSString *entryName = [_entryList objectAtIndex:indexPath.row];
	id object = [[NSClassFromString(entryName) alloc] init];
	if (object)
	{
		[self.navigationController pushViewController:object animated:YES];
	}
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

@end

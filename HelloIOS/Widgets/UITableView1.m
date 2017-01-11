//
//  UITableViewEnhanced.m
//  HelloIOS
//
//  Created by sethmao on 2016/12/9.
//  Copyright © 2016年 younger. All rights reserved.
//

#import "UITableView1.h"

//#define PRINT_METHOD

typedef NS_ENUM(NSInteger, UITableViewScrollDirection) {
	UITableViewScrollDirection_None,
	UITableViewScrollDirection_Up,		// 向上滚动，即看下面的内容
	UITableViewScrollDirection_Down
};

@interface UITableView1 () <UITableViewDelegate, UITableViewDataSource>

// 单方向预处理能力值，默认为10
@property (nonatomic) int preFetchCapacity;

// 当前屏幕上面的预处理索引
@property (nonatomic, strong) NSMutableSet *aboveIndexPreFetchs;

// 当前屏幕下面的预处理索引
@property (nonatomic, strong) NSMutableSet *belowIndexPreFetchs;

// 滚动方向
@property (nonatomic) UITableViewScrollDirection scrolledDirection;
@property (nonatomic) BOOL willScroll;

@end

@implementation UITableView1

- (instancetype)initWithFrame:(CGRect)frame style:(UITableViewStyle)style
{
	if (self = [super initWithFrame:frame style:style])
	{
		self.delegate = self;
		self.dataSource = self;
		self.preFetchCapacity = 10;
		
		self.aboveIndexPreFetchs = [NSMutableSet set];
		self.belowIndexPreFetchs = [NSMutableSet set];
	}
	
	return self;
}

- (void)printMethodName:(NSString *)name
{
#ifdef PRINT_METHOD
	NSLog(@"%@", name);
#endif
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	NSInteger ret = [self.dataSource1 tableView:tableView numberOfRowsInSection:section];
	
	return ret;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	UITableViewCell *ret = [self.dataSource1 tableView:tableView cellForRowAtIndexPath:indexPath];
	
	NSLog(@"cellForRowAtIndexPath index=%@", @(indexPath.row));
	
	if (self.scrolledDirection == UITableViewScrollDirection_None || self.scrolledDirection == UITableViewScrollDirection_Down)
	{
		if (![self.belowIndexPreFetchs containsObject:@(indexPath.row)])
		{
			[self.belowIndexPreFetchs addObject:@(indexPath.row)];
			[self.dataSourcePrefetch1 tableView:self prefetchRowsAtIndexPaths:@[@(indexPath.row)]];
		}
	}
	else
	{
		
	}
	
	return ret;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	NSInteger ret = 1;
	if ([self.dataSource1 respondsToSelector:@selector(numberOfSectionsInTableView:)])
	{
		ret = [self.dataSource1 numberOfSectionsInTableView:tableView];
	}
	
	return ret;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	NSString *ret = nil;
	if ([self.dataSource1 respondsToSelector:@selector(tableView:titleForHeaderInSection:)])
	{
		ret = [self.dataSource1 tableView:tableView titleForHeaderInSection:section];
	}
	
	return ret;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	NSString *ret = nil;
	if([self.dataSource1 respondsToSelector:@selector(tableView:titleForFooterInSection:)])
	{
		ret = [self.dataSource1 tableView:tableView titleForFooterInSection:section];
	}
	
	return ret;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	BOOL ret = NO;
	if ([self.dataSource1 respondsToSelector:@selector(tableView:canEditRowAtIndexPath:)])
	{
		ret = [self.dataSource1 tableView:tableView canEditRowAtIndexPath:indexPath];
	}
	
	return ret;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	BOOL ret = NO;
	if ([self.dataSource1 respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)])
	{
		ret = [self.dataSource1 tableView:tableView canMoveRowAtIndexPath:indexPath];
	}
	
	return ret;
}

- (nullable NSArray<NSString *> *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	NSArray<NSString *> *ret = nil;
	if ([self.dataSource1 respondsToSelector:@selector(sectionIndexTitlesForTableView:)])
	{
		ret = [self.dataSource1 sectionIndexTitlesForTableView:tableView];
	}
	
	return ret;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	NSInteger ret = 0;
	if ([self.dataSource1 respondsToSelector:@selector(tableView:sectionForSectionIndexTitle:atIndex:)])
	{
		ret = [self.dataSource1 tableView:tableView sectionForSectionIndexTitle:title atIndex:index];
	}
	
	return ret;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	if ([self.dataSource1 respondsToSelector:@selector(tableView:commitEditingStyle:forRowAtIndexPath:)])
	{
		[self.dataSource1 tableView:tableView commitEditingStyle:editingStyle forRowAtIndexPath:indexPath];
	}
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	if ([self.dataSource1 respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)])
	{
		[self.dataSource1 tableView:tableView moveRowAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
	}
}

#pragma mark UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	CGFloat ret = 0;
	if ([self.delegate1 respondsToSelector:@selector(tableView:heightForRowAtIndexPath:)])
	{
		ret = [self.delegate1 tableView:tableView heightForRowAtIndexPath:indexPath];
	}
	
	NSLog(@"heightForRowAtIndexPath index=%@", @(indexPath.row));
	
	return ret;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 tableView:tableView didSelectRowAtIndexPath:indexPath];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	
	CGFloat translationY = [self.panGestureRecognizer translationInView:self].y;
	if (translationY == 0)
	{
		// 进入或者退出
	}
	
	[self.delegate1 scrollViewDidScroll:scrollView];
	
	if (translationY != 0 && !self.willScroll)
	{
		self.willScroll = YES;
		self.scrolledDirection = translationY ? UITableViewScrollDirection_Down : UITableViewScrollDirection_Up;
	}
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewDidZoom:scrollView];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewWillBeginDragging:scrollView];
	
	self.willScroll = NO;
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewWillEndDragging:scrollView withVelocity:velocity targetContentOffset:targetContentOffset];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewDidEndDragging:scrollView willDecelerate:decelerate];
}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewWillBeginDecelerating:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewDidEndDecelerating:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	[self.delegate1 scrollViewDidEndScrollingAnimation:scrollView];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	if ([self.delegate1 respondsToSelector:@selector(tableView:willDisplayCell:forRowAtIndexPath:)])
	{
		[self.delegate1 tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
	}
	
	if (self.scrolledDirection == UITableViewScrollDirection_Up)
	{
		
	}
	else if (self.scrolledDirection == UITableViewScrollDirection_Down)
	{
		
	}
	else
	{
		
	}
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	if ([self.delegate1 respondsToSelector:@selector(tableView:willDisplayHeaderView:forSection:)])
	{
		[self.delegate1 tableView:tableView willDisplayHeaderView:view forSection:section];
	}
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	if ([self.delegate1 respondsToSelector:@selector(tableView:willDisplayFooterView:forSection:)])
	{
		[self.delegate1 tableView:tableView willDisplayFooterView:view forSection:section];
	}
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
	[self printMethodName:[NSString stringWithUTF8String:__FUNCTION__]];
	if ([self.delegate1 respondsToSelector:@selector(tableView:didEndDisplayingCell:forRowAtIndexPath:)])
	{
		[self.delegate1 tableView:tableView didEndDisplayingCell:cell forRowAtIndexPath:indexPath];
	}
	
	if (self.scrolledDirection == UITableViewScrollDirection_Up)
	{
		
	}
	else if (self.scrolledDirection == UITableViewScrollDirection_Down)
	{
		
	}
	else
	{
		
	}
}

@end

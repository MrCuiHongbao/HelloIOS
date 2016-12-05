//
//  BiggerTableViewController.m
//  TableViewTest
//
//  Created by JuliusZhou on 8/8/16.
//  Copyright © 2016 JuliusZhou. All rights reserved.
//

#import "BiggerTableViewController.h"
#import "BiggerTableViewCell.h"

@interface BiggerTableViewController () {
	CGFloat MAXOffset;
}

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSArray *cellHeights;

@property (nonatomic, strong) NSIndexPath *middleIndexPath;
@property (nonatomic, strong) NSIndexPath *playingIndexPath;
@property (nonatomic, assign) UIDeviceOrientation orientation;

@property (nonatomic, strong) __kindof UIView *fullScreenView;

@end

@implementation BiggerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.dataSource = @[UIColor.redColor, UIColor.blueColor, UIColor.greenColor, UIColor.yellowColor, UIColor.brownColor, UIColor.orangeColor];
    self.dataSource = @[@"1", @"2", @"3", @"4", @"5", @"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13",@"14",@"15"];
    self.cellHeights = @[@(300), @(330), @(250), @(360), @(130), @(220), @(150), @(250), @(320), @(270), @(280), @(310), @(330), @(320), @(340)];
    
    self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
	
	MAXOffset = 0.75 * self.view.bounds.size.height / 2;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, CGRectGetHeight(self.view.bounds)/2 - 300/2 )];
    headerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.tableView.tableHeaderView = headerView;
//	self.view.backgroundColor = [UIColor clearColor];
	self.playingIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//    self.tableView.sectionHeaderHeight = 60;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(orientationDidChanged:) name:UIDeviceOrientationDidChangeNotification object:UIDevice.currentDevice];
	self.orientation = UIDevice.currentDevice.orientation;
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[NSNotificationCenter.defaultCenter removeObserver:self name:UIDeviceOrientationDidChangeNotification object:UIDevice.currentDevice];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
#warning Incomplete implementation, return the number of sections
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
#warning Incomplete implementation, return the number of rows
    return self.dataSource.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.cellHeights[indexPath.row] integerValue];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BiggerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cellID" forIndexPath:indexPath];
    
    // Configure the cell...
    [cell setupUI];
	
	CGRect cellFrame = [tableView rectForRowAtIndexPath:indexPath];
	cell.cover.frame = (CGRect){ cellFrame.origin.x, cellFrame.origin.y - 30, cell.cover.frame.size };
	[tableView addSubview:cell.cover];
	
//    cell.backgroundContent.backgroundColor = self.dataSource[indexPath.row];
	NSString *data = self.dataSource[indexPath.row];
	
	cell.textLabel.text = data;
	cell.topLabel.text = data;
	[cell.topLabel sizeToFit];
	cell.bottomLabel.text = data;
	[cell.bottomLabel sizeToFit];
//    if (indexPath.row == 0) {
//        cell.backgroundContent.hidden = YES;
//    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(nonnull UITableViewCell *)cell forRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
//	cell.backgroundColor = [UIColor clearColor];
//	[cell.superview bringSubviewToFront:cell];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if ([UIDevice currentDevice].orientation == UIDeviceOrientationPortrait) {
		[[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
		[UIViewController attemptRotationToDeviceOrientation];
//		if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
//			BiggerTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//			self.fullScreenView = cell.playerView;
//			self.fullScreenView = [[UIImageView alloc] initWithImage:cell.playerView.image];
//			self.fullScreenView.frame = self.view.bounds;
//			[self.view addSubview:self.fullScreenView];
//			tableView.scrollEnabled = NO;
//		} else {
//			
//		}
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	__weak typeof(self) weakSelf = self;
	[self.tableView.visibleCells enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(__kindof UITableViewCell * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
		CGRect frame = [weakSelf.tableView rectForRowAtIndexPath:[weakSelf.tableView indexPathForCell:obj]];
		CGFloat centerCellY = CGRectGetMidY(frame);
		CGFloat centerOffsetY = scrollView.contentOffset.y + self.view.bounds.size.height / 2;
		
		CGFloat ratio = fabs(centerCellY - centerOffsetY) / MAXOffset;
		ratio = ratio > 1 ? 1 : ratio;
		
		BiggerTableViewCell *cell = obj;
		cell.maskView.alpha = ratio * 0.7;
		cell.cover.alpha = 1 - ratio;
//		cell.cover.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:ratio * 0.8];
		
		NSLog(@"%f", fabs(centerCellY - centerOffsetY));
	}];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
	self.playingIndexPath = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
//	UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingIndexPath];
//	[cell.superview bringSubviewToFront:cell];
//	[self.tableView bringSubviewToFront:[self.tableView cellForRowAtIndexPath:self.playingIndexPath]];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
	self.middleIndexPath = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
//    int tomove = ((int)targetContentOffset->y % (int)self.tableView.rowHeight);
//    if(tomove < self.tableView.rowHeight/2)
//        targetContentOffset->y -= tomove;
//    else
//        targetContentOffset->y += (self.tableView.rowHeight-tomove);
    
//    CGFloat rowHeight = self.tableView.rowHeight;
//    int verticalOffset = ((int)targetContentOffset->y % (int)rowHeight);
//    if (velocity.y < 0) {
//        targetContentOffset->y -= verticalOffset;
////        targetContentOffset->y = (int)targetContentOffset->y % (int)rowHeight;
//    } else if (velocity.y > 0) {
//        targetContentOffset->y += (rowHeight - verticalOffset);
////        targetContentOffset->y = (int)targetContentOffset->y % (int)rowHeight;
//    } else { // No velocity, snap to closest page
//        if (verticalOffset < rowHeight / 2) {
//            targetContentOffset->y -= verticalOffset;
//        } else {
//            targetContentOffset->y += (rowHeight - verticalOffset);
//        }
//    }
	UITableViewCell *middleCell;
	
    NSIndexPath *pathForTargetTopCell = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
    CGRect rectForTargetTopCell = [self.tableView rectForRowAtIndexPath:pathForTargetTopCell];
    
    CGPoint targetCellOffset = CGPointMake(CGRectGetMidX(rectForTargetTopCell), CGRectGetMidY(rectForTargetTopCell) - CGRectGetHeight(self.view.bounds)/2);

	
    *targetContentOffset = targetCellOffset;
//	self.middleIndexPath = pathForTargetTopCell;
	
    if (velocity.y < - 0.1) {
        if (pathForTargetTopCell.row > 0 && pathForTargetTopCell.row == self.middleIndexPath.row) {
            NSIndexPath *previousIndexPath = [NSIndexPath indexPathForRow:pathForTargetTopCell.row - 1 inSection:pathForTargetTopCell.section];
            CGRect rectForPreviousCell = [self.tableView rectForRowAtIndexPath:previousIndexPath];
            *targetContentOffset = CGPointMake(CGRectGetMidX(rectForPreviousCell), CGRectGetMidY(rectForPreviousCell) - CGRectGetHeight(self.view.bounds)/2);
//			self.middleIndexPath = previousIndexPath;
			middleCell = [self.tableView cellForRowAtIndexPath:previousIndexPath];
        }
    } else if (velocity.y > 0.1 && pathForTargetTopCell.row == self.middleIndexPath.row) {
        if (pathForTargetTopCell.row < self.dataSource.count - 1) {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:pathForTargetTopCell.row + 1 inSection:pathForTargetTopCell.section];
            CGRect rectForNextCell = [self.tableView rectForRowAtIndexPath:nextIndexPath];
            *targetContentOffset = CGPointMake(CGRectGetMidX(rectForNextCell), CGRectGetMidY(rectForNextCell) - CGRectGetHeight(self.view.bounds)/2);
//			self.middleIndexPath = nextIndexPath;
			middleCell = [self.tableView cellForRowAtIndexPath:nextIndexPath];
        }
    }
	
//	[middleCell.superview bringSubviewToFront:middleCell];
}

//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//	
//}

//- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
//	
//}


//- (BOOL)shouldAutorotate
//{
//	return NO;
//}

//- (UIInterfaceOrientationMask)supportedInterfaceOrientations
//{
//	return UIInterfaceOrientationMaskAllButUpsideDown;
//}

- (void)orientationDidChanged:(NSNotification *)notification {
//	NSIndexPath *middleIndexPath = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
	UIDevice *device = notification.object;
	
//	[self.fullScreenView removeFromSuperview];
//	[self tableView:self.tableView changeOrientation:device.orientation AtIndexPath:self.playingIndexPath];
	
	if (device.orientation == UIDeviceOrientationLandscapeLeft || device.orientation == UIDeviceOrientationLandscapeRight) {
		[self.fullScreenView removeFromSuperview];
		[self tableView:self.tableView changeOrientation:device.orientation AtIndexPath:self.playingIndexPath];
	} else if (device.orientation == UIDeviceOrientationPortraitUpsideDown) {
//		[self.fullScreenView removeFromSuperview];
		self.tableView.scrollEnabled = YES;
	} else {
		self.tableView.scrollEnabled = YES;
		BiggerTableViewCell *cell = [self.tableView cellForRowAtIndexPath:self.playingIndexPath];
		self.fullScreenView.frame = cell.contentView.bounds;
		[self.fullScreenView removeFromSuperview];
		[cell.contentView addSubview:self.fullScreenView];
	}
	self.orientation = [UIDevice currentDevice].orientation;
}

- (void)tableView:(UITableView *)tableView changeOrientation:(UIDeviceOrientation)orientation AtIndexPath:(NSIndexPath *)indexPath  {
//	[[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
//	[UIViewController attemptRotationToDeviceOrientation];
	if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation)) {
		BiggerTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		self.fullScreenView = cell.playerView;
		self.fullScreenView = [[UIImageView alloc] initWithImage:cell.playerView.image];
		self.fullScreenView.frame = self.view.bounds;
		[self.view addSubview:self.fullScreenView];
		tableView.scrollEnabled = NO;
	} else {
		
	}
//	BiggerTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
//	self.fullScreenView = [[UIImageView alloc] initWithImage:cell.playerView.image];
//	CGRect cellFrame = [tableView rectForRowAtIndexPath:indexPath];
//	self.fullScreenView.frame = cellFrame;
//	[self.view addSubview:self.fullScreenView];
	
//	switch (orientation) {
//		case UIDeviceOrientationUnknown: {
//			break;
//		}
//		case UIDeviceOrientationPortrait: {
//			[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//				CGFloat angle;
//				if (self.orientation == UIDeviceOrientationLandscapeLeft) {
//					angle = - M_PI_2;
//				} else if (self.orientation == UIDeviceOrientationLandscapeRight) {
//					angle = M_PI_2;
//				}
//				self.fullScreenView.transform = CGAffineTransformRotate(self.fullScreenView.transform, angle);
//				self.fullScreenView.bounds = (CGRect){CGPointZero, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds)};
//			} completion:^(BOOL finished) {
//				
//			}];
//			break;
//		}
//		case UIDeviceOrientationPortraitUpsideDown: {
//			
//			break;
//		}
//		case UIDeviceOrientationLandscapeLeft: {
//			[UIView animateWithDuration:0.5 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
//				CGFloat angle;
//				if (self.orientation == UIDeviceOrientationPortrait) {
//					angle = M_PI_2;
//				} else if (self.orientation == UIDeviceOrientationLandscapeRight) {
//					angle = M_PI;
//				}
//				self.fullScreenView.transform = CGAffineTransformRotate(self.fullScreenView.transform, angle);
//				self.fullScreenView.bounds = (CGRect){CGPointZero, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds)};
//			} completion:^(BOOL finished) {
//				
//			}];
//			break;
//		}
//		case UIDeviceOrientationLandscapeRight: {
//			
//		}
//		case UIDeviceOrientationFaceUp: {
//			break;
//		}
//		case UIDeviceOrientationFaceDown: {
//			break;
//		}
//	}
	
//	if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft) {
//		//turn left
//		[UIView animateWithDuration:0.5 animations:^{
//			self.fullScreenView.transform = CGAffineTransformRotate(self.fullScreenView.transform, M_PI_2);
//			self.fullScreenView.bounds = (CGRect){CGPointZero, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds)};
//		}];
//	} else if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight) {
//		[UIView animateWithDuration:0.5 animations:^{
//			self.fullScreenView.transform = CGAffineTransformRotate(self.fullScreenView.transform, - M_PI_2);
//			self.fullScreenView.bounds = (CGRect){CGPointZero, CGRectGetHeight(self.view.bounds), CGRectGetWidth(self.view.bounds)};
//		}];
//	}
}





/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

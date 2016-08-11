//
//  BiggerTableViewController.m
//  TableViewTest
//
//  Created by JuliusZhou on 8/8/16.
//  Copyright © 2016 JuliusZhou. All rights reserved.
//

#import "BiggerTableViewController.h"
#import "BiggerTableViewCell.h"

@interface BiggerTableViewController ()

@property (nonatomic, strong) NSArray *dataSource;
@property (nonatomic, strong) NSArray *cellHeights;

@property (nonatomic, strong) NSIndexPath *middleIndexPath;

@end

@implementation BiggerTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.dataSource = @[UIColor.redColor, UIColor.blueColor, UIColor.greenColor, UIColor.yellowColor, UIColor.brownColor, UIColor.orangeColor];
    self.dataSource = @[@"1", @"2", @"3", @"4", @"5", @"6",@"7",@"8",@"9",@"10",@"11",@"12",@"13",@"14",@"15"];
    self.cellHeights = @[@(300), @(330), @(250), @(360), @(130), @(220), @(150), @(250), @(320), @(270), @(280), @(310), @(330), @(320), @(340)];
    
    self.tableView.decelerationRate = UIScrollViewDecelerationRateFast;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, CGRectGetHeight(self.view.bounds)/2 - 300/2 )];
    headerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
    self.tableView.tableHeaderView = headerView;
//    self.tableView.sectionHeaderHeight = 60;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
//    cell.backgroundContent.backgroundColor = self.dataSource[indexPath.row];
    cell.textLabel.text = self.dataSource[indexPath.row];
//    if (indexPath.row == 0) {
//        cell.backgroundContent.hidden = YES;
//    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//    int tomove = ((int)self.tableView.contentOffset.y % (int)self.tableView.rowHeight);
//    if(tomove < self.tableView.rowHeight/2) [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y-tomove) animated:YES];
//    else [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y+(self.tableView.rowHeight-tomove)) animated:YES];
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
    
    NSIndexPath *pathForTargetTopCell = [self.tableView indexPathForRowAtPoint:CGPointMake(CGRectGetMidX(self.tableView.bounds), CGRectGetMidY(self.tableView.bounds))];
    CGRect rectForTargetTopCell = [self.tableView rectForRowAtIndexPath:pathForTargetTopCell];
    
    CGPoint targetCellOffset = CGPointMake(CGRectGetMidX(rectForTargetTopCell), CGRectGetMidY(rectForTargetTopCell) - CGRectGetHeight(self.view.bounds)/2);
    
    *targetContentOffset = targetCellOffset;
    
    if (velocity.y < - 0.1) {
        if (pathForTargetTopCell.row > 0 && pathForTargetTopCell.row == self.middleIndexPath.row) {
            NSIndexPath *previousIndexPath = [NSIndexPath indexPathForRow:pathForTargetTopCell.row - 1 inSection:pathForTargetTopCell.section];
            CGRect rectForPreviousCell = [self.tableView rectForRowAtIndexPath:previousIndexPath];
            *targetContentOffset = CGPointMake(CGRectGetMidX(rectForPreviousCell), CGRectGetMidY(rectForPreviousCell) - CGRectGetHeight(self.view.bounds)/2);
        }
    } else if (velocity.y > 0.1 && pathForTargetTopCell.row == self.middleIndexPath.row) {
        if (pathForTargetTopCell.row < self.dataSource.count - 1) {
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForRow:pathForTargetTopCell.row + 1 inSection:pathForTargetTopCell.section];
            CGRect rectForNextCell = [self.tableView rectForRowAtIndexPath:nextIndexPath];
            *targetContentOffset = CGPointMake(CGRectGetMidX(rectForNextCell), CGRectGetMidY(rectForNextCell) - CGRectGetHeight(self.view.bounds)/2);
        }
    }
    
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

//
//  VideoSplitManager.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/31.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "VideoSplitManager.h"

@interface VideoSplitManager ()

@property (nonatomic, strong) NSMutableArray *splits;

@end

@implementation VideoSplitManager

+ (VideoSplitManager*)shareInstance
{
	static VideoSplitManager* g_VideoSplitManager = nil;
	static dispatch_once_t predicate;
	if (g_VideoSplitManager == nil)
	{
		dispatch_once(&predicate, ^{
			g_VideoSplitManager = [VideoSplitManager new];
		});
	}
	return g_VideoSplitManager;
}

- (instancetype)init {
	if (self = [super init]) {
		_splits = [[NSMutableArray alloc] init];
	}
	
	return self;
}

- (void)clear {
	while ([self popSplit]);
}

- (BOOL)canDelete {
	return [self.splits count] > 0;
}

- (void)pushSplit:(NSString *)path {
	[_splits addObject:path];
	
	NSLog(@"pushSplit %@", path);
}

- (NSString *)popSplit {
	NSString *split = nil;
	if ([self canDelete]) {
		split = [_splits objectAtIndex:(_splits.count - 1)];
		[_splits removeObject:split];
		
		NSFileManager *mgr = [NSFileManager defaultManager];
		[mgr removeItemAtPath:split error:nil];
		
		NSLog(@"popSplit %@", split);
	}
	
	return split;
}

- (NSUInteger)lastSplitNumber {
	return _splits.count - 1;
}

- (NSString *)genNextRecordFilename {
	NSUInteger i = _splits.count;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *outpathURL = paths[0];
	NSFileManager *mgr = [NSFileManager defaultManager];
	[mgr createDirectoryAtPath:outpathURL withIntermediateDirectories:YES attributes:nil error:nil];
	NSString *filename = [NSString stringWithFormat:@"split_video_%ld.mp4", i];
	outpathURL = [outpathURL stringByAppendingPathComponent:filename];
	
	return outpathURL;
}

- (NSString *)getLastRecordFilename {
	if (_splits.count == 0)
		return nil;
	
	NSUInteger i = _splits.count - 1;
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *outpathURL = paths[0];
	NSFileManager *mgr = [NSFileManager defaultManager];
	[mgr createDirectoryAtPath:outpathURL withIntermediateDirectories:YES attributes:nil error:nil];
	NSString *filename = [NSString stringWithFormat:@"split_video_%ld.mp4", i];
	outpathURL = [outpathURL stringByAppendingPathComponent:filename];
	
	return outpathURL;
}

- (NSArray *)getAllSplits {
	return _splits;
}

- (NSString *)allocNewSplit {
	NSString *file = [self genNextRecordFilename];
	[self pushSplit:file];
	
	return file;
}

@end

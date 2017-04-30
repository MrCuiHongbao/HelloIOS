//
//  VideoCompositionController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/4/30.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "VideoCompositionController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "PlayerView.h"

@interface VideoCompositionController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (nonatomic, retain) UIImagePickerController *imagePickerController;

@property (nonatomic, retain) UIButton *importVideoBtn1;
@property (nonatomic, retain) UIButton *importVideoBtn2;

@property (nonatomic, retain) UIButton *compositionBtn;

@property (nonatomic, retain) UIView *previewView;

@property (nonatomic, assign) int sw;
@property (nonatomic, assign) int sh;

@property (nonatomic, assign) int importVideoIndex;
@property (nonatomic, retain) NSURL *video1;
@property (nonatomic, retain) NSURL *video2;

@property (nonatomic, retain) PlayerView *playerView;
@property (nonatomic, retain) AVPlayer *player;

@end

@implementation VideoCompositionController

- (UIButton *)compositionBtn
{
	if (!_compositionBtn)
	{
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		[btn setFrame:CGRectMake(10, self.sh - 40, self.sw - 10, 30)];
		[btn setTitle:@"合成视频" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onComposition) forControlEvents:UIControlEventTouchUpInside];
		_compositionBtn = btn;
	}
	
	return _compositionBtn;
}

- (UIView *)previewView
{
	if (!_previewView)
	{
		CGRect rect = CGRectMake(10, 10, self.sw - 20, self.sw - 20);
		UIView *view = [[UIView alloc] initWithFrame:rect];
		[view setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:0 alpha:1]];
		_previewView = view;
		
		if (!_importVideoBtn1)
		{
			UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
			[btn setFrame:CGRectMake(0, 0, CGRectGetWidth(rect) / 2, CGRectGetHeight(rect))];
			[btn setTitle:@"导入视频1" forState:UIControlStateNormal];
			[btn addTarget:self action:@selector(onImportVideo:) forControlEvents:UIControlEventTouchUpInside];
			[view addSubview:btn];
			_importVideoBtn1 = btn;
		}
		
		if (!_importVideoBtn2)
		{
			UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
			[btn setFrame:CGRectMake(CGRectGetWidth(rect) / 2, 0, CGRectGetWidth(rect) / 2, CGRectGetHeight(rect))];
			[btn setTitle:@"导入视频2" forState:UIControlStateNormal];
			[btn addTarget:self action:@selector(onImportVideo:) forControlEvents:UIControlEventTouchUpInside];
			[view addSubview:btn];
			_importVideoBtn2 = btn;
		}
		
		if (!_playerView)
		{
			PlayerView *playerView = [[PlayerView alloc] initWithFrame:rect];
			[playerView setBackgroundColor:[UIColor colorWithWhite:0 alpha:1]];
			[playerView setHidden:YES];
			_playerView = playerView;
		}
	}
	
	return _previewView;
}

- (UIImagePickerController *)imagePickerController
{
	if (!_imagePickerController)
	{
		_imagePickerController = [[UIImagePickerController alloc] init];
		_imagePickerController.delegate = self;
		_imagePickerController.allowsEditing = NO;
	}
	
	return _imagePickerController;
}

- (void)loadView
{
	[super loadView];
	self.sw = [[UIScreen mainScreen] bounds].size.width;
	self.sh = [[UIScreen mainScreen] bounds].size.height;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	[self.view addSubview:self.compositionBtn];
	[self.view addSubview:self.previewView];
	[self.view addSubview:self.playerView];
}

- (void)onImportVideo:(id)sender
{
	BOOL canImport = YES;
	if (sender == self.importVideoBtn1)
	{
		self.importVideoIndex = 0;
		canImport = self.video1 == nil;
	}
	else if (sender == self.importVideoBtn2)
	{
		self.importVideoIndex = 1;
		canImport = self.video2 == nil;
	}
	
	if (canImport)
	{
		self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
		self.imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:@"public.movie", nil];
		[self presentViewController:self.imagePickerController animated:YES completion:nil];
	}
}

- (void)onComposition
{
	if (!self.video1 || !self.video2)
	{
		return;
	}
	
	NSLog(@"video1=%@\n, video2=%@", self.video1, self.video2);
	
	//Here where load our movie Assets using AVURLAsset
	AVURLAsset* firstAsset = [AVURLAsset URLAssetWithURL:self.video1 options:nil];
	AVURLAsset * secondAsset = [AVURLAsset URLAssetWithURL:self.video2 options:nil];
 
	//Create AVMutableComposition Object.This object will hold our multiple AVMutableCompositionTrack.
	AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
 
	//Here we are creating the first AVMutableCompositionTrack.See how we are adding a new track to our AVMutableComposition.
	AVMutableCompositionTrack *firstTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	//Now we set the length of the firstTrack equal to the length of the firstAsset and add the firstAsset to out newly created track at kCMTimeZero so video plays from the start of the track.
	[firstTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, firstAsset.duration) ofTrack:[[firstAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
 
	//Now we repeat the same process for the 2nd track as we did above for the first track.Note that the new track also starts at kCMTimeZero meaning both tracks will play simultaneously.
	AVMutableCompositionTrack *secondTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	[secondTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondAsset.duration) ofTrack:[[secondAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
	
	CGAffineTransform txf1 = [firstAsset preferredTransform];
	CGSize size1 = [firstAsset naturalSize];
	CGAffineTransform txf2 = [secondAsset preferredTransform];
	CGSize size2 = [secondAsset naturalSize];
	
	//See how we are creating AVMutableVideoCompositionInstruction object.This object will contain the array of our AVMutableVideoCompositionLayerInstruction objects.You set the duration of the layer.You should add the lenght equal to the lingth of the longer asset in terms of duration.
	AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, firstAsset.duration);
 
	//We will be creating 2 AVMutableVideoCompositionLayerInstruction objects.Each for our 2 AVMutableCompositionTrack.here we are creating AVMutableVideoCompositionLayerInstruction for out first track.see how we make use of Affinetransform to move and scale our First Track.so it is displayed at the bottom of the screen in smaller size.(First track in the one that remains on top).
	AVMutableVideoCompositionLayerInstruction *FirstlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:firstTrack];
	CGAffineTransform Scale = CGAffineTransformMakeScale(0.5f,0.5f);
	CGAffineTransform Move = CGAffineTransformMakeTranslation(CGRectGetWidth(self.previewView.frame) / 2,0);
	[FirstlayerInstruction setTransform:CGAffineTransformConcat(Scale,Move) atTime:kCMTimeZero];
 
	//Here we are creating AVMutableVideoCompositionLayerInstruction for out second track.see how we make use of Affinetransform to move and scale our second Track.
	AVMutableVideoCompositionLayerInstruction *SecondlayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:secondTrack];
	CGAffineTransform SecondScale = CGAffineTransformMakeScale(0.5f,0.5f);
	CGAffineTransform SecondMove = CGAffineTransformMakeTranslation(0,0);
	[SecondlayerInstruction setTransform:CGAffineTransformConcat(SecondScale,SecondMove) atTime:kCMTimeZero];
 
	//Now we add our 2 created AVMutableVideoCompositionLayerInstruction objects to our AVMutableVideoCompositionInstruction in form of an array.
	MainInstruction.layerInstructions = [NSArray arrayWithObjects:FirstlayerInstruction,SecondlayerInstruction,nil];;
 
	//Now we create AVMutableVideoComposition object.We can add mutiple AVMutableVideoCompositionInstruction to this object.We have only one AVMutableVideoCompositionInstruction object in our example.You can use multiple AVMutableVideoCompositionInstruction objects to add multiple layers of effects such as fade and transition but make sure that time ranges of the AVMutableVideoCompositionInstruction objects dont overlap.
	AVMutableVideoComposition *MainCompositionInst = [AVMutableVideoComposition videoComposition];
	MainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
	MainCompositionInst.frameDuration = CMTimeMake(1, 30);
	MainCompositionInst.renderSize = CGSizeMake(CGRectGetWidth(self.previewView.frame), CGRectGetHeight(self.previewView.frame));
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *outpathURL = paths[0];
	NSFileManager *mgr = [NSFileManager defaultManager];
	[mgr createDirectoryAtPath:outpathURL withIntermediateDirectories:YES attributes:nil error:nil];
	outpathURL = [outpathURL stringByAppendingPathComponent:@"output.mp4"];
	[mgr removeItemAtPath:outpathURL error:nil];
	
	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPreset640x480];
	exportSession.videoComposition = MainCompositionInst;
	exportSession.outputURL = [NSURL fileURLWithPath:outpathURL];
	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	[exportSession exportAsynchronouslyWithCompletionHandler:^(void){
		switch(exportSession.status)
		{
			case AVAssetExportSessionStatusCompleted:
			{
				[self writeVideoToPhotoLibrary:[NSURL fileURLWithPath:outpathURL]];
				NSLog(@"export completed...");
				break;
			}
			case AVAssetExportSessionStatusFailed:
			{
				NSLog(@"export failed...");
				break;
			}
			case AVAssetExportSessionStatusCancelled:
			{
				NSLog(@"export cancel...");
				break;
			}
			case AVAssetExportSessionStatusWaiting:
			{
				NSLog(@"export waiting...");
				break;
			}
			case AVAssetExportSessionStatusUnknown:
			{
				break;
			}
		}
	}];
	
 
	//Finally just add the newly created AVMutableComposition with multiple tracks to an AVPlayerItem and play it using AVPlayer.
	AVPlayerItem * newPlayerItem = [AVPlayerItem playerItemWithAsset:mixComposition];
	newPlayerItem.videoComposition = MainCompositionInst;
	self.player = [AVPlayer playerWithPlayerItem:newPlayerItem];
	//[self.player addObserver:self forKeyPath:@"status" options:0 context:AVPlayerDemoPlaybackViewControllerStatusObservationContext];
	self.playerView.player = self.player;
	[self.playerView setVideoFillMode:AVLayerVideoGravityResizeAspectFill];
	[self.playerView setHidden:NO];
	[self.playerView.player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
	if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum([url path]))
	{
		UISaveVideoAtPathToSavedPhotosAlbum([url path], nil, nil, nil);
	}
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (UIImage *)getScreenShotImageFromVideoPath:(NSURL *)url{
	// Gets the asset - note ALAsset is deprecated, not AVAsset.
	AVAsset *asset = [AVAsset assetWithURL:url];
	
	// Calculate a time for the snapshot - I'm using the half way mark.
	CMTime duration = [asset duration];
	CMTime snapshot = CMTimeMake(duration.value / 2, duration.timescale);
	
	// Create a generator and copy image at the time.
	// I'm not capturing the actual time or an error.
	AVAssetImageGenerator *generator =
	[AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
	CGImageRef imageRef = [generator copyCGImageAtTime:snapshot
											actualTime:nil
												 error:nil];
	
	// Make a UIImage and release the CGImage.
	UIImage *thumbnail = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	return thumbnail;
}

#pragma mark UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(nullable NSDictionary<NSString *,id> *)editingInfo
{
	
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
	NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
	//判断资源类型
	if ([mediaType isEqualToString:@"public.image"]){

	}else if ([mediaType isEqualToString:@"public.movie"]){
		//如果是视频
		NSURL *url = info[UIImagePickerControllerMediaURL];
		UIImage *videoThumb = [self getScreenShotImageFromVideoPath:url];
		UIButton *btn = self.importVideoIndex == 0 ? self.importVideoBtn1 : self.importVideoBtn2;
		[btn setImage:videoThumb forState:UIControlStateNormal];
		
		if (self.importVideoIndex == 0)
		{
			self.video1 = url;
		}
		else
		{
			self.video2 = url;
		}
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end

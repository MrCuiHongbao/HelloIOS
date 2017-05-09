//
//  MultipleVideoRecorderController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/8.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "MultipleVideoRecorderController.h"
#import "CaptureToolKit.h"

#pragma GLKViewWithBounds

@implementation GLKViewWithBounds

@end

#pragma VideoSplitManager

@interface VideoSplitManager : NSObject

@property (nonatomic, retain) NSMutableArray *splits;

@end

@implementation VideoSplitManager

- (instancetype)init {
	if (self = [super init]) {
		_splits = [[NSMutableArray alloc] init];
	}
	
	return self;
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

- (NSString *)getNextRecordFilename {
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

- (NSString *)allocNewSplit {
	NSString *file = [self getNextRecordFilename];
	[self pushSplit:file];
	
	return file;
}

@end

#pragma mark MultipleVideoRecorderController

@interface MultipleVideoRecorderController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, assign) int sw;
@property (nonatomic, assign) int sh;

@property (nonatomic, assign) MultiRecordState recordState;

@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *eaglContext;

@property (nonatomic, retain) GLKViewWithBounds *feedView;

@property (nonatomic, strong) NSLock *lock;

@property (nonatomic, retain) dispatch_queue_t captureSessionQueue;
@property (nonatomic, retain) dispatch_queue_t writerQueue;

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureDevice *captureDevice;
@property (nonatomic, retain) AVCaptureDeviceInput *captureDevideInput;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *writerInputPixelBufferAdaptor;
@property (nonatomic, assign) BOOL canWrite;

@property (nonatomic,strong) AVAssetReaderTrackOutput *assetVideoReaderOutput;
@property (nonatomic,strong) AVAssetReaderTrackOutput *assetAudioReaderOutput;
@property (nonatomic,strong) AVAssetReader *reader;
@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat sourceVideoFrameTime;
@property (nonatomic, assign) CGFloat sourceVideoSumTime;
@property (nonatomic, assign) CGFloat sourceVideoLeftTime;
@property (nonatomic) CGAffineTransform videoTransform;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) NSDictionary *adaptorSettings;
@property (nonatomic, strong) NSDictionary *videoTrackOutputSetting;
@property (nonatomic, strong) NSDictionary *audioTrackOutputSetting;

@property (nonatomic, assign) CMSampleBufferRef currentVideoBuffer;

@property (nonatomic, strong) NSString *exportVideoPath;
@property (nonatomic, strong) NSString *sourceVideoPath;

@property (nonatomic, assign) BOOL needRefresh;

@property (nonatomic, retain) VideoSplitManager *videoSplitManager;

@end

@implementation MultipleVideoRecorderController

- (instancetype)init {
	if (self == [super init]) {
		self.recordState = MultiRecordStateUnknown;
		
		self.sw = [[UIScreen mainScreen] bounds].size.width;
		self.sh = [[UIScreen mainScreen] bounds].size.height;
		
		self.lock = [[NSLock alloc] init];
		
		_videoSplitManager = [[VideoSplitManager alloc] init];
	}
	
	return self;
}

- (void)dealloc {
	CVPixelBufferPoolRelease(_writerInputPixelBufferAdaptor.pixelBufferPool);
}

- (void)setRecordState:(MultiRecordState)recordState {
	_recordState = recordState;
}

// 安装摄像头设备
- (void)setupCapture {
	self.recordState = MultiRecordStateInit;
	if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0) {
		_captureSessionQueue = dispatch_queue_create("capture_session_queue", DISPATCH_QUEUE_SERIAL);
		_writerQueue = dispatch_queue_create("asset_writer_queue", DISPATCH_QUEUE_SERIAL);
		
		[self setupContexts];
		
		[self setupCaptureSession];
	}
}

- (GLKViewWithBounds *)setupRenderWidth:(CGRect)frame {
	if (!_feedView) {
		_feedView = [self setupFeedViewWithFrame:frame];
		[_feedView setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:1]];
	}
	
	return _feedView;
}

- (GLKViewWithBounds *)setupFeedViewWithFrame:(CGRect)frame {
	GLKViewWithBounds *feedView = [[GLKViewWithBounds alloc] initWithFrame:frame context:self.eaglContext];
	feedView.enableSetNeedsDisplay = NO;
	
	// because the native video image from the back camera is in UIDeviceOrientationLandscapeLeft (i.e. the home button is on the right),
	// we need to apply a clockwise 90 degree transform so that we can draw the video preview as if we were in a landscape-oriented view;
	// if you're using the front camera and you want to have a mirrored preview (so that the user is seeing themselves in the mirror),
	// you need to apply an additional horizontal flip (by concatenating CGAffineTransformMakeScale(-1.0, 1.0) to the rotation transform)
	feedView.transform = CGAffineTransformMakeRotation(M_PI_2);
	feedView.frame = frame;
	
	// bind the frame buffer to get the frame buffer width and height;
	// the bounds used by CIContext when drawing to a GLKView are in pixels (not points),
	// hence the need to read from the frame buffer's width and height;
	// in addition, since we will be accessing the bounds in another queue (_captureSessionQueue),
	// we want to obtain this piece of information so that we won't be
	// accessing _videoPreviewView's properties from another thread/queue
	[feedView bindDrawable];
	
	feedView.viewBounds = CGRectMake(0.0, 0.0, feedView.drawableWidth, feedView.drawableHeight);
	
	//	dispatch_async(dispatch_get_main_queue(), ^(void) {
	//		CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI_2);
	//
	//		feedView.transform = transform;
	//		feedView.frame = frame;
	//	});
	
	return feedView;
}

- (void)setupContexts {
	// setup the GLKView for video/image preview
	_eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	// create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
	_ciContext = [CIContext contextWithEAGLContext:_eaglContext
										   options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
}

- (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
	
	AVCaptureDevice *captureDevice = devices.firstObject;
	for (AVCaptureDevice *device in devices) {
		if (device.position == position) {
			captureDevice = device;
			break;
		}
	}
	return captureDevice;
}

- (void)setupCaptureSession {
	if (_captureSession) {
		return;
	}
	
	dispatch_async(_captureSessionQueue, ^(void) {
		NSError *error = nil;
		
		// 获取视频设备
		NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
		AVCaptureDevice *videoDevice = [videoDevices objectAtIndex:0];
		
		// 获取设备输入组件
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if (!videoDeviceInput)
		{
			return;
		}
		
		// 获取输出规格
		NSString *preset = AVCaptureSessionPresetMedium;
		if (![videoDevice supportsAVCaptureSessionPreset:preset])
		{
			return;
		}
		
		// 初始化摄像头会话
		_captureSession = [[AVCaptureSession alloc] init];
		_captureSession.sessionPreset = preset;
		
		// 创建并配置视频输出组件
		AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
		videoDataOutput.videoSettings = self.videoSettings;
		[videoDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
		
		[_captureSession beginConfiguration];
		
		if (![_captureSession canAddOutput:videoDataOutput])
		{
			_captureSession = nil;
			return;
		}
		
		[_captureSession addInput:videoDeviceInput];
		[_captureSession addOutput:videoDataOutput];
		
		//[self addPreviewLayer];
		
		[_captureSession commitConfiguration];
		
		[_captureSession startRunning];
	});
}

- (void)setupSourceVideo:(NSString *)sourceVideo {
	self.sourceVideoPath = sourceVideo;
	
	[self setupAssetReading:self.sourceVideoPath];
	
	self.recordState = MultiRecordStateReady;
}

// 创建录制会话，准备开始录制
- (void)createRecordSession {
	self.recordState = MultiRecordStateReady;
	
	//[self setupAssetReading:self.sourceVideoPath];
}

// 销毁录制会话，回收资源
- (void)destroyRecordSession {
	self.recordState = MultiRecordStateFinish;
}

// 开始录制分段
- (BOOL)startRecord {
	if (self.recordState != MultiRecordStateReady && self.recordState != MultiRecordStateWillDeleteSplit) {
		NSLog(@"recordState must be MultiRecordStateReady or MultiRecordStateWillDeleteSplit");
		return NO;
	}
	
	self.recordState = MultiRecordStatePrepareRecording;
	
	[self setupAssetWriter:[_videoSplitManager allocNewSplit]];
	
	self.recordState = MultiRecordStateRecording;
	
	// 同步开始解析源视频
	_timer = [NSTimer scheduledTimerWithTimeInterval:_sourceVideoFrameTime target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
	[_timer fire];
	
	return YES;
}

// 停止录制分段
- (void)stopRecord {
	if (self.recordState != MultiRecordStateRecording) {
		NSLog(@"recordState must be MultiRecordStateRecording");
		return;
	}
	
	[_timer invalidate];
	_timer = nil;
	
	[self stopAssetWriter];
	
	if ([self.delegate respondsToSelector:@selector(recordFinished)]) {
		[self.delegate recordFinished];
	}
}

- (void)willDeleteLastSplit {
	if (self.recordState != MultiRecordStateReady) {
		NSLog(@"recordState must be MultiRecordStateReady");
		return;
	}
	
	self.recordState = MultiRecordStateWillDeleteSplit;
	
	return;
}

// 删除录制分段
- (BOOL)deleteLastSplit {
	if (self.recordState != MultiRecordStateWillDeleteSplit) {
		NSLog(@"recordState must be MultiRecordStateWillDeleteSplit");
		return NO;
	}
	
	if (![_videoSplitManager canDelete]) {
		return NO;
	}
	
	[_videoSplitManager popSplit];
	self.recordState = MultiRecordStateReady;
	
	if ([self.delegate respondsToSelector:@selector(lastSplitDeleted)]) {
		[self.delegate lastSplitDeleted];
	}
	
	return YES;
}

- (CGSize)recordResolution {
	return CGSizeMake(self.sw, self.sw);
}

#pragma mark All settings

- (NSDictionary*) videoSettings {
	// CoreImage wants BGRA pixel format
	if (!_videoSettings) {
		_videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
	}
	
	return _videoSettings;
}

- (NSDictionary*) adaptorSettings {
	if (!_adaptorSettings) {
		_adaptorSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
							 (id)kCVPixelBufferWidthKey: @(480),
							 (id)kCVPixelBufferHeightKey: @(480),
							 @"IOSurfaceOpenGLESTextureCompatibility": @YES,
							 @"IOSurfaceOpenGLESFBOCompatibility": @YES,};
	}
	
	return _adaptorSettings;
}

- (NSDictionary *)videoCompressionSettings {
	if (!_videoCompressionSettings) {
		//写入视频大小
		CGSize size = [self recordResolution];
		NSInteger numPixels = size.width * size.height;
		
		//每像素比特
		CGFloat bitsPerPixel = 6.0;
		NSInteger bitsPerSecond = numPixels * bitsPerPixel;
		
		// 码率和帧率设置
		NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
												 AVVideoExpectedSourceFrameRateKey : @(30),
												 AVVideoMaxKeyFrameIntervalKey : @(30),
												 AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel };
		
		//视频属性
		_videoCompressionSettings = @{ AVVideoCodecKey : AVVideoCodecH264,
									   AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
									   AVVideoWidthKey : @(size.height),
									   AVVideoHeightKey : @(size.width),
									   AVVideoCompressionPropertiesKey : compressionProperties };
	}
	
	return _videoCompressionSettings;
}

- (NSDictionary *)audioCompressionSettings {
	if (!_audioCompressionSettings) {
		_audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
									   AVFormatIDKey : @(kAudioFormatMPEG4AAC),
									   AVNumberOfChannelsKey : @(1),
									   AVSampleRateKey : @(22050) };
	}
	
	return _audioCompressionSettings;
}

- (NSDictionary *)videoTrackOutputSetting {
	if (!_videoTrackOutputSetting) {
		_videoTrackOutputSetting = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
	}
	
	return _videoTrackOutputSetting;
}

- (NSDictionary *)audioTrackOutputSetting {
	if (!_audioTrackOutputSetting) {
		_audioTrackOutputSetting = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
									  (id)kCVPixelBufferWidthKey : @(480),
									  (id)kCVPixelBufferHeightKey : @(320) };
	}
	
	return _audioTrackOutputSetting;
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if (self.currentVideoBuffer) {
		[self renderByGL1:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
		return;
	}
	
	[self renderByGL:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
}

- (void)renderByGL1:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	
	// update the video dimensions information
	//_currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
	CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
	
	[self.lock lock];
	
	CVImageBufferRef videoBuffer = CMSampleBufferGetImageBuffer(self.currentVideoBuffer);
	CIImage *sourceVideo = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)videoBuffer options:nil];
	
	// 合成视频帧
	CIImage *destImage = [self renderFrameLeft:sourceImage right:sourceVideo];
	//
	//	CFRelease(self.currentVideoBuffer);
	//	self.currentVideoBuffer = nil;
	
	[self.lock unlock];
	
	[self.feedView bindDrawable];
	
	if (_eaglContext != [EAGLContext currentContext]) {
		[EAGLContext setCurrentContext:_eaglContext];
	}
	
	// clear eagl view to black
	glClearColor(0, 0, 0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// set the blend mode to "source over" so that CI will use that
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	// 绘制视频帧到屏幕上
	if (destImage) {
		[_ciContext drawImage:destImage inRect:_feedView.viewBounds fromRect:destImage.extent];
	}
	
	[_feedView display];
	
	// 输出视频帧到文件
	if (self.recordState == MultiRecordStateRecording) {
		CVPixelBufferRef renderBuffer = NULL;
		CVPixelBufferPoolCreatePixelBuffer(NULL, _writerInputPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
		if (!renderBuffer) {
			NSLog(@"renderBuffer is NULL...");
			return;
		}
		CVPixelBufferLockBaseAddress(renderBuffer, 0);
		[_ciContext render:destImage toCVPixelBuffer:renderBuffer bounds:_feedView.viewBounds colorSpace:NULL];
		CVPixelBufferUnlockBaseAddress(renderBuffer, 0);
		[self appendSampleBuffer:AVMediaTypeVideo CVPixelBufferRef:renderBuffer withPresentationTime:presentationTime];
	}
}

- (void)renderByGL:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	
	// update the video dimensions information
	//_currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
	
	CGRect sourceExtent = sourceImage.extent;
	CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
	
	GLKViewWithBounds *feedView = self.feedView;
	
	CGSize previewSize1 = CGSizeMake(feedView.viewBounds.size.width, feedView.viewBounds.size.height / 2);
	CGRect inRect = CGRectMake(0, 0, feedView.viewBounds.size.width, feedView.viewBounds.size.height / 2);
	CGFloat previewAspect1 = previewSize1.width / previewSize1.height;
	
	// we want to maintain the aspect radio of the screen size, so we clip the video image
	CGRect drawRect = sourceExtent;
	if (sourceAspect > previewAspect1) {
		// use full height of the video image, and center crop the width
		drawRect.origin.x += (drawRect.size.width - drawRect.size.height * previewAspect1) / 2.0;
		drawRect.size.width = drawRect.size.height * previewAspect1;
	} else {
		// use full width of the video image, and center crop the height
		drawRect.origin.y += (drawRect.size.height - drawRect.size.width / previewAspect1) / 2.0;
		drawRect.size.height = drawRect.size.width / previewAspect1;
	}
	
	[feedView bindDrawable];
	
	if (_eaglContext != [EAGLContext currentContext]) {
		[EAGLContext setCurrentContext:_eaglContext];
	}
	
	// clear eagl view to grey
	glClearColor(0, 0, 0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// set the blend mode to "source over" so that CI will use that
	glEnable(GL_BLEND);
	glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	if (sourceImage) {
		[_ciContext drawImage:sourceImage inRect:inRect fromRect:drawRect];
	}
	
	[self.lock lock];
	
	if (self.currentVideoBuffer)
	{
		// 视频帧尺寸
		CIImage *sourceVideo = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(self.currentVideoBuffer) options:nil];
		CGRect videoExtent = sourceVideo.extent;
		CGFloat videoAspect = videoExtent.size.width / videoExtent.size.height;
		
		// 预览框尺寸
		CGSize videoPreviewSize = CGSizeMake(feedView.viewBounds.size.width, feedView.viewBounds.size.height / 2);
		CGRect videoInRect = CGRectMake(0, feedView.viewBounds.size.height / 2, feedView.viewBounds.size.width, feedView.viewBounds.size.height / 2);
		CGFloat videoPreviewAspect = videoPreviewSize.width / videoPreviewSize.height;
		
		// 视频帧等比缩放并居中显示到预览框
		CGRect videoDrawRect = videoExtent;
		if (videoPreviewAspect > videoAspect) {
			videoInRect.origin.x = (CGRectGetWidth(videoInRect) - CGRectGetHeight(videoInRect) * videoAspect) / 2;
			videoInRect.size.width = CGRectGetHeight(videoInRect) * videoAspect;
		} else {
			// use full width of the video image, and center crop the height
			videoInRect.origin.y = (CGRectGetHeight(videoInRect) - CGRectGetWidth(videoInRect) / videoAspect) / 2;
			videoInRect.size.height = CGRectGetWidth(videoInRect) / videoAspect;
		}
		
		if (sourceVideo) {
			[_ciContext drawImage:sourceVideo inRect:videoInRect fromRect:videoDrawRect];
		}
	}
	[self.lock unlock];
	
	UIImage *image;
	[image drawInRect:inRect];
	
	[feedView display];
}

- (CIImage *)renderFrameLeft:(CIImage *)image1 right:(CIImage *)image2 {
	// w:h = 2:1
	CGFloat destAsptect = 2;
	
	CGRect image1Rect = image1.extent;
	CGFloat image1Asptect = CGRectGetWidth(image1Rect) / CGRectGetHeight(image1Rect);
	if (image1Asptect < destAsptect) {
		image1Rect.origin.y = (CGRectGetHeight(image1Rect) - CGRectGetWidth(image1Rect) / destAsptect) / 2;
		image1Rect.size.height = CGRectGetWidth(image1Rect) / destAsptect;
	} else {
		image1Rect.origin.x = (CGRectGetWidth(image1Rect) - CGRectGetHeight(image1Rect) * destAsptect) / 2;
		image1Rect.size.width = CGRectGetHeight(image1Rect) * destAsptect;
	}
	CIImage *destImage1 = [image1 imageByCroppingToRect:image1Rect];
	
	CGRect image2Rect = image2.extent;
	CGFloat image2Asptect = CGRectGetWidth(image2Rect) / CGRectGetHeight(image2Rect);
	if (image2Asptect < destAsptect) {
		image2Rect.origin.y = (CGRectGetHeight(image2Rect) - CGRectGetWidth(image2Rect) / destAsptect) / 2;
		image2Rect.size.height = CGRectGetWidth(image2Rect) / destAsptect;
	} else {
		image2Rect.origin.x = (CGRectGetWidth(image2Rect) - CGRectGetHeight(image2Rect) * destAsptect) / 2;
		image2Rect.size.width = CGRectGetHeight(image2Rect) * destAsptect;
	}
	CIImage *destImage2 = [image2 imageByCroppingToRect:image2Rect];
	
	UIImage *tmp1 = [[UIImage alloc] initWithCIImage:destImage1];
	UIImage *tmp2 = [[UIImage alloc] initWithCIImage:destImage2];
	CGSize size = CGSizeMake(CGRectGetWidth(image1Rect), CGRectGetWidth(image1Rect));
	UIGraphicsBeginImageContext(size);
	[[UIColor colorWithWhite:0 alpha:1] setFill];
	[tmp2 drawInRect:CGRectMake(0, 0, size.width, size.height / 2)];
	[tmp1 drawInRect:CGRectMake(0, size.height / 2, size.width, size.height / 2)];
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return [[CIImage alloc] initWithImage:result];
}

- (void)appendSampleBuffer:(NSString *)mediaType CVPixelBufferRef:(CVPixelBufferRef)pixelBuffer withPresentationTime:(CMTime)presentationTime
{
	if (pixelBuffer == NULL){
		NSLog(@"empty sampleBuffer");
		return;
	}
	
	@synchronized(self){
		if (self.recordState < MultiRecordStateRecording){
			NSLog(@"not ready yet");
			return;
		}
	}
	
	CFRetain(pixelBuffer);
	dispatch_async(_writerQueue, ^{
		@autoreleasepool {
			@synchronized(self) {
				if (self.recordState > MultiRecordStateRecording){
					CFRelease(pixelBuffer);
					return;
				}
			}
			
			if (!self.canWrite && mediaType == AVMediaTypeVideo) {
				[_writer startSessionAtSourceTime:presentationTime];
				self.canWrite = YES;
			}
			
			//写入视频数据
			if (mediaType == AVMediaTypeVideo && _writerInput.isReadyForMoreMediaData) {
				BOOL ret =  [_writerInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
				if (!ret) {
					@synchronized (self) {
						[self stopAssetWriter];
						[self destroyWrite];
					}
				}
			}
			
			CFRelease(pixelBuffer);
		}
	} );
}

- (void)setupAssetReading:(NSString *)videoFile {
	if (!_reader) {
		NSURL *videoURL = [NSURL fileURLWithPath:videoFile];
		AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
		_videoAsset = asset;
		NSError *error = nil;
		
		_reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
		
		NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
		if (videoTracks.count == 0) {
			NSLog(@"NO video track...");
			return;
		}
		AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
		
		_videoTransform = videoTrack.preferredTransform;
		
		CMTime duration = [asset duration];
		CGFloat sumTime = duration.value / duration.timescale;
		CGFloat sumFrame = sumTime * videoTrack.nominalFrameRate;
		CGFloat totalTime = CMTimeGetSeconds(duration);
		CGFloat frameTime = totalTime / sumFrame;
		_sourceVideoFrameTime = frameTime;
		_sourceVideoSumTime = sumTime;
		_needRefresh = YES;
		
		_assetVideoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:self.videoTrackOutputSetting];
		[_reader addOutput:_assetVideoReaderOutput];
		
		//	NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
		//	AVAssetTrack *audioTrack = [audioTracks objectAtIndex:0];
		
		//	_assetAudioReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:audioTrack outputSettings:self.audioTrackOutputSetting];
		//	[_reader addOutput:_assetAudioReaderOutput];
		
		if (![_reader startReading]) {
			AVAssetReaderStatus status = [_reader status];
			NSError *err = [_reader error];
			NSLog(@"startReading error");
		}
	}
}

-(void)onTimer {
	if ([_reader status] == AVAssetReaderStatusReading) {
		dispatch_async(_writerQueue, ^(void){
			CMSampleBufferRef videoBuffer = [_assetVideoReaderOutput copyNextSampleBuffer];
			if (videoBuffer) {
				[self.lock lock];
				
				// 有可能录制帧率没有视频帧率高，会丢视频帧，这里要把录制没有处理的视频帧释放掉
				if (self.currentVideoBuffer) {
					CFRelease(self.currentVideoBuffer);
					self.currentVideoBuffer = nil;
				}
				
				self.currentVideoBuffer = videoBuffer;
				
				// 计算源视频剩余时长
				CMTime durationTime = [_videoAsset duration];
				CMTime presentTime = CMSampleBufferGetPresentationTimeStamp(videoBuffer);
				CGFloat leftSeconds = CMTimeGetSeconds(CMTimeSubtract(durationTime, presentTime));
				if (self.sourceVideoSumTime - leftSeconds >= 1 || leftSeconds == 0) {
					self.sourceVideoLeftTime = leftSeconds;
					self.needRefresh = YES;
				}
				
				[self.lock unlock];
			}
		});
	} else {
		// 读完视频文件，销毁资源
		[_timer invalidate];
		_timer = nil;
		
		[_reader cancelReading];
		_reader = nil;
		
		_videoAsset = nil;
		
		[self stopRecord];
		
		dispatch_async(dispatch_get_main_queue(), ^(void){
			//[self _showAlertViewWithMessage:@"录制完成"];
		});
	}
	
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		//[self.durationView setText:[NSString stringWithFormat:@"%f", self.sumTime]];
		self.needRefresh = NO;
	});
}

- (void)setupAssetWriter:(NSString *)writerOutputPath {
	if (!_writer) {
		NSFileManager *mgr = [NSFileManager defaultManager];
		[mgr removeItemAtPath:writerOutputPath error:nil];
		
		NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:writerOutputPath];
		NSError *err;
		_writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeMPEG4 error:&err];
		
		_writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
		_writerInput.expectsMediaDataInRealTime = YES;	//expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
		
		if (_videoTransform.a == 1 && _videoTransform.d == 1 && _videoTransform.b == 0 && _videoTransform.c == 0) {
			_writerInput.transform = CGAffineTransformMakeRotation(-M_PI_2);
		}
		
		if ([_writer canAddInput:_writerInput]) {
			[_writer addInput:_writerInput];
		}else {
			NSLog(@"AssetWriter videoInput append Failed");
		}
		
		_writerInputPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_writerInput sourcePixelBufferAttributes:self.adaptorSettings];
		
		if (![_writer startWriting]) {
			NSLog(@"[%@]err %@", [NSString stringWithUTF8String:__FUNCTION__], err.description);
		}
	}
}

- (void)stopAssetWriter
{
	self.recordState = self.sourceVideoLeftTime < self.sourceVideoFrameTime ? MultiRecordStateFinish : MultiRecordStateReady;
	
	if(_writer && _writer.status == AVAssetWriterStatusWriting) {
		[_writer finishWritingWithCompletionHandler:^{
			if (self.recordState == MultiRecordStateFinish) {
				NSURL *videoURL = [NSURL fileURLWithPath:[_videoSplitManager getLastRecordFilename]];
				NSURL *audioURL = [NSURL fileURLWithPath:self.sourceVideoPath];
				if (![self mergeAudioAndVideo:videoURL audio:audioURL]) {
					// 合成音频失败，就直接导出没有音频的视频
					[CaptureToolKit writeVideoToPhotoLibrary:videoURL];
				}
			}
			
			_writer = nil;
			_canWrite = NO;
		}];
	}
}

- (BOOL)mergeAudioAndVideo:(NSURL *)videoFile audio:(NSURL *)audioFromVideoFile {
	// 创建拼接工程
	AVMutableComposition* mc = [[AVMutableComposition alloc] init];
	
	// 添加视频和音频轨道
	AVMutableCompositionTrack *videoTrack = [mc addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVMutableCompositionTrack *audioTrack = [mc addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	AVURLAsset* asset1 = [AVURLAsset URLAssetWithURL:videoFile options:nil];
	if ([asset1 tracksWithMediaType:AVMediaTypeVideo].count == 0) {
		NSLog(@"NO video track...");
		return NO;
	}
	AVAssetTrack *videoAsset = [[asset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
	[videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset1.duration) ofTrack:videoAsset atTime:kCMTimeZero error:nil];
	
	
	AVURLAsset* asset2 = [AVURLAsset URLAssetWithURL:audioFromVideoFile options:nil];
	if ([asset2 tracksWithMediaType:AVMediaTypeAudio].count == 0) {
		NSLog(@"NO audio track...");
		return NO;
	}
	AVAssetTrack *audioAsset = [[asset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
	[audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:audioAsset atTime:kCMTimeZero error:nil];
	
	// 90度旋转
	CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(videoAsset.naturalSize.height, 0.0);
	CGAffineTransform mixedTransform = CGAffineTransformRotate(translateToCenter, M_PI_2);
	
	// 视频指令工程
	AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset1.duration);
	
	// 视频旋转
	AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	[roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
	roateInstruction.layerInstructions = @[roateLayerInstruction];
	
	// 视频工程
	AVMutableVideoComposition *waterMarkVideoComposition = [AVMutableVideoComposition videoComposition];
	waterMarkVideoComposition.frameDuration = CMTimeMake(1, 30);
	waterMarkVideoComposition.renderSize = videoAsset.naturalSize;
	waterMarkVideoComposition.instructions = @[roateInstruction];
	
	// 导出
	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mc presetName:AVAssetExportPresetMediumQuality];
	exportSession.videoComposition = waterMarkVideoComposition;
	exportSession.outputURL = [NSURL fileURLWithPath:self.exportVideoPath];
	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	[exportSession exportAsynchronouslyWithCompletionHandler:^(void){
		switch(exportSession.status)
		{
			case AVAssetExportSessionStatusExporting:
			{
				NSLog(@"exporting...");
				break;
			}
			case AVAssetExportSessionStatusCompleted:
			{
				[CaptureToolKit writeVideoToPhotoLibrary:[NSURL fileURLWithPath:self.exportVideoPath]];
				self.exportVideoPath = nil;
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
	
	return YES;
}

- (void)destroyWrite{
	
}

#pragma mark setup view

- (NSString *)exportVideoPath {
	if (!_exportVideoPath) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *outpathURL = paths[0];
		NSFileManager *mgr = [NSFileManager defaultManager];
		[mgr createDirectoryAtPath:outpathURL withIntermediateDirectories:YES attributes:nil error:nil];
		outpathURL = [outpathURL stringByAppendingPathComponent:@"export_video.mp4"];
		[mgr removeItemAtPath:outpathURL error:nil];
		
		_exportVideoPath = outpathURL;
	}
	
	return _exportVideoPath;
}

@end

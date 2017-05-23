//
//  MultipleVideoRecorderController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/8.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "MultipleVideoRecorderController.h"
#import "CaptureToolKit.h"

#pragma mark GLKViewWithBounds

@implementation GLKViewWithBounds

@end

#pragma mark VideoSnapshot

@interface VideoSnapshot : NSObject

@property (nonatomic) CMTime time;

@property (nonatomic) CMSampleBufferRef buffer;

@end

@implementation VideoSnapshot

- (instancetype)init {
	if (self = [super init]) {
		
	}
	
	return self;
}

- (void)dealloc {
	if (self.buffer) {
		CFRelease(self.buffer);
		self.buffer = nil;
	}
}

@end

#pragma mark VideoSplitManager

@interface VideoSplitManager : NSObject

@property (nonatomic, strong) NSMutableArray *splits;

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

- (NSArray *)getAllSplits {
	return _splits;
}

- (NSString *)allocNewSplit {
	NSString *file = [self getNextRecordFilename];
	[self pushSplit:file];
	
	return file;
}

@end

#pragma mark MultipleVideoRecorderController

@interface MultipleVideoRecorderController () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, assign) int sw;
@property (nonatomic, assign) int sh;

@property (nonatomic, assign) MultiRecordState recordState;
@property (nonatomic, assign) MultiRecordState lastRecordState;

@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *eaglContext;

@property (nonatomic, strong) GLKViewWithBounds *feedView;

//@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, strong) NSObject *lock;

// 队列
@property (nonatomic, strong) dispatch_queue_t captureSessionQueue;
@property (nonatomic, strong) dispatch_queue_t writerQueue;
@property (nonatomic, strong) dispatch_queue_t readerQueue;
@property (nonatomic, strong) dispatch_source_t readerTimer;

// 摄像头
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureDevideInput;
@property (nonatomic, assign) AVCaptureDevicePosition cameraPosition;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

// 写视频
@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *videoWriterInput;
@property (nonatomic, strong) AVAssetWriterInput *audioWriterInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *writerInputPixelBufferAdaptor;
@property (nonatomic, assign) BOOL canWrite;

// 读视频
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetVideoReaderOutput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *assetAudioReaderOutput;
@property (nonatomic, strong) AVAssetReader *reader;
@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic, strong) NSTimer *progressUpdateTimer;
@property (nonatomic, assign) CGFloat sourceVideoFrameTime;
@property (nonatomic, assign) CGFloat sourceVideoSumTime;
@property (nonatomic, assign) CGFloat sourceVideoLeftTime;
@property (nonatomic) CGAffineTransform videoTransform;
@property (nonatomic, assign) BOOL isFirstFrame;
@property (nonatomic, assign) BOOL canHandleVideo;

// 音频播放
@property (nonatomic, strong) AVPlayer *audioPlayer;
@property (nonatomic, assign) BOOL isAudioPlaying;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) NSDictionary *adaptorSettings;
@property (nonatomic, strong) NSDictionary *videoTrackOutputSetting;
@property (nonatomic, strong) NSDictionary *audioTrackOutputSetting;

@property (nonatomic) CMSampleBufferRef currentVideoBuffer;
@property (nonatomic, retain) NSMutableArray *videoSnapshots;

@property (nonatomic, strong) NSString *exportVideoPath;
@property (nonatomic, strong) NSString *sourceVideoPath;

@property (nonatomic, strong) VideoSplitManager *videoSplitManager;

@property (nonatomic) CGFloat cost;
@property (nonatomic) CGFloat count;

@property (nonatomic, strong) NSDate *costDate;

@property (nonatomic) BOOL isFullscreenRecord;

@end

@implementation MultipleVideoRecorderController

- (instancetype)init {
	return [self initWithSingle:NO];
}

- (instancetype)initWithSingle:(BOOL)isSingle {
	if (self == [super init]) {
		[self init:isSingle];
	}
	
	return self;
}

- (void)init:(BOOL)isSingle {
	self.recordState = MultiRecordStateUnknown;
	
	self.sw = [[UIScreen mainScreen] bounds].size.width;
	self.sh = [[UIScreen mainScreen] bounds].size.height;
	
	//self.lock = [[NSLock alloc] init];
	self.lock = [NSObject new];
	
	_videoSplitManager = [[VideoSplitManager alloc] init];
	
	_videoSnapshots = [NSMutableArray array];
	
	self.isFirstFrame = YES;
	
	self.cameraPosition = AVCaptureDevicePositionBack;
	
	self.isFullscreenRecord = isSingle;
	
	self.recordState = MultiRecordStateInit;
}

- (void)dealloc {
	CVPixelBufferPoolRelease(_writerInputPixelBufferAdaptor.pixelBufferPool);

	if (self.currentVideoBuffer) {
		CFRelease(self.currentVideoBuffer);
		self.currentVideoBuffer = nil;
	}
	
	[self.videoSnapshots removeAllObjects];
}

- (BOOL)isSplitRecorder {
	return !self.isFullscreenRecord;
}

- (void)singleRecord:(BOOL)isSingle {
	self.isFullscreenRecord = isSingle;
}

- (void)setRecordState:(MultiRecordState)recordState {
	if (_recordState != recordState) {
		_lastRecordState = _recordState;
		_recordState = recordState;
		
		dispatch_async(dispatch_get_main_queue(), ^(){
			if ([self.delegate respondsToSelector:@selector(recordStateChanged:lastState:)]) {
				[self.delegate recordStateChanged:self.recordState lastState:self.lastRecordState];
			}
		});
	}
}

// 安装摄像头设备
- (void)setupCapture {
	if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0) {
		_captureSessionQueue = dispatch_queue_create("capture_session_queue", DISPATCH_QUEUE_SERIAL);
		_writerQueue = dispatch_queue_create("asset_writer_queue", DISPATCH_QUEUE_SERIAL);
		_readerQueue = dispatch_queue_create("asset_reader_queue", DISPATCH_QUEUE_SERIAL);
		
		[self setupContexts];
		
		[self setupCaptureSession];
		
		self.recordState = MultiRecordStateReady;
	}
}

- (void)uninstallCapture {
	if (self.captureSession) {
		[self.captureSession stopRunning];
	}
	
	[self stopVideoExtrace];
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
		// 获取视频设备
		AVCaptureDevice *videoDevice = [self cameraWithPosition:self.cameraPosition];
		
		// 获取输出规格
		NSString *preset = AVCaptureSessionPresetMedium;
		if (![videoDevice supportsAVCaptureSessionPreset:preset]) {
			return;
		}
		
		// 初始化摄像头会话
		_captureSession = [[AVCaptureSession alloc] init];
		_captureSession.sessionPreset = preset;
		
		[_captureSession beginConfiguration];
		
		[self addVideoDevice:videoDevice];
		
		[self addAudioDevice];
		
		//[self addPreviewLayer];
		
		[_captureSession commitConfiguration];
		
		[_captureSession startRunning];
	});
}

- (void)addVideoDevice:(AVCaptureDevice *)videoDevice {
	// 获取设备输入组件
	NSError *error = nil;
	AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
	if (!videoDeviceInput || error)
	{
		return;
	}
	
	// 创建并配置视频输出组件
	AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
	videoDataOutput.videoSettings = self.videoSettings;
	[videoDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
	
	if (![_captureSession canAddOutput:videoDataOutput])
	{
		_captureSession = nil;
		return;
	}
	
	[_captureSession addInput:videoDeviceInput];
	[_captureSession addOutput:videoDataOutput];
	
	AVCaptureConnection *conn = [self videoCaptureConnection:videoDataOutput];
	if (conn && conn.supportsVideoMirroring) {
		conn.videoMirrored = self.cameraPosition == AVCaptureDevicePositionFront;
		conn.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
	}
	
	_videoOutput = videoDataOutput;
}

- (void)addAudioDevice {
	if ([self isSplitRecorder]) {
		return;
	}
	
	//添加一个音频设备
	NSError *audioError;
	AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	
	// 音频输入对象
	AVCaptureDeviceInput *audioDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&audioError];
	if (audioError) {
		NSLog(@"取得录音设备时出错 ------ %@",audioError);
		return;
	}
	
	AVCaptureAudioDataOutput *audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
	[audioDataOutput setSampleBufferDelegate:self queue:_captureSessionQueue];
	
	if ([_captureSession canAddInput:audioDeviceInput]) {
		[_captureSession addInput:audioDeviceInput];
	}
	
	if ([_captureSession canAddOutput:audioDataOutput]) {
		[_captureSession addOutput:audioDataOutput];
	}
	
	_audioOutput = audioDataOutput;
}

- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition)position {
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices) {
		if ([device position] == position) {
			return device;
		}
	}
	return nil;
}

- (AVCaptureConnection *)videoCaptureConnection:(AVCaptureVideoDataOutput *)videoOutput {
	for (AVCaptureConnection *connection in [videoOutput connections] ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:AVMediaTypeVideo] ) {
				return connection;
			}
		}
	}
	
	return nil;
}

- (void)switchCamera {
	NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
	if (cameraCount <= 1) {
		return;
	}
	
	if(_captureSession) {
		[_captureSession beginConfiguration];
		
		AVCaptureInput* currentCameraInput = [_captureSession.inputs objectAtIndex:0];
		[_captureSession removeInput:currentCameraInput];
		
		AVCaptureDevice *newCamera = nil;
		if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
			newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
			self.cameraPosition = AVCaptureDevicePositionFront;
		}
		else {
			newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
			self.cameraPosition = AVCaptureDevicePositionBack;
		}
		
		//Add input to session
		NSError *err = nil;
		AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
		if(!newVideoInput || err) {
			NSLog(@"Error creating capture device input: %@", err.localizedDescription);
		}
		else {
			[_captureSession addInput:newVideoInput];
		}
		
		AVCaptureVideoDataOutput *videoDataOutput = _captureSession.outputs.firstObject;
		AVCaptureConnection *conn = [self videoCaptureConnection:videoDataOutput];
		if (conn && conn.supportsVideoMirroring) {
			conn.videoMirrored = self.cameraPosition == AVCaptureDevicePositionFront;
			conn.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
		}
		
		[_captureSession commitConfiguration];
	}
}

- (void)setupSourceVideo:(NSString *)sourceVideo {
	self.sourceVideoPath = sourceVideo;
	
	[self setupAssetReading:sourceVideo atTime:kCMTimeZero];
	
	[self setupAudioPlayer:sourceVideo atTime:kCMTimeZero];
	
	[self setupVideoExtracrTimer];
}

- (CGFloat)recordDuration {
	return self.sourceVideoSumTime;
}

- (CGFloat)currentDuration {
	return self.sourceVideoSumTime - self.sourceVideoLeftTime;
}

- (void)toggleRecord {
	if (self.recordState == MultiRecordStateReady) {
		[self startRecord];
	} else if (self.recordState == MultiRecordStateRecording) {
		[self stopRecord:MultiRecordStateReady];
	} else {
		NSLog(@"Neither ready nor recording, state is %ld", self.recordState);
	}
}

// 开始录制分段
- (BOOL)startRecord {
	if (self.recordState != MultiRecordStateReady) {
		NSLog(@"recordState must be MultiRecordStateReady or MultiRecordStateWillDeleteSplit");
		return NO;
	}
	
	if (!self.isFullscreenRecord && !self.sourceVideoPath) {
		NSLog(@"source video is not setup");
		return NO;
	}
	
	@synchronized (self) {
		// 加载视频录制写控制器
		[self setupAssetWriter:[_videoSplitManager allocNewSplit]];
		
		// 启动视频帧处理
		if ([self isSplitRecorder]) {
			[self startVideoExtrace];
		}
		
		// 初始化进度回调定时器
		_progressUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0/60 repeats:YES block:^(NSTimer *timer){
			if ([self.delegate respondsToSelector:@selector(progressUpdate:duration:)]) {
				CGFloat current = self.sourceVideoSumTime - self.sourceVideoLeftTime;
				CGFloat duration = self.sourceVideoSumTime;
				[self.delegate progressUpdate:current duration:duration];
			}
		}];
		[_progressUpdateTimer fire];
		
		self.recordState = MultiRecordStateRecording;
	}
	
	return YES;
}

// 停止录制分段
- (void)stopRecord:(MultiRecordState)state {
	if (self.recordState != MultiRecordStateRecording) {
		NSLog(@"recordState must be MultiRecordStateRecording");
		return;
	}
	
	@synchronized (self) {
		// 暂停视频帧处理
		if ([self isSplitRecorder]) {
			[self stopVideoExtrace];
			[self setupVideoExtracrTimer];
		}
		
		// 释放进度回调定时器
		[_progressUpdateTimer invalidate];
		_progressUpdateTimer = nil;
		
		// 停止源视频音频播放
		[_audioPlayer pause];
		self.isAudioPlaying = NO;
		
		// 结束写控制器，表示一个分段文件生成
		[self stopAssetWriter];
		
		self.recordState = state;
	}
	
	// 记录源视频的当前帧，作为删除分段后的跳转快照
	if ([self isSplitRecorder]) {
		VideoSnapshot *vs = [VideoSnapshot new];
		@synchronized (self.lock) {
			CFRetain(self.currentVideoBuffer);
			vs.buffer = self.currentVideoBuffer;
			vs.time = CMSampleBufferGetPresentationTimeStamp(self.currentVideoBuffer);
			[self.videoSnapshots addObject:vs];
		}
	}
}

- (int)deleteLastSplit {
	if (self.recordState != MultiRecordStateReady && self.recordState != MultiRecordStateFinish) {
		return -1;
	}
	
	if (![_videoSplitManager canDelete]) {
		return -1;
	}
	
	// 删除最后一个分段
	[_videoSplitManager popSplit];
	
	if ([self isSplitRecorder]) {
		// 没有分段时，标记为开始帧
		if (![_videoSplitManager canDelete]) {
			self.isFirstFrame = YES;
		}
		
		// 删除最后一个录制快照，取前一个分段快照
		[self.videoSnapshots removeLastObject];
		VideoSnapshot *vs = [self.videoSnapshots lastObject];
		@synchronized (self.lock) {
			if (self.currentVideoBuffer) {
				CFRelease(self.currentVideoBuffer);
				self.currentVideoBuffer = nil;
			}
			
			CFRetain(vs.buffer);
			self.currentVideoBuffer = vs.buffer;
		}
		
		// 初始化源视频的reader
		if (_reader) {
			[_reader cancelReading];
			_reader = nil;
		}
		[self setupAssetReading:self.sourceVideoPath atTime:vs.time];
		[_audioPlayer seekToTime:vs.time];
	}
	
	@synchronized (self) {
		self.recordState = MultiRecordStateReady;
	}
	
	return 0;
}

- (CGSize)recordResolution {
	return self.feedView.viewBounds.size;
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
		CGSize size = [self recordResolution];
		
		//宽高是视频帧的宽高
		_adaptorSettings = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
							 (id)kCVPixelBufferWidthKey: @(size.width),
							 (id)kCVPixelBufferHeightKey: @(size.height),
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
									   AVVideoWidthKey : @(size.width),
									   AVVideoHeightKey : @(size.height),
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
	if ([self isSplitRecorder]) {
		[self renderByGL1:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
		return;
	}
	
	[self renderByGL:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
}

- (void)renderByGL1:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	NSDate *start = nil;
	if (self.recordState == MultiRecordStateRecording) {
		start = [NSDate date];
	}
	
	CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
	
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CIImage *captureFrame = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
	
	CIImage *sourceVideoFrame = nil;
	@synchronized(self.lock) {
		if (self.currentVideoBuffer) {
			CVImageBufferRef videoBuffer = CMSampleBufferGetImageBuffer(self.currentVideoBuffer);
			sourceVideoFrame = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)videoBuffer options:nil];
			//presentationTime = CMSampleBufferGetPresentationTimeStamp(self.currentVideoBuffer);
		}
	}
	
	CIImage *destImage = [self renderFrameLeft2:captureFrame right:sourceVideoFrame overlayColor:NO];
	
	if (self.recordState == MultiRecordStateRecording && start) {
		NSDate *end = [NSDate date];
		NSTimeInterval cost = [end timeIntervalSinceDate:start];
		//NSLog(@"record video cost %f", cost);
		start = end;
		
		self.cost += cost;
		self.count++;
	}
	
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
	
	if (sourceVideoFrame) {
		dispatch_async(_writerQueue, ^(){
			[self outputVideoFrame:destImage withPresentationTime:presentationTime];
		});
	}
}

- (void)outputVideoFrame:(CIImage *)frame withPresentationTime:(CMTime)presentationTime {
	@synchronized (self) {
		if (self.recordState == MultiRecordStateRecording) {
			CVPixelBufferRef renderBuffer = NULL;
			CVPixelBufferPoolCreatePixelBuffer(NULL, _writerInputPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
			if (renderBuffer) {
				CVPixelBufferLockBaseAddress(renderBuffer, 0);
				[_ciContext render:frame toCVPixelBuffer:renderBuffer bounds:_feedView.viewBounds colorSpace:NULL];
				CVPixelBufferUnlockBaseAddress(renderBuffer, 0);
				
				[self appendSampleBuffer:AVMediaTypeVideo CVPixelBufferRef:renderBuffer withPresentationTime:presentationTime];
				CFRelease(renderBuffer);
			}
		}
	}
}

- (void)renderByGL:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if (!CMSampleBufferDataIsReady(sampleBuffer)) {
		return;
	}
	
	NSDate *start = nil;
	if (self.recordState == MultiRecordStateRecording) {
		start = [NSDate date];
	}
	
	if (captureOutput == _videoOutput) {
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		CIImage *sourceImage = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)imageBuffer options:nil];
		
		CGRect sourceExtent = sourceImage.extent;
		CGFloat sourceAspect = sourceExtent.size.width / sourceExtent.size.height;
		
		GLKViewWithBounds *feedView = self.feedView;
		
		CGSize previewSize1 = CGSizeMake(feedView.viewBounds.size.width, feedView.viewBounds.size.height);
		CGRect inRect = CGRectMake(0, 0, feedView.viewBounds.size.width, feedView.viewBounds.size.height);
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
		
		UIImage *image;
		[image drawInRect:inRect];
		
		[feedView display];
	}
	
	@synchronized (self) {
		if (self.recordState == MultiRecordStateRecording) {
			CFRetain(sampleBuffer);
			dispatch_async(_writerQueue, ^(){
				NSString *mediaType = (captureOutput == _videoOutput) ? AVMediaTypeVideo : AVMediaTypeAudio;
				[self appendSampleBuffer:mediaType CMSampleBufferRef:sampleBuffer];
				CFRelease(sampleBuffer);
			});
		}
	}
	
	if (self.recordState == MultiRecordStateRecording && start) {
		NSDate *end = [NSDate date];
		NSTimeInterval cost = [end timeIntervalSinceDate:start];
		//NSLog(@"record video cost %f", cost);
		start = end;
		
		self.cost += cost;
		self.count++;
	}
}

- (CIImage *)renderFrameLeft:(CIImage *)image1 right:(CIImage *)image2 overlayColor:(BOOL)overlay {
	// 绘制屏幕尺寸的宽高比
	CGSize size = self.feedView.viewBounds.size;
	CGFloat destAsptect = size.width / (size.height / 2);
	
	UIImage *tmp1 = nil;
	UIImage *tmp2 = nil;
	if (image1) {
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
		tmp1 = [[UIImage alloc] initWithCIImage:destImage1];
	}
	
	if (image2) {
		/*
		CGRect drawRect = CGRectMake(0, 0, size.width, size.height / 2);
		CGRect image2Rect = image2.extent;
		CGFloat scale;
		if (_videoTransform.a == 1 && _videoTransform.d == 1 && _videoTransform.b == 0 && _videoTransform.c == 0) {
			CGFloat image2Asptect = CGRectGetHeight(image2Rect) / CGRectGetWidth(image2Rect);
			if (image2Asptect < destAsptect) {
				scale = CGRectGetHeight(image2Rect) / CGRectGetHeight(drawRect);
			} else {
				scale = CGRectGetWidth(image2Rect) / CGRectGetWidth(drawRect);
			}
			tmp2 = [[UIImage alloc] initWithCIImage:image2 scale:scale orientation:UIImageOrientationLeft];
		} else {
			CGFloat image2Asptect = CGRectGetWidth(image2Rect) / CGRectGetHeight(image2Rect);
			if (image2Asptect < destAsptect) {
				scale = CGRectGetHeight(image2Rect) / CGRectGetHeight(drawRect);
			} else {
				scale = CGRectGetWidth(image2Rect) / CGRectGetWidth(drawRect);
			}
			// tmp2 = [[UIImage alloc] initWithCIImage:image2];
			tmp2 = [[UIImage alloc] initWithCIImage:image2 scale:scale orientation:UIImageOrientationUp];
		}
		 */
		if (_videoTransform.a == 1 && _videoTransform.d == 1 && _videoTransform.b == 0 && _videoTransform.c == 0) {
			tmp2 = [[UIImage alloc] initWithCIImage:image2 scale:1.0 orientation:UIImageOrientationLeft];
		} else {
			tmp2 = [[UIImage alloc] initWithCIImage:image2];
		}
	}
	
	UIGraphicsBeginImageContext(size);
	[[UIColor colorWithWhite:0 alpha:1] setFill];
	
	if (tmp2) {
		CGRect drawRect = CGRectMake(0, 0, size.width, size.height / 2);
		CGRect image2Rect = CGRectMake(0, 0, tmp2.size.width, tmp2.size.height);
		CGFloat image2Asptect = CGRectGetWidth(image2Rect) / CGRectGetHeight(image2Rect);
		if (image2Asptect < destAsptect) {
			drawRect.origin.x = (CGRectGetWidth(drawRect) - CGRectGetHeight(drawRect) * image2Asptect) / 2;
			drawRect.size.width = CGRectGetHeight(drawRect) * image2Asptect;
		} else {
			drawRect.origin.y = (CGRectGetHeight(drawRect) - CGRectGetWidth(drawRect) / image2Asptect) / 2;
			drawRect.size.height = CGRectGetWidth(drawRect) / image2Asptect;
		}
		
		[tmp2 drawInRect:drawRect];
		
		if (overlay) {
			CGContextRef context = UIGraphicsGetCurrentContext();
			[[UIColor colorWithWhite:0 alpha:0.8] setFill];
			CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height / 2));
			CGContextDrawPath(context,kCGPathFill);
		}
	}
	
	if (tmp1) {
		CGRect drawRect = CGRectMake(0, size.height / 2, size.width, size.height / 2);
		[tmp1 drawInRect:drawRect];
	}
	
	UIImage *result = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return [[CIImage alloc] initWithImage:result];
}

- (CIImage *)renderFrameLeft2:(CIImage *)image1 right:(CIImage *)image2 overlayColor:(BOOL)overlay {
	// 绘制屏幕尺寸的宽高比
	CGSize size = self.feedView.viewBounds.size;
	CGFloat destAsptect = size.width / (size.height / 2);
	int viewWidth = (int)size.width;
	int viewHeight = (int)size.height;
	int splitHeight = viewHeight >> 1;
	
	UIGraphicsBeginImageContext(size);
	[[UIColor colorWithWhite:0 alpha:1] setFill];
	
	// CIContext *ciContext = [CIContext contextWithOptions:nil];
	CIContext *ciContext = _ciContext;
	CGContextRef context = UIGraphicsGetCurrentContext();
	
	// Flip the context because UIKit coordinate system is upside down to Quartz coordinate system
	CGContextTranslateCTM(context, 0.0, viewHeight);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	if (image1) {
		CGRect drawRect = CGRectMake(0, 0, viewWidth, splitHeight);
		CGRect image1Rect = image1.extent;
		CGFloat image1Asptect = CGRectGetWidth(image1Rect) / CGRectGetHeight(image1Rect);
		if (image1Asptect < destAsptect) {
			image1Rect.origin.y = (CGRectGetHeight(image1Rect) - CGRectGetWidth(image1Rect) / destAsptect) / 2;
			image1Rect.size.height = CGRectGetWidth(image1Rect) / destAsptect;
		} else {
			image1Rect.origin.x = (CGRectGetWidth(image1Rect) - CGRectGetHeight(image1Rect) * destAsptect) / 2;
			image1Rect.size.width = CGRectGetHeight(image1Rect) * destAsptect;
		}
		CGImageRef cgimg = [ciContext createCGImage:image1 fromRect:image1Rect];
		
		CGContextDrawImage(context, drawRect, cgimg);
		CGImageRelease(cgimg);
	}
	
	// fill
	if (image2 && false) {
		BOOL noRotate = _videoTransform.a == 1 && _videoTransform.d == 1 && _videoTransform.b == 0 && _videoTransform.c == 0;
		
		CGRect drawRect = CGRectMake(0, splitHeight, viewWidth, splitHeight);
		CGRect image2Rect = image2.extent;
		if (noRotate) {
			CGContextSaveGState(context);
			CGContextTranslateCTM(context, viewWidth >> 1, viewHeight >> 1);
			CGContextRotateCTM(context, M_PI_2);
			CGContextTranslateCTM(context, -(viewHeight >> 1), -(viewWidth >> 1));
			
			image2Rect = CGRectMake(0, 0, CGRectGetHeight(image2Rect), CGRectGetWidth(image2Rect));
		}
		
		CGFloat image2Asptect = CGRectGetWidth(image2Rect) / CGRectGetHeight(image2Rect);
		if (image2Asptect < destAsptect) {
			image2Rect.origin.y = (CGRectGetHeight(image2Rect) - CGRectGetWidth(image2Rect) / destAsptect) / 2;
			image2Rect.size.height = CGRectGetWidth(image2Rect) / destAsptect;
		} else {
			image2Rect.origin.x = (CGRectGetWidth(image2Rect) - CGRectGetHeight(image2Rect) * destAsptect) / 2;
			image2Rect.size.width = CGRectGetHeight(image2Rect) * destAsptect;
		}
		
		if (noRotate) {
			image2Rect = CGRectMake(CGRectGetMinY(image2Rect), CGRectGetMinX(image2Rect), CGRectGetHeight(image2Rect), CGRectGetWidth(image2Rect));
			drawRect = CGRectMake(CGRectGetMinY(drawRect), CGRectGetMinX(drawRect), CGRectGetHeight(drawRect), CGRectGetWidth(drawRect));
		}
		
		CGImageRef cgimg = [ciContext createCGImage:image2 fromRect:image2Rect];
		CGContextDrawImage(context, drawRect, cgimg);
		CGImageRelease(cgimg);
		
		if (noRotate) {
			CGContextRestoreGState(context);
		}
	}
	
	// fit
	if (image2) {
		// 图片没有旋转
		BOOL noRotate = _videoTransform.a == 1 && _videoTransform.d == 1 && _videoTransform.b == 0 && _videoTransform.c == 0;
		
		CGRect drawRect = CGRectMake(0, splitHeight, viewWidth, splitHeight);
		CGRect image2Rect = image2.extent;
		if (noRotate) {
			CGContextSaveGState(context);
			CGContextTranslateCTM(context, viewWidth >> 1, viewHeight >> 1);
			CGContextRotateCTM(context, M_PI_2);
			CGContextTranslateCTM(context, -(viewHeight >> 1), -(viewWidth >> 1));
			
			image2Rect = CGRectMake(0, 0, CGRectGetHeight(image2Rect), CGRectGetWidth(image2Rect));
		}
		
		CGFloat image2Asptect = CGRectGetWidth(image2Rect) / CGRectGetHeight(image2Rect);
		if (image2Asptect < destAsptect) {
			drawRect.origin.x = (CGRectGetWidth(drawRect) - CGRectGetHeight(drawRect) * image2Asptect) / 2;
			drawRect.size.width = CGRectGetHeight(drawRect) * image2Asptect;
		} else {
			drawRect.origin.y = (CGRectGetHeight(drawRect) - CGRectGetWidth(drawRect) / image2Asptect) / 2;
			drawRect.size.height = CGRectGetWidth(drawRect) / image2Asptect;
		}
		
		if (noRotate) {
			drawRect = CGRectMake(CGRectGetMinY(drawRect), CGRectGetMinX(drawRect), CGRectGetHeight(drawRect), CGRectGetWidth(drawRect));
		}
		
		CIImage *finalImage;
		CGFloat scale = CGRectGetWidth(drawRect) / CGRectGetWidth(image2.extent);
		if (scale < 1) {
			CIFilter *resizeFilter = [CIFilter filterWithName:@"CILanczosScaleTransform"];
			[resizeFilter setValue:image2 forKey:@"inputImage"];
			[resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
			[resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
			finalImage = resizeFilter.outputImage;
		} else {
			finalImage = image2;
		}
		
		CGImageRef cgimg = [ciContext createCGImage:finalImage fromRect:finalImage.extent];
		CGContextDrawImage(context, drawRect, cgimg);
		CGImageRelease(cgimg);
		
		if (overlay) {
			CGContextRef context = UIGraphicsGetCurrentContext();
			[[UIColor colorWithWhite:0 alpha:0.8] setFill];
			CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height / 2));
			CGContextDrawPath(context,kCGPathFill);
		}
		
		if (noRotate) {
			CGContextRestoreGState(context);
		}
	}
	
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
	
	if (self.recordState != MultiRecordStateRecording){
		NSLog(@"not ready yet");
		return;
	}
	
	if (!self.canWrite && mediaType == AVMediaTypeVideo) {
		[_writer startSessionAtSourceTime:presentationTime];
		self.canWrite = YES;
	}
	
	//写入视频数据
	if (mediaType == AVMediaTypeVideo && _videoWriterInput.isReadyForMoreMediaData) {
		BOOL ret =  [_writerInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
		if (!ret) {
			@synchronized (self) {
				[self stopAssetWriter];
				[self destroyWrite];
			}
		}
	}
}

- (void)appendSampleBuffer:(NSString *)mediaType CMSampleBufferRef:(CMSampleBufferRef)sampleBuffer
{
	if (sampleBuffer == NULL){
		NSLog(@"empty sampleBuffer");
		return;
	}
	
	if (self.recordState != MultiRecordStateRecording){
		NSLog(@"not ready yet");
		return;
	}
	
	if (!self.canWrite) {
		if (mediaType == AVMediaTypeVideo) {
			CMTime presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
			[_writer startSessionAtSourceTime:presentationTime];
			self.canWrite = YES;
		} else {
			// 丢掉一开始的音频数据，避免写入一些初始的黑屏帧
			return;
		}
	}
	
	//写入视频数据
	if (mediaType == AVMediaTypeVideo) {
		if (_videoWriterInput.isReadyForMoreMediaData) {
			BOOL ret = [_videoWriterInput appendSampleBuffer:sampleBuffer];
			if (!ret) {
				@synchronized (self) {
					[self stopAssetWriter];
					[self destroyWrite];
				}
			}
		}
	} else if (mediaType == AVMediaTypeAudio) {
		if (_audioWriterInput.isReadyForMoreMediaData) {
			BOOL ret = [_audioWriterInput appendSampleBuffer:sampleBuffer];
			if (!ret) {
				@synchronized (self) {
					[self stopAssetWriter];
					[self destroyWrite];
				}
			}
		}
	}
}

- (void)setupAssetReading:(NSString *)videoFile atTime:(CMTime)atTime{
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
		CGFloat totalTime = CMTimeGetSeconds(duration);
		_sourceVideoFrameTime = 1 / videoTrack.nominalFrameRate;
		_sourceVideoSumTime = totalTime;
		[self updateVideoLeftTime:atTime];
		
		_reader.timeRange = CMTimeRangeMake(atTime, kCMTimePositiveInfinity);
		
		_assetVideoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:self.videoTrackOutputSetting];
		[_reader addOutput:_assetVideoReaderOutput];
		
		if (![_reader startReading]) {
//			AVAssetReaderStatus status = [_reader status];
//			NSError *err = [_reader error];
//			NSLog(@"startReading error");
		}
	}
}

- (void)setupVideoExtracrTimer {
	if (!_readerTimer) {
		NSTimeInterval period = _sourceVideoFrameTime;
		//dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _readerQueue);
		dispatch_source_set_timer(timer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
		self.readerTimer = timer;
		
		__weak typeof(self) weakSelf = self;
		dispatch_source_set_event_handler(timer, ^{
			[weakSelf handleVideoFrame];
		});
	}
}

- (void)startVideoExtrace {
	if (_readerTimer) {
		dispatch_resume(_readerTimer);
	}
}

- (void)stopVideoExtrace {
	if (self.readerTimer) {
		dispatch_source_cancel(self.readerTimer);
		self.readerTimer = nil;
	}
}

- (void)handleVideoFrame {
	if ([_reader status] == AVAssetReaderStatusReading) {
		@synchronized (self) {
			if (self.recordState != MultiRecordStateRecording) {
				NSLog(@"[%@]Not recording", [NSString stringWithUTF8String:__FUNCTION__]);
				return;
			}
			
			if (!self.isAudioPlaying) {
				[_audioPlayer play];
				self.isAudioPlaying = YES;
				self.costDate = [NSDate date];
			}
			
			CMSampleBufferRef videoBuffer = [_assetVideoReaderOutput copyNextSampleBuffer];
			if (videoBuffer) {
				@synchronized(self.lock) {
					// 有可能录制帧率没有视频帧率高，会丢视频帧，这里要把录制没有处理的视频帧释放掉
					if (self.currentVideoBuffer) {
						CFRelease(self.currentVideoBuffer);
						self.currentVideoBuffer = nil;
					}
					
					self.currentVideoBuffer = videoBuffer;
					
					// 记录第一帧到分段快照
					if (self.isFirstFrame) {
						VideoSnapshot *vs = [VideoSnapshot new];
						CFRetain(self.currentVideoBuffer);
						vs.buffer = self.currentVideoBuffer;
						vs.time = CMSampleBufferGetPresentationTimeStamp(self.currentVideoBuffer);
						[self.videoSnapshots addObject:vs];
						self.isFirstFrame = NO;
					}
				}
				
				[self updateVideoLeftTime:CMSampleBufferGetPresentationTimeStamp(videoBuffer)];
			}
		}
	} else {
		[self stopRecord:MultiRecordStateFinish];
	
		NSLog(@"video duration %f", [self.costDate timeIntervalSinceNow]);
	}
}

- (void)setupAudioPlayer:(NSString *)videoFile atTime:(CMTime)atTime {
	if (!_audioPlayer) {
		NSURL *url = [NSURL fileURLWithPath:videoFile];
		_audioPlayer = [[AVPlayer alloc] initWithURL:url];
		_audioPlayer.actionAtItemEnd = AVPlayerActionAtItemEndNone;
		[_audioPlayer seekToTime:atTime];
	}
}

- (void)setupAssetWriter:(NSString *)writerOutputPath {
	if (!_writer) {
		NSFileManager *mgr = [NSFileManager defaultManager];
		[mgr removeItemAtPath:writerOutputPath error:nil];
		
		NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:writerOutputPath];
		NSError *err;
		_writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeMPEG4 error:&err];
		
		// 视频写
		_videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
		_videoWriterInput.expectsMediaDataInRealTime = YES;	//expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
		
		if ([_writer canAddInput:_videoWriterInput]) {
			[_writer addInput:_videoWriterInput];
		}else {
			NSLog(@"AssetWriter videoInput append Failed");
		}
		
		_writerInputPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_videoWriterInput sourcePixelBufferAttributes:self.adaptorSettings];
		
		// 音频写
		_audioWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
		_audioWriterInput.expectsMediaDataInRealTime = YES;
		
		if ([_writer canAddInput:_audioWriterInput]) {
			[_writer addInput:_audioWriterInput];
		}else {
			NSLog(@"AssetWriter audioInput append Failed");
		}
		
		if (![_writer startWriting]) {
			NSLog(@"[%@]err %@", [NSString stringWithUTF8String:__FUNCTION__], err.description);	NSDate *start = nil;
			if (self.recordState == MultiRecordStateRecording) {
				start = [NSDate date];
			}
		}
	}
}

- (void)updateVideoLeftTime:(CMTime)presentTime {
	CMTime durationTime = [_videoAsset duration];
	CGFloat leftSeconds = CMTimeGetSeconds(CMTimeSubtract(durationTime, presentTime));
	self.sourceVideoLeftTime = leftSeconds;
	
	// NSLog(@"left time is %f", self.sourceVideoLeftTime);
}

- (void)stopAssetWriter
{
	if(_writer && _writer.status == AVAssetWriterStatusWriting) {
		[_writer finishWritingWithCompletionHandler:^{
			_writer = nil;
			_canWrite = NO;
		}];
	}
}

- (void)exportVideo:(void(^)(NSString *))exportResult {
	NSLog(@"record cost %f", self.cost / self.count);
	
	if (![self isSplitRecorder]) {
		[self exportVideoWithFull:exportResult];
		return;
	}
	
	if (self.recordState != MultiRecordStateFinish) {
		NSLog(@"export failure. record state is %ld", self.recordState);
		return;
	}
	
	NSArray<NSString *> * videoFiles = [_videoSplitManager getAllSplits];
	NSString *audioFromVideoFile = self.sourceVideoPath;
	
	// 创建拼接工程
	AVMutableComposition* mc = [[AVMutableComposition alloc] init];
	
	// 添加视频和音频轨道
	AVMutableCompositionTrack *videoTrack = [mc addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVMutableCompositionTrack *audioTrack = [mc addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	// 插入音频轨
	NSURL *audioURL = [NSURL fileURLWithPath:audioFromVideoFile];
	AVURLAsset* asset2 = [AVURLAsset URLAssetWithURL:audioURL options:nil];
	if ([asset2 tracksWithMediaType:AVMediaTypeAudio].count == 0) {
		NSLog(@"NO audio track...");
		return;
	}
	AVAssetTrack *audioAsset = [[asset2 tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
	[audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:audioAsset atTime:kCMTimeZero error:nil];
	
	// 插入视频轨
	for (long i=videoFiles.count - 1; i>=0; i--) {
		NSString *videoPath = videoFiles[i];
		NSURL *videoFile = [NSURL fileURLWithPath:videoPath];
		AVURLAsset* asset1 = [AVURLAsset URLAssetWithURL:videoFile options:nil];
		if ([asset1 tracksWithMediaType:AVMediaTypeVideo].count == 0) {
			NSLog(@"NO video track...");
			return;
		}
		AVAssetTrack *videoAsset = [[asset1 tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
		[videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset1.duration) ofTrack:videoAsset atTime:kCMTimeZero error:nil];
	}
	
	// 对齐视频和音频轨道的长度
	CMTime audioTimeRange = audioTrack.timeRange.duration;
	CMTime videoTimeRange = videoTrack.timeRange.duration;
	int32_t ret = CMTimeCompare(audioTimeRange, videoTimeRange);
	if (ret < 0) {
		CMTimeRange remove = CMTimeRangeFromTimeToTime(audioTimeRange, videoTimeRange);
		[videoTrack removeTimeRange:remove];
	} else if (ret > 0) {
		CMTimeRange remove = CMTimeRangeFromTimeToTime(videoTimeRange, audioTimeRange);
		[audioTrack removeTimeRange:remove];
	}
	
	// 90度旋转
	CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
	CGAffineTransform mixedTransform = CGAffineTransformRotate(translateToCenter, M_PI_2);
	
	// 视频指令工程
	AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	// roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.duration);
	roateInstruction.timeRange = videoTrack.timeRange;
	
	// 视频旋转
	AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	[roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
	roateInstruction.layerInstructions = @[roateLayerInstruction];
	
	// 视频工程
	CGSize renderSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
	AVMutableVideoComposition *waterMarkVideoComposition = [AVMutableVideoComposition videoComposition];
	waterMarkVideoComposition.frameDuration = CMTimeMake(1, 30);
	waterMarkVideoComposition.renderSize = renderSize;
	waterMarkVideoComposition.instructions = @[roateInstruction];
	
	// 导出
	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mc presetName:AVAssetExportPresetMediumQuality];
	exportSession.videoComposition = waterMarkVideoComposition;
	exportSession.outputURL = [NSURL fileURLWithPath:self.exportVideoPath];
	exportSession.outputFileType = AVFileTypeMPEG4;
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
				exportResult(self.exportVideoPath);
				break;
			}
			case AVAssetExportSessionStatusFailed:
			{
				NSLog(@"export failed...");
				exportResult(nil);
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
		
		self.recordState = MultiRecordStateExported;
	}];
}

- (void)exportVideoWithFull:(void(^)(NSString *))exportResult {
	if (self.recordState != MultiRecordStateReady) {
		NSLog(@"export failure. record state is %ld", self.recordState);
		return;
	}
	
	NSArray<NSString *> * videoFiles = [_videoSplitManager getAllSplits];
	
	// 创建拼接工程
	AVMutableComposition* mc = [[AVMutableComposition alloc] init];
	
	// 添加视频和音频轨道
	AVMutableCompositionTrack *videoTrack = [mc addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	AVMutableCompositionTrack *audioTrack = [mc addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
	
	void (^loadAsset)(NSString *mediaType, AVMutableCompositionTrack *track) = ^(NSString *mediaType, AVMutableCompositionTrack *track) {
		for (long i=videoFiles.count - 1; i>=0; i--) {
			NSString *videoPath = videoFiles[i];
			NSURL *videoFile = [NSURL fileURLWithPath:videoPath];
			AVURLAsset* asset = [AVURLAsset URLAssetWithURL:videoFile options:nil];
			if ([asset tracksWithMediaType:mediaType].count == 0) {
				NSLog(@"NO video track...");
				return;
			}
			AVAssetTrack *assetTrack = [[asset tracksWithMediaType:mediaType] objectAtIndex:0];
			[track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:assetTrack atTime:kCMTimeZero error:nil];
		}
	};
	
	// 插入音频轨
	loadAsset(AVMediaTypeAudio, audioTrack);
	loadAsset(AVMediaTypeVideo, videoTrack);
	
	// 对齐视频和音频轨道的长度
	CMTime audioTimeRange = audioTrack.timeRange.duration;
	CMTime videoTimeRange = videoTrack.timeRange.duration;
	int32_t ret = CMTimeCompare(audioTimeRange, videoTimeRange);
	if (ret < 0) {
		CMTimeRange remove = CMTimeRangeFromTimeToTime(audioTimeRange, videoTimeRange);
		[videoTrack removeTimeRange:remove];
	} else if (ret > 0) {
		CMTimeRange remove = CMTimeRangeFromTimeToTime(videoTimeRange, audioTimeRange);
		[audioTrack removeTimeRange:remove];
	}
	
	// 90度旋转
	CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
	CGAffineTransform mixedTransform = CGAffineTransformRotate(translateToCenter, M_PI_2);
	
	// 视频指令工程
	AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	// roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.duration);
	roateInstruction.timeRange = videoTrack.timeRange;
	
	// 视频旋转
	AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
	[roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
	roateInstruction.layerInstructions = @[roateLayerInstruction];
	
	// 视频工程
	CGSize renderSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
	AVMutableVideoComposition *waterMarkVideoComposition = [AVMutableVideoComposition videoComposition];
	waterMarkVideoComposition.frameDuration = CMTimeMake(1, 30);
	waterMarkVideoComposition.renderSize = renderSize;
	waterMarkVideoComposition.instructions = @[roateInstruction];
	
	// 导出
	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:mc presetName:AVAssetExportPresetMediumQuality];
	exportSession.videoComposition = waterMarkVideoComposition;
	exportSession.outputURL = [NSURL fileURLWithPath:self.exportVideoPath];
	exportSession.outputFileType = AVFileTypeMPEG4;
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
				exportResult(self.exportVideoPath);
				break;
			}
			case AVAssetExportSessionStatusFailed:
			{
				NSLog(@"export failed...");
				exportResult(nil);
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
		
		self.recordState = MultiRecordStateExported;
	}];
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

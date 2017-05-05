//
//  SplitRecordViewController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/2.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "SplitRecordViewController.h"
#import "CaptureToolKit.h"

#pragma mark - Custom GLKView

// Note: I made this subclass to streamline the sample code. Fully accept it might not be the best way to do this.

@interface GLKViewWithBounds : GLKView

@property (nonatomic, assign) CGRect viewBounds;

@end


@implementation GLKViewWithBounds

@end


#pragma mark - View Controller

@interface SplitRecordViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AVPlayerItemOutputPullDelegate>

@property (nonatomic, retain) UIButton *closeBtn;

@property (nonatomic, retain) UIButton *recordBtn;

@property (nonatomic, retain) UIButton *deleteBtn;

@property (nonatomic, retain) UIButton *pickerBtn;

@property (nonatomic, retain) UIView *previewView;

@property (nonatomic, strong) CALayer *previewLayer;

@property (nonatomic, retain) UIView *lineView;

@property (nonatomic, retain) UILabel *durationView;

@property (nonatomic, assign) int sw;
@property (nonatomic, assign) int sh;

@property (nonatomic, retain) AVCaptureSession *captureSession;
@property (nonatomic, retain) AVCaptureDevice *captureDevice;
@property (nonatomic, retain) AVCaptureDeviceInput *captureDevideInput;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;

@property (nonatomic, retain) AVCaptureOutput *captureOutput;
@property (nonatomic, retain) AVCaptureVideoDataOutput *captureVideoDataOutput;

@property (nonatomic, strong) AVAssetWriter *writer;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *writerInputPixelBufferAdaptor;

@property (nonatomic, retain) dispatch_queue_t sessionQueue;

@property (nonatomic, retain) dispatch_queue_t writerQueue;

@property (nonatomic, strong) CIContext *ciContext;
@property (nonatomic, strong) EAGLContext *eaglContext;

@property (nonatomic, assign) CMVideoDimensions currentVideoDimensions;

@property (nonatomic, retain) GLKViewWithBounds *feedView;

@property (nonatomic,strong) AVAssetReaderTrackOutput *assetVideoReaderOutput;
@property (nonatomic,strong) AVAssetReaderTrackOutput *assetAudioReaderOutput;
@property (nonatomic,strong) AVAssetReader *reader;
@property (nonatomic, strong) AVURLAsset *videoAsset;
@property (nonatomic,strong) NSTimer *timer;
@property (nonatomic, assign) CGFloat frameTime;

@property AVPlayerItemVideoOutput *videoOutput;
@property CADisplayLink *displayLink;

@property (nonatomic, strong) NSURL *sourceVideoPath;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (nonatomic, assign) CMSampleBufferRef currentVideoBuffer;
@property (nonatomic, assign) CVImageBufferRef currentAudioBuffer;
@property (nonatomic, strong) CIImage *currentVideoImage;

@property (nonatomic, strong) NSLock *lock;

@property (nonatomic) BOOL isRecording;

@property (nonatomic, strong) NSString *videoPath;
@property (nonatomic, strong) NSString *outputVideoPath;

@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) NSDictionary *adaptorSettings;
@property (nonatomic, strong) NSDictionary *videoTrackOutputSetting;
@property (nonatomic, strong) NSDictionary *audioTrackOutputSetting;

@property (nonatomic, assign) FMRecordState writeState;

@property (nonatomic, assign) BOOL canWrite;

@property (nonatomic, assign) CGFloat sumTime;
@property (nonatomic, assign) BOOL needRefresh;

@end

@implementation SplitRecordViewController

- (instancetype)init {
	if (self = [super init]) {
		_lock = [[NSLock alloc] init];
	}
	
	return self;
}

#pragma mark init view

- (GLKViewWithBounds *)feedView {
	if (!_feedView) {
		_feedView = [self setupFeedViewWithFrame:CGRectMake(0, 100, self.sw, self.sw)];
		[_feedView setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:1]];
	}
	
	return _feedView;
}

- (UIButton *)closeBtn {
	if (!_closeBtn) {
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setFrame:CGRectMake(0, 0, 60, 40)];
		[btn setTitle:@"关闭" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_closeBtn = btn;
	}
	
	return _closeBtn;
}

- (UIButton *)recordBtn {
	if (!_recordBtn) {
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setFrame:CGRectMake(self.sw / 3, self.sh - 40, self.sw / 3, 40)];
		[btn setTitle:@"录制" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_recordBtn = btn;
	}
	
	return _recordBtn;
}

- (UIButton *)deleteBtn {
	if (!_deleteBtn) {
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setFrame:CGRectMake(0, self.sh - 40, self.sw / 3, 40)];
		[btn setTitle:@"删除" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_deleteBtn = btn;
	}
	
	return _deleteBtn;
}

- (UIButton *)pickerBtn {
	if (!_pickerBtn) {
		UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
		[btn setFrame:CGRectMake(self.sw * 2 / 3, self.sh - 40, self.sw / 3, 40)];
		[btn setTitle:@"选视频" forState:UIControlStateNormal];
		[btn addTarget:self action:@selector(onClickBtn:) forControlEvents:UIControlEventTouchUpInside];
		_pickerBtn = btn;
	}
	
	return _pickerBtn;
}

- (UIImagePickerController *)imagePickerController {
	if (!_imagePickerController) {
		_imagePickerController = [[UIImagePickerController alloc] init];
		_imagePickerController.delegate = self;
		_imagePickerController.allowsEditing = NO;
	}
	
	return _imagePickerController;
}

- (UILabel *)durationView {
	if (!_durationView) {
		_durationView = [[UILabel alloc] initWithFrame:CGRectMake(10, 60, 100, 60)];
		[_durationView setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:1]];
	}
	
	return _durationView;
}

- (UIView *)previewView {
	if (!_previewView) {
		UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 100, self.sw, self.sw)];
		[view setBackgroundColor:[UIColor colorWithWhite:0.1 alpha:1]];
		_previewView = view;
	}
	
	return _previewView;
}

- (UIView *)lineView {
	if (!_lineView) {
		UIView *line = [[UIView alloc] initWithFrame:CGRectMake(self.sw / 2, 0, 1, self.sh)];
		[line setBackgroundColor:[UIColor colorWithRed:1 green:0 blue:0 alpha:1]];
		_lineView = line;
	}
	
	return _lineView;
}

- (void)onClickBtn:(id)sender {
	if (sender == self.closeBtn) {
		[self.navigationController popViewControllerAnimated:YES];
	} else if (sender == self.pickerBtn) {
		self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeSavedPhotosAlbum;
		self.imagePickerController.mediaTypes = [[NSArray alloc] initWithObjects:@"public.movie", nil];
		[self presentViewController:self.imagePickerController animated:YES completion:nil];
	} else if (sender == self.recordBtn) {
		if (self.writeState == FMRecordStateInit) {
			[self startRecord];
		} else if (self.writeState == FMRecordStateRecording){
			[self stopRecord];
			
			dispatch_async(dispatch_get_main_queue(), ^(void){
				[self _showAlertViewWithMessage:@"录制完成"];
			});
		} else if (self.writeState == FMRecordStateFinish) {
			dispatch_async(dispatch_get_main_queue(), ^(void){
				[self _showAlertViewWithMessage:@"已录制完成"];
			});
		}
	} else if (sender == self.deleteBtn) {
		if (self.writeState == FMRecordStateFinish) {
			self.writeState = FMRecordStateInit;
			if (self.currentVideoBuffer) {
				CFRelease(self.currentVideoBuffer);
				self.currentVideoBuffer = nil;
			}
		}
	}
}

#pragma mark vc lifecycle

- (void)initData {
	self.sw = [[UIScreen mainScreen] bounds].size.width;
	self.sh = [[UIScreen mainScreen] bounds].size.height;
}

- (void)setupControlPanel {
	[self.view addSubview:self.closeBtn];
	[self.view addSubview:self.deleteBtn];
	[self.view addSubview:self.recordBtn];
	[self.view addSubview:self.pickerBtn];
	[self.view addSubview:self.durationView];
}

- (void)setupPreview {
	//[self.view addSubview:self.previewView];
	
	[self.view addSubview:self.feedView];
	
	[self.view addSubview:self.lineView];
}

- (void)loadView {
	[super loadView];
	
	[self initData];
	
	[self setupControlPanel];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0) {
		_sessionQueue = dispatch_queue_create("capture_session_queue", DISPATCH_QUEUE_SERIAL);
		
		_writerQueue = dispatch_queue_create("asset_writer_queue", DISPATCH_QUEUE_SERIAL);
		
		// Contexts
		[self setupContexts];
	
		// Sessions
		[self setupCaptureSession];
		
		[self setupPreview];
	}
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:YES];
}

- (BOOL)prefersStatusBarHidden
{
	return YES;
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupLink {
	// Setup CADisplayLink which will callback displayPixelBuffer: at every vsync.
	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
	[[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[[self displayLink] setPaused:YES];
	
	// Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
	NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
	self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
	[[self videoOutput] setDelegate:self queue:_writerQueue];
}

#pragma mark - Feed Views

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

#pragma mark - Contexts and Sessions

- (void)setupContexts {
	// setup the GLKView for video/image preview
	_eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
	
	// create the CIContext instance, note that this must be done after _videoPreviewView is properly set up
	_ciContext = [CIContext contextWithEAGLContext:_eaglContext
										   options:@{kCIContextWorkingColorSpace : [NSNull null]} ];
}

- (void)setupCaptureSession {
	if (_captureSession) {
		return;
	}
	
	dispatch_async(_sessionQueue, ^(void) {
		NSError *error = nil;
		
		// get the input device and also validate the settings
		NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
		
		AVCaptureDevice *_videoDevice = nil;
		
		if (!_videoDevice) {
			_videoDevice = [videoDevices objectAtIndex:0];
		}
		
		// obtain device input
		AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:_videoDevice error:&error];
		if (!videoDeviceInput)
		{
			[self _showAlertViewWithMessage:[NSString stringWithFormat:@"Unable to obtain video device input, error: %@", error]];
			return;
		}
		
		
		// obtain the preset and validate the preset
		NSString *preset = AVCaptureSessionPresetMedium;
		
		if (![_videoDevice supportsAVCaptureSessionPreset:preset])
		{
			[self _showAlertViewWithMessage:[NSString stringWithFormat:@"Capture session preset not supported by video device: %@", preset]];
			return;
		}
		
		// create the capture session
		_captureSession = [[AVCaptureSession alloc] init];
		_captureSession.sessionPreset = preset;
		
		// create and configure video data output
		
		AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
		videoDataOutput.videoSettings = self.videoSettings;
		[videoDataOutput setSampleBufferDelegate:self queue:self.sessionQueue];
		
		// begin configure capture session
		[_captureSession beginConfiguration];
		
		if (![_captureSession canAddOutput:videoDataOutput])
		{
			[self _showAlertViewWithMessage:@"Cannot add video data output"];
			_captureSession = nil;
			return;
		}
		
		// connect the video device input and video data and still image outputs
		[_captureSession addInput:videoDeviceInput];
		[_captureSession addOutput:videoDataOutput];
		
		//[self addPreviewLayer];
		
		[_captureSession commitConfiguration];
		
		// then start everything
		[_captureSession startRunning];
	});
}

- (NSString *)videoPath {
	if (!_videoPath) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *outpathURL = paths[0];
		NSFileManager *mgr = [NSFileManager defaultManager];
		[mgr createDirectoryAtPath:outpathURL withIntermediateDirectories:YES attributes:nil error:nil];
		outpathURL = [outpathURL stringByAppendingPathComponent:@"output.mp4"];
		[mgr removeItemAtPath:outpathURL error:nil];
		
		_videoPath = outpathURL;
	}
	
	return _videoPath;
}

- (NSString *)outputVideoPath {
	if (!_outputVideoPath) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *outpathURL = paths[0];
		NSFileManager *mgr = [NSFileManager defaultManager];
		[mgr createDirectoryAtPath:outpathURL withIntermediateDirectories:YES attributes:nil error:nil];
		outpathURL = [outpathURL stringByAppendingPathComponent:@"output1.mp4"];
		[mgr removeItemAtPath:outpathURL error:nil];
		
		_outputVideoPath = outpathURL;
	}
	
	return _outputVideoPath;
}



- (CGSize)recordResolution {
	int width = CGRectGetWidth(self.feedView.frame);
	int height = CGRectGetHeight(self.feedView.frame);
	return CGSizeMake(width, height);
}

- (NSDictionary*) videoSettings {
	// CoreImage wants BGRA pixel format
	if (!_videoSettings) {
		_videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInteger:kCVPixelFormatType_32BGRA]};
	}
	
	return _videoSettings;
}

- (NSDictionary*) adaptorSettings {
	if (!_adaptorSettings) {
		CGSize resolution = [self recordResolution];
		
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
		_videoTrackOutputSetting = @{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA),
									   (id)kCVPixelBufferWidthKey : @(480),
									   (id)kCVPixelBufferHeightKey : @(320) };
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

/**
 *  设置预览层
 */
-(void)addPreviewLayer{
//	_captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
//	_captureVideoPreviewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.previewView.frame) / 2, CGRectGetHeight(self.previewView.frame));
//
//	//如果预览图层和视频方向不一致，可以修改这个
//	//_captureVideoPreviewLayer.connection.videoOrientation = [_movieOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
//	
//	_captureVideoPreviewLayer.position = CGPointMake(CGRectGetWidth(self.previewView.frame) / 4, CGRectGetHeight(self.previewView.frame) / 2);
//	
//	_captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//	
//	CALayer *layer = self.previewView.layer;
//	layer.masksToBounds = YES;
//	[self.view layoutIfNeeded];
//	[layer addSublayer:_captureVideoPreviewLayer];
	
	_previewLayer = [CALayer layer];
	_previewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.previewView.frame) / 2, CGRectGetHeight(self.previewView.frame));
	_previewLayer.position = CGPointMake(CGRectGetWidth(self.previewView.frame) / 4, CGRectGetHeight(self.previewView.frame) / 2);
	_previewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI/2);
	[self.previewView.layer addSublayer:_previewLayer];
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

#pragma mark - Misc

- (void)_showAlertViewWithMessage:(NSString *)message {
	[self _showAlertViewWithMessage:message title:@"Error"];
}


- (void)_showAlertViewWithMessage:(NSString *)message title:(NSString *)title {
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
														message:message
													   delegate:nil
											  cancelButtonTitle:@"Dismiss"
											  otherButtonTitles:nil];
		[alert show];
	});
}

#pragma mark UIImagePickerControllerDelegate, UINavigationControllerDelegate

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
		self.sourceVideoPath = url;
		
		//[self startReading:url];
		
		NSLog(@"picker video path %@", url.absoluteString);
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if (self.currentVideoBuffer) {
		[self renderByGL1:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
		return;
	}
	
	[self renderByGL:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
	//[self render:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	
}

- (void)renderByGL1:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	
	// update the video dimensions information
	_currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
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
	if (self.writeState == FMRecordStateRecording) {
		CVPixelBufferRef renderBuffer = NULL;
		CVPixelBufferPoolCreatePixelBuffer(NULL, _writerInputPixelBufferAdaptor.pixelBufferPool, &renderBuffer);
		CVPixelBufferLockBaseAddress(renderBuffer, 0);
		[_ciContext render:destImage toCVPixelBuffer:renderBuffer bounds:_feedView.viewBounds colorSpace:NULL];
		CVPixelBufferUnlockBaseAddress(renderBuffer, 0);
		[self appendSampleBuffer:AVMediaTypeVideo CVPixelBufferRef:renderBuffer withPresentationTime:presentationTime];
	}
}

- (void)renderByGL:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CMFormatDescriptionRef formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	
	// update the video dimensions information
	_currentVideoDimensions = CMVideoFormatDescriptionGetDimensions(formatDesc);
	
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
	CVImageBufferRef videoBuffer = self.currentVideoBuffer;
	if (videoBuffer)
	{
		// 视频帧尺寸
		CIImage *sourceVideo = [CIImage imageWithCVPixelBuffer:(CVPixelBufferRef)videoBuffer options:nil];
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

- (void)maxFromImage:(const vImage_Buffer)src toImage:(const vImage_Buffer)dst
{
	int kernelSize = 7;
	vImageMin_Planar8(&src, &dst, NULL, 0, 0, kernelSize, kernelSize, kvImageDoNotTile);
}

- (void)render:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	
	// For the iOS the luma is contained in full plane (8-bit)
	size_t width = CVPixelBufferGetWidthOfPlane(imageBuffer, 0);
	size_t height = CVPixelBufferGetHeightOfPlane(imageBuffer, 0);
	size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
	
	Pixel_8 *lumaBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
	
	const vImage_Buffer inImage = { lumaBuffer, height, width, bytesPerRow };
	
	Pixel_8 *outBuffer = (Pixel_8 *)calloc(width*height, sizeof(Pixel_8));
	const vImage_Buffer outImage = { outBuffer, height, width, bytesPerRow };
	[self maxFromImage:inImage toImage:outImage];
	
	CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
	CGContextRef context = CGBitmapContextCreate(outImage.data, width, height, 8, bytesPerRow, grayColorSpace, kCGBitmapByteOrderDefault);
	CGImageRef dstImageFilter = CGBitmapContextCreateImage(context);
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		_previewLayer.contents = (__bridge id)dstImageFilter;
	});
	
	free(outBuffer);
	CGImageRelease(dstImageFilter);
	CGContextRelease(context);
	CGColorSpaceRelease(grayColorSpace);
}

#pragma mark video link
- (void)displayLinkCallback:(id)sender {
	
}

#pragma mark video

- (void)startRecord {
	[self startReading:self.sourceVideoPath];
	
	_timer = [NSTimer scheduledTimerWithTimeInterval:_frameTime target:self selector:@selector(onTimer) userInfo:nil repeats:YES];
	[_timer fire];
	
	[self startWrite];
}

- (void)stopRecord {
	[_timer invalidate];
	_timer = nil;
	
	[self stopWrite];
}

- (void)startReading:(NSURL *)videoFile {
	if (!_reader) {
		AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoFile options:nil];
		_videoAsset = asset;
		NSError *error = nil;
		
		_reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
		
		NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
		if (videoTracks.count == 0) {
			NSLog(@"NO video track...");
			return;
		}
		AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
		
		CMTime duration = [asset duration];
		CGFloat sumTime = duration.value / duration.timescale;
		CGFloat sumFrame = sumTime * videoTrack.nominalFrameRate;
		CGFloat totalTime = CMTimeGetSeconds(duration);
		CGFloat frameTime = totalTime / sumFrame;
		_frameTime = frameTime;
		_sumTime = sumTime;
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
		}
	}
}

-(void)onTimer {
	dispatch_async(_writerQueue, ^(void){
		if ([_reader status] == AVAssetReaderStatusReading) {
			CMSampleBufferRef videoBuffer = [_assetVideoReaderOutput copyNextSampleBuffer];
			if (videoBuffer) {
				[self.lock lock];
				
				// 有可能录制帧率没有视频帧率高，会丢视频帧，这里要把录制没有处理的视频帧释放掉
				if (self.currentVideoBuffer) {
					CFRelease(self.currentVideoBuffer);
					self.currentVideoBuffer = nil;
				}
				
				self.currentVideoBuffer = videoBuffer;
				
				CMTime durationTime = [_videoAsset duration];
				CMTime presentTime = CMSampleBufferGetPresentationTimeStamp(videoBuffer);
				CGFloat leftSeconds = CMTimeGetSeconds(CMTimeSubtract(durationTime, presentTime));
				self.sumTime = leftSeconds;
				self.needRefresh = YES;
				
				[self.lock unlock];
			}
			
			return;
		}
		
		// 读完视频文件，销毁资源
		[_timer invalidate];
		_timer = nil;
		
		[_reader cancelReading];
		_reader = nil;
		
		_videoAsset = nil;
		
		[self stopRecord];
		
		dispatch_async(dispatch_get_main_queue(), ^(void){
			[self _showAlertViewWithMessage:@"录制完成"];
		});
	});
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self.durationView setText:[NSString stringWithFormat:@"%f", self.sumTime]];
		self.needRefresh = NO;
	});
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
		if (self.writeState < FMRecordStateRecording){
			NSLog(@"not ready yet");
			return;
		}
	}
	
	CFRetain(pixelBuffer);
	dispatch_async(_writerQueue, ^{
		@autoreleasepool {
			@synchronized(self) {
				if (self.writeState > FMRecordStateRecording){
					CFRelease(pixelBuffer);
					return;
				}
			}
			
			if (!self.canWrite && mediaType == AVMediaTypeVideo) {
				[_writer startSessionAtSourceTime:presentationTime];
				self.canWrite = YES;
			}
			
			//写入视频数据
			if (mediaType == AVMediaTypeVideo) {
				if (_writerInput.isReadyForMoreMediaData) {
					if (_writerInputPixelBufferAdaptor) {
						BOOL ret =  [_writerInputPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTime];
						if (!ret) {
							@synchronized (self) {
								[self stopWrite];
								[self destroyWrite];
							}
						}
					} else {
//						BOOL success = [_writerInput appendSampleBuffer:pixelBuffer];
//						if (!success) {
//							@synchronized (self) {
//								[self stopWrite];
//								[self destroyWrite];
//							}
//						}
					}
				}
			}
			
			//写入音频数据
//			if (mediaType == AVMediaTypeAudio) {
//				if (self.assetWriterAudioInput.readyForMoreMediaData) {
//					BOOL success = [self.assetWriterAudioInput appendSampleBuffer:sampleBuffer];
//					if (!success) {
//						@synchronized (self) {
//							[self stopWrite];
//							[self destroyWrite];
//						}
//					}
//				}
//			}
			
			CFRelease(pixelBuffer);
		}
	} );
}

- (void)startWrite
{
	self.writeState = FMRecordStatePrepareRecording;
	[self setupWriter];
}

- (void)setupWriter {
	if (!_writer) {
		NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:self.videoPath];
		self.writer = [AVAssetWriter assetWriterWithURL:outputURL fileType:AVFileTypeMPEG4 error:nil];
		
		_writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:self.videoCompressionSettings];
		//expectsMediaDataInRealTime 必须设为yes，需要从capture session 实时获取数据
		_writerInput.expectsMediaDataInRealTime = YES;
		_writerInput.transform = CGAffineTransformMakeRotation(M_PI / 2.0);
		
		//	_assetWriterAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:self.audioCompressionSettings];
		//	_assetWriterAudioInput.expectsMediaDataInRealTime = YES;
		
		if ([_writer canAddInput:_writerInput]) {
			[_writer addInput:_writerInput];
		}else {
			NSLog(@"AssetWriter videoInput append Failed");
		}
		
		//	if ([_assetWriter canAddInput:_assetWriterAudioInput]) {
		//		[_assetWriter addInput:_assetWriterAudioInput];
		//	}else {
		//		NSLog(@"AssetWriter audioInput Append Failed");
		//	}
		
		_writerInputPixelBufferAdaptor = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:_writerInput sourcePixelBufferAttributes:self.adaptorSettings];
		
		[_writer startWriting];
		
		self.writeState = FMRecordStateRecording;
	}
}

- (void)stopWrite
{
	if (!_writerInputPixelBufferAdaptor)
	{
		self.writeState = FMRecordStateFinish;
		__weak __typeof(self)weakSelf = self;
		if(_writer && _writer.status == AVAssetWriterStatusWriting){
			dispatch_async(_writerQueue, ^{
				[_writer finishWritingWithCompletionHandler:^{
					//[CaptureToolKit writeVideoToPhotoLibrary:[NSURL URLWithString:weakSelf.videoPath]];
					
					if (![weakSelf mergeAudioAndVideo:[NSURL fileURLWithPath:self.videoPath] audio:self.sourceVideoPath]) {
						[CaptureToolKit writeVideoToPhotoLibrary:[NSURL fileURLWithPath:weakSelf.videoPath]];
					}
					
					_writer = nil;
				}];
			});
		}
		
		return;
	}
	
	self.writeState = FMRecordStateFinish;
	__weak __typeof(self)weakSelf = self;
	if(_writer && _writer.status == AVAssetWriterStatusWriting) {
		dispatch_async(_writerQueue, ^{
			[_writer finishWritingWithCompletionHandler:^{
				CVPixelBufferPoolRelease(_writerInputPixelBufferAdaptor.pixelBufferPool);
				//[CaptureToolKit writeVideoToPhotoLibrary:[NSURL URLWithString:weakSelf.videoPath]];
				
				if (![weakSelf mergeAudioAndVideo:[NSURL fileURLWithPath:self.videoPath] audio:self.sourceVideoPath]) {
					[CaptureToolKit writeVideoToPhotoLibrary:[NSURL URLWithString:weakSelf.videoPath]];
				}
				
				_writer = nil;
			}];
		});
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
	exportSession.outputURL = [NSURL fileURLWithPath:self.outputVideoPath];
	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	[exportSession exportAsynchronouslyWithCompletionHandler:^(void){
		switch(exportSession.status)
		{
			case AVAssetExportSessionStatusCompleted:
			{
				[CaptureToolKit writeVideoToPhotoLibrary:[NSURL fileURLWithPath:self.outputVideoPath]];
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

#pragma mark AVPlayerItemOutputPullDelegate

- (void)outputMediaDataWillChange:(AVPlayerItemOutput *)sender {
	
}

- (void)outputSequenceWasFlushed:(AVPlayerItemOutput *)output {
	
}

@end

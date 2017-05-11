//
//  SplitRecordViewController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/2.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "SplitRecordViewController.h"
#import "CaptureToolKit.h"
#import "MultipleVideoRecorderController.h"

#pragma mark - View Controller

@interface SplitRecordViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, MultipleVideoRecorderControllerDelegate>

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

@property (nonatomic, retain) GLKViewWithBounds *feedView;

@property AVPlayerItemVideoOutput *videoOutput;
@property CADisplayLink *displayLink;

@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (nonatomic, assign) CMSampleBufferRef currentVideoBuffer;
@property (nonatomic, assign) CVImageBufferRef currentAudioBuffer;
@property (nonatomic, strong) CIImage *currentVideoImage;

@property (nonatomic) BOOL isRecording;

@property (nonatomic, retain) MultipleVideoRecorderController *recorderController;

@end

@implementation SplitRecordViewController

- (instancetype)init {
	if (self = [super init]) {
		
	}
	
	return self;
}

#pragma mark init view

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
		[_recorderController toggleRecord];
	} else if (sender == self.deleteBtn) {
		[_recorderController deleteLastSplit];
	}
}

#pragma mark vc lifecycle

- (void)initData {
	self.sw = [[UIScreen mainScreen] bounds].size.width;
	self.sh = [[UIScreen mainScreen] bounds].size.height;
	
	_recorderController = [[MultipleVideoRecorderController alloc] init];
	_recorderController.delegate = self;
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
	
	_feedView = [_recorderController setupRenderWidth:CGRectMake(0, 100, self.sw, self.sw * 1.25)];
	[self.view addSubview:self.feedView];
	
	[self.view addSubview:self.lineView];
}

- (void)dealloc {

}

- (void)loadView {
	[super loadView];
	
	[self initData];
	
	[self setupControlPanel];
}


- (void)viewDidLoad {
    [super viewDidLoad];
	
	if ([[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count] > 0) {
		[_recorderController setupCapture];
		
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

//- (void)setupLink {
//	// Setup CADisplayLink which will callback displayPixelBuffer: at every vsync.
//	self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
//	[[self displayLink] addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//	[[self displayLink] setPaused:YES];
//	
//	// Setup AVPlayerItemVideoOutput with the required pixelbuffer attributes.
//	NSDictionary *pixBuffAttributes = @{(id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
//	self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:pixBuffAttributes];
//	[[self videoOutput] setDelegate:self queue:_writerQueue];
//}


- (CGSize)recordResolution {
	int width = CGRectGetWidth(self.feedView.frame);
	int height = CGRectGetHeight(self.feedView.frame);
	return CGSizeMake(width, height);
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
	_previewLayer.affineTransform = CGAffineTransformMakeRotation(M_PI_2);
	[self.previewView.layer addSublayer:_previewLayer];
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
		
		[_recorderController setupSourceVideo:[url path]];
		
		//[self startReading:url];
		
		NSLog(@"picker video path %@", url.absoluteString);
	}
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark MultipleVideoRecorderControllerDelegate

- (void)recordStateChanged:(MultiRecordState)state lastState:(MultiRecordState)lastState {
	NSLog(@"current record state is %ld, last is %ld", state, lastState);
}


@end

//
//  RecordController.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/4/30.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "RecordController.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "UserDefine.h"

typedef NS_ENUM(NSInteger,VideoStatus){
	VideoStatusEnded = 0,
	VideoStatusStarted
};

@interface RecordController ()
{   //拍摄视频相关
	AVCaptureSession * _captureSession;/**< 是一个会话对象,是设备音频/视频整个录制期间的管理者. */
	AVCaptureDevice *_videoDevice;/**< 视频设备 */
	AVCaptureDevice *_audioDevice;/**< 音频设备 */
	AVCaptureDeviceInput *_videoInput;/**< 视频输入 */
	AVCaptureDeviceInput *_audioInput;/**< 音频输入 */
	AVCaptureMovieFileOutput *_movieOutput;/**< 视频输出 */
	AVCaptureVideoPreviewLayer *_captureVideoPreviewLayer;/**< 预览拍摄过程中的图像 */
	
	//播放相关
	AVPlayer *_player;/**< 播放器对象 */
	AVPlayerItem *_playItem;/**< 一个媒体资源管理对象，管理者视频的一些基本信息和状态，一个AVPlayerItem对应着一个视频资源 */
	AVPlayerLayer *_playerLayer;
	BOOL _isPlaying;
	
}

@property (strong, nonatomic) UIView *recordingView;/**<  */

@property (strong, nonatomic) UIButton *recordingButton;/**< 录制按钮 */

@property (strong, nonatomic) UILabel *timeLabel;/**< 倒计时时间 */

@property (strong, nonatomic) UIButton *playButton;/**< 播放按钮 */

@property (nonatomic,assign) VideoStatus status;

@property (nonatomic,assign) BOOL canSave;

@property (nonatomic,strong) CADisplayLink *link;

@property (strong, nonatomic) NSURL *videoUrl;/**< 视频URL */
@end

@implementation RecordController

static float CountdownTime = 15 * 60;//倒计时时间，时间为15s，* 60 因为CADisplayLink 1/60秒刷新一次

- (void)viewDidLoad {
	[super viewDidLoad];
	[self setUILayout];
	[self getAuthorization];
	//对视频播放完进行监听
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackFinished:)name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}
-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
}
-(void)viewDidDisappear:(BOOL)animated{
	[super viewDidDisappear:animated];
	//移除通知
	[[NSNotificationCenter defaultCenter]removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}
#pragma mark - ****************  界面布局
-(void)setUILayout{
	self.view.backgroundColor = RGBColor(245, 245, 245);
	CGFloat jianGe = 20;
	CGFloat btnH = 30;
	CGFloat btnW = 120;
	CGFloat lblH = 40;
	CGFloat lblW = 120;
	CGFloat boFangH = 160;
	_recordingView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_W, SCREEN_H/2)];
	_recordingView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:_recordingView];
	
	_timeLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.view.center.x - lblW/2, _recordingView.frame.size.height + _recordingView.frame.origin.y + lblH, lblW, lblH)];
	_timeLabel.hidden = NO;
	_timeLabel.text = [NSString stringWithFormat:@"倒计时：%d秒",(int)(CountdownTime/60)];
	_timeLabel.textAlignment = NSTextAlignmentCenter;
	_timeLabel.font = [UIFont systemFontOfSize:18.0];
	_timeLabel.textColor = RGBColor(217, 28, 26);
	[self.view addSubview:_timeLabel];
	
	_recordingButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_recordingButton.frame = CGRectMake(self.view.center.x - btnW/2, _timeLabel.frame.size.height + _timeLabel.frame.origin.y + jianGe, btnW, btnH);
	[_recordingButton setTitle:@"开始录制" forState:UIControlStateNormal];
	[_recordingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	_recordingButton.backgroundColor = RGBColor(217, 28, 26);
	_recordingButton.titleLabel.font = [UIFont fontWithName:@"STHeitiSC-Light" size:14.0];
	_recordingButton.layer.cornerRadius = 3;
	[_recordingButton addTarget:self action:@selector(recordButton:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_recordingButton];
	
	_playButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_playButton.frame = CGRectMake(0, 0, boFangH, boFangH);
	_playButton.center = _recordingView.center;
	[_playButton setImage:[UIImage imageNamed:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
	_playButton.hidden = YES;
	[_playButton addTarget:self action:@selector(playButton:) forControlEvents:UIControlEventTouchUpInside];
	[_recordingView addSubview:_playButton];
	
}
#pragma mark - **************** Button 方法
/**
 *  点击录制
 *
 *  @param sender
 */
-(void)recordButton:(UIButton *)sender{
	if ([sender.titleLabel.text isEqualToString:@"开始录制"]) {
		[self startAnimation];
	}else{
		[self saveVideo:_videoUrl];
	}
	
}
/**
 *  点击播放
 *
 *  @param sender
 */
-(void)playButton:(UIButton *)sender{
	[_player play];
	_playButton.hidden = YES;
}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}
#pragma mark - **************** 视频录制相关
#pragma mark -- 获取授权
-(void)getAuthorization{
	//此处获取摄像头授权
	switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
		case AVAuthorizationStatusAuthorized://已授权可以使用
		{
			NSLog(@"授权成功！");
			[self setupAVCaptureInfo];
			return;
		}
		case AVAuthorizationStatusNotDetermined://未授权
		{
			//则再次请求授权
			[AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
				if (granted) {//授权成功
					[self setupAVCaptureInfo];
					return;
				}else{
					//授权失败
					return;
				}
				
			}];
		}
			break;
		default:    //用户拒绝授权/未授权
			break;
	}
}
#pragma mark - 设置相关信息
-(void)setupAVCaptureInfo{
	[self addSession];
	//开始配置视频的会话对象
	[_captureSession beginConfiguration];
	[self addVideo];
	[self addAudio];
	[self addPreviewLayer];
	//提交配置
	[_captureSession commitConfiguration];
	//开启会话----> 不等于开始录制
	[_captureSession startRunning];
}
/**
 *  设置视频的会话对象
 */
-(void)addSession{
	_captureSession = [[AVCaptureSession alloc]init];
	//设置视频分辨率
	//注意，这个地方设置的模式/分辨率大小将影响后面的拍摄质量
	if ([_captureSession canSetSessionPreset:AVAssetExportPreset640x480]) {
		[_captureSession setSessionPreset:AVAssetExportPreset640x480];
	}
}
/**
 *  设置视频设备
 */
-(void)addVideo{
	_videoDevice = [self deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];//AVCaptureDevicePositionBack -- 后摄像头
	[self addVideoInput];
	[self addMovieOutput];
}
/**
 *  设置视频输入对象
 */
-(void)addVideoInput{
	NSError *videoError;
	//视频输入对象
	//根据输入设备初始化输入对象，用户获取输入数据
	_videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:_videoDevice error:&videoError];
	if (videoError) {
		NSLog(@"-------取得摄像头设备时出错---%@",[videoError localizedDescription]);
		return;
	}
	//将视频输入对象添加到会话（AVCaptureSession）中
	if ([_captureSession canAddInput:_videoInput]) {
		[_captureSession addInput:_videoInput];
	}
}
/**
 *  设置视频输出对象
 */
-(void)addMovieOutput{
	//拍摄视频输出对象
	//初始化输出设备对象，用户获取输出数据
	_movieOutput = [[AVCaptureMovieFileOutput alloc] init];
	
	if ([_captureSession canAddOutput:_movieOutput]) {
		[_captureSession addOutput:_movieOutput];
		//设置连接管理对象
		AVCaptureConnection *captureConnection = [_movieOutput connectionWithMediaType:AVMediaTypeVideo];
		//视频稳定设置
		if ([captureConnection isVideoStabilizationSupported]) {
			captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
		}
		//视频旋转方向的设置
		captureConnection.videoScaleAndCropFactor = captureConnection.videoMaxScaleAndCropFactor;
	}
}
/**
 *  设置音频设备
 */
-(void)addAudio{
	NSError *audioError;
	//添加一个音频设备
	_audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
	// 音频输入对象
	_audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:_audioDevice error:&audioError];
	if (audioError) {
		NSLog(@"取得录音设备时出错 ------ %@",audioError);
		return;
	}
	//将音频输入对象添加到会话 (AVCaptureSession) 中
	if ([_captureSession canAddInput:_audioInput]) {
		[_captureSession addInput:_audioInput];
	}
}
/**
 *  设置预览层
 */
-(void)addPreviewLayer{
	[self.view layoutIfNeeded];
	
	//通过会话（AVCaptureSession）创建预览图层
	_captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
	_captureVideoPreviewLayer.frame = self.view.layer.bounds;
	//如果预览图层和视频方向不一致，可以修改这个
	_captureVideoPreviewLayer.connection.videoOrientation = [_movieOutput connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
	//设置captureVideoPreviewLayer在父视图中的位置
	_captureVideoPreviewLayer.position = CGPointMake(self.view.frame.size.width*0.5,self.recordingView.frame.size.height*0.5);
	
	//显示在视图表面的图层
	CALayer *layer = self.recordingView.layer;
	layer.masksToBounds = YES;
	[self.view layoutIfNeeded];
	[layer addSublayer:_captureVideoPreviewLayer];
}
-(void)startAnimation{
	if (self.status == VideoStatusEnded) {
		self.status = VideoStatusStarted;
		[UIView animateWithDuration:0.5 animations:^{
			
		} completion:^(BOOL finished) {
			[self stopLink];
			[self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
		}];
	}
}
-(void)stopAnimation{
	if (self.status == VideoStatusStarted) {
		self.status = VideoStatusEnded;
		[self stopLink];
		[self stopRecord];
		_playButton.hidden = NO;
		
		[UIView animateWithDuration:0.5 animations:^{
			[_recordingButton setTitle:@"保存到相册" forState:UIControlStateNormal];
			
		} completion:^(BOOL finished) {
			
		}];
	}
}

-(CADisplayLink *)link{
	if (!_link) {
		_link = [CADisplayLink displayLinkWithTarget:self selector:@selector(refresh:)];
		[self startRecord];
	}
	return _link;
}
-(void)stopLink{
	_link.paused = YES;
	[_link invalidate];
	_link = nil;
}
-(void)refresh:(CADisplayLink *)link{
	if (CountdownTime <= 0) {
		CountdownTime = 15 * 60;
		[self recordComplete];
		[self stopAnimation];
		_timeLabel.hidden = YES;
		return;
	}
	CountdownTime -= 1;
	NSLog(@"%f",CountdownTime);
	_timeLabel.text = [NSString stringWithFormat:@"倒计时：%d秒",(int)(CountdownTime/60)];
}
/**
 *  获取录制视频的地址
 *
 *  @return outPutFileURL
 */
- (NSURL *)outPutFileURL
{
	return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), @"outPut.mov"]];
}

- (void)startRecord
{
	[_movieOutput startRecordingToOutputFileURL:[self outPutFileURL] recordingDelegate:self];
}
- (void)stopRecord
{
	// 取消视频拍摄
	[_movieOutput stopRecording];
}

- (void)recordComplete
{
	self.canSave = YES;
}
//这个在完全退出小视频时调用
- (void)quit
{
	[_captureSession stopRunning];
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
	NSLog(@"---- 开始录制 ----");
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
	NSLog(@"---- 录制结束 ---%@-%@ ",outputFileURL,captureOutput.outputFileURL);
	if (outputFileURL.absoluteString.length == 0 && captureOutput.outputFileURL.absoluteString.length == 0 ) {
		return;
	}
	if (self.canSave) {
		_videoUrl = outputFileURL;
		self.canSave = NO;
		[self creatPlayView];
	}
}

#pragma mark - 获取摄像头-->前/后
-(AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position{
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
#pragma mark - **************** 播放相关
-(void)creatPlayView{
	NSLog(@"%@",_videoUrl);
	[_captureVideoPreviewLayer removeFromSuperlayer];
	[self.view layoutIfNeeded];
	_playItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
	_player = [AVPlayer playerWithPlayerItem:_playItem];
	_playerLayer =[AVPlayerLayer playerLayerWithPlayer:_player];
	_playerLayer.frame = _recordingView.frame;
	_playerLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;//视频填充模式
	_playerLayer.position = CGPointMake(self.view.frame.size.width*0.5,self.recordingView.frame.size.height*0.5);
	CALayer *layer = self.recordingView.layer;
	layer.masksToBounds = true;
	[self.view layoutIfNeeded];
	
	[layer addSublayer:_playerLayer];
	[self.recordingView bringSubviewToFront:_playButton];
}
#pragma mark - 视频播放通知回调
-(void)playbackFinished:(NSNotification *)notification
{
	[_player seekToTime:CMTimeMake(0, 1)];
	_playButton.hidden = NO;
}
#pragma mark - **************** 压缩保存
- (NSURL *)compressedURL
{
	return [NSURL fileURLWithPath:[[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"compressed.mp4"]]];
}

- (CGFloat)fileSize:(NSURL *)path
{
	return [[NSData dataWithContentsOfURL:path] length]/1024.00 /1024.00;
}

// 压缩视频
-(void)saveVideoWithUrl:(NSURL *)url
{
	NSLog(@"开始压缩,压缩前大小 %f MB",[self fileSize:url]);
	
	AVURLAsset *avAsset = [[AVURLAsset alloc] initWithURL:url options:nil];
	NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
	if ([compatiblePresets containsObject:AVAssetExportPresetLowQuality]) {
		
		AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
		exportSession.outputURL = [self compressedURL];
		//优化网络
		exportSession.shouldOptimizeForNetworkUse = true;
		//转换后的格式
		exportSession.outputFileType = AVFileTypeMPEG4;
		//异步导出
		[exportSession exportAsynchronouslyWithCompletionHandler:^{
			// 如果导出的状态为完成
			if ([exportSession status] == AVAssetExportSessionStatusCompleted) {
				NSLog(@"压缩完毕,压缩后大小 %f MB",[self fileSize:[self compressedURL]]);
				[self saveVideo:[self compressedURL]];
			}else{
				NSLog(@"当前压缩进度:%f",exportSession.progress);
			}
			
		}];
	}
}


- (void)saveVideo:(NSURL *)outputFileURL
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	[library writeVideoAtPathToSavedPhotosAlbum:outputFileURL
								completionBlock:^(NSURL *assetURL, NSError *error) {
									if (error) {
										NSLog(@"保存视频失败:%@",error);
									} else {
										NSLog(@"保存视频到相册成功");
									}
								}];
}

@end

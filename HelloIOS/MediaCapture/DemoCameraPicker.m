//
//  DemoCameraPicker.m
//  HelloIOS
//
//  Created by 毛星辉 on 2017/5/30.
//  Copyright © 2017年 younger. All rights reserved.
//

#import "DemoCameraPicker.h"
#import "VideoRecordSettings.h"

@interface DemoCameraPicker () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic, strong) dispatch_queue_t captureSessionQueue;

// 摄像头
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@end

@implementation DemoCameraPicker

- (instancetype)init {
	if (self = [super init]) {
		self.needAudio = YES;
		self.captureSessionPreset = AVCaptureSessionPreset640x480;
	}
	
	return self;
}

- (void)setupCapture {
	if (_captureSession) {
		return;
	}
	
	_captureSessionQueue = dispatch_queue_create("capture_session_queue", DISPATCH_QUEUE_SERIAL);
	
	dispatch_async(_captureSessionQueue, ^(void) {
		// 初始化摄像头会话
		_captureSession = [[AVCaptureSession alloc] init];
		
		// 获取输出规格
		NSString *preset = self.captureSessionPreset;
		if ([_captureSession canSetSessionPreset:preset]) {
			_captureSession.sessionPreset = preset;
		}
		
		[_captureSession beginConfiguration];
		
		[self addVideoDevice];
		
		[self addAudioDevice];
		
		//[self addPreviewLayer];
		
		[_captureSession commitConfiguration];
		
		[_captureSession startRunning];
	});
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

- (void)addVideoDevice {
	// 获取视频设备
	AVCaptureDevice *videoDevice = [self cameraWithPosition:self.cameraPosition];
	
	// 获取设备输入组件
	NSError *error = nil;
	AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
	if (!videoDeviceInput || error)
	{
		return;
	}
	_videoDeviceInput = videoDeviceInput;
	
	// 创建并配置视频输出组件
	AVCaptureVideoDataOutput *videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
	videoDataOutput.videoSettings = [VideoRecordSettings shareInstance].videoSettings;
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
	if (!self.needAudio) {
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

- (void)uninstallCapture {
	if (self.captureSession) {
		[self.captureSession stopRunning];
	}
}

- (void)switchCamera {
	NSUInteger cameraCount = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
	if (cameraCount <= 1) {
		return;
	}
	
	if(_captureSession) {
		[_captureSession beginConfiguration];
		
		AVCaptureDeviceInput *currentCameraInput = _videoDeviceInput;
		for (AVCaptureDeviceInput *input in _captureSession.inputs) {
			if (input == _videoDeviceInput) {
				[_captureSession removeInput:input];
				break;
			}
		}
		
		AVCaptureDevice *newCamera = nil;
		if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack) {
			newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
			self.cameraPosition = AVCaptureDevicePositionFront;
		}
		else {
			newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
			self.cameraPosition = AVCaptureDevicePositionBack;
		}
		
		NSError *err = nil;
		AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&err];
		if(!newVideoInput || err) {
			NSLog(@"Error creating capture device input: %@", err.localizedDescription);
		}
		else {
			[_captureSession addInput:newVideoInput];
			_videoDeviceInput = newVideoInput;
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

#pragma mark AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
	if (captureOutput == _videoOutput) {
		[self.delegate onCaptureVideoSampleBuffer:sampleBuffer];
	} else if (captureOutput == _audioOutput) {
		[self.delegate onCatureAudioSampleBuffer:sampleBuffer];
	} else {
		
	}
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
//	if (captureOutput == _videoOutput) {
//		[self.delegate onCaptureVideoSampleBuffer:sampleBuffer];
//	} else if (captureOutput == _audioOutput) {
//		[self.delegate onCatureAudioSampleBuffer:sampleBuffer];
//	} else {
//		
//	}
}

@end

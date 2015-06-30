//
//  SFCameraModel.m
//  CVTest
//
//  Created by Michael Ilich on 2013-02-01.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

#import "SFCameraModel.h"

#define CAMERA_PREVIEW_SCALE 3
#define DEGTORAD(x) x*M_PI / 180

@interface SFCameraModel () {
}

// AVFoundation functions
- (BOOL)createCaptureSession;
- (void)destroyCaptureSession;

@end

@implementation SFCameraModel

@synthesize camDelegate = _camDelegate;

// AVCapture properties
@synthesize captureSession = _captureSession;
@synthesize captureDevice = _captureDevice;
@synthesize videoOutput = _videoOutput;
@synthesize videoPreviewLayer = _videoPreviewLayer;
@synthesize contrastPreviewView = _contrastPreviewView;
@synthesize previewController = _previewController;

- (id) initWithViewController:(UIViewController *)initViewController
{
    self = [super init];
    
    if (self) {
        
        self.previewController = [initViewController retain];
        
        // AVCapture Setup
        [self createCaptureSession];
        [_captureSession startRunning];
    }
    
    return self;
}

- (void) dealloc
{

    // AVCapture Stop Recording Outside App/View
    [self destroyCaptureSession];

    [_captureSession release];
    [_captureDevice release];
    [_videoOutput release];
    [_videoPreviewLayer release];
    [_contrastPreviewView release];
    
    _captureSession = nil;
    _captureDevice = nil;
    _videoOutput = nil;
    _videoPreviewLayer = nil;
    _contrastPreviewView = nil;
    
    [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  VIDEO CAPTURE
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    NSAutoreleasePool* localpool = [[NSAutoreleasePool alloc] init];
    
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CGRect videoRect = CGRectMake(0.0f, 0.0f, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer));
    AVCaptureVideoOrientation videoOrientation = [[[_videoOutput connections] objectAtIndex:0] videoOrientation];
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseaddress = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    if ([self.camDelegate respondsToSelector:@selector(processFrame:forOrientation:atAddress:)]) {
        [self.camDelegate processFrame:videoRect forOrientation:videoOrientation atAddress:baseaddress];
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
    [localpool drain];
}

- (BOOL)createCaptureSession
{
    // Set up AV capture
    NSArray* devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    if ([devices count] == 0) {
        NSLog(@"No video capture devices found");
        return NO;
    }
    
    _captureDevice = [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo] retain];
    
    // Create the capture session
    _captureSession = [[AVCaptureSession alloc] init];
    _captureSession.sessionPreset =  AVCaptureSessionPresetLow;
    
    // Create device input
    NSError *error = nil;
    AVCaptureDeviceInput *input = [[AVCaptureDeviceInput alloc] initWithDevice:_captureDevice error:&error];
    
    // Create and configure device output
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL);
    [_videoOutput setSampleBufferDelegate:self queue:queue];
    dispatch_release(queue);
    
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    OSType format = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    
    _videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:format] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    
    // Connect up inputs and outputs
    if ([_captureSession canAddInput:input]) {
        [_captureSession addInput:input];
    }
    
    if ([_captureSession canAddOutput:_videoOutput]) {
        [_captureSession addOutput:_videoOutput];
    }
    
    [input release];
    
    // Create the preview layer
    _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_videoPreviewLayer setFrame:CGRectMake(0, 0, self.previewController.view.frame.size.width/CAMERA_PREVIEW_SCALE, self.previewController.view.frame.size.height/CAMERA_PREVIEW_SCALE)];
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewController.view.layer insertSublayer:_videoPreviewLayer atIndex:0];
    
    // Create the contrast preview layer
    _contrastPreviewView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bird1.jpg"]];
    [_contrastPreviewView setFrame:CGRectMake(0, self.previewController.view.frame.size.height -((self.previewController.view.frame.size.width/CAMERA_PREVIEW_SCALE)*0.5+self.previewController.view.frame.size.height/CAMERA_PREVIEW_SCALE), self.previewController.view.frame.size.height/CAMERA_PREVIEW_SCALE, self.previewController.view.frame.size.width/CAMERA_PREVIEW_SCALE)];
    _contrastPreviewView.layer.anchorPoint = CGPointMake(0, (self.previewController.view.frame.size.width/CAMERA_PREVIEW_SCALE)/self.previewController.view.frame.size.width);
    CGAffineTransform rotationTransform = CGAffineTransformIdentity;
    _contrastPreviewView.transform = CGAffineTransformRotate(rotationTransform, DEGTORAD(90));
    [self.previewController.view addSubview:_contrastPreviewView];
    
    return YES;
}

// Tear down the video capture session
- (void)destroyCaptureSession
{
    [_captureSession stopRunning];
    
    [_videoPreviewLayer removeFromSuperlayer];
    [_videoPreviewLayer release];
    [_videoOutput release];
    [_captureDevice release];
    [_captureSession release];
    
    _videoPreviewLayer = nil;
    _videoOutput = nil;
    _captureDevice = nil;
    _captureSession = nil;
}

- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation
{
    CGSize viewSize = self.previewController.view.bounds.size;
    NSString * const videoGravity = _videoPreviewLayer.videoGravity;
    CGFloat widthScale = 1.0f;
    CGFloat heightScale = 1.0f;
    
    // Move origin to center so rotation and scale are applied correctly
    CGAffineTransform t = CGAffineTransformMakeTranslation(-videoFrame.size.width / 2.0f, -videoFrame.size.height / 2.0f);
    
    switch (videoOrientation) {
        case AVCaptureVideoOrientationPortrait:
            widthScale = viewSize.width / videoFrame.size.width;
            heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationPortraitUpsideDown:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI));
            widthScale = viewSize.width / videoFrame.size.width;
            heightScale = viewSize.height / videoFrame.size.height;
            break;
            
        case AVCaptureVideoOrientationLandscapeRight:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(M_PI_2));
            widthScale = viewSize.width / videoFrame.size.height;
            heightScale = viewSize.height / videoFrame.size.width;
            break;
            
        case AVCaptureVideoOrientationLandscapeLeft:
            t = CGAffineTransformConcat(t, CGAffineTransformMakeRotation(-M_PI_2));
            widthScale = viewSize.width / videoFrame.size.height;
            heightScale = viewSize.height / videoFrame.size.width;
            break;
    }
    
    // Adjust scaling to match video gravity mode of video preview
    if (videoGravity == AVLayerVideoGravityResizeAspect) {
        heightScale = MIN(heightScale, widthScale);
        widthScale = heightScale;
    }
    else if (videoGravity == AVLayerVideoGravityResizeAspectFill) {
        heightScale = MAX(heightScale, widthScale);
        widthScale = heightScale;
    }
    
    // Apply the scaling
    t = CGAffineTransformConcat(t, CGAffineTransformMakeScale(widthScale, heightScale));
    
    // Move origin back from center
    t = CGAffineTransformConcat(t, CGAffineTransformMakeTranslation(viewSize.width / 2.0f, viewSize.height / 2.0f));
    
    return t;
}

- (void) updateContrastPreview:(UIImage *)img
{
    self.contrastPreviewView.image = img;
}

@end

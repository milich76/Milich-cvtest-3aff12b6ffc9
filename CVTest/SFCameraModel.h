//
//  SFCameraModel.h
//  CVTest
//
//  Created by Michael Ilich on 2013-02-01.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol SFCameraDelegate <NSObject>
- (void) processFrame:(CGRect)videoRect forOrientation:(AVCaptureVideoOrientation)orientation atAddress:(void *)baseaddress;
@end

@interface SFCameraModel : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    id<SFCameraDelegate> _camDelegate;

    AVCaptureSession *_captureSession;
    AVCaptureDevice *_captureDevice;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    
    UIImageView *_contrastPreviewView;
    
    UIViewController *_previewController;
}

@property(nonatomic, assign) id<SFCameraDelegate> camDelegate;

// AVFoundation components
@property (nonatomic, readonly) AVCaptureSession *captureSession;
@property (nonatomic, readonly) AVCaptureDevice *captureDevice;
@property (nonatomic, readonly) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic, readonly) UIImageView *contrastPreviewView;

@property (nonatomic, retain) UIViewController *previewController;

// AVFoundation callback functions
- (id) initWithViewController:(UIViewController *)initViewController;
- (CGAffineTransform)affineTransformForVideoFrame:(CGRect)videoFrame orientation:(AVCaptureVideoOrientation)videoOrientation;
- (void) updateContrastPreview:(UIImage *)img;

@end

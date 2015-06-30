//
//  SFMotionDetector.m
//  CVTest
//
//  Created by Michael Ilich on 2013-02-01.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

#import "SFMotionDetector.h"
#import "SFMotionConst.h"

// OpenCV Libraries
#import <opencv2/core/core.hpp>
#import <opencv2/imgproc/imgproc.hpp>
#import <opencv2/imgproc/imgproc_c.h>
#import <opencv2/video/video.hpp>
#import <opencv2/video/tracking.hpp>
#import <opencv2/highgui/highgui.hpp>
#import <opencv2/highgui/cap_ios.h>
#import <opencv2/videostab/frame_source.hpp>
#import <opencv2/videostab/optical_flow.hpp>
#include <iostream>
#include <vector>

@interface SFMotionDetector () {
    cv::Mat cam1;
    cv::Mat cam2;
    
    NSTimer *_motionTimer;
}

@property (nonatomic, retain) NSTimer *motionTimer;

@end

@implementation SFMotionDetector

@synthesize motionDelegate = _motionDelegate;
@synthesize motionTimer = _motionTimer;

- (id) init
{
    self = [super init];
    
    if (self) {
        // set up timer function
         self.motionTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFunctionForPhaseCorrelation) userInfo:nil repeats:YES];
    }
    
    return self;
}

- (void) dealloc
{
    [_motionTimer release];
    
    [super dealloc];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  OpenCV Phase Correlation
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (UIImage *)imageWithCVMat:(const cv::Mat&)cvMat
{
    
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                     // Width
                                        cvMat.rows,                                     // Height
                                        8,                                              // Bits per component
                                        8 * cvMat.elemSize(),                           // Bits per pixel
                                        cvMat.step[0],                                  // Bytes per row
                                        colorSpace,                                     // Colorspace
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,  // Bitmap info flags
                                        provider,                                       // CGDataProviderRef
                                        NULL,                                           // Decode
                                        false,                                          // Should interpolate
                                        kCGRenderingIntentDefault);                     // Intent
    
    UIImage *image = [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

- (void) processFrame:(CGRect)videoRect forOrientation:(AVCaptureVideoOrientation)orientation atAddress:(void *)baseaddress;
{
    cv::Mat mat(videoRect.size.height, videoRect.size.width, CV_8UC1, baseaddress, 0);
    cv::Mat contrastMat = cv::Mat::zeros(mat.size(), mat.type());
    cv::Mat edgesMat = cv::Mat::zeros(mat.size(), mat.type());

    @synchronized(self) {
        // blur the image
        blur(mat, edgesMat, cv::Size(BLUR_WIDTH,BLUR_HEIGHT));
            // cv::GaussianBlur(edgesMat,edgesMat,cv::Size(3,3),1.5);
    }

    // Canny edge detector
    Canny(edgesMat, edgesMat, LOW_THRESH, LOW_THRESH*RATIO_HI_LO, KERNEL_SIZE);
    
    @synchronized(self) {
        mat.copyTo(contrastMat, edgesMat);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.motionDelegate updateContrastPreview:[self imageWithCVMat:contrastMat]];
    });

    @synchronized(self){
        if (cam1.empty()) {
            contrastMat.copyTo(cam1);
        } else {
            cam1.copyTo(cam2);
            contrastMat.copyTo(cam1);
        }
    }

}

-(CGPoint)calculatePhaseCorrelationOfMat1:(cv::Mat)mat1 andMat2:(cv::Mat)mat2
{
    // SHIFT
    cv::Mat pa_64f, pb_64f;
    mat1.convertTo(pa_64f, CV_64F);
    mat2.convertTo(pb_64f, CV_64F);
    cv::Point2d pt = cv::phaseCorrelate(pa_64f, pb_64f);
    return CGPointMake(pt.x, pt.y);
    
    // SCALE NEW
//    cv::Mat pa = cv::Mat::zeros(mat1.size(), CV_8UC1);
//    cv::Mat pb = cv::Mat::zeros(mat2.size(), CV_8UC1);
//    IplImage ipl_a = mat1, ipl_pa = pa;
//    IplImage ipl_b = mat2, ipl_pb = pb;
//    cvLogPolar(&ipl_a, &ipl_pa, cvPoint2D32f(mat1.cols/2, mat1.rows/2), 40, CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS);
//    cvLogPolar(&ipl_b, &ipl_pb, cvPoint2D32f(mat2.cols/2, mat2.rows/2), 40, CV_INTER_LINEAR+CV_WARP_FILL_OUTLIERS);
//    
//    cv::Mat pa_64f, pb_64f;
//    pa.convertTo(pa_64f, CV_64F);
//    pb.convertTo(pb_64f, CV_64F);
//    
//    cv::Point2d p_pt = cv::phaseCorrelate(pa_64f, pb_64f);
//    NSLog(@"SCALE: %.2f",exp(p_pt.x));
//    return CGPointMake(p_pt.x, p_pt.y);
    
    // SCALE OLD
//    cv::Mat pa = cv::Mat::zeros(mat1.size(), CV_8UC1);
//    cv::Mat pb = cv::Mat::zeros(mat2.size(), CV_8UC1);
//    IplImage ipl_a = mat1, ipl_pa = pa;
//    IplImage ipl_b = mat2, ipl_pb = pb;
//    cvLogPolar(&ipl_a, &ipl_pa, cvPoint2D32f(mat1.cols >> 1, mat1.rows >> 1), 40);
//    cvLogPolar(&ipl_b, &ipl_pb, cvPoint2D32f(mat2.cols >> 1, mat2.rows >> 1), 40);
//    
//    cv::Mat pa_64f, pb_64f;
//    pa.convertTo(pa_64f, CV_64F);
//    pb.convertTo(pb_64f, CV_64F);
//    
//    cv::Point2d p_pt = cv::phaseCorrelate(pa_64f, pb_64f);
//    NSLog(@"SCALE: %.2f",exp(p_pt.x));
//
//    std::cout << "Shift = " << pt
//    << "Rotation = " << cv::format("%.2f", pt.y*180/(a.cols >> 1))
//    << std::endl;
//
//    return CGPointMake(p_pt.x, p_pt.y);

}

- (void)timerFunctionForPhaseCorrelation
{
    
    cv::Mat camSnap1;
    cv::Mat camSnap2;
    
    float xMove;
    float zMove;
    
    @synchronized(self){
        cam1.copyTo(camSnap1);
        cam2.copyTo(camSnap2);
    }
    
    if ((!camSnap1.empty())&&(!camSnap2.empty())) {
        CGPoint myMove = [self calculatePhaseCorrelationOfMat1:camSnap1 andMat2:camSnap2];

        if (fabs(myMove.x) < MAX_PHASE_SHIFT_X) {
            xMove = myMove.x * WALK_SCALE_X;
        } else {
            xMove = 0;
        }

        if (fabs(myMove.y) < MAX_PHASE_SHIFT_Y) {
            zMove = myMove.y * WALK_SCALE_Y;
        } else {
            zMove = 0;
        }
        
        if ([self.motionDelegate respondsToSelector:@selector(movementDetectedForX:andZ:)]) {
            [self.motionDelegate movementDetectedForX:xMove andZ:zMove];
        }

    }
}

@end

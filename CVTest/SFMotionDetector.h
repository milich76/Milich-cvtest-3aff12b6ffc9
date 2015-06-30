//
//  SFMotionDetector.h
//  CVTest
//
//  Created by Michael Ilich on 2013-02-01.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@protocol SFMotionDelegate <NSObject>
- (void) movementDetectedForX:(float)x andZ:(float)z;
- (void) updateContrastPreview:(UIImage *)img;
@end

@interface SFMotionDetector : NSObject {
    id<SFMotionDelegate> _motionDelegate;
}

@property(nonatomic, assign) id<SFMotionDelegate> motionDelegate;

- (id) init;
- (void) processFrame:(CGRect)videoRect forOrientation:(AVCaptureVideoOrientation)orientation atAddress:(void *)baseaddress;

@end

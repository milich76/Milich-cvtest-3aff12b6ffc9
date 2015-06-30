//
//  SFViewController.m
//  CVTest
//
//  Created by Michael Ilich on 2013-01-11.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

#import "SFViewController.h"
#import "SFGLKViewController.h"
#import <CoreMotion/CoreMotion.h>

#define INITIAL_DISTANCE -8.0f

@interface SFViewController () {
    
    SFGLKViewController *_myGlkViewController;
    SFCameraModel *_myCamera;
    SFMotionDetector *_motionDetector;
    
    float walkStart;
    float walkDelta;
    
}

@end

@implementation SFViewController

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Lock Device Orientation to Landscape Right
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Handle Touch Events
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for(id touch in touches) {
        CGPoint touchPoint = [touch locationInView:self.view];
        walkStart = touchPoint.y;
        walkDelta = 0.0f;
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {

    for(id touch in touches) {
        CGPoint touchPoint = [touch locationInView:self.view];
        walkDelta = (walkStart - touchPoint.y) / CGRectGetHeight(self.view.frame);
        
        if(walkDelta < -0.5f) {
            walkDelta = -0.5f;
        } else if(walkDelta > 0.5f) {
            walkDelta = 0.5f;
        }
        
        [_myGlkViewController addToDistanceX:0.0f andZ:(walkDelta*5.0)];
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {

    walkStart = 0.0f;
    walkDelta = 0.0f;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Standard UIViewController functions
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)dealloc
{
    
    [_myGlkViewController release]; _myGlkViewController =nil;
    _myCamera.camDelegate = nil;
    [_myCamera release]; _myCamera = nil;
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Motion Variables
    walkStart = 0.0f;
    walkDelta = 0.0f;
    
    _myGlkViewController = [[SFGLKViewController alloc] initWithDistance:INITIAL_DISTANCE];
    _myGlkViewController.view.frame = self.view.frame;
    [self.view addSubview: _myGlkViewController.view];
    [self addChildViewController:_myGlkViewController];
    [_myGlkViewController didMoveToParentViewController:self];
    
    _myCamera = [[SFCameraModel alloc] initWithViewController:_myGlkViewController];
    _myCamera.camDelegate = self;
    
    _motionDetector = [[SFMotionDetector alloc] init];
    _motionDetector.motionDelegate = self;
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    // GLView unloaded on low memory
    [_myGlkViewController didReceiveMemoryWarning];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  SFCameraDelegate Methods
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) processFrame:(CGRect)videoRect forOrientation:(AVCaptureVideoOrientation)orientation atAddress:(void *)baseaddress
{
    [_motionDetector processFrame:videoRect forOrientation:orientation atAddress:baseaddress];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  SFMotionDelegate Methods
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) movementDetectedForX:(float)x andZ:(float)z
{
    
//    [_myGlkViewController addToDistanceX:x andZ:z];
//    [_myGlkViewController addToDistanceX:0 andZ:x];
//    [_myGlkViewController shiftFromDistanceX:x andZ:z];
//    [_myGlkViewController subOnlyFromDistanceZ:z];

    [_myGlkViewController shiftFromDistanceX:x andZ:z];
}

- (void) updateContrastPreview:(UIImage *)img
{
    [_myCamera updateContrastPreview:img];
}

@end

//
//  SFGLKViewController.h
//  CVTest
//
//  Created by Michael Ilich on 2013-02-01.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

#import <GLKit/GLKit.h>

@interface SFGLKViewController : GLKViewController

- (id)initWithDistance:(float)initialDistance;

- (void)addToDistanceX:(float)xMove andZ:(float)zMove;
- (void)subFromDistanceX:(float)xMove andZ:(float)zMove;
-(void)subOnlyFromDistanceZ:(float)zMove;
- (void)shiftFromDistanceX:(float)xMove andZ:(float)zMove;

@end

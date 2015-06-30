//
//  SFMotionConst.h
//  CVTest
//
//  Created by Michael Ilich on 2013-03-08.
//  Copyright (c) 2013 Sarofax. All rights reserved.
//

// CANNY EDGE DETECTION
#define LOW_THRESH 20 // 0 to 100
#define RATIO_HI_LO 3 // 3
#define KERNEL_SIZE 5 // 5, originally 3

// IMAGE BLUR PARAMETERS
#define BLUR_WIDTH 5 // 5
#define BLUR_HEIGHT 5 // 5

// MOVEMENT CONSTRAINTS
#define MAX_PHASE_SHIFT_X 30 // Must cut off the image shift to avoid gyro glitches
#define MAX_PHASE_SHIFT_Y 25 // Must cut off the image shift to avoid gyro glitches
#define WALK_SCALE_X 0.025
#define WALK_SCALE_Y 0.15

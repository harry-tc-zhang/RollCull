//
//  OpenCVWrapper.m
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/3/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

#import "OpenCVWrapper.h"
#import "OpenCVOps.h"
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

using namespace cv;

@implementation OpenCVWrapper

+ (NSString*)openCVVersionString {
    return [NSString stringWithFormat:@"OpenCV Version %s",  CV_VERSION];
}

+ (NSDictionary*)getPropsFromUIImage: (UIImage*)image {
    NSLog(@"Input image is width %f and height %f", image.size.width, image.size.height);
    cv::Mat imageMat = [OpenCVOps cvMatFromUIImage:image convertColor:true];
    [OpenCVOps getColorHistogramFromMat:imageMat withRBins:32 GBins:64 BBins:16];
    [OpenCVOps getPixelBrightnessHistogramFromMat:imageMat withBins:50];
    [OpenCVOps getFocusMeasureFromMat:imageMat withStep:5];
    
    return [NSMutableDictionary dictionary];
}

+ (UIImage*)testCVMatConversionOnUIImage: (UIImage*)image {
    return [OpenCVOps UIImageFromCVMat:[OpenCVOps cvMatFromUIImage:image convertColor:true]];
}

@end

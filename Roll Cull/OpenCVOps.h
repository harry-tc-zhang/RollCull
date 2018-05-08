//
//  OpenCVOps.h
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/4/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface OpenCVOps : NSObject

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image convertColor:(Boolean)cvt;

+ (UIImage*)UIImageFromCVMat:(cv::Mat)cvMat;

+ (NSArray*)getColorHistogramFromMat: (cv::Mat)src withRBins: (int)histSize GBins: (int)gSize BBins:(int)bSize;

+ (NSArray*)getPixelBrightnessHistogramFromMat: (cv::Mat)image withBins: (int)histSize;

+ (double)getAverageExposureOfMat: (cv::Mat)image;

+ (NSArray*)getFocusMeasureFromMat: (cv::Mat)image withStep: (int)step;

@end

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
#import <vector>

using namespace cv;
using namespace std;

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

+ (UIImage*)diffImage: (UIImage*)image1 withImage: (UIImage*)image2 {
    Mat mat1 = [OpenCVOps cvMatFromUIImage:image1 convertColor:false];
    Mat mat2 = [OpenCVOps cvMatFromUIImage:image2 convertColor:false];
    Mat diffMat;
    absdiff(mat1, mat2, diffMat);
    UIImage* debugImage = [OpenCVOps UIImageFromCVMat:diffMat];
    NSLog(@"Test");
    return debugImage;
}

+ (void)analyzeForegroundOnImages: (NSArray*)images {
    Mat tmpMat = [OpenCVOps cvMatFromUIImage:images[0] convertColor:false];
    Mat accuMat = Mat(tmpMat.rows, tmpMat.cols, CV_32FC4);
    Mat accuTmp;
    for(id img in images) {
        [OpenCVOps cvMatFromUIImage:img convertColor:false].convertTo(accuTmp, CV_32FC4);
        accumulate(accuTmp, accuMat);
    }
    Mat avgMat;
    accuMat.convertTo(avgMat, CV_8UC4, 1.0 / (float)images.count);
    
    Mat diffMat;
    absdiff([OpenCVOps cvMatFromUIImage:images[1] convertColor:false], avgMat, diffMat);
    
    Mat diffGray;
    cvtColor(diffMat, diffGray, CV_BGRA2GRAY);
    
    threshold(diffGray, diffGray, 64, 255, THRESH_BINARY);
    
    UIImage* debugImage = [OpenCVOps UIImageFromCVMat:diffGray];
    
    return;
}

+ (NSDictionary*)evaluateQualityOfFaces: (NSArray*)faces inImage: (UIImage*)image {
    NSLog(@"Face evaluation");
    Mat imgMat = [OpenCVOps cvMatFromUIImage:image convertColor:false];
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:@"Face" forKey:@"Type"];
    for(int i = 0; i < [faces count]; i ++) {
        NSArray* face = (NSArray*)faces[i];
        Mat faceRegion = imgMat(cv::Rect([face[0] floatValue], [face[1] floatValue], [face[2] floatValue], [face[3] floatValue]));
        NSArray* focusInfo = [OpenCVOps getFocusMeasureFromMat:faceRegion withStep:1];
        NSLog(@"%@", focusInfo);
        [dict setObject:focusInfo forKey:@"Focus"];
        double exposureInfo = [OpenCVOps getAverageExposureOfMat:faceRegion];
        NSLog(@"%f", exposureInfo);
        [dict setObject:[NSNumber numberWithDouble: exposureInfo] forKey:@"Exposure"];
        double sizeInfo = ([face[2] floatValue] + [face[3] floatValue]) / 2;
        NSLog(@"%f", sizeInfo);
        [dict setObject:[NSNumber numberWithDouble: sizeInfo] forKey:@"Size"];
    }
    return dict;
}

+ (NSDictionary*)evaluateQuaityOfImage: (UIImage*)image {
    int gridNum = 5;
    int gridWidth = (int)(image.size.width / gridNum);
    int gridHeight = (int)(image.size.height / gridNum);
    
    Mat imgMat = [OpenCVOps cvMatFromUIImage:image convertColor:false];
    
    NSMutableDictionary* dict = [NSMutableDictionary dictionary];
    [dict setObject:@"Scene" forKey:@"Type"];
    
    // Stuff to be measured by region
    double exposureMeasure = 0;
    double focusXMeasure = 0;
    double focusYMeasure = 0;
    double regionCount = 0;
    
    for(int j = 0; j < gridNum; j ++) {
        for(int i = 0; i < gridNum; i ++) {
            cv::Rect rect(i * gridWidth, j * gridHeight, gridWidth, gridHeight);
            Mat currentRegion = imgMat(rect);
            
            double textureDensity = [OpenCVOps getTextureDensityOfMat:currentRegion];
            NSLog(@"Texture density for region (%d, %d): %f", j, i, textureDensity);
            // Discard foliage
            if(textureDensity > 0.9) {
                double avgHue = [OpenCVOps getAvgHueOfMat:currentRegion];
                if((avgHue >= 80) && (avgHue <= 150)) {
                    continue;
                }
            }
            // Discard sky
            if(textureDensity < 0.1) {
                continue;
            }
            
            double regionExposure = [OpenCVOps getAverageExposureOfMat:currentRegion];
            exposureMeasure += regionExposure;
            
            NSArray* focusMeasures = [OpenCVOps getFocusMeasureFromMat:currentRegion withStep:1];
            double focusX = [focusMeasures[0] doubleValue];
            focusXMeasure = focusXMeasure > focusX ? focusXMeasure : focusX;
            double focusY = [focusMeasures[1] doubleValue];
            focusYMeasure = focusYMeasure > focusY ? focusYMeasure : focusY;
            
            regionCount += 1;
        }
    }
    
    NSLog(@"Focus measures: X %f, Y %f", focusXMeasure, focusYMeasure);
    [dict setObject:[NSArray arrayWithObjects:[NSNumber numberWithDouble:focusXMeasure], [NSNumber numberWithDouble:focusYMeasure], nil] forKey:@"Focus"];
    
    exposureMeasure = exposureMeasure / regionCount;
    NSLog(@"Image exposure is %f", exposureMeasure);
    [dict setObject:[NSNumber numberWithDouble:exposureMeasure] forKey:@"Exposure"];
    
    double imgContrast = [OpenCVOps getContrastOfMat:imgMat];
    NSLog(@"Image contrast is %f", imgContrast);
    [dict setObject:[NSNumber numberWithDouble:imgContrast] forKey:@"Contrast"];
    
    double imgSaturation = [OpenCVOps getSaturationOfMat:imgMat];
    NSLog(@"Image saturation is %f", imgSaturation);
    [dict setObject:[NSNumber numberWithDouble:imgSaturation] forKey:@"Saturation"];
    
    double imageSymmetry = [OpenCVOps getSymmetryOfMat:imgMat];
    NSLog(@"Image symmetry is %f", imageSymmetry);
    [dict setObject:[NSNumber numberWithDouble:imageSymmetry] forKey:@"Symmetry"];
    
    return dict;
}

@end

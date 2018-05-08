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
    for(int i = 0; i < [faces count]; i ++) {
        NSArray* face = (NSArray*)faces[i];
        //float* x = (float*)face[0];
        //NSLog(@"%@", face->origin);
        //NSLog(@"%@", face->size);
        Mat faceRegion = imgMat(cv::Rect([face[0] floatValue], [face[1] floatValue], [face[2] floatValue], [face[3] floatValue]));
        NSArray* focusInfo = [OpenCVOps getFocusMeasureFromMat:faceRegion withStep:3];
        NSLog(@"%@", focusInfo);
        double exposureInfo = [OpenCVOps getAverageExposureOfMat:faceRegion];
        NSLog(@"%f", exposureInfo);
    }
    return [NSMutableDictionary dictionary];
}

@end

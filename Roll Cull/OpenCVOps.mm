//
//  OpenCVOps.m
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/4/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

#import "OpenCVOps.h"
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

using namespace std;
using namespace cv;

@implementation OpenCVOps

// Function lifted from https://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image convertColor:(Boolean)cvt
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(colorSpace);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    CGBitmapInfo bitmapInfo = kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault;
    
    // check whether the UIImage is greyscale already
    if (numberOfComponents == 1){
        cvMat = cv::Mat(rows, cols, CV_8UC1); // 8 bits per component, 1 channels
        bitmapInfo = kCGImageAlphaNone | kCGBitmapByteOrderDefault;
    }
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,             // Pointer to backing data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    bitmapInfo);              // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    if(numberOfComponents == 1) {
        if(cvt) {
            Mat colorMat(rows, cols, CV_8UC4);
            cvtColor(cvMat, colorMat, CV_GRAY2BGR);
            return colorMat;
        }
    }
    
    return cvMat;
}

// Function lifted from https://stackoverflow.com/questions/10254141/how-to-convert-from-cvmat-to-uiimage-in-objective-c
+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(
                                        cvMat.cols,                 //width
                                        cvMat.rows,                 //height
                                        8,                          //bits per component
                                        8 * cvMat.elemSize(),       //bits per pixel
                                        cvMat.step[0],              //bytesPerRow
                                        colorSpace,                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                   //CGDataProviderRef
                                        NULL,                       //decode
                                        false,                      //should interpolate
                                        kCGRenderingIntentDefault   //intent
                                        );
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

// Code largely lifted from https://docs.opencv.org/2.4/doc/tutorials/imgproc/histograms/histogram_calculation/histogram_calculation.html
+ (NSArray*)getColorHistogramFromMat: (Mat)src withRBins: (int)rSize GBins: (int)gSize BBins:(int)bSize {
    Mat dst;
    
    if(!src.data) {
        return nullptr;
    }
    
    /// Separate the image in 3 places ( B, G and R )
    vector<Mat> bgr_planes;
    split(src, bgr_planes);
    
    /// Establish the number of bins
    
    /// Set the ranges ( for B,G,R) )
    float range[] = {0, 256} ;
    const float* histRange = {range};
    
    bool uniform = true;
    bool accumulate = false;
    
    Mat b_hist, g_hist, r_hist;
    
    /// Compute the histograms:
    calcHist(&bgr_planes[0], 1, 0, Mat(), b_hist, 1, &rSize, &histRange, uniform, accumulate);
    calcHist(&bgr_planes[1], 1, 0, Mat(), g_hist, 1, &gSize, &histRange, uniform, accumulate);
    calcHist(&bgr_planes[2], 1, 0, Mat(), r_hist, 1, &bSize, &histRange, uniform, accumulate);
    
    NSLog(@"rMat size: %d, %d", r_hist.rows, r_hist.cols);
    float pixelCount = 0;
    for(int i = 0; i < r_hist.rows; i ++) {
        NSLog(@"rMat at %d: %f", i, r_hist.at<float>(i));
        pixelCount += r_hist.at<float>(i);
    }
    NSLog(@"PixelCount from histogram: %f; image size is %d", pixelCount, src.cols * src.rows);
    
    NSMutableArray* histogram = [NSMutableArray array];
    for(int i = 0; i < r_hist.rows; i ++) {
        [histogram addObject:[NSNumber numberWithFloat: r_hist.at<float>(i)]];
    }
    for(int i = 0; i < g_hist.rows; i ++) {
        [histogram addObject:[NSNumber numberWithFloat: g_hist.at<float>(i)]];
    }
    for(int i = 0; i < b_hist.rows; i ++) {
        [histogram addObject:[NSNumber numberWithFloat: b_hist.at<float>(i)]];
    }
    NSLog(@"Histogram: %@", histogram);
    
    /* Display-related stuff we don't need
     
    // Draw the histograms for B, G and R
    int hist_w = 512; int hist_h = 400;
    int bin_w = cvRound( (double) hist_w/histSize );
    
    //Mat histImage( hist_h, hist_w, CV_8UC3, Scalar( 0,0,0) );
    
    /// Normalize the result to [ 0, histImage.rows ]
    //normalize(b_hist, b_hist, 0, histImage.rows, NORM_MINMAX, -1, Mat() );
    //normalize(g_hist, g_hist, 0, histImage.rows, NORM_MINMAX, -1, Mat() );
    //normalize(r_hist, r_hist, 0, histImage.rows, NORM_MINMAX, -1, Mat() );
    
    
    /// Draw for each channel
    for( int i = 1; i < histSize; i++ )
    {
        line( histImage, cv::Point( bin_w*(i-1), hist_h - cvRound(b_hist.at<float>(i-1)) ) ,
             cv::Point( bin_w*(i), hist_h - cvRound(b_hist.at<float>(i)) ),
             Scalar( 255, 0, 0), 2, 8, 0  );
        line( histImage, cv::Point( bin_w*(i-1), hist_h - cvRound(g_hist.at<float>(i-1)) ) ,
             cv::Point( bin_w*(i), hist_h - cvRound(g_hist.at<float>(i)) ),
             Scalar( 0, 255, 0), 2, 8, 0  );
        line( histImage, cv::Point( bin_w*(i-1), hist_h - cvRound(r_hist.at<float>(i-1)) ) ,
             cv::Point( bin_w*(i), hist_h - cvRound(r_hist.at<float>(i)) ),
             Scalar( 0, 0, 255), 2, 8, 0  );
    }
    
    UIImage* histUIImage = [OpenCVOps UIImageFromCVMat:histImage];
    NSLog(@"This is a test");
    
    
    /// Display
    //namedWindow("calcHist Demo", CV_WINDOW_AUTOSIZE );
    //imshow("calcHist Demo", histImage );
    
    //waitKey(0);
    */
    
    return histogram;
}

// Gets image intensity values using the LAB color space.
// Code is similar to its color counterpart
+ (NSArray*)getPixelBrightnessHistogramFromMat: (cv::Mat)image withBins: (int)histSize {
    Mat labMat;
    
    cvtColor(image, labMat, CV_BGR2Lab);
    
    vector<Mat> labPlanes;
    split(labMat, labPlanes);
    
    /// Set the ranges for intensity
    float range[] = {0, 256} ;
    const float* histRange = {range};
    
    bool uniform = true;
    bool accumulate = false;
    
    Mat lHist;
    calcHist(&labPlanes[0], 1, 0, Mat(), lHist, 1, &histSize, &histRange, uniform, accumulate);
    
    NSLog(@"lHist rows: %d, cols: %d", lHist.rows, lHist.cols);
    
    NSMutableArray* histogram = [NSMutableArray array];
    float pixelCount = 0;
    for(int i = 0; i < lHist.rows; i ++) {
        [histogram addObject:[NSNumber numberWithFloat: lHist.at<float>(i)]];
        pixelCount += lHist.at<float>(i);
    }
    NSLog(@"PixelCount: %f, image size: %d", pixelCount, image.cols * image.rows);
    
    return histogram;
}

+ (double)getAverageExposureOfMat: (cv::Mat)image {
    Mat labMat;
    
    cvtColor(image, labMat, CV_BGR2Lab);
    
    vector<Mat> labPlanes;
    split(labMat, labPlanes);
    
    return mean(labPlanes[0])[0];
}

// Focus measure using measure proposed in work by Nayar and Nakagawa (1994)
// (Shape from Focus)
+ (NSArray*)getFocusMeasureFromMat: (cv::Mat)image withStep: (int)step {
    int kernel_size = step * 2 + 1;
    
    Mat bwImage;
    cvtColor(image, bwImage, COLOR_BGR2GRAY);
    bwImage.convertTo(bwImage, CV_32F);
    
    Mat xFilter = Mat::zeros(kernel_size, kernel_size, CV_32F);
    xFilter.at<float>(step, step) = 2;
    xFilter.at<float>(step, 0) = -1;
    xFilter.at<float>(step, step * 2) = -1;
    
    Mat xFocusImage;
    filter2D(bwImage, xFocusImage, -1, xFilter);
    xFocusImage = abs(xFocusImage);
    xFocusImage.convertTo(xFocusImage, CV_8U);
    
    int xFocusedCount = 0;
    for(int i = 0; i < xFocusImage.cols; i ++) {
        double min, max;
        minMaxIdx(xFocusImage.col(i), &min, &max);
        //NSLog(@"%f", max);
        if(max > 10) {
            xFocusedCount += 1;
        }
    }
    NSLog(@"x: %d/%d", xFocusedCount, xFocusImage.cols);
    double xFocusCoverage = (float)xFocusedCount / (float)xFocusImage.cols;
    
    Mat yFilter = Mat::zeros(kernel_size, kernel_size, CV_32F);
    yFilter.at<float>(step, step) = 2;
    yFilter.at<float>(0, step) = -1;
    yFilter.at<float>(step * 2, step) = -1;
    
    Mat yFocusImage;
    filter2D(bwImage, yFocusImage, -1, yFilter);
    yFocusImage = abs(yFocusImage);
    yFocusImage.convertTo(yFocusImage, CV_8U);
    
    int yFocusedCount = 0;
    for(int i = 0; i < yFocusImage.rows; i ++) {
        double min, max;
        minMaxIdx(yFocusImage.row(i), &min, &max);
        //NSLog(@"%f", max);
        if(max > 10) {
            yFocusedCount += 1;
        }
    }
    NSLog(@"y: %d/%d", yFocusedCount, yFocusImage.rows);
    double yFocusCoverage = (float)yFocusedCount / (float)yFocusImage.rows;
    
    UIImage* debugImage = [OpenCVOps UIImageFromCVMat:xFocusImage];
    UIImage* debugImage2 = [OpenCVOps UIImageFromCVMat:yFocusImage];
    return [NSArray arrayWithObjects:[NSNumber numberWithFloat:xFocusCoverage], [NSNumber numberWithFloat:yFocusCoverage], nil];
}

@end

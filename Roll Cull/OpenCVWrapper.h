//
//  OpenCVWrapper.h
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/3/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

+ (NSString*)openCVVersionString;

+ (NSDictionary*)getPropsFromUIImage: (UIImage*)image;

+ (UIImage*)testCVMatConversionOnUIImage: (UIImage*)image;

@end

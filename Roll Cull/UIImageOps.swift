//
//  UIImageOps.swift
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/8/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

import UIKit

class UIImageOps: NSObject {
    class func drawRectangleOnImage(image: UIImage, rectangle: CGRect) -> UIImage {
        let imageSize = image.size
        let scale: CGFloat = 0
        UIGraphicsBeginImageContextWithOptions(imageSize, false, scale)
        
        image.draw(at: CGPoint(x: 0, y: 0));
        
        let rectToDraw = CGRect(x: rectangle.origin.x * image.size.width, y: (1 - rectangle.origin.y) * image.size.height - rectangle.height * image.size.height, width: rectangle.width * image.size.width, height: rectangle.height * image.size.height)
        
        UIColor.black.setFill()
        UIRectFill(rectToDraw)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    // Code lifted from https://stackoverflow.com/questions/44724257/convert-vision-boundingbox-from-vnfaceobservation-to-rect-to-draw-on-image
    class func getFaceRectFromBoundingBox(image: UIImage, bbox: CGRect) -> CGRect {
        return CGRect(
            x: bbox.origin.x * image.size.width,
            y: (1 - bbox.origin.y) * image.size.height - bbox.height * image.size.height,
            width: bbox.width * image.size.width,
            height: bbox.height * image.size.height
        )
    }
}

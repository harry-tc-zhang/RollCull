//
//  ViewController.swift
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/3/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

import UIKit
import Photos
import Vision

class ViewController: UIViewController {

    // All code related to Apple's Photos framework lifted from this sample:
    // https://developer.apple.com/library/content/samplecode/UsingPhotosFramework/Introduction/Intro.html
    
    @IBOutlet weak var testImageView: UIImageView!
    var allPhotos: PHFetchResult<PHAsset>!
    let imageManager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        //print("\(OpenCVWrapper.openCVVersionString())")
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        let firstAsset = allPhotos.firstObject!
        let imageSize = CGSize(width: 1920, height: 1920);
        var itemOptions = PHImageRequestOptions();
        itemOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat;
        //print(imageSize);
        imageManager.requestImage(for: firstAsset, targetSize: imageSize, contentMode: .aspectFit, options: itemOptions, resultHandler: {image, _ in
            self.testImageView.image = OpenCVWrapper.testCVMatConversion(on: image);
            //OpenCVWrapper.getPropsFrom(image)
            // Code below using the iOS Vision API is adapted from https://medium.com/@kravik/ios-11-tutorial-vision-framework-3c836d5ecadd
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: {request, error in
                if let results = request.results as? [VNFaceObservation] {
                    for faceObservation in results {
                        print(faceObservation)
                    }
                }
            })
            let vnImage = VNImageRequestHandler(cgImage: image!.cgImage!, options: [:])
            try? vnImage.perform([detectFaceRequest])
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


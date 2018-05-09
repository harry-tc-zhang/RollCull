//
//  ImageDetailViewController.swift
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/8/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

import UIKit
import Photos

class ImageDetailViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var attributes: UITextView!
    var asset = PHAsset()
    let imageManager = PHCachingImageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(asset)
        
        let itemOptions = PHImageRequestOptions();
        itemOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        itemOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
        itemOptions.isSynchronous = true
        
        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: itemOptions, resultHandler: {image, _ in
            self.imageView.image = image;
            OpenCVWrapper.evaluateQuaity(of: image);
        })
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

//
//  BurstOperationController.swift
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/6/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

import UIKit
import Photos
import Vision

class GroupOperationController: UIViewController {
    
    fileprivate let cellIdentifier = "burstPhotoCell"
    fileprivate let sectionHeaderIdentifier = "photoTypeHeader"
    var burstAssets: PHFetchResult<PHAsset>!
    var groupedAssets = [String:[PHAsset]]()
    var thumbnails = [String:[UIImage]]()
    //var groupedAssets = [String:[UIImage]]()
    let thumbnailManager = PHCachingImageManager()
    let highresManager = PHCachingImageManager()
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    var widthPerItem: CGFloat = 200
    fileprivate let itemsPerRow: CGFloat = 2
    
    var assetGroup = [PHAsset]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //debugPrint(assetGroup)
        
        // Set up layout of collection view
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        widthPerItem = availableWidth / itemsPerRow
        
        // Retrieve images
        let itemOptions = PHImageRequestOptions();
        itemOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        itemOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
        itemOptions.isSynchronous = true
        
        let thumbnailSize = CGSize(width: widthPerItem, height: widthPerItem);
        
        for asset in assetGroup {
            var thumbnail = UIImage()
            var highres = UIImage()
            self.thumbnailManager.requestImage(for: asset, targetSize: thumbnailSize, contentMode: .aspectFill, options: itemOptions, resultHandler: {image, _ in
                thumbnail = image!
            })
            self.highresManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth / 2, height: asset.pixelHeight / 2), contentMode: .aspectFill, options: itemOptions, resultHandler: {image, _ in
                highres = image!
            })
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: {request, error in
                if let results = request.results as? [VNFaceObservation] {
                    if results.count > 0 {
                        if self.thumbnails["People"] != nil {
                            self.thumbnails["People"]!.append(thumbnail)
                        } else {
                            self.thumbnails["People"] = [thumbnail]
                        }
                        if self.groupedAssets["People"] != nil {
                            self.groupedAssets["People"]!.append(asset)
                        } else {
                            self.groupedAssets["People"] = [asset]
                        }
                        
                        let firstBoundingBox = UIImageOps.getFaceRectFromBoundingBox(image: highres, bbox: results[0].boundingBox)
                        OpenCVWrapper.evaluateQuality(ofFaces: [[firstBoundingBox.origin.x, firstBoundingBox.origin.y, firstBoundingBox.size.width, firstBoundingBox.size.height]], in: highres)
                        
                        //print(results[0].boundingBox)
                        
                    } else {
                        if self.thumbnails["Other"] != nil {
                            self.thumbnails["Other"]!.append(thumbnail)
                        } else {
                            self.thumbnails["Other"] = [thumbnail]
                        }
                        if self.groupedAssets["Other"] != nil {
                            self.groupedAssets["Other"]!.append(asset)
                        } else {
                            self.groupedAssets["Other"] = [asset]
                        }
                    }
                }
            })
            let vnImage = VNImageRequestHandler(cgImage: highres.cgImage!, options: [:])
            try? vnImage.perform([detectFaceRequest])
        }
        
        return
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

extension GroupOperationController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return thumbnails.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerItem = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionHeaderIdentifier, for: indexPath) as! GroupOperationSectionHeader
            headerItem.headerText.text = Array(thumbnails.keys)[indexPath.section]
            return headerItem
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails[Array(thumbnails.keys)[section]]!.count;
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! GroupOperationCell
        cell.cellImage.image = thumbnails[Array(thumbnails.keys)[indexPath.section]]![indexPath.item]
        return cell
    }
}

extension GroupOperationController: UICollectionViewDelegate {
    
}


// Code lifted from https://www.raywenderlich.com/136159/uicollectionview-tutorial-getting-started
extension GroupOperationController : UICollectionViewDelegateFlowLayout {
    //1
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        //2
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    //3
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets
    }
    
    // 4
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return sectionInsets.left
    }
}

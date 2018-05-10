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
    
    @IBOutlet weak var selectBtn: UIBarButtonItem!
    @IBOutlet weak var deleteBtn: UIBarButtonItem!
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    fileprivate let cellIdentifier = "burstPhotoCell"
    fileprivate let sectionHeaderIdentifier = "photoTypeHeader"
    var groupedAssets = [String:[PHAsset]]()
    var thumbnails = [PHAsset:UIImage]()
    var assetProps = [PHAsset:[String:Any]]()
    //var groupedAssets = [String:[UIImage]]()
    let thumbnailManager = PHCachingImageManager()
    let highresManager = PHCachingImageManager()
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    var widthPerItem: CGFloat = 200
    fileprivate let itemsPerRow: CGFloat = 2
    
    var selectionMode: Bool = false
    var assetsToDelete = [PHAsset]()
    
    fileprivate let segueIdentifier = "showDetailsSegue"
    var assetToPass = PHAsset()
    var propsToPass = [String:Any]()
    
    var assetGroup = [PHAsset]()
    
    func compareFaceResults(f1: PHAsset, f2: PHAsset) -> Bool {
        // Compare focus first, using minimum of focus measure
        let f1Focus = assetProps[f1]!["Focus"]! as! [Double]
        let f1MinFocus = min(f1Focus[0], f1Focus[1])
        let f2Focus = assetProps[f2]!["Focus"]! as! [Double]
        let f2MinFocus = min(f2Focus[0], f2Focus[1])
        if f1MinFocus - f2MinFocus > 0.05 {
            return false
        } else if f2MinFocus - f1MinFocus > 0.05 {
            return true
        }
        
        // If focus is close, compare face size
        let f1Size = assetProps[f1]!["Size"]! as! Double
        let f2Size = assetProps[f2]!["Size"]! as! Double
        if f1Size / f2Size > 1.5 {
            return false
        } else if f2Size / f1Size > 1.5 {
            return true
        }
        
        // If size is also close, compare exposure
        let f1ExposureDev = abs(assetProps[f1]!["Exposure"]! as! Double - 128.0)
        let f2ExposureDev = abs(assetProps[f2]!["Exposure"]! as! Double - 128.0)
        return f1ExposureDev < f2ExposureDev
    }
    
    func compareSceneResults(s1: PHAsset, s2: PHAsset) -> Bool {
        // Compare focus first, using minimum of focus measure
        let s1Focus = assetProps[s1]!["Focus"]! as! [Double]
        let s1MinFocus = min(s1Focus[0], s1Focus[1])
        let s2Focus = assetProps[s2]!["Focus"]! as! [Double]
        let s2MinFocus = min(s2Focus[0], s2Focus[1])
        if s1MinFocus - s2MinFocus > 0.05 {
            return false
        } else if s2MinFocus - s1MinFocus > 0.05 {
            return true
        }
        
        // If focus is close, compare exposure with a loose standard
        let s1ExposureDev = abs(assetProps[s1]!["Exposure"]! as! Double - 128.0);
        let s2ExposureDev = abs(assetProps[s1]!["Exposure"]! as! Double - 128.0);
        if !((s1ExposureDev < 32.0) && (s2ExposureDev < 32.0)) {
            if s1ExposureDev - s2ExposureDev > 16.0 {
                return true
            } else if s2ExposureDev - s1ExposureDev > 16.0 {
                return false
            }
        }
        
        // If exposure is also close, compare saturation
        let s1Saturation = assetProps[s1]!["Saturation"]! as! Double
        let s2Saturation = assetProps[s2]!["Saturation"]! as! Double
        if s1Saturation - s2Saturation > 4 {
            return false
        } else if s2Saturation - s1Saturation > 4 {
            return true
        }
        
        // If saturationn is also close, compare contrast
        let s1Contrast = assetProps[s1]!["Contrast"]! as! Double
        let s2Contrast = assetProps[s2]!["Contrast"]! as! Double
        if s1Contrast / s2Contrast > 1.2 {
            return false
        } else if s2Contrast / s1Contrast > 1.2 {
            return true
        }
        
        // If everything else is close, look at symmetry
        let s1Symmetry = assetProps[s1]!["Symmetry"]! as! Double
        let s2Symmetry = assetProps[s2]!["Symmetry"]! as! Double
        return s1Symmetry < s2Symmetry
    }
    
    @objc func selectBtnAction(_ sender: UIBarButtonItem) {
        if !selectionMode {
            //print("Entered selection mode.")
            selectionMode = true
            selectBtn.title = "Cancel"
            deleteBtn.isEnabled = true
        } else {
            selectionMode = false
            selectBtn.title = "Select"
            deleteBtn.isEnabled = false
            assetsToDelete.removeAll()
            photoCollectionView.reloadData()
        }
    }
    
    @objc func deleteBtnAction(_ sender: UIBarButtonItem) {
        if selectionMode {
            PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.deleteAssets(self.assetsToDelete as NSArray)
                }, completionHandler: { (success, error) in
                    if success {
                        DispatchQueue.main.async {
                            self.navigationController?.popViewController(animated: true)
                        }
                    }
                })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //debugPrint(assetGroup)
        
        // Set up select button
        selectBtn.action = #selector(selectBtnAction(_:))
        deleteBtn.isEnabled = false
        deleteBtn.tintColor = UIColor.red
        deleteBtn.action = #selector(deleteBtnAction(_:))
        
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
                self.thumbnails[asset] = image!
            })
            self.highresManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth / 2, height: asset.pixelHeight / 2), contentMode: .aspectFill, options: itemOptions, resultHandler: {image, _ in
                highres = image!
            })
            let detectFaceRequest = VNDetectFaceRectanglesRequest(completionHandler: {request, error in
                if let results = request.results as? [VNFaceObservation] {
                    if results.count > 0 {
                        if self.groupedAssets["People"] != nil {
                            self.groupedAssets["People"]!.append(asset)
                        } else {
                            self.groupedAssets["People"] = [asset]
                        }
                        
                        // We find the biggest face ane evaluate it, because it's likely to be our subject.
                        var largestSize = results[0].boundingBox.width + results[0].boundingBox.height
                        var largestResult = results[0]
                        for result in results {
                            var rSize = result.boundingBox.width + result.boundingBox.height;
                            if rSize > largestSize {
                                largestSize = rSize;
                                largestResult = result;
                            }
                        }
                        
                        let largestBoundingBox = UIImageOps.getFaceRectFromBoundingBox(image: highres, bbox: largestResult.boundingBox)
                        self.assetProps[asset] = OpenCVWrapper.evaluateQuality(ofFaces: [[largestBoundingBox.origin.x, largestBoundingBox.origin.y, largestBoundingBox.size.width, largestBoundingBox.size.height]], in: highres) as! [String:Any]
                        
                        //print(results[0].boundingBox)
                        
                    } else {
                        if self.groupedAssets["Other"] != nil {
                            self.groupedAssets["Other"]!.append(asset)
                        } else {
                            self.groupedAssets["Other"] = [asset]
                        }
                        
                        self.assetProps[asset] = OpenCVWrapper.evaluateQuaity(of: highres) as! [String:Any]
                    }
                }
            })
            let vnImage = VNImageRequestHandler(cgImage: highres.cgImage!, options: [:])
            try? vnImage.perform([detectFaceRequest])
        }
        
        if groupedAssets["People"] != nil {
            groupedAssets["People"]!.sort(by: compareFaceResults(f1:f2:))
            groupedAssets["People"]!.reverse()
        }
        
        if groupedAssets["Other"] != nil {
            groupedAssets["Other"]!.sort(by: compareSceneResults(s1:s2:))
            groupedAssets["Other"]!.reverse()
        }
        
        return
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! ImageDetailViewController
        destinationVC.asset = assetToPass
        destinationVC.imageProps = propsToPass
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
        return groupedAssets.count;
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            let headerItem = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: sectionHeaderIdentifier, for: indexPath) as! GroupOperationSectionHeader
            headerItem.headerText.text = Array(groupedAssets.keys)[indexPath.section]
            return headerItem
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return groupedAssets[Array(groupedAssets.keys)[section]]!.count;
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! GroupOperationCell
        let currentAsset = groupedAssets[Array(groupedAssets.keys)[indexPath.section]]![indexPath.item]
        cell.cellImage.image = thumbnails[currentAsset]
        if assetsToDelete.contains(currentAsset) {
            cell.cellLabel.text = "X"
        } else {
            cell.cellLabel.text = ""
        }
        return cell
    }
}

extension GroupOperationController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentAsset = groupedAssets[Array(groupedAssets.keys)[indexPath.section]]![indexPath.item]
        if(selectionMode) {
            if assetsToDelete.contains(currentAsset) {
                assetsToDelete = assetsToDelete.filter{$0 != currentAsset}
            } else {
                assetsToDelete.append(currentAsset)
            }
            //print(assetsToDelete)
            photoCollectionView.reloadItems(at: [indexPath])
        } else {
            assetToPass = groupedAssets[Array(groupedAssets.keys)[indexPath.section]]![indexPath.item]
            propsToPass = assetProps[assetToPass]!
            self.performSegue(withIdentifier: segueIdentifier, sender: self)
        }
    }
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

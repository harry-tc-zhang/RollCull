//
//  BurstOperationController.swift
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/6/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

import UIKit
import Photos

class GroupOperationController: UIViewController {
    
    fileprivate let cellIdentifier = "burstPhotoCell"
    var burstAssets: PHFetchResult<PHAsset>!
    var burstArray = [PHAsset]()
    var thumbnails = [UIImage]()
    var highresPhotos = [UIImage]()
    let thumbnailManager = PHCachingImageManager()
    let highresManager = PHCachingImageManager()
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    var widthPerItem: CGFloat = 200
    fileprivate let itemsPerRow: CGFloat = 2
    
    @IBOutlet weak var burstCollectionView: UICollectionView!
    var burstIdentifier: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(burstIdentifier)
        
        let burstRetrieveOptions = PHFetchOptions()
        burstRetrieveOptions.includeAllBurstAssets = true
        burstAssets = PHAsset.fetchAssets(withBurstIdentifier: burstIdentifier, options: burstRetrieveOptions)
        //debugPrint(burstAssets)
        
        let itemOptions = PHImageRequestOptions();
        itemOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat
        itemOptions.resizeMode = PHImageRequestOptionsResizeMode.fast
        itemOptions.isSynchronous = true
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        widthPerItem = availableWidth / itemsPerRow
        
        let thumbnailSize = CGSize(width: widthPerItem, height: widthPerItem);
        let highresSize = CGSize(width: burstAssets.firstObject!.pixelWidth / 4, height: burstAssets.firstObject!.pixelHeight / 4)
        
        burstAssets.enumerateObjects{(object, index, stop) -> Void in
            self.burstArray.append(object)
            self.thumbnailManager.requestImage(for: object, targetSize: thumbnailSize, contentMode: .aspectFit, options: itemOptions, resultHandler: {image, _ in
                self.thumbnails.append(image!)
            })
            
            //let highresSize = CGSize(width: object.pixelWidth / 4, height: object.pixelHeight / 4)
            self.highresManager.requestImage(for: object, targetSize: highresSize, contentMode: .aspectFit, options: itemOptions, resultHandler: {image, _ in
                self.highresPhotos.append(image!)
            })
        }
        
        //OpenCVWrapper.diffImage(highresPhotos[0], with: highresPhotos[2])
        OpenCVWrapper.analyzeForeground(onImages: highresPhotos)
        
        print("viewDidLoad finished.")
        
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

extension GroupOperationController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return thumbnails.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! GroupOperationCell
        cell.cellImage.image = thumbnails[indexPath.item]
        if burstAssets[indexPath.item].burstSelectionTypes == .autoPick {
            cell.cellLabel.text = "P"
        } else {
            cell.cellLabel.text = ""
        }
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

//
//  CollectionViewController.swift
//  Roll Cull
//
//  Created by Tiancheng Zhang on 5/6/18.
//  Copyright © 2018 Tiancheng Zhang. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "Cell"

class GroupOverviewController: UICollectionViewController {
    
    fileprivate let cellIdentifier = "burstCell"
    fileprivate let segueIdentifier = "burstOperationSegue"
    var allPhotos: PHFetchResult<PHAsset>!
    var burstSets = [PHAsset]()
    let imageManager = PHCachingImageManager()
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    var widthPerItem: CGFloat = 0
    var burstIdentifierToPass = ""
    
    fileprivate let itemsPerRow: CGFloat = 2

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(BurstOverviewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        print("Burst preview loaded.")
        
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        allPhotos.enumerateObjects{(object, index, stop) -> Void in
            if object.representsBurst {
                self.burstSets.append(object)
            }
        }
        print(burstSets.count)
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        widthPerItem = availableWidth / itemsPerRow

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! GroupOperationController
        destinationVC.burstIdentifier = burstIdentifierToPass
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let destinationVC = GroupOperationController()
        destinationVC.burstIdentifier = burstSets[indexPath.item].burstIdentifier!
        burstIdentifierToPass = burstSets[indexPath.item].burstIdentifier!
        self.performSegue(withIdentifier: segueIdentifier, sender: self)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return burstSets.count;
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! GroupOverviewCell
        
        // Configure the cell
        let imageSize = CGSize(width: widthPerItem, height: widthPerItem);
        var itemOptions = PHImageRequestOptions();
        itemOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat;
        imageManager.requestImage(for: burstSets[indexPath.item], targetSize: imageSize, contentMode: .aspectFit, options: itemOptions, resultHandler: {image, _ in
            print(indexPath.item)
            print(self.burstSets[indexPath.item])
            cell.cellImage.image = image;
            let burstRetrieveOptions = PHFetchOptions()
            burstRetrieveOptions.includeAllBurstAssets = true
            let currentBursts = PHAsset.fetchAssets(withBurstIdentifier: self.burstSets[indexPath.item].burstIdentifier!, options: burstRetrieveOptions)
            print(currentBursts.count)
            cell.countLabel.text = String(currentBursts.count)
        })
        
        return cell
    }
    /*
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        <#code#>
    }
*/
    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}

// Code lifted from https://www.raywenderlich.com/136159/uicollectionview-tutorial-getting-started
extension GroupOverviewController : UICollectionViewDelegateFlowLayout {
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

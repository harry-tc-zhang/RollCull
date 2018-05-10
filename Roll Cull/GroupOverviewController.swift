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
    var locationSets = [String:[PHAsset]]()
    var locationKeys = [String]()
    let imageManager = PHCachingImageManager()
    fileprivate let sectionInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    var widthPerItem: CGFloat = 0
    var locOfGroupToPass: String = ""
    let locRoundPower: Double = 100
    
    fileprivate let itemsPerRow: CGFloat = 2
    
    func loadPhotoData () {
        locationSets.removeAll()
        locationKeys.removeAll()
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        allPhotos.enumerateObjects{(object, index, stop) -> Void in
            if let cdate = object.creationDate {
                let interval = cdate.timeIntervalSinceNow
                if (-interval) / (24 * 60 * 60) > 30 {
                    stop.pointee = true
                }
            }
            if let loc = object.location {
                let roughLat = Double(round(loc.coordinate.latitude * self.locRoundPower) / self.locRoundPower)
                let roughLong = Double(round(loc.coordinate.longitude * self.locRoundPower) / self.locRoundPower)
                var roughDays = 0
                if let cdate = object.creationDate {
                    roughDays = Int(round((-cdate.timeIntervalSinceNow) / (24 * 60 * 60)))
                }
                let roughLocStr = "lat\(roughLat)long\(roughLong)day\(roughDays)"
                if self.locationSets[roughLocStr] != nil {
                    self.locationSets[roughLocStr]!.append(object)
                } else {
                    self.locationSets[roughLocStr] = [object]
                    self.locationKeys.append(roughLocStr)
                }
            }
        }
        collectionView?.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        //self.collectionView!.register(BurstOverviewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
        print("Burst preview loaded.")
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        widthPerItem = availableWidth / itemsPerRow

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadPhotoData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! GroupOperationController
        destinationVC.assetGroup = locationSets[locOfGroupToPass]!;
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        locOfGroupToPass = locationKeys[indexPath.item]
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
        return locationSets.count;
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! GroupOverviewCell
        
        // Configure the cell
        let imageSize = CGSize(width: widthPerItem, height: widthPerItem);
        let itemOptions = PHImageRequestOptions();
        itemOptions.deliveryMode = PHImageRequestOptionsDeliveryMode.highQualityFormat;
        imageManager.requestImage(for: locationSets[locationKeys[indexPath.item]]![0], targetSize: imageSize, contentMode: .aspectFill, options: itemOptions, resultHandler: {image, _ in
            //print(self.burstSets[indexPath.item])
            cell.cellImage.image = image;
            cell.countLabel.text = String(self.locationSets[self.locationKeys[indexPath.item]]!.count)
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

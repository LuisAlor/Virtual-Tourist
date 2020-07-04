//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 26.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    var selectedPin: Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Search for photos in flicker from the selected pin
        FlickrClient.flickrGETSearchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude, completionHandler: searchFlickrPhotosHandler(photos:error:))
        
    }
    
    func searchFlickrPhotosHandler(photos: [Photo], error: Error?){
        print(photos)
//        for photo in photos{
//            FlickrClient.downloadImage(imageURL: URL(string: photo.imageURL)!, completionHandler: downloadFlickrImagesHandler(data:error:))
//        }
    }
    
    func downloadFlickrImagesHandler(data: Data?, error: Error?){
        print("Download")
    }
    
}

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
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpFetchedResultsController()
    
        if let photosFetched = fetchedResultsController.fetchedObjects{
            if !photosFetched.isEmpty{
                print("Photos already in CoreDataDatabase for this pin")
            }else{
                print("Downloading set of photos if exists")
                //Search for photos in flicker from the selected pin
                FlickrClient.flickrGETSearchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude, completionHandler: searchFlickrPhotosHandler(photos:error:))
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setUpFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        fetchedResultsController = nil
    }
    
    /// Configures the Fetch Results controller to get saved photos
    fileprivate func setUpFetchedResultsController() {
        //Fetch Request Setup
        let fetchRequest: NSFetchRequest<FlickrPhoto> = FlickrPhoto.fetchRequest()
        
        // The %@ is replaced in runtime to the current Pin
        let predicate = NSPredicate(format: "pin == %@", selectedPin)
        fetchRequest.predicate = predicate
        
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
    
        try? fetchedResultsController.performFetch()
    }

    ///Downloads all the pictures that were obtained through Flickr API response.
    func searchFlickrPhotosHandler(photos: [Photo], error: Error?){
        print(photos)
        if !photos.isEmpty{
            for photo in photos{
                FlickrClient.downloadImage(imageURL: URL(string: photo.imageURL)!, completionHandler: downloadFlickrImagesHandler(data:error:))
                print("Downloading Image")
            }
        }else{
            print("No images were saved/found")
        }
    }
    
    ///Handles the downloaded image and saves in CoreData DB
    func downloadFlickrImagesHandler(data: Data?, error: Error?){
        let imageToSave = FlickrPhoto(context: CoreDataController.shared.viewContext)
        if let data = data {
            //Set the imageFile to the picture downloaded
            imageToSave.imageFile = data
            //Select to what pin this image corresponds
            imageToSave.pin = selectedPin
            //Save to coreData DB
            CoreDataController.shared.saveViewContext()
        }
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
    
    
}

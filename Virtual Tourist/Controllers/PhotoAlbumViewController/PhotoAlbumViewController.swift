//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 26.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var newCollection: UIButton!
    @IBOutlet weak var activityViewIndicator: UIActivityIndicatorView!
    @IBOutlet weak var noImagesLabel: UILabel!
    
    var selectedPin: Pin!
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    var photosURL: [Photo] = []
    var blockOperations: [BlockOperation] = []
    var flickrPhotos = [FlickrPhoto]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
        setupFetchedResultsController()
        setupMapView()
                
        //Hide activity indicatory when stops
        activityViewIndicator.hidesWhenStopped = true
        noImagesLabel.isHidden = true
        
        if !checkPinHasAlbum() {
            activityViewIndicator.startAnimating()
            newCollection.isEnabled = false
            FlickrClient.flickrGETSearchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
        }else{
            if let objects = fetchedResultsController.fetchedObjects{
                flickrPhotos = objects
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setupFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        fetchedResultsController = nil
    }
    
    ///Configures the Fetch Results controller to get saved photos.
    fileprivate func setupFetchedResultsController() {
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
    
    ///Checks if th pin already contains an album from the persistent store.
    func checkPinHasAlbum() -> Bool {
        if let photosFetched = fetchedResultsController.fetchedObjects{
            if !photosFetched.isEmpty{
                return true
            }
        }
        return false
    }
    
    ///Sets photosURL to the ones obtained by flickr API, and reloads the collectionView to activate placeholder images.
    func getFlickrImagesURL(photos: [Photo], error: Error?){
        
        if error == nil {
            if photos.count != 0 {
                self.noImagesLabel.isHidden = true
                for photo in photos {
                    // Sometime the image may not contain imageURL, if so do not append!
                    if photo.imageURL != nil {
                        let image = FlickrPhoto(context: CoreDataController.shared.viewContext)
                        image.pin = self.selectedPin
                        flickrPhotos.append(image)
                        self.photosURL.append(photo)
                    }
                }
            } else {
                self.noImagesLabel.isHidden = false
                self.newCollection.isEnabled = true
            }
        }
        self.collectionView.reloadData()
        CoreDataController.shared.saveViewContext()
        activityViewIndicator.stopAnimating()
    }
    
    ///Configures MapView Region and Add Saved Pin as annotation.
    func setupMapView(){
        
        //Set mapView delegate to PhotoAlbumViewController
        mapView.delegate = self
    
        var annotations = [MKPointAnnotation]()
                       
        let lat = CLLocationDegrees(selectedPin.latitude)
        let long = CLLocationDegrees(selectedPin.longitude)
                   
        // The lat and long to create a CLLocationCoordinates2D instance.
        let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                   
        // Here we create the annotation and set its coordiate, title, and subtitle properties
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
       
        // Place the annotation in an array of annotations.
        annotations.append(annotation)
        
        // When the array is complete, add the annotations to the map.
        self.mapView.addAnnotations(annotations)
        
        //Set map region for our pin
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)

    }
    
    ///Configures the CollectionFlowLayout and sets delegation and datasource for the CollectionView
    fileprivate func setupCollectionView() {
          collectionView.delegate = self
          collectionView.dataSource = self
          setCollectionFlowLayout()
      }
    
    ///Configures the CollectionView Flow layout for our items to fit accoarding to its content.
    func setCollectionFlowLayout() {
        
        let items: CGFloat = view.frame.size.width > view.frame.size.height ? 5.0 : 3.0
        let space: CGFloat = 1.0
        let dimension = (view.frame.size.width - ((items + 1) * space)) / items
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumLineSpacing = 8.0 - items
        layout.minimumInteritemSpacing = space
        layout.itemSize = CGSize(width: dimension, height: dimension)
        
        collectionView.collectionViewLayout = layout
    }
    
    ///Gets a new collection of photos (deletes previous ones from persistent store).
    @IBAction func getNewCollection(_ sender: UIButton?){
        
        flickrPhotos = []
        photosURL = []
    
        if let  objects = fetchedResultsController.fetchedObjects{
            for object in objects{
                CoreDataController.shared.viewContext.delete(object)
            }
            CoreDataController.shared.saveViewContext()
            FlickrClient.flickrGETSearchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
        }
    }
}

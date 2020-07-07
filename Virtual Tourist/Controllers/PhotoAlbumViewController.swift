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
    
    var selectedPin: Pin!
    var fetchedResultsController: NSFetchedResultsController<FlickrPhoto>!
    var imagesURL: [Photo] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //Set mapView delegate to PhotoAlbumViewController
        mapView.delegate = self
        
        setupFetchedResultsController()
        setupMapView()
        
        if !checkPinHasAlbum() {
            FlickrClient.flickrGETSearchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
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
    
    /// Configures the Fetch Results controller to get saved photos
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
    
    func checkPinHasAlbum() -> Bool {
        if let photosFetched = fetchedResultsController.fetchedObjects{
            if !photosFetched.isEmpty{
                return true
            }
        }
        return false
    }
    
    func getFlickrImagesURL(photos: [Photo], error: Error?){
        if error == nil {
            
            self.imagesURL = photos
            self.collectionView.reloadData()
            
            if !photos.isEmpty{
                for photo in photos{
                    FlickrClient.downloadImage(imageURL: URL(string: photo.imageURL)!, completionHandler: downloadFlickrImagesHandler(data:error:))
                }
            }else{
                //TO-DO Add label for showing no images were found
                print("No images were saved/found")
                newCollection.isEnabled = true
            }
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
    
    ///Configures MapView Region and Add Saved Pin as annotation.
    func setupMapView(){
    
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
    
    @IBAction func getNewCollection(_ sender: UIButton?){
        //TO-DO
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{


    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                collectionView.insertItems(at: [newIndexPath])
            }
        case .delete:
            if let indexPath = indexPath{
                collectionView.deleteItems(at: [indexPath])
            }
        case .move, .update:
            break
    
        @unknown default:
            break
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if checkPinHasAlbum() {
            return fetchedResultsController.sections?[section].numberOfObjects ?? 0
        } else {
            return imagesURL.count
        }
    }
    
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
        if checkPinHasAlbum() {
            let object = fetchedResultsController.object(at: indexPath)
            if let flickrPhoto = object.imageFile {
                cell.imageView.image = UIImage(data: flickrPhoto)
            }
        } else {
            cell.imageView.image = UIImage(named: "photo_placeholder")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Select from indexPath which object from CollectionView should be deleted from persistent store
        let objectToDelete = fetchedResultsController.object(at: indexPath)
        CoreDataController.shared.viewContext.delete(objectToDelete)
    }
        
}

extension PhotoAlbumViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //Name our reusable pin ID
        let reuseId = "pin"
        //Dequee for any free annotaion view with reuseId
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        //If no pin exist create one and setup
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .blue

        } else {
            //If there is set it as our annotation
            pinView!.annotation = annotation
        }
        return pinView
    }
    
}

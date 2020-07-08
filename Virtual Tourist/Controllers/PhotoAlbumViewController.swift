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
                    let image = FlickrPhoto(context: CoreDataController.shared.viewContext)
                    image.pin = self.selectedPin
                    flickrPhotos.append(image)
                    self.photosURL.append(photo)
                }
            } else {
                self.noImagesLabel.isHidden = false
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
        if let  objects = fetchedResultsController.fetchedObjects{
            for object in objects{
                CoreDataController.shared.viewContext.delete(object)
            }
            CoreDataController.shared.saveViewContext()

            FlickrClient.flickrGETSearchPhotos(lat: selectedPin.latitude, lon: selectedPin.longitude, completionHandler: getFlickrImagesURL(photos:error:))
        }
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate{
        
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        if type == NSFetchedResultsChangeType.insert {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertItems(at: [newIndexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadItems(at: [indexPath!])
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.move {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.moveItem(at: indexPath!, to: newIndexPath!)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteItems(at: [indexPath!])
                    }
                })
            )
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
        if type == NSFetchedResultsChangeType.insert {
            
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.update {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
        else if type == NSFetchedResultsChangeType.delete {
            blockOperations.append(
                BlockOperation(block: { [weak self] in
                    if let this = self {
                        this.collectionView!.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                    }
                })
            )
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView!.performBatchUpdates({ () -> Void in
                for operation: BlockOperation in self.blockOperations {
                    operation.start()
                }
            }, completion: { (finished) -> Void in
                self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource{
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return flickrPhotos.count
    }
        
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCollectionViewCell", for: indexPath) as! PhotoCollectionViewCell
            
        if flickrPhotos[indexPath.row].imageFile != nil {
            cell.imageView.image = UIImage(data: flickrPhotos[indexPath.row].imageFile!)
        } else {
            cell.imageView.image = UIImage(named: "photo_placeholder")
            DispatchQueue.main.async {
                    FlickrClient.downloadImage(imageURL: URL(string: self.photosURL[indexPath.row].imageURL)!) { (data, error) in
                        if let data = data {
                            cell.imageView.image = UIImage(data: data)
                            self.flickrPhotos[indexPath.row].imageFile = data
                            CoreDataController.shared.saveViewContext()
                        }
                    }
                }
            }
            return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //Select from indexPath which object from CollectionView should be deleted from persistent store
        let objectToDelete = fetchedResultsController.object(at: indexPath)
        flickrPhotos.remove(at: indexPath.row)
        CoreDataController.shared.viewContext.delete(objectToDelete)
        CoreDataController.shared.saveViewContext()
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

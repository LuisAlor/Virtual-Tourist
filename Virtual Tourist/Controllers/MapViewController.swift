//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 25.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, UIGestureRecognizerDelegate, NSFetchedResultsControllerDelegate {
    
    //IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpFetchedResultsController()
        setupMapView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //Hide NavigationBar from MapView
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //Show NavigationBar when the viewWillDisappear
        navigationController?.setNavigationBarHidden(false, animated: animated)
        fetchedResultsController = nil
    }
    
    /// Setups map with gestures and restores user's region if available
    fileprivate func setupMapView() {
        //Set MapView's delegate
        self.mapView.delegate = self
        //Create a UITapGestureRecognizer
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        //Add gestureRecognizer to the mapView
        mapView.addGestureRecognizer(gestureRecognizer)
        //Disable map rotation, it is kind of annoying and not relevant feature for this app.
        mapView.isRotateEnabled = false
        //Set gestureRecognizer delegate to MapViewController
        gestureRecognizer.delegate = self
        //Check if there is a mapUserRegion saved in UserDefaults and if there are pins stored generate the corresponding annotations
        if let region = getMapRegion(), let pins = fetchedResultsController.fetchedObjects {
            mapView.setRegion(region, animated: true)
            generateAnnotations(pins)
        }
    }
    
    /// Setups the fetch Results controller to get our pins
    fileprivate func setUpFetchedResultsController() {
        //Fetch Request Setup
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch{
            print("Error in fecthing")
        }
    }
    
    ///Handles tap gestures and generatea an annotation on the MapView.
    @objc func handleTapGesture(_ gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .ended {
            let location = gestureRecognizer.location(in: self.mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: self.mapView)

            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            self.mapView.addAnnotation(annotation)
            
            let pin = Pin(context: CoreDataController.shared.viewContext)
            pin.latitude = coordinate.latitude
            pin.longitude = coordinate.longitude
            CoreDataController.shared.saveViewContext()
        }
    }
    
    ///Gets the user's map region if exists in UserDefaults database
    func getMapRegion() -> MKCoordinateRegion? {
        if let userMapRegion = UserDefaults.standard.dictionary(forKey: "userMapRegion"){
            let userCenter = CLLocationCoordinate2D(latitude: userMapRegion["latitude"] as! CLLocationDegrees, longitude: userMapRegion["longitude"] as! CLLocationDegrees)
            let userSpan = MKCoordinateSpan(latitudeDelta: userMapRegion["delta_latitude"] as! CLLocationDegrees, longitudeDelta: userMapRegion["delta_longitude"] as! CLLocationDegrees)
            return MKCoordinateRegion(center: userCenter, span: userSpan)
        }
        return nil
    }
    
    ///Generates all the annotations from saved Pins
    func generateAnnotations(_ pins: [Pin]){
        
        var annotations = [MKPointAnnotation]()
               
        for pin in pins {
           
            let lat = CLLocationDegrees(pin.latitude)
            let long = CLLocationDegrees(pin.longitude)
                       
            // The lat and long to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                       
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
           
            // Place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        // When the array is complete, add the annotations to the map.
        self.mapView.addAnnotations(annotations)
    }
    
    /// Saves user current  center and span to UserDefaults database
    func saveUserRegion(_ mapRegion: MKCoordinateRegion?){
        if let mapRegion = mapRegion {
            let userMapRegion = ["latitude": mapRegion.center.latitude,
                                 "longitude": mapRegion.center.longitude,
                                 "delta_latitude": mapRegion.span.latitudeDelta,
                                 "delta_longitude": mapRegion.span.longitudeDelta]
            UserDefaults.standard.set(userMapRegion, forKey: "userMapRegion")
        }
    }
}
//MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        //Name our reusable pin ID
        let reuseId = "pin"
        //Dequee for any free annotaion view with reuseId
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        //If no pin exist create one and setup
        if pinView == nil{
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.tintColor = UIColor.blue
            pinView!.animatesDrop = true
        } else {
            //If there is set it as our annotation
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        //Deselect the actual annotation for being able to select it after pressing back.
        mapView.deselectAnnotation(view.annotation, animated: true)
        let photoAlbumViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        if let selectedPinLat = view.annotation?.coordinate.latitude,
            let selectedPinLon = view.annotation?.coordinate.longitude, let pins = fetchedResultsController.fetchedObjects{
            for pin in pins{
                //Pins needs to be fetched for having the newest
                if pin.latitude == selectedPinLat && pin.longitude == selectedPinLon{
                    photoAlbumViewController.selectedPin = pin
                }else{
                    print("No pins matched")
                }
            }
        }
    
        
        self.navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //If the region changed then save this to keep data persistent.
        saveUserRegion(mapView.region)
    }

}


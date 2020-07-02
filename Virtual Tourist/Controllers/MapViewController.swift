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
        
        //Set MapView's delegate
        self.mapView.delegate = self
        
        //Create a UITapGestureRecognizer
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        //Add gestureRecognizer to the mapView
        mapView.addGestureRecognizer(gestureRecognizer)
        //Set gestureRecognizer delegate to MapViewController
        gestureRecognizer.delegate = self
        
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        }
        catch{
            print("Error in fecthing")
        }
        
        if let pins = fetchedResultsController.fetchedObjects{
            generateAnnotations(pins)
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
            pin.latitude = coordinate.latitude.magnitude
            pin.longitude = coordinate.longitude.magnitude
            CoreDataController.shared.saveViewContext()
        }
    }
    
    //MARK: - generateAnnotations: Generate all the annotations from the StudentsLocation Data
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
        //TO DO
    }
}


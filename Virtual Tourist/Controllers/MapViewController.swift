//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 25.06.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //IBOutlets
    @IBOutlet weak var mapView: MKMapView!
    
    //Data Controller Injected to MapViewController
    var coreDataController: CoreDataController!
    
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
            
            FlickrClient.flickrGETSearchPhotos(lat: coordinate.latitude, lon: coordinate.longitude) { (Photos, error) in
                print(Photos)
            }
            
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
        let photoAlbumViewController = storyboard?.instantiateViewController(identifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumViewController.coreDataController = coreDataController
        performSegue(withIdentifier: "SegueToPhotoAlbumViewController", sender: self)
    }
    
    
}


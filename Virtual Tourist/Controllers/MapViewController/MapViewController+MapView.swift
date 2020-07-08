//
//  MapViewController+MapView.swift
//  Virtual Tourist
//
//  Created by Luis Angel Vazquez Alor on 08.07.2020.
//  Copyright © 2020 Luis Angel Vazquez Alor. All rights reserved.
//

import Foundation
import MapKit

extension MapViewController: MKMapViewDelegate{
    
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
                
        //Deselect the actual annotation for being able to select it after pressing back.
        mapView.deselectAnnotation(view.annotation, animated: true)
                        
        let photoAlbumViewController = UIStoryboard.init(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        
        if let selectedPinLat = view.annotation?.coordinate.latitude,
            let selectedPinLon = view.annotation?.coordinate.longitude, let pins = fetchedResultsController.fetchedObjects{
            for pin in pins{
                if pin.latitude == selectedPinLat && pin.longitude == selectedPinLon{
                    photoAlbumViewController.selectedPin = pin
                }
            }
            self.navigationController?.pushViewController(photoAlbumViewController, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //If the region changed then save this to keep data persistent.
        saveUserRegion(mapView.region)
    }
    
}

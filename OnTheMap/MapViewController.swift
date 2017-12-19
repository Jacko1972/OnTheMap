//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 14/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var pointAnnotations = [MKPointAnnotation]()
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            if OnTheMapClass.sharedInstance.studentLocations.count > 0 {
                loadAnnotations()
            }
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            if OnTheMapClass.sharedInstance.studentLocations.count > 0 {
                loadAnnotations()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.title = "On The Map"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(loadAnnotations), name: NSNotification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
        checkLocationAuthorizationStatus()
    }
    
    @objc func loadAnnotations() {
        if OnTheMapClass.sharedInstance.studentLocations.count > 0 {
            for record in OnTheMapClass.sharedInstance.studentLocations {
                let location = CLLocationCoordinate2D(latitude: record.latitude!, longitude: record.longitude!)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = record.getFullName()
                annotation.subtitle = record.mediaURL
                pointAnnotations.append(annotation)
            }
        } else {
            displayAlert(title: "No Data!", msg: "No locations have been retrieved from the app to display!")
        }
        if pointAnnotations.count > 0 {
            mapView.addAnnotations(pointAnnotations)
        }
        if mapView.userLocation.location == nil {
            setRegion(center: CLLocationCoordinate2D(latitude: pointAnnotations[0].coordinate.latitude, longitude: pointAnnotations[0].coordinate.longitude))
        } else {
            setRegion(center: CLLocationCoordinate2D(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude))
        }
    }
    
    func setRegion(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 4, longitudeDelta: 4))
        mapView.setRegion(region, animated: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        var onTheMapPin = mapView.dequeueReusableAnnotationView(withIdentifier: "OnTheMapPin") as? MKPinAnnotationView
        if onTheMapPin == nil {
            onTheMapPin = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "OnTheMapPin")
            onTheMapPin!.canShowCallout = true
            onTheMapPin!.pinTintColor = UIColor.red
            onTheMapPin!.rightCalloutAccessoryView = UIButton(type: UIButtonType.detailDisclosure)
        }
        return onTheMapPin
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let onTheMapPin = view.annotation as? MKPointAnnotation else {
            return
        }
        if UIApplication.shared.canOpenURL(URL.init(string: onTheMapPin.subtitle!)!) {
            UIApplication.shared.open(URL(string: onTheMapPin.subtitle!)!, options: [:], completionHandler: nil)
        } else {
            displayAlert(title: "Invalid URL", msg: "Could not open the URL provided by API.")
        }
    }
}

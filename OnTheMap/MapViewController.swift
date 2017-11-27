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
    var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    var pointAnnotations = [MKPointAnnotation]()
    
    func checkLocationAuthorizationStatus() {
        print("checkStatus")
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            print("authorised")
            mapView.showsUserLocation = true
            if appDelegate.studentLocations.count > 0 {
                print("count: \(appDelegate.studentLocations.count)")
                loadAnnotations()
            }
        } else {
            print("requestMade")
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("statusUpdated")
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            if appDelegate.studentLocations.count > 0 {
                loadAnnotations()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.title = "On The Map"
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(loadAnnotations), name: NSNotification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
        checkLocationAuthorizationStatus()
    }
    
    @objc func loadAnnotations() {
        
        print("loadAnnotations count: \(appDelegate.studentLocations.count)")
        if appDelegate.studentLocations.count > 0 {
            for record in appDelegate.studentLocations {
                let location = CLLocationCoordinate2D(latitude: record.latitude!, longitude: record.longitude!)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = record.firstName! + " " + record.lastName!
                annotation.subtitle = record.mediaURL
                pointAnnotations.append(annotation)
            }
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
        let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
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
            print("error")
            return
        }
        UIApplication.shared.open(URL(string: onTheMapPin.subtitle!)!, options: [:], completionHandler: nil)
    }
}

//
//  LocationConfirmationViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 04/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class LocationConfirmationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var finishButton: UIButton!
    let locationManager = CLLocationManager()
    var mapItem: MKMapItem?
    var link: String?
    
    @IBAction func finishAction(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
//        guard let mapItem = mapItem else {
//            displayAlert(title: "Missing Map Item", msg: "Map Item not stored to pass to Udacity API!")
//            return
//        }
//        guard let link = link else {
//            displayAlert(title: "Information Missing", msg: "No Link was passed from previous View!")
//            return
//        }
//        OnTheMapClient.sharedInstance().sendInformationToUdacityApi(mapItem, link) { (response, error) in
//            if error != nil {
//                self.displayAlert(title: "Error From Update", msg: "An Error was returned on update: \(error?.localizedDescription ?? "Missing Error")")
//                return
//            }
//            if response {
//
//            } else {
//                self.displayAlert(title: "Update Failed", msg: "Update sent but failed!")
//            }
//        }
    }
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            if mapItem != nil {
                loadPlaceMarks()
            }
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            if mapItem != nil {
                loadPlaceMarks()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        self.navigationItem.title = "Confirm Location"
        checkLocationAuthorizationStatus()
    }
    
    func loadPlaceMarks() {
        if mapItem != nil {
            mapView.addAnnotation((mapItem?.placemark)!)
        } else {
            displayAlert(title: "Missing Map Item", msg: "An error occurred where no Map Item is available!")
        }
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
        }
        return onTheMapPin
    }
}
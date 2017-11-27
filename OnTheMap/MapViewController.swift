//
//  MapViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 14/11/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    let locationManager = CLLocationManager()
    var studentLocations: [StudentInformation] = [StudentInformation]()
    var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
            let center = CLLocationCoordinate2D(latitude: mapView.userLocation.coordinate.latitude, longitude: mapView.userLocation.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02))
            mapView.setRegion(region, animated: true)
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        navigationItem.title = "On The Map"
        if appDelegate.studentLocations.count > 0 {
            studentLocations = appDelegate.studentLocations
            loadAnnotations()
        }
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(loadAnnotations), name: NSNotification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
        checkLocationAuthorizationStatus()
    }

    @objc func loadAnnotations() {
        print("loadMapView")
        if studentLocations.count > 0 {
            for record in studentLocations {
                let location = CLLocationCoordinate2D(latitude: record.latitude!, longitude: record.longitude!)
                let annotation = MKPointAnnotation()
                annotation.coordinate = location
                annotation.title = record.firstName! + " " + record.lastName!
                annotation.subtitle = record.mediaURL
                mapView.addAnnotation(annotation)
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "StudentLocationsDownloaded"), object: nil)
    }

}

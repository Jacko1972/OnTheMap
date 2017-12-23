//
//  LocationConfirmationViewController.swift
//  OnTheMap
//
//  Created by Andrew Jackson on 04/12/2017.
//  Copyright © 2017 Jacko1972. All rights reserved.
////

import UIKit
import MapKit
import CoreLocation

class LocationConfirmationViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var finishButton: UIButton!
    let locationManager = CLLocationManager()
    var mapItem: MKMapItem?
    var link: String?
    let reachability = Reachability()!
    
    @IBAction func finishAction(_ sender: UIButton) {
        
        guard let name = mapItem?.name else {
            displayAlert(title: "Missing Map Name", msg: "Name not stored to pass to Udacity API!")
            return
        }
        guard let latitude = mapItem?.placemark.coordinate.latitude, let longitude = mapItem?.placemark.coordinate.longitude else {
            displayAlert(title: "Information Missing", msg: "No Location coordinates stored to pass to Udacity API!")
            return
        }
        guard let link = link else {
            displayAlert(title: "Information Missing", msg: "No Link was passed from previous View!")
            return
        }
        guard let key = OnTheMapClass.sharedInstance.postSession?.account.key else {
            displayAlert(title: "Missing Information", msg: "Missing Unique Key for information!")
            return
        }
        guard let first_name = OnTheMapClass.sharedInstance.studentPublicInformation?.first_name, let last_name = OnTheMapClass.sharedInstance.studentPublicInformation?.last_name else {
            displayAlert(title: "Missing Information", msg: "Missing First or Last Name from Personal Information Object!")
            return
        }
        
        let locationInfo = LocationInformation(uniqueKey: key, firstName: first_name, lastName: last_name, mapString: name,
                                               mediaURL: link, latitude: latitude, longitude: longitude)
        toggleActivityIndicator(true)
        OnTheMapClient.instance.sendInformationToUdacityApi(locationInfo) { (response, error) in
            if error != nil {
                DispatchQueue.main.async {
                    self.displayAlert(title: "Error From Update", msg: "An Error was returned on update: \(error?.localizedDescription ?? "Missing Error")")
                    self.toggleActivityIndicator(false)
                }
                return
            }
            if response {
                OnTheMapClient.instance.downloadStudentInformation() { (success, error) in
                    DispatchQueue.main.async {
                        self.toggleActivityIndicator(false)
                        if success {
                            self.dismiss(animated: true, completion: nil)
                        } else {
                            self.displayAlert(title: "Information Download Error",
                                              msg: "Domain: \(String(describing: error!.domain)). The system returned the following error: \(String(describing: error!.localizedDescription))")
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.toggleActivityIndicator(false)
                    self.displayAlert(title: "Update Failed", msg: "Update sent but failed!")
                }
            }
        }
    }
    
    func toggleActivityIndicator(_ animate: Bool) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = animate
        finishButton.isHidden = animate
        animate ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
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
        finishButton.setTitle("FINISH", for: .normal)
        finishButton.setTitle("No Internet", for: .disabled)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(networkStatusChanged(_:)), name: .reachabilityChanged, object: reachability)
        do {
            try reachability.startNotifier()
        } catch {
            print("could not start reachability notifier")
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability.stopNotifier()
        NotificationCenter.default.removeObserver(self, name: .reachabilityChanged, object: reachability)
    }
    
    @objc func networkStatusChanged(_ notification: Notification) {
        let reachability = notification.object as! Reachability
        switch reachability.connection {
        case .none:
            allowInternetActions(false)
        default:
            allowInternetActions(true)
        }
    }
    
    func allowInternetActions(_ available: Bool) -> Void {
        finishButton.isEnabled = available
    }
    
    func loadPlaceMarks() {
        if mapItem != nil {
            mapView.addAnnotation((mapItem?.placemark)!)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: (mapItem?.placemark.coordinate.latitude)!, longitude: (mapItem?.placemark.coordinate.longitude)!), span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2))
            mapView.setRegion(region, animated: true)
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

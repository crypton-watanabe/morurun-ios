//
//  MapViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/08.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import MapKit
import MKMapViewZoom

class MapViewController: UIViewController, MKMapViewDelegate {
    
    private let latitude: Double
    private let longitude: Double
    private let location: Location?
    @IBOutlet weak var mapView: MKMapView!
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    init(latitude: Double, longitude: Double, locationId: String) {
        self.location = Location.objects(where: "location_id = %@", locationId).firstObject() as? Location
        if let location = self.location {
            self.latitude = location.latitude
            self.longitude = location.longitude
        }
        else {
            self.latitude = latitude
            self.longitude = longitude
        }
        
        super.init(nibName: R.nib.mapViewController.name, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let coordinate = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        self.mapView.setCenter(coordinate, zoomLevel: 14, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        annotation.title = self.location?.name
        self.mapView.addAnnotation(annotation)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationId = "annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationId)
        if annotationView == nil {
            let pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationId)
            pinAnnotationView.pinTintColor = UIColor.red
            pinAnnotationView.animatesDrop = true
            if let _ = self.location {
                pinAnnotationView.canShowCallout = true
                pinAnnotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            annotationView = pinAnnotationView
        }
        return annotationView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        UIApplication.shared.openURL(self.location!.contentsUrl!)
    }
}

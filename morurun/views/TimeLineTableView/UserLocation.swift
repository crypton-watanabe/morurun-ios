//
//  UserLocation.swift
//  morurun
//
//  Created by watanabe on 2016/11/08.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import MapKit
import RxSwift
import RxCocoa

class UserLocation: NSObject, CLLocationManagerDelegate {
    
    private let locationManager = CLLocationManager()
    let currentLocation = Variable<CLLocation?>(nil)
    let isInMuroran = Variable<Bool>(false)
    
    override init() {
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 10_000 // 10km
    }
    
    func startTracking() {
        self.locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
        case .denied: break
            // TODO:
        default: break
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // TODO:
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        manager.stopUpdatingLocation()
        
        self.currentLocation.value = locations.first
        
        CLGeocoder().reverseGeocodeLocation(locations.last!) {placemarks, error in
            guard let placemarkLocality = placemarks?.last?.locality as NSString? else { return }
            
            let inMuroran = placemarkLocality.contains("室蘭") || placemarkLocality.lowercased.contains("muroran")
            self.isInMuroran.value = inMuroran
        }
    }
}

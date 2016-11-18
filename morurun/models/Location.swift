//
//  Location.swift
//  morurun
//
//  Created by watanabe on 2016/11/09.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import Realm
import RxSwift
import RxAlamofire

fileprivate let latitudeMeterParDegree = 0.000008983148616
fileprivate let longitudeMeterParDegree = 0.000010966382364

class Location: RLMObject {
    
    override class func primaryKey() -> String {
        return "location_id"
    }
    
    override class func indexedProperties() -> [String] {
        return ["location_id"]
    }
    
    dynamic var location_id = ""
    dynamic var name = ""
    dynamic var information = ""
    dynamic var url = ""
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    
    var contentsUrl: URL? {
        get {
            return URL(string: self.url)
        }
    }
    
    var distance: Int? {
        get {
            guard let currentLocation = AppDelegate.shared.userLocation.currentLocation.value else {
                return nil
            }
            let latm = abs(currentLocation.coordinate.latitude - self.latitude) / latitudeMeterParDegree
            let lonm = abs(currentLocation.coordinate.longitude - self.longitude) / longitudeMeterParDegree
            return Int(sqrt(pow(latm, 2.0) + pow(lonm, 2.0)))
        }
    }
}

extension Reactive where Base: Location {
    
    static func requestGetLocation() -> Observable<[AnyHashable:Any]> {
        return Observable.create { observer in
            
            guard var request = try? urlRequest(.get, URLManager.shared.getLocations) else {
                observer.onError(RegistrationDialogViewModel.Error.requestGenerateError)
                return Disposables.create {}
            }
            request.timeoutInterval = Bundle.main.infoDictionary!["RequestTimeoutInterval"] as! Double
            
            let disposable = URLSession.shared
                .rx
                .json(request: request)
                .asObservable()
                .subscribe(
                    onNext: { response in
                        if let json = response as? [AnyHashable : Any], let jsonArray = json["location"] as? [[AnyHashable:Any]] {
                            jsonArray.forEach { observer.onNext($0) }
                            observer.onCompleted()
                        }
                        else {
                            observer.onError(RegistrationDialogViewModel.Error.deserializationError)
                        }
                },
                    onError: { error in
                        observer.onError(error)
                },
                    onCompleted: nil,
                    onDisposed: nil)
            
            return Disposables.create { disposable.dispose() }
        }
    }
    
    static func updateLocation() -> Observable<Location> {
        
        return Observable.create { observer in
            let disposable = self.requestGetLocation()
                .observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { json in
                        do {
                            let realm = RLMRealm.default()
                            try realm.transaction { error in
                                let location = Location.createOrUpdate(in: realm, withValue: json)
                                observer.onNext(location)
                            }
                        }
                        catch let err {
                            observer.onError(err)
                        }
                },
                    onError: { error in
                        observer.onError(error)
                },
                    onCompleted: {
                         observer.onCompleted()
                },
                    onDisposed: nil)
            return Disposables.create { disposable.dispose() }
        }
    }
}

//
//  Posting.swift
//  morurun
//
//  Created by watanabe on 2016/11/01.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import Realm
import RxSwift
import RxAlamofire

class Posting: RLMObject {
    
    enum Contentstype: Int {
        case movie = 1
        case picture = 2
    }
    
    override class func primaryKey() -> String {
        return "posting_id"
    }
    override class func indexedProperties() -> [String] {
        return ["posting_id"]
    }
    
    dynamic var posting_id = 0
    dynamic var user_id = ""
    dynamic var user_nickname = ""
    dynamic var datetime = Date()
    dynamic var type_id = 0
    dynamic var comment = ""
    dynamic var url = ""
    dynamic var latitude = 0.0
    dynamic var longitude = 0.0
    dynamic var location_id = ""

    var contentsUrl: URL? {
        get {
            return URL(string: self.url)
        }
    }
    var contentsType: Contentstype {
        get {
            return Contentstype(rawValue: self.type_id)!
        }
    }
    var dateString: String {
        get {
            let today = Date()
            let interval = Int(today.timeIntervalSince(self.datetime))
            
            let hourPerTimeInterval = 60 * 60
            let dayPerTimeInterval = 24 * hourPerTimeInterval
            if interval < dayPerTimeInterval {
                let deltaHours = interval / hourPerTimeInterval
                return "\(deltaHours)時間前"
            }
            else {
                let deltaDays = interval / dayPerTimeInterval
                return "\(deltaDays)日前"
            }
        }
    }
}

extension Reactive where Base: Posting {
    
    static func requestGetPostings() -> Observable<[AnyHashable:Any]> {
        return Observable.create { observer in
            
            guard var request = try? urlRequest(.get, URLManager.shared.getPostings, parameters: ["length": 20, "beforeAt": Date()]) else {
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
                        if let json = response as? [AnyHashable : Any], let jsonArray = json["posting"] as? [[AnyHashable:Any]] {
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                            
                            for index in 0..<jsonArray.count {
                                var json = jsonArray[index]
                                json["datetime"] = dateFormatter.date(from: json["datetime"] as? String ?? "")
                                observer.onNext(json)
                            }
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
    
    static func updatePostings() -> Observable<Posting> {
        
        return Observable.create { observer in
            let disposable = self.requestGetPostings()
                .observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { json in
                        do {
                            let realm = RLMRealm.default()
                            try realm.transaction { error in
                                let posting = Posting.createOrUpdate(in: realm, withValue: json)
                                observer.onNext(posting)
                            }
                        }
                        catch let err {
                            observer.onError(err)
                        }
                },
                    onError: { error in
                        observer.onError(error)
                },
                    onCompleted: { observer.onCompleted() },
                    onDisposed: nil)
            return Disposables.create { disposable.dispose() }
        }
    }
}

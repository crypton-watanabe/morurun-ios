//
//  RegistrationDialogViewModel.swift
//  morurun
//
//  Created by watanabe on 2016/11/04.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import RxSwift
import Alamofire
import RxAlamofire

class RegistrationDialogViewModel: ReactiveCompatible {
    
    enum Error: Swift.Error {
        case validationError
        case requestGenerateError
        case deserializationError
    }
    
    fileprivate let disposeBag = DisposeBag()
    
    let nickname = Variable<String?>("")
    let isValid = Variable<Bool>(false)
    let errorMessage = Variable<String>("")
    
    init() {
        self.nickname
            .asObservable()
            .map { ($0 as NSString?)?.trimmingCharacters(in: CharacterSet.whitespaces) }
            .map { $0?.lengthOfBytes(using: String.Encoding.utf8) ?? 0 }
            .bindNext {[unowned self] length in
                if length == 0 {
                    self.errorMessage.value = ""
                    self.isValid.value = false
                }
                else if length > 50 {
                    self.errorMessage.value = NSLocalizedString("ニックネームが長すぎます。", comment: "")
                    self.isValid.value = false
                }
                else {
                    self.errorMessage.value = ""
                    self.isValid.value = true
                }
            }
            .addDisposableTo(self.disposeBag)
    }
}

extension Reactive where Base: RegistrationDialogViewModel {
    
    func requestRegistration() -> Observable<Any> {
        return Observable.create { observer in
            
            guard self.base.isValid.value else {
                observer.onError(RegistrationDialogViewModel.Error.validationError)
                return Disposables.create {}
            }
            
            var parameters = [String:Any]()
            let nickname = self.base.nickname.value!
            parameters["nickname"] = self.base.nickname.value!
            
            var uid = AppConfig.shared.uid.value
            if let uid = uid {
                parameters["uid"] = uid
            }
            guard var request = try? urlRequest(.post, URLManager.shared.setupUser, parameters: parameters) else {
                observer.onError(RegistrationDialogViewModel.Error.requestGenerateError)
                return Disposables.create {}
            }
            request.timeoutInterval = Bundle.main.infoDictionary!["RequestTimeoutInterval"] as! Double
            
            let disposable = URLSession.shared
                .rx
                .json(request: request)
                .asObservable()
                .observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { response in
                        let json = response as? [String : Any]
                        if json?["status"] as? String == "OK" {
                            uid = json?["uid"] as? String
                            observer.onNext(response)
                            observer.onCompleted()
                        }
                        else {
                            observer.onError(RegistrationDialogViewModel.Error.deserializationError)
                        }
                    },
                    onError: { error in
                        observer.onError(error)
                    },
                    onCompleted: {
                        AppConfig.shared.nickname.value = nickname
                        AppConfig.shared.uid.value = uid
                    },
                    onDisposed: nil)
            return Disposables.create { disposable.dispose() }
        }
    }
}

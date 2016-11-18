//
//  PostingViewModel.swift
//  morurun
//
//  Created by watanabe on 2016/11/06.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import AVFoundation
import Alamofire
import RxAlamofire

class PostingViewModel : ReactiveCompatible {
    
    private let disposeBag = DisposeBag()
    let comment = Variable<String?>("")
    let image = Variable<UIImage?>(nil)
    let movieUrl = Variable<URL?>(nil)
    let isValid = Variable<Bool>(false)
    let thumbnail = Variable<UIImage?>(nil)
    let errorMessage = Variable<String>("")
    let location = Variable<Location?>(nil)
    
    init() {
        
        self.image.asObservable()
            .bindTo(self.thumbnail)
            .addDisposableTo(self.disposeBag)
        
        self.movieUrl
            .asObservable()
            .map { url -> UIImage? in
                var thumbnailImage: UIImage?
                
                guard let movieUrl = url else { return nil }
                let avAsset = AVURLAsset(url: movieUrl)
                let imageGenerator = AVAssetImageGenerator(asset: avAsset)
                imageGenerator.appliesPreferredTrackTransform = true
                let ctTime = CMTime(seconds: 0.0, preferredTimescale: 30)
                if let cgImage = try? imageGenerator.copyCGImage(at: ctTime, actualTime: nil) {
                    thumbnailImage = UIImage(cgImage: cgImage)
                }
                return thumbnailImage
            }
            .subscribeOn(SerialDispatchQueueScheduler(qos: .default))
            .observeOn(MainScheduler.instance)
            .bindNext({[unowned self] image in
                assert(Thread.current.isMainThread)
                self.thumbnail.value = image
            })
            .addDisposableTo(self.disposeBag)
        
        Observable.combineLatest(self.comment.asObservable(),
                                 self.image.asObservable(),
                                 self.movieUrl.asObservable(),
                                 resultSelector:{ ($0, $1, $2) } )
            .bindNext { comment, image, url in
                if image == nil && url == nil {
                    self.isValid.value = false
                    self.errorMessage.value = NSLocalizedString("写真/動画を選択して下さい", comment: "")
                    return
                }
                let trimString = (comment as NSString?)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                let charCount = trimString?.lengthOfBytes(using: String.Encoding.utf8) ?? 0
                guard charCount > 0 else {
                    self.isValid.value = false
                    self.errorMessage.value = NSLocalizedString("コメントを入力して下さい", comment: "")
                    return
                }
                self.isValid.value = true
                self.errorMessage.value = ""
            }
            .addDisposableTo(self.disposeBag)
        
    }
}

extension Reactive where Base: PostingViewModel {
    
    private func postImage(request: URLRequest, image: UIImage) -> Observable<Float> {
        return Observable.create { observer in
            guard let data = UIImageJPEGRepresentation(image, 0.7) else {
                observer.onError(RegistrationDialogViewModel.Error.deserializationError)
                return Disposables.create {  }
            }
            
            let uploadTask = Alamofire.upload(data, with: request)
            let responseDisposable = uploadTask
                .rx
                .responseJSON()
                .subscribe(onNext: nil,
                           onError: {observer.onError($0)},
                           onCompleted: {observer.onCompleted()},
                           onDisposed: nil)
            
            let progressDisposable = Observable<Int>
                .interval(0.3, scheduler: MainScheduler.instance)
                .bindNext { _ in
                    let comleted = Float(uploadTask.uploadProgress.completedUnitCount)
                    let total = Float(uploadTask.uploadProgress.totalUnitCount)
                    var progress = comleted / total / 2 + 0.5
                    if progress.isNaN { progress = 0 }
                    observer.onNext(progress) }
            
            return Disposables.create { responseDisposable.dispose(); progressDisposable.dispose() }
        }
    }
    
    private func exportMovie(sourceUrl: URL, destUrl: URL) -> Observable<Float> {
        return Observable.create { observer in
            
            guard let exportSession = AVAssetExportSession(asset: AVAsset(url: sourceUrl), presetName: AVAssetExportPresetHighestQuality) else {
                observer.onError(RegistrationDialogViewModel.Error.deserializationError)
                return Disposables.create {  }
            }
            exportSession.outputFileType = AVFileTypeQuickTimeMovie
            exportSession.outputURL = destUrl
            exportSession.shouldOptimizeForNetworkUse = true
            exportSession.exportAsynchronously(completionHandler: {
                if let error = exportSession.error {
                    observer.onError(error)
                }
                else {
                    observer.onCompleted()
                }
            })
            
            let disposable = Observable<Int>
                .interval(0.3, scheduler: MainScheduler.instance)
                .bindNext { _ in
                    var progress = exportSession.progress / 2
                    if progress.isNaN { progress = 0 }
                    observer.onNext(progress)
            }
        
            return Disposables.create { disposable.dispose() }
        }
    }
    
    private func sendMovie(request: URLRequest, url: URL) -> Observable<Float> {
        return Observable.create { observer in
            let uploadTask = Alamofire.upload(url, with: request)
            let responseDisposable = uploadTask
                .rx
                .responseJSON()
                .subscribe(onNext: nil,
                           onError: {observer.onError($0)},
                           onCompleted: {observer.onCompleted()},
                           onDisposed: nil)
            
            let progressDisposable = Observable<Int>
                .interval(0.3, scheduler: MainScheduler.instance)
                .bindNext { _ in
                    let completed = Float(uploadTask.uploadProgress.completedUnitCount)
                    let total = Float(uploadTask.uploadProgress.totalUnitCount)
                    var progress = completed / total / 2 + 0.5
                    if progress.isNaN { progress = 0 }
                    observer.onNext(progress) }
            
            return Disposables.create { responseDisposable.dispose(); progressDisposable.dispose() }
        }
    }
    
    private func postMovie(request: URLRequest, url: URL) -> Observable<Float> {
        return Observable.create { observer in
            
            var tmpFileUrl = URL(fileURLWithPath: NSTemporaryDirectory())
            tmpFileUrl.appendPathComponent(UUID().uuidString)
            
            let export = self.exportMovie(sourceUrl: url, destUrl: tmpFileUrl)
            let send = self.sendMovie(request: request, url: tmpFileUrl)
            

            let disposable = export.concat(send).asObservable()
                .asObservable()
                .subscribe(observer)
            
            return Disposables.create {
                disposable.dispose()
                _ = try? FileManager().removeItem(at: tmpFileUrl)
            }
        }
    }
    
    func postData() -> Observable<Float> {
        return Observable.create { observer in
            let location = AppDelegate.shared.userLocation.currentLocation.value
            var headers = [String : String]()
            headers["Content-Type"] = "undefined"
            headers["uid"] = AppConfig.shared.uid.value ?? ""
            headers["type"] = self.base.image.value == nil ? "1" : "2"
            headers["comment"] = self.base.comment.value?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? ""
            if let location = self.base.location.value {
                headers["location_id"] = "\(location.location_id)"
            }
            else {
                headers["location_id"] = ""
            }
            headers["latitude"] = "\(location?.coordinate.latitude ?? 0)"
            headers["longitude"] = "\(location?.coordinate.longitude ?? 0)"
            
            guard var request = try? urlRequest(.post, URLManager.shared.postData, headers: headers) else {
                observer.onError(RegistrationDialogViewModel.Error.requestGenerateError)
                return Disposables.create {}
            }
            request.timeoutInterval = Bundle.main.infoDictionary!["RequestTimeoutInterval"] as! Double
            
            var disposable: Disposable?
            if let image = self.base.image.value {
                disposable = self.postImage(request: request, image: image)
                    .asObservable()
                    .subscribe(observer)
            }
            else if let url = self.base.movieUrl.value {
                disposable = self.postMovie(request: request, url: url)
                    .asObservable()
                    .subscribe(observer)
            }
            
            return Disposables.create { disposable?.dispose() }
        }
    }
}

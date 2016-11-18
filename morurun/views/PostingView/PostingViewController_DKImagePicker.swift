//
//  PostingViewController_DKImagePicker.swift
//  morurun
//
//  Created by watanabe on 2016/11/07.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import DKImagePickerController
import AVFoundation
import MobileCoreServices

extension PostingViewController {
    
    private var pickerController: DKImagePickerController {
        get {
            let pickerController = DKImagePickerController()
            pickerController.deselectAllAssets()
            pickerController.singleSelect = true
            let delegate = CustomUIDelegate()
            delegate.image.asObservable()
                .bindTo(self.postingViewModel.image)
                .addDisposableTo(self.disposeBag)
            delegate.movieUrl.asObservable()
                .bindTo(self.postingViewModel.movieUrl)
                .addDisposableTo(self.disposeBag)
            pickerController.didSelectAssets = { (assets: [DKAsset]) in
                guard let asset = assets.first else { return }
                if !asset.isVideo {
                    asset.fetchOriginalImage(true) { image, info in
                        delegate.image.value = image
                    }
                }
                else {
                    asset.fetchAVAsset(true, options: nil) { avasset, info in
                        let url = (avasset as? AVURLAsset)?.url
                        delegate.movieUrl.value = url
                    }
                }
            }
            pickerController.UIDelegate = delegate
            return pickerController
        }
    }
    
    func configureDKImagePicker() {
        
        pickerController.singleSelect = true
        let delegate = CustomUIDelegate()
        delegate.image.asObservable()
            .bindTo(self.postingViewModel.image)
            .addDisposableTo(self.disposeBag)
        delegate.movieUrl.asObservable()
            .bindTo(self.postingViewModel.movieUrl)
            .addDisposableTo(self.disposeBag)
        pickerController.didSelectAssets = { (assets: [DKAsset]) in
            guard let asset = assets.first else { return }
            if !asset.isVideo {
                asset.fetchOriginalImage(true) { image, info in
                    delegate.image.value = image
                }
            }
            else {
                asset.fetchAVAsset(true, options: nil) { avasset, info in
                    let url = (avasset as? AVURLAsset)?.url
                    delegate.movieUrl.value = url
                }
            }
        }
        pickerController.UIDelegate = delegate
        
        self.pictureSelectButton
            .rx
            .tap
            .bindNext {[unowned self] _ in self.present(self.pickerController, animated: true, completion: nil) }
            .addDisposableTo(self.disposeBag)
    }
}

class CustomUIDelegate: DKImagePickerControllerDefaultUIDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let image = Variable<UIImage?>(nil)
    let movieUrl = Variable<URL?>(nil)
    
    override func imagePickerControllerCreateCamera(_ imagePickerController: DKImagePickerController,
                                                    didCancel: @escaping (() -> Void),
                                                    didFinishCapturingImage: @escaping ((_ image: UIImage) -> Void),
                                                    didFinishCapturingVideo: @escaping ((_ videoURL: URL) -> Void)) -> UIViewController {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        return picker
    }
    
    // MARK: - UIImagePickerControllerDelegate methods
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! String
        
        if mediaType == kUTTypeImage as String {
            let image = info[UIImagePickerControllerOriginalImage] as? UIImage
            self.image.value = image
        } else if mediaType == kUTTypeMovie as String {
            let movieUrl = info[UIImagePickerControllerMediaURL] as? URL
            self.movieUrl.value = movieUrl
        }
        self.imagePickerController.presentingViewController?.dismiss(animated: true, completion: nil)
    }
}

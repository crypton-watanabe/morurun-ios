//
//  PostingViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/04.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import RxCocoa
import RxSwift
import MobileCoreServices
import DKImagePickerController
import SGNavigationProgress

class PostingViewController : UIViewController, UIScrollViewDelegate {
    
    let postingViewModel = PostingViewModel()
    let disposeBag = DisposeBag()
    private typealias CommentAndImage = (comment: String?, image: UIImage?)
    private var commentAndImageObserver: AnyObserver<CommentAndImage> {
        get {
            return AnyObserver<CommentAndImage> {[unowned self] event in
                switch event {
                case .next(let element):
                    self.measuringContentsHeight(element.comment, image: element.image)
                default: break
                }
            }
        }
    }
    @IBOutlet weak var scrollContentsView: UIView!
    @IBOutlet weak var contentsViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var keyboardAccessoryView: UIView!
    @IBOutlet weak var pictureSelectButton: UIButton!
    @IBOutlet weak var checkinButton: UIButton!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var imageViewTapGestureRecognizer: UITapGestureRecognizer!
    @IBOutlet var imageCloseButton: UIButton!
    @IBOutlet weak var shareBarButton: UIBarButtonItem!
    @IBOutlet var progressView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textView.inputAccessoryView = self.keyboardAccessoryView
        self.configureAVPlayerViewController()
        self.configureDKImagePicker()
        
        self.textView
            .rx
            .text
            .asObservable()
            .bindTo(self.postingViewModel.comment)
            .addDisposableTo(self.disposeBag)
        self.postingViewModel
            .thumbnail
            .asObservable()
            .bindTo(self.imageView.rx.image)
            .addDisposableTo(self.disposeBag)
        self.imageViewTapGestureRecognizer
            .rx
            .event
            .bindNext {[unowned self] _ in self.textView.resignFirstResponder() }
            .addDisposableTo(self.disposeBag)
        self.imageCloseButton
            .rx
            .tap
            .bindNext {[unowned self] _ in
                self.postingViewModel.image.value = nil
                self.postingViewModel.movieUrl.value = nil
            }
            .addDisposableTo(self.disposeBag)
        self.checkinButton
            .rx
            .tap
            .bindNext {[unowned self] _ in
                let viewController = R.storyboard.location.locationTableViewController()!
                viewController.selectedLocation.value = self.postingViewModel.location.value
                viewController.selectedLocation
                    .asObservable()
                    .bindTo(self.postingViewModel.location)
                    .addDisposableTo(self.disposeBag)
                
//                self.present(viewController, animated: true, completion: nil)
                self.navigationController?.pushViewController(viewController, animated: true)
            }
            .addDisposableTo(self.disposeBag)
        self.postingViewModel
            .thumbnail
            .asObservable()
            .map { $0 == nil }
            .bindTo(self.imageCloseButton.rx.isHidden)
            .addDisposableTo(self.disposeBag)
        self.shareBarButton
            .rx
            .tap
            .asObservable()
            .filter {[unowned self] in !self.postingViewModel.errorMessage.value.isEmpty }
            .bindNext {[unowned self] _ in
                let alertViewController = UIAlertController(title: nil, message: self.postingViewModel.errorMessage.value, preferredStyle: .alert)
                alertViewController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alertViewController, animated: true, completion: nil)
            }
            .addDisposableTo(self.disposeBag)
        self.shareBarButton
            .rx
            .tap
            .asObservable()
            .filter {[unowned self] in self.postingViewModel.errorMessage.value.isEmpty }
            .bindNext {[unowned self] _ in
                AppDelegate.shared.window?.addSubviewFill(self.progressView)
                self.textView.resignFirstResponder()
                self.postingViewModel.rx.postData()
                    .asObservable()
                    .subscribe(
                        onNext: { [unowned self] in
                            self.navigationController?.setSGProgressPercentage($0 * 100, andTintColor: UIColor.blue)
                        },
                        onError: { [unowned self] error in
                            print(error.localizedDescription)
                            let alertController = UIAlertController(title: nil, message: "エラーが発生しました。", preferredStyle: .alert)
                            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                            self.present(alertController, animated: true, completion: nil)
                        },
                        onCompleted: { [unowned self] in
                            self.dismiss(animated: true, completion: nil)
                        },
                        onDisposed: {[unowned self] in
                            self.progressView.removeFromSuperview()
                        })
                    .addDisposableTo(self.disposeBag)
            }
            .addDisposableTo(self.disposeBag)
        Observable.combineLatest(self.textView.rx.text.asObservable(),
                                 self.imageView.rx.observe(UIImage.self, "image"),
                                 resultSelector:{ ($0, $1) } )
            .bindTo(self.commentAndImageObserver)
            .addDisposableTo(self.disposeBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.textView.becomeFirstResponder()
        
        
        if AppConfig.shared.uid.value == nil {
            guard let view = R.nib.registrationDialogView.firstView(owner: nil) else { return }
            AppDelegate.shared.window?.addSubviewFill(view)
        }
    }
    
    private func measuringContentsHeight(_ comment: String?, image: UIImage?) {
        var textViewNewHeight = self.textView.sizeThatFits(CGSize(width: self.textView.frame.width,
                                                                height: CGFloat.greatestFiniteMagnitude)).height

        var imageViewNewHeight: CGFloat = {
            guard let newImage = image else { return 0 }
            let scaleFactor = self.imageView.frame.width / newImage.size.width
            return newImage.size.height * scaleFactor
        }()
        
        var contentHeight = max(textViewNewHeight + imageViewNewHeight, self.view.frame.height + 1)
        
        (self.view as! UIScrollView).contentSize = CGSize(width: self.view.frame.size.width,
                                                          height: contentHeight)
        print(#function, contentHeight)
        if textViewNewHeight.isNaN {
            textViewNewHeight = 0
        }
        if imageViewNewHeight.isNaN {
            imageViewNewHeight = 0
        }
        if contentHeight.isNaN {
            contentHeight = 0
        }
        self.contentsViewHeightConstraint.constant = contentHeight
        self.textViewHeightConstraint.constant = textViewNewHeight
        self.imageViewHeightConstraint.constant = imageViewNewHeight
    }
    
    // MARK: - UIScrollViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            return
        }
        if !scrollView.isDecelerating {
            return
        }
        self.textView.resignFirstResponder()
    }
}

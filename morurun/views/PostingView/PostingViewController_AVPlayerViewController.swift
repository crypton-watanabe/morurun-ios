//
//  PostingViewController_AVPlayerViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/07.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit
import RxCocoa
import RxSwift

fileprivate var videoPreviewViewController = AVPlayerViewController()

extension PostingViewController {
    
    func configureAVPlayerViewController() {
        assert(videoPreviewViewController.parent == nil)
        self.addChildViewController(videoPreviewViewController)
        
        self.postingViewModel.movieUrl
            .asObservable()
            .bindNext {[unowned self] url in
                videoPreviewViewController.view.removeFromSuperview()
                if let url = self.postingViewModel.movieUrl.value {
                    videoPreviewViewController.player = AVPlayer(url: url)
                }
                else {
                    videoPreviewViewController.player = nil
                }
            }
            .addDisposableTo(self.disposeBag)
        self.imageViewTapGestureRecognizer
            .rx
            .event
            .filter { _ in videoPreviewViewController.player != nil }
            .bindNext {[unowned self] _ in
                self.imageView.addSubviewFill(videoPreviewViewController.view)
                videoPreviewViewController.player?.play()
            }
            .addDisposableTo(self.disposeBag)
        
        let disposable = Disposables.create {
            videoPreviewViewController.removeFromParentViewController()
        }
        self.disposeBag.insert(disposable)
    }
}

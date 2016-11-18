//
//  SplashViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/14.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class SplashViewController : UIViewController {
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let locationObserver = Location.rx.updateLocation().map { $0 as Any }
        let loadPostingObserver = Posting.rx.updatePostings().map { $0 as Any }
        
        locationObserver.concat(loadPostingObserver)
            .asObservable()
            .subscribe(
                onNext: nil,
                onError: { [unowned self] error in
                    print(error.localizedDescription)
                    let alertController = UIAlertController(title: nil, message: "エラーが発生しました。", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                },
                onCompleted: { _ in
                    AppDelegate.shared.window?.rootViewController = R.storyboard.timeLineTableView.instantiateInitialViewController()
                },
                onDisposed: nil
            )
            .addDisposableTo(self.disposeBag)
    }
}

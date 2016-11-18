//
//  DebugViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/09.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

#if DEVELOP
class DebugViewController: UIViewController {
    
    private let disposeBag = DisposeBag()
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.textField.text = AppConfig.shared.debugUrlString.value
        self.button
            .rx
            .tap
            .bindNext {[unowned self] in
                AppConfig.shared.debugUrlString.value = self.textField.text
                _ = Observable<Int>
                    .interval(1, scheduler: MainScheduler.instance)
                    .bindNext({ _ in exit(0) })
            }
            .addDisposableTo(self.disposeBag)
    }
}
#endif

//
//  RegistrationDialogView.swift
//  morurun
//
//  Created by watanabe on 2016/11/04.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class RegistrationDialogView : UIView {
    
    private let disposeBag = DisposeBag()
    private let viewModel = RegistrationDialogViewModel()
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var okButton: UIButton!
    @IBOutlet weak var errorMessageLabel: UILabel!
    @IBOutlet weak var loadingView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.textField.text = AppConfig.shared.nickname.value
        self.textField.becomeFirstResponder()
        
        self.textField
            .rx
            .text
            .asObservable()
            .bindTo(self.viewModel.nickname)
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .isValid
            .asObservable()
            .bindTo(self.okButton.rx.isEnabled)
            .addDisposableTo(self.disposeBag)
        
        self.okButton
            .rx
            .tap
            .asObservable()
            .bindNext {[unowned self] _ in
                AppConfig.shared.nickname.value = self.textField.text
                self.closeDialog()
            }
            .addDisposableTo(self.disposeBag)
        
        self.viewModel
            .errorMessage
            .asObservable()
            .bindTo(self.errorMessageLabel.rx.text)
            .addDisposableTo(self.disposeBag)
    }
    
    private func closeDialog() {
        self.loadingView.alpha = 1.0
        
        self.viewModel
            .rx
            .requestRegistration()
            .observeOn(MainScheduler.instance)
            .subscribe (
                onNext: nil,
                onError: { [weak self] error in
                    self?.errorMessageLabel.text = "エラーが発生しました"
                },
                onCompleted: { [weak self] in
                    UIView.animate(withDuration: 0.2,
                                   animations: { self?.alpha = 0 },
                                   completion: { _ in self?.removeFromSuperview() })
                },
                onDisposed: { [weak self] in
                    self?.loadingView.alpha = 0.0
                }
            )
            .addDisposableTo(self.disposeBag)
    }
}

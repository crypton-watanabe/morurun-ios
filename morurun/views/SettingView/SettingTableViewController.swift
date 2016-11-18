//
//  SettingTableViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/07.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class SettingTableViewController: UITableViewController {
    
    private let disposeBag = DisposeBag()
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var userCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appConfigNickname = AppConfig.shared.nickname
        appConfigNickname.userDefaults
            .rx.observe(String.self, appConfigNickname.propertyName)
            .map { $0 ?? "--" }
            .bindTo(self.nicknameLabel.rx.text)
            .addDisposableTo(self.disposeBag)
        self.versionLabel.text = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }
    
    private func onTapUserCell() {
        guard let view = R.nib.registrationDialogView.firstView(owner: nil) else { return }
        AppDelegate.shared.window?.addSubviewFill(view)
    }
    
    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let cell = tableView.cellForRow(at: indexPath), cell == self.userCell {
            self.onTapUserCell()
        }
    }
}

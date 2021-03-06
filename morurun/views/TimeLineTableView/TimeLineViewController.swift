//
//  TimeLineViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/15.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Realm
import MoPub

class TimeLineViewController : UIViewController, UITableViewDelegate, UITableViewDataSource, MPAdViewDelegate {
    
    private let disposeBag = DisposeBag()
    private var postings = [Posting]()
    private var notificationToken: RLMNotificationToken?
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newPostBarButton: UIBarButtonItem!
    @IBOutlet weak var settingBarButton: UIBarButtonItem!
    @IBOutlet var emptyMessageView: UIView!
    @IBOutlet weak var adBaseView: UIView!
    @IBOutlet weak var adViewWidthConstraint: NSLayoutConstraint!
    
    // TODO: Replace this test id with your personal ad unit id
    var adView: MPAdView = MPAdView(adUnitId: "0fd404de447942edb7610228cb412614", size: MOPUB_BANNER_SIZE)
    
    deinit {
        self.notificationToken?.stop()
    }
    
    private func loadPostings() {
        Posting
            .rx
            .updatePostings()
            .subscribe(
                onNext: nil,
                onError: { [unowned self] error in
                    let alertController = UIAlertController(title: nil, message: "エラーが発生しました。", preferredStyle: .alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alertController, animated: true, completion: nil)
                },
                onCompleted: nil,
                onDisposed: { [unowned self] in
                    self.tableView.refreshControl?.endRefreshing()
                    self.tableView.reloadData()
                }
            )
            .addDisposableTo(self.disposeBag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.tableFooterView = UIView()
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 1000
        self.tableView.refreshControl = self.refreshControl
        
        self.refreshControl
            .rx
            .controlEvent(UIControlEvents.valueChanged)
            .delay(1.0, scheduler: MainScheduler.instance)
            .bindNext { [unowned self] in self.loadPostings() }
            .addDisposableTo(self.disposeBag)
        
        self.notificationToken = Posting.allObjects().sortedResults(usingProperty: "datetime", ascending: false).addNotificationBlock({ (resuluts, changes, error) in
            self.postings.removeAll()
            self.postings = resuluts?.value(forKeyPath: "self") as? [Posting] ?? []
            self.tableView.reloadData()
        })
        AppDelegate.shared.userLocation
            .isInMuroran
            .asObservable()
            .bindTo(self.newPostBarButton.rx.isEnabled)
            .addDisposableTo(self.disposeBag)
        self.newPostBarButton
            .rx
            .tap
            .bindNext {[unowned self] in
                let viewController = R.storyboard.posting().instantiateInitialViewController()!
                self.present(viewController, animated: true, completion: nil)
            }
            .addDisposableTo(self.disposeBag)
        self.settingBarButton
            .rx
            .tap
            .bindNext {
                let viewController = R.storyboard.setting().instantiateInitialViewController()!
                self.present(viewController, animated: true, completion: nil)
            }
            .addDisposableTo(self.disposeBag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.adView.delegate = self
        self.adView.frame = CGRect(x: 0,
                                   y: 0,
                                   width: MOPUB_BANNER_SIZE.width,
                                   height: MOPUB_BANNER_SIZE.height)
        self.adBaseView.addSubviewFill(self.adView)
        self.adViewWidthConstraint.constant = MOPUB_BANNER_SIZE.width
        self.adView.loadAd()
    }
    
    func viewControllerForPresentingModalView() -> UIViewController {
        return self
    }
    
    // MARK: - Actions
    @IBAction func unwind(segue: UIStoryboardSegue) {
    }
    
    private func onTouchMapButton(posting: Posting) {
        let mapViewController = MapViewController(latitude: posting.latitude, longitude: posting.longitude, locationId: posting.location_id)
        self.navigationController?.pushViewController(mapViewController, animated: true)
    }
    
    // MARK: - UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postings.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let posting = self.postings[(indexPath as NSIndexPath).row]
        
        let cell: TimeLineTableViewCell?
        switch posting.contentsType {
        case .movie:
            cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.movieCell, for: indexPath)
        case .picture:
            cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.pictureCell, for: indexPath)
        }
        
        cell?.posting.value = posting
        cell?.mapButtonTouchHandler = self.onTouchMapButton
        
        return cell!
    }
    // MARK: - UITableViewDelegate Protocol
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if self.postings.isEmpty {
            return tableView.frame.height - tableView.contentInset.top - tableView.contentInset.bottom
        }
        else {
            return 0
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.emptyMessageView
    }
}

//
//  LocationTableViewController.swift
//  morurun
//
//  Created by watanabe on 2016/11/09.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LocationTableViewController: UITableViewController {
    
    private let disposeBag = DisposeBag()
    private var locations = Location.allObjects().value(forKeyPath: "self") as! [Location]
    let selectedLocation = Variable<Location?>(nil)
    
    @IBOutlet var selectedLocationView: UIView!
    @IBOutlet weak var selectedLocationLabel: UILabel!
    @IBOutlet weak var deselectedLocationButton: UIButton!
    
    deinit {
        print(NSStringFromClass(type(of : self)), #function)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // FIXME: このソートは時間がかかる
        locations.sort(by: { ($0.distance ?? Int.max) < ($1.distance ?? Int.max) })
        self.tableView.separatorInset = UIEdgeInsets.zero
        self.tableView.tableFooterView = UIView()
        
        self.selectedLocation
            .asObservable()
            .bindNext {[unowned self] location in
                self.selectedLocationLabel.text = location?.name
                self.tableView.reloadData()
            }
            .addDisposableTo(self.disposeBag)
        self.deselectedLocationButton
            .rx
            .tap
            .bindNext {[unowned self] in
                self.selectedLocation.value = nil
            }
            .addDisposableTo(self.disposeBag)
    }
    
    // MARK: - UITableViewDelegate Protocol
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedLocation.value = self.locations[indexPath.row]
        _ = self.navigationController?.popViewController(animated: true)
    }
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return self.selectedLocation.value != nil ? 60 : 0
    }
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return self.selectedLocationView
    }
    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.locations.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let location = self.locations[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.locationCell,
                                                 for: indexPath)!
        
        cell.locationNameLabel.text = location.name
        if let distance = location.distance {
            cell.distanceLabel.text =  "\(distance)m"
        }
        else {
            cell.distanceLabel.text =  nil
        }
        
        
        return cell
    }
}

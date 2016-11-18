//
//  UIView_extensions.swift
//  morurun
//
//  Created by watanabe on 2016/11/02.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit

extension UIView {
    
    func insertSubviewFill(_ view: UIView, at: Int) {
        self.insertSubview(view, at: at)
        self.subViewFill(view)
    }
    
    func addSubviewFill(_ subView: UIView) {
        self.addSubview(subView)
        self.subViewFill(subView)
    }
    
    private func subViewFill(_ subView: UIView) {
        subView.translatesAutoresizingMaskIntoConstraints = false
        
        let viewDic = ["subView" : subView]
        
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[subView]-0-|",
                                                          options: [],
                                                          metrics: nil,
                                                          views: viewDic);
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[subView]-0-|",
                                                          options: [],
                                                          metrics: nil,
                                                          views: viewDic);
        self.addConstraints(vConstraints)
        self.addConstraints(hConstraints)
        
        self.layoutIfNeeded()
    }
}

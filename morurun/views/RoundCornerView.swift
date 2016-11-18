//
//  RoundCornerView.swift
//  morurun
//
//  Created by watanabe on 2016/11/04.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit

@IBDesignable
class RoundCornerView: UIView {
    
    @IBInspectable
    var cornerRadius: CGFloat = 0.0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.cornerRadius = self.cornerRadius
    }
}

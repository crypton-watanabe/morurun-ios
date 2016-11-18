//
//  TimeLineTableViewCell.swift
//  morurun
//
//  Created by watanabe on 2016/11/01.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import RxSwift
import SDWebImage
import IDMPhotoBrowser

class TimeLineTableViewCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    let posting = Variable<Posting?>(nil)
    var mapButtonTouchHandler: ((Posting) -> Void)?
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var youtubeView: YoutubeView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewTrailingConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        self.posting
            .asObservable()
            .filter { $0 == nil }
            .bindNext {[unowned self] _ in
                self.userNameLabel.text = ""
                self.timeLabel.text = ""
                self.messageTextView.text = ""
                self.youtubeView?.url = nil
                self.thumbImageView?.image = nil
            }
            .addDisposableTo(self.disposeBag)
        
        self.posting
            .asObservable()
            .filter({ $0 != nil }).map({ $0! })
            .bindNext {[unowned self] posting in
                self.userNameLabel.text = posting.user_nickname
                self.timeLabel.text = posting.dateString
                self.messageTextView.text = posting.comment
                self.youtubeView?.url = posting.contentsUrl
                self.thumbImageView?.image = nil
                self.thumbImageView?.sd_setImage(with: posting.contentsUrl)
            }
            .addDisposableTo(self.disposeBag)
        
        self.messageTextView
            .rx
            .observe(String.self, "text")
            .asObservable()
            .bindNext {[unowned self] _ in
                let superViewWidth = UIScreen.main.bounds.width
                let fitsWidth = superViewWidth - self.textViewLeadingConstraint.constant - self.textViewTrailingConstraint.constant
                let textView = self.messageTextView!
                let size = textView.sizeThatFits(CGSize(width: fitsWidth, height: CGFloat.greatestFiniteMagnitude))
                
                self.textViewHeightConstraint.constant = size.height
                self.contentView.setNeedsLayout()
            }
            .addDisposableTo(self.disposeBag)
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        self.thumbImageView?.addGestureRecognizer(tapGestureRecognizer)
        tapGestureRecognizer
            .rx
            .event
            .bindNext({ tapGestureRecognizer in
                let imageView = tapGestureRecognizer.view as? UIImageView
                assert(imageView != nil)
                guard let image = imageView?.image else { return }
                
                let browserViewController = IDMPhotoBrowser(photos: [IDMPhoto(image: image)])
                browserViewController?.displayToolbar = false
                browserViewController?.usePopAnimation = true
                AppDelegate.shared.window?.rootViewController?.present(browserViewController!, animated: true, completion: nil)
            })
            .addDisposableTo(self.disposeBag)
    }
    @IBAction func touchUpMapButton(_ sender: Any) {
        guard let posting = self.posting.value else { return }
        self.mapButtonTouchHandler?(posting)
    }
    
    @IBAction func touchUpShareButton(_ sender: Any) {
        guard let posting = self.posting.value else { return }
        let activityItems = [posting.comment, posting.contentsUrl!] as [Any]
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        AppDelegate.shared.window?.rootViewController?.present(activityViewController, animated: true, completion: nil)
    }
}

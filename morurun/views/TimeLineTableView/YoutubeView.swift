//
//  YoutubeView.swift
//  morurun
//
//  Created by watanabe on 2016/11/02.
//  Copyright © 2016年 Crypton Future Media, INC. All rights reserved.
//

import UIKit
import WebKit
import RxSwift
import RxCocoa

public class YoutubeView: UIView {
    
    private let disposeBag = DisposeBag()
    private var webView: WKWebView?
    var url: URL? {
        didSet {
            if let url = self.url {
                let request = URLRequest(url: url)
                _ = self.webView?.load(request)
            }
            else {
                _ = self.webView?.loadHTMLString("", baseURL: nil)
            }
        }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
        
        let webView = WKWebView()
        self.addSubviewFill(webView)
        webView
            .rx.observe(Bool.self, "loading")
            .bindNext({ webView.isHidden = $0 ?? true })
            .addDisposableTo(self.disposeBag)
        
        self.webView = webView
        self.webView?.scrollView.isScrollEnabled = false
    }
}

extension Reactive where Base: YoutubeView {
    public var url: UIBindingObserver<Base, URL?> {
        return UIBindingObserver(UIElement: self.base) { view, url in
            view.url = url
        }
    }
}

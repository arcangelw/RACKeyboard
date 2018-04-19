//
//  InputBar.swift
//  RACKeyboard_Example
//
//  Created by 吴哲 on 2018/4/19.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift
import Result
import RACKeyboard

class InputBar: UIView {
    
    let toolbar = UIToolbar()
    let textView = UITextView().then {
        $0.placeholder = "你有什么想说的!"
        $0.isEditable = true
        $0.showsVerticalScrollIndicator = false
        $0.layer.borderColor = UIColor.lightGray.withAlphaComponent(0.6).cgColor
        $0.layer.borderWidth = 1 / UIScreen.main.scale
        $0.layer.cornerRadius = 3
    }
    let sendButton = UIButton(type: .system).then {
        $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
        $0.setTitle("Send", for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.toolbar)
        self.addSubview(self.textView)
        self.addSubview(self.sendButton)
        
        self.toolbar.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        
        self.textView.snp.makeConstraints { make in
            make.top.left.equalTo(7)
            make.right.equalTo(self.sendButton.snp.left).offset(-7)
            make.bottom.equalTo(-7)
        }
        
        self.sendButton.snp.makeConstraints { make in
            make.top.equalTo(7)
            make.bottom.equalTo(-7)
            make.right.equalTo(-7)
        }
        
        self.sendButton.reactive.isEnabled <~ SignalProducer(value: false).concat(self.textView.reactive.continuousTextValues
            .map({
                if let text = $0 ,text.isEmpty == false {
                    return true
                }
                return false
            }).take(during: reactive.lifetime).producer)
        
        RACKeyboard.shared.visibleHeight.map({$0 > 0.0}).skipRepeats().producer.take(during: reactive.lifetime).startWithValues { [weak self] (visible) in
            guard let `self` = self else { return }
            var bottomInset = 0.f
            if #available(iOS 11.0, *), !visible, let bottom = self.superview?.safeAreaInsets.bottom {
                bottomInset = bottom
            }
            self.toolbar.snp.remakeConstraints({ (make) in
                make.left.right.top.equalTo(0)
                make.bottom.equalTo(bottomInset)
            })
        }
        
    }
    
    @available(iOS 11.0, *)
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        guard let bottomInset = self.superview?.safeAreaInsets.bottom else {
            return
        }
        
        self.toolbar.snp.remakeConstraints { make in
            make.top.left.right.equalTo(0)
            make.bottom.equalTo(bottomInset)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: self.width, height: 44)
    }
}

extension Reactive where Base: InputBar {
    var sendButtonTap:SignalProducer<String, NoError>{
        return self.base.sendButton.reactive.controlEvents(.touchUpInside).withLatest(from: self.base.textView.reactive.continuousTextValues)
            .take(during: self.lifetime)
            .map({$0.1})
            .filter({
                if let text = $0 ,text.isEmpty == false {
                    return true
                }
                return false
            })
            .map({$0!})
            .producer.on(value: { _ in
                self.base.textView.text = nil
                self.base.sendButton.isEnabled = false
            })
    }
    
}


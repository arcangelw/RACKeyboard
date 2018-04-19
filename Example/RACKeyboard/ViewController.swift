//
//  ViewController.swift
//  RACKeyboard
//
//  Created by arcangelw on 04/19/2018.
//  Copyright (c) 2018 arcangelw. All rights reserved.
//

import UIKit
import ReusableKit
import ReactiveCocoa
import ReactiveSwift
import Result
import RACKeyboard

class ViewController: UIViewController {
    
    struct Reusable {
        static let messageCell = ReusableCell<UITableViewCell>()
    }
    private var didSetupViewConstraints = false
    
    fileprivate var messages:[String] = [
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "Morbi et eros elementum, semper massa eu, pellentesque sapien.",
        "你还好么！！！",
        "我不好！！！",
        "Nam feugiat urna non tortor ornare viverra.",
        "Aenean sollicitudin justo scelerisque tincidunt venenatis.",
        "Nullam iaculis nisi in justo feugiat, at pharetra nulla dignissim.",
        "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
        "Morbi et eros elementum, semper massa eu, pellentesque sapien.",
        "你还好么！！！",
        "我不好！！！",
        "Nam feugiat urna non tortor ornare viverra.",
        "Aenean sollicitudin justo scelerisque tincidunt venenatis.",
        "Nullam iaculis nisi in justo feugiat, at pharetra nulla dignissim."
    ]
    
    let tableView = UITableView().then {
        $0.alwaysBounceVertical = true
        $0.keyboardDismissMode = .interactive
        $0.backgroundColor = .yellow
        $0.register(Reusable.messageCell)
        $0.rowHeight = UITableViewAutomaticDimension
        $0.estimatedRowHeight  = UITableViewAutomaticDimension
    }
    
    let inputBar = InputBar().then {
        $0.backgroundColor = .green
    }
    
    deinit {
        print("root deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.tableView)
        self.view.addSubview(self.inputBar)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        DispatchQueue.main.async {
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.scrollToRow(at: indexPath, at:.none, animated: true)
        }
        
        RACKeyboard.shared.visibleHeight.producer.take(during: self.reactive.lifetime).startWithValues { [weak self] keyboardVisibleHeight in
            guard let `self` = self, self.didSetupViewConstraints else { return }
            var actualKeyboardHeight = keyboardVisibleHeight
            if #available(iOS 11.0, *), keyboardVisibleHeight > 0 {
                actualKeyboardHeight = actualKeyboardHeight - self.view.safeAreaInsets.bottom
            }
            self.inputBar.snp.updateConstraints { make in
                make.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-actualKeyboardHeight)
            }
            self.view.setNeedsLayout()
            /**
             额 测试一下 7 << 16  感觉没有什么特别明显的效果
             源码参考来自 Telegram 项目：https://github.com/peter-iakovlev/Telegram/blob/public/Share/TGShareController.m#L662
             */
            UIView.animate(withDuration: 0.25, delay: 0, options: UIViewAnimationOptions(rawValue: 7 << 16 | UIViewAnimationOptions.allowAnimatedContent.rawValue), animations: {
                self.tableView.contentInset.bottom = keyboardVisibleHeight + self.inputBar.height
                self.tableView.scrollIndicatorInsets.bottom = self.tableView.contentInset.bottom
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
        
        RACKeyboard.shared.willShowVisibleHeight.producer.take(during: self.reactive.lifetime).startWithValues {[weak self] keyboardVisibleHeight in
            guard let `self` = self else { return }
            self.tableView.contentOffset.y += keyboardVisibleHeight
            print("keyboardVisibleHeight : \(keyboardVisibleHeight)")
        }
        
        self.inputBar.reactive.sendButtonTap.take(during: self.reactive.lifetime).startWithValues {[weak self] text in
            guard let `self` = self else { return }
            self.messages.append(text)
            let indexPath = IndexPath(row: self.messages.count - 1, section: 0)
            self.tableView.insertRows(at: [indexPath], with: .none)
            self.tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
        
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        guard !self.didSetupViewConstraints else { return }
        self.didSetupViewConstraints = true
        self.tableView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        self.inputBar.snp.makeConstraints { make in
            make.left.right.equalTo(0)
            make.bottom.equalTo(self.bottomLayoutGuide.snp.top)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if self.tableView.contentInset.bottom == 0 {
            self.tableView.contentInset.bottom = self.inputBar.height
            self.tableView.scrollIndicatorInsets.bottom = self.tableView.contentInset.bottom
        }
    }
}

extension ViewController:UITableViewDelegate{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let v = ViewController()
        self.navigationController?.pushViewController(v, animated: true)
    }
}

extension ViewController:UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeue(Reusable.messageCell, for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text = self.messages[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
}


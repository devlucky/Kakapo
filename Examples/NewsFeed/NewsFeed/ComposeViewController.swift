//
//  ComposeViewController.swift
//  NewsFeed
//
//  Created by Alex Manzella on 28/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import SnapKit

class ComposeViewController: UIViewController, UITextViewDelegate {
    
    private let networkManager: NetworkManager
    private let textView: UITextView = {
        let textView = UITextView()
        textView.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        return textView
    }()
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    required init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem?.enabled = false
        
        view.addSubview(textView)
        textView.delegate = self
        textView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        [UIKeyboardWillShowNotification, UIKeyboardWillChangeFrameNotification, UIKeyboardWillHideNotification].forEach { (name) in
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardFrameDidChange(_:)), name: name, object: nil)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
    }
    
    // MARK: Actions

    @objc private func keyboardFrameDidChange(notification: NSNotification) {
        guard let frame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        textView.snp_updateConstraints { (make) in
            make.bottom.equalTo(view).inset(frame.CGRectValue().height)
        }
    }

    @objc private func cancel() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @objc private func done() {
        networkManager.createPost(with: textView.text)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(textView: UITextView) {
        navigationItem.rightBarButtonItem?.enabled = textView.text.characters.count > 0
    }
}

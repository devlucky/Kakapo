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
        textView.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
        return textView
    }()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        view.backgroundColor = UIColor.white
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        view.addSubview(textView)
        textView.delegate = self
        textView.snp.makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        [NSNotification.Name.UIKeyboardWillShow, NSNotification.Name.UIKeyboardWillChangeFrame, NSNotification.Name.UIKeyboardWillHide].forEach { (name) in
            NotificationCenter.default.addObserver(self, selector: #selector(keyboardFrameDidChange(_:)), name: name, object: nil)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
    }
    
    // MARK: Actions

    @objc private func keyboardFrameDidChange(_ notification: Notification) {
        guard let frame = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        textView.snp.updateConstraints { (make) in
            make.bottom.equalTo(view).inset(frame.cgRectValue.height)
        }
    }

    @objc private func cancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func done() {
        networkManager.createPost(with: textView.text)
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        navigationItem.rightBarButtonItem?.isEnabled = textView.text.characters.count > 0
    }
}

//
//  PostViewController.swift
//  KakapoExample
//
//  Created by Alex Manzella on 15/04/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import SnapKit
import SwiftyJSON

class PostViewController: UIViewController {
    let postId: String
    let textView = UITextView()
    var post: Post? {
        didSet {
            let titleAttributes = [NSFontAttributeName: UIFont.systemFontOfSize(25), NSForegroundColorAttributeName: UIColor.blackColor()]
            let title = "\(post?.title ?? "")\n"
            let attributedText = NSMutableAttributedString(string: title, attributes: titleAttributes)
            attributedText.appendAttributedString(NSAttributedString(string: post?.content ?? ""))
            textView.attributedText = attributedText
        }
    }
    
    required init(postId: String) {
        self.postId = postId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        view.backgroundColor = UIColor.whiteColor()
        textView.editable = false
        textView.font = UIFont.systemFontOfSize(UIFont.labelFontSize())
        textView.textColor = UIColor(white: 0.95, alpha: 1)
        view.addSubview(textView)

        textView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
        
        textView.setContentCompressionResistancePriority(250, forAxis: .Vertical)
        
        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: Route.Post(postId))!) { (data, response, _) in
            guard let data = data else { return }
            
            let json = JSON(data: data)
            dispatch_async(dispatch_get_main_queue(), {
                self.post = Post(json: json["post"])
            })
        }.resume()
    }
}

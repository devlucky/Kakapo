//
//  ViewController.swift
//  NewsFeed
//
//  Created by Alex Manzella on 08/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
@testable import Kakapo

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let manager: Manager = {
            let configuration: NSURLSessionConfiguration = {
                let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
                configuration.protocolClasses = [KakapoServer.self]
                configuration.HTTPAdditionalHeaders = ["session-configuration-header": "foo"]
                
                return configuration
            }()
            
            return Manager(configuration: configuration)
            }()
        
        manager.request(.GET, "https://kakapobook.com/api/newsfeed").response { (response) in
            print(response.0)
        }
        
//        NSURLSession.sharedSession().dataTaskWithURL(NSURL(string: "https://kakapobook.com/api/newsfeed")!) { (data, resp, error) in
//            print(data)
//            print(error)
//        }.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


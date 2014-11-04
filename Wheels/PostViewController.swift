//
//  PostViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class PostViewController: UIViewController
{
    @IBOutlet var newPostTextField: UITextView!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var imFullButton: UIButton!
    @IBOutlet var grabber: UIView!
    
    var index:Int? = nil
    
    var postID: String? = nil
    
    let imFullComment = "Lleno"
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        grabber.layer.cornerRadius = 20
        view.bringSubviewToFront(grabber)
    }
    
    @IBAction func sendButtonPressed(sender: UIButton)
    {
        //postMessageToGroup(newPostTextField.text)
    }
    
    @IBAction func imFullButtonPressed(sender: AnyObject)
    {
        postComment(imFullComment, toPostID: postID!)
    }
    
    func postMessageToGroup(post:String)
    {
        var params = [post:"message"]
        
        FBRequestConnection.startWithGraphPath("/\(kWheelsGroupID)/feed", parameters: params, HTTPMethod: "POST", completionHandler:
            { (connection:FBRequestConnection!, results:AnyObject!, error:NSError!) -> Void in
            
                if error == nil
                {
                    let postID = results["id"] as String
                    self.postID = postID
                }
        })
        
    }
    
    func postComment(comment:String, toPostID postID:String)
    {
        var params = [comment:"message"]
    
        FBRequestConnection.startWithGraphPath("/\(postID)/comments", parameters: params, HTTPMethod: "POST", completionHandler:
            { (connection:FBRequestConnection!, results:AnyObject!, error:NSError!) -> Void in
                
                if error == nil
                {
                    
                }
        })
    }
}
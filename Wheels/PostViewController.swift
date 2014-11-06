//
//  PostViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class PostViewController: UIViewController, UITextFieldDelegate
{
    let kTestsGroupID = "1635866786640178"
    
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
        
        newPostTextField.layer.cornerRadius = 3
        //newPostTextField.delegate = self
        
        view.setNeedsLayout()
        view.setNeedsUpdateConstraints()
        
        if parentViewController is MainViewController
        {
            
        }
    }
    
    @IBAction func sendButtonPressed(sender: UIButton)
    {
        postMessageToGroup(newPostTextField.text)
    }
    
    @IBAction func imFullButtonPressed(sender: AnyObject)
    {
        if postID != nil
        {
            postComment(imFullComment, toPostID: postID!)
        }
    }
    
    func postMessageToGroup(post:String)
    {
        var params = ["message":post] as NSDictionary
        
        FBRequestConnection.startWithGraphPath("/\(kWheelsGroupID)/feed", parameters: params, HTTPMethod: "POST", completionHandler:
            { (connection:FBRequestConnection!, results:AnyObject!, error:NSError!) -> Void in
            
                if error == nil
                {
                    println("message published: \(post)")
                    let postID = results["id"] as String
                    self.postID = postID
                    self.sendButton.enabled = false
                    
                    UIView.animateWithDuration(0.5, animations: {
                        
                        self.newPostTextField.backgroundColor = UIColor.clearColor()
                    })
                }
        })
        
    }
    
    func postComment(comment:String, toPostID postID:String)
    {
        var params = ["message":comment] as NSDictionary
    
        FBRequestConnection.startWithGraphPath("/\(postID)/comments", parameters: params, HTTPMethod: "POST", completionHandler:
            { (connection:FBRequestConnection!, results:AnyObject!, error:NSError!) -> Void in
                
                if error == nil
                {
                    println("comment published: \(comment)")
                    self.imFullButton.backgroundColor = UIColor(red: 132/255.0, green: 164/255.0, blue: 146/255.0, alpha: 1)
                    self.imFullButton.enabled = false
                }
        })
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent)
    {
        newPostTextField.endEditing(true)
    }
}
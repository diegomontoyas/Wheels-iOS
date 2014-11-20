//
//  PostViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class PostViewController: UIViewController, UITextViewDelegate
{
    let kTestsGroupID = "1635866786640178"
    
    @IBOutlet var newPostTextView: UITextView!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var imFullButton: UIButton!
    @IBOutlet var grabber: UIView!
    @IBOutlet var backBorderView: UIView!
    @IBOutlet weak var logOutButton: UIButton!
    
    weak var mainPageViewController:MainPageViewController?

    private(set) var postID: String? = nil
    
    let imFullComment = "Lleno"
    
    let sendButtonEnabledColor = UIColor(red: 90/255.0, green: 130/255.0, blue: 200/255.0, alpha: 1)
    let sendButtonDisabledColor = UIColor(red: 170/255.0, green: 178/255.0, blue: 200/255.0, alpha: 1)
    
    let errorButtonColor = UIColor(red: 210/255.0, green: 125/255.0, blue: 115/255.0, alpha: 1)
    let sendButtonSentPostColor = UIColor(red: 100/255.0, green: 180/255.0, blue: 116/255.0, alpha: 1)

    let imFullButtonEnabledColor = UIColor(red: 210/255.0, green: 125/255.0, blue: 115/255.0, alpha: 1)
    let imFullButtonDisabledColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)
    
    let buttonStandardCornerRadius:CGFloat = 6
    
    var initialBackBorderViewColor: UIColor!
    
    private(set) var waitingForConfirmation = false
    private(set) var showingLastSentPost = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: Selector("grabberTapped:"))
        
        grabber.layer.cornerRadius = 20
        view.bringSubviewToFront(grabber)
        //grabber.addGestureRecognizer(tapGestureRecognizer)
        
        newPostTextView.layer.cornerRadius = buttonStandardCornerRadius
        backBorderView.layer.cornerRadius = buttonStandardCornerRadius
        sendButton.layer.cornerRadius = buttonStandardCornerRadius
        imFullButton.layer.cornerRadius = buttonStandardCornerRadius
        logOutButton.layer.cornerRadius = buttonStandardCornerRadius
        
        if newPostTextView.text.isEmpty
        {
            disableSendButton()
        }
        else
        {
            enableSendButton()
        }
        
        imFullButton.hidden = true
        enableImFullButton()
        
        newPostTextView.delegate = self
        
        initialBackBorderViewColor = backBorderView.backgroundColor
    }
    
    override func viewDidAppear(animated: Bool)
    {
        NSNotificationCenter.defaultCenter().postNotificationName("postViewControllerViewDidAppear", object: nil)
    }
    
    func grabberTapped(sender:AnyObject)
    {
        mainPageViewController?.controllerGrabberPressed(self)
    }
    
    @IBAction func sendButtonPressed(sender: UIButton)
    {
        if waitingForConfirmation
        {
            waitingForConfirmation = false
            postMessageToGroup(newPostTextView.text)
        }
        else
        {
            if showingLastSentPost
            {
                newPost()
            }
            else
            {
                waitingForConfirmation = true
                changeSendButtonToAskForConfirmation()
            }
        }
    }
    
    @IBAction func logoutButtonPressed(sender: AnyObject)
    {
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func imFullButtonPressed(sender: AnyObject)
    {
        if postID != nil
        {
            postComment(imFullComment, toPostID: postID!)
        }
    }
    
    func enableSendButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.sendButton.enabled = true
            self.sendButton.backgroundColor = self.sendButtonEnabledColor
        })
    }
    
    func changeSendButtonToNewPost()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.sendButton.enabled = true
            self.sendButton.backgroundColor = self.sendButtonEnabledColor
            self.sendButton.setTitle("New", forState: .Normal)
        })
    }
    
    func changeSendButtonToSend()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.sendButton.enabled = true
            self.sendButton.backgroundColor = self.sendButtonEnabledColor
            self.sendButton.setTitle("Send", forState: .Normal)
        })
    }
    
    func changeSendButtonToAskForConfirmation()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.sendButton.enabled = true
            self.sendButton.backgroundColor = self.sendButtonEnabledColor
            self.sendButton.setTitle("¿Sure?", forState: .Normal)
            
            }, completion:{ (_) -> Void in
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue())
                {
                    self.waitingForConfirmation = false
                    self.changeSendButtonToSend()
                }
            })
    }
    
    func changeSendButtonToPostSentAndUnhideImFullButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.sendButton.enabled = false
            self.sendButton.backgroundColor = self.sendButtonSentPostColor
            self.sendButton.setTitle("Sent", forState: .Normal)
            
            }, completion:{ (_) -> Void in
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC))), dispatch_get_main_queue())
                {
                    self.changeSendButtonToNewPost()
                    self.imFullButton.hidden = false
                    self.enableImFullButton()
                }
        })
    }
    
    func disableSendButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.sendButton.enabled = false
            self.sendButton.backgroundColor = self.sendButtonDisabledColor
        })
    }
    
    func enableImFullButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.imFullButton.enabled = true
            self.imFullButton.setTitle("I'm full!", forState: .Normal)
            self.imFullButton.backgroundColor = self.imFullButtonEnabledColor
        })
    }
    
    func disableImFullButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.imFullButton.enabled = false
            self.imFullButton.setTitle("Full", forState: .Normal)
            self.imFullButton.backgroundColor = self.imFullButtonDisabledColor
        })
    }
    
    func newPost()
    {
        showingLastSentPost = false
        changeSendButtonToSend()
        newPostTextView.text = nil
        
        UIView.animateWithDuration(0.5, animations: {
            
            self.imFullButton.hidden = true
            self.newPostTextView.backgroundColor = UIColor.whiteColor()
            self.backBorderView.backgroundColor = self.initialBackBorderViewColor
        })
    }
    
    func postMessageToGroup(post:String)
    {
        var params = ["message":post] as NSDictionary
        
        FBRequestConnection.startWithGraphPath("/\(kTestsGroupID)/feed", parameters: params, HTTPMethod: "POST", completionHandler:
            { (connection:FBRequestConnection!, results:AnyObject!, error:NSError!) -> Void in
            
                if error == nil
                {
                    println("message published: \(post)")
                    let postID = results["id"] as String
                    self.postID = postID
                    self.changeSendButtonToPostSentAndUnhideImFullButton()
                    self.newPostTextView.endEditing(true)
                    self.showingLastSentPost = true
                    
                    UIView.animateWithDuration(0.5, animations: {
                        
                        self.newPostTextView.backgroundColor = UIColor.clearColor()
                        self.backBorderView.backgroundColor = UIColor.clearColor()
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
                    
                    self.disableImFullButton()
                }
        })
    }
    
    override func touchesEnded(touches: NSSet, withEvent event: UIEvent)
    {
        newPostTextView.endEditing(true)
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool
    {
        let textViewRange = NSMakeRange(0, countElements(newPostTextView.text))
        
        if (NSEqualRanges(range, textViewRange) && text.isEmpty)
        {
            disableSendButton()
        }
        else
        {
            enableSendButton()
        }
        return true
    }
}
//
//  ViewController.swift
//  Wheels
//
//  Created by Diego on 10/23/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import UIKit
import AudioToolbox

extension String
{
    func contains(string: String) -> Bool
    {
        return self.lowercaseString.rangeOfString(string.lowercaseString) != nil
    }
}

extension Array
{
    func contains<T where T : Equatable>(obj: T) -> Bool {
        return self.filter({$0 as? T == obj}).count > 0
    }
}

class PostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate
{
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var keywordsTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    var posts = [Post]()
    
    let queue = NSOperationQueue()
    var checking = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        keywordsTextField.delegate = self
        timeTextField.delegate = self
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool)
    {
        if let indexPath = tableView.indexPathForSelectedRow()
        {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        start()
    }
    
    func reCheckDeletingRecentPosts(deletingRecentPosts:Bool)
    {
        FBRequestConnection.startWithGraphPath("429208293784763/feed", completionHandler: { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            
            if deletingRecentPosts
            {
                self.posts = []
            }
            
            self.receivedFacebookPostsInfoWithConnection(connection, result: result, error: error)
        })
    }
    
    func receivedFacebookPostsInfoWithConnection(connection: FBRequestConnection!, result: AnyObject!, error: NSError!)
    {
        println("receiving...")
        
        if (error == nil)
        {
            var postsJSON = result["data"] as Array<AnyObject>
            var newPosts = false
            
            for rawPost in postsJSON
            {
                var message = rawPost["message"] as String
                var comments = rawPost["comments"]? as FBGraphObject?
                
                var keywords = keywordsTextField.text.componentsSeparatedByString(" ")
                var containsKewords = false
                var containsTime = message.contains(timeTextField.text) || timeTextField.text.isEmpty
                
                for word in keywords
                {
                    if message.contains(word)
                    {
                        containsKewords = true
                        break
                    }
                }
                
                var full = false
                
                if let actualComments = comments
                {
                    var dataJSON = actualComments["data"] as Array<AnyObject>
                    
                    for comment in dataJSON
                    {
                        var messageComment = comment["message"] as String
                        
                        if messageComment.contains("lleno")
                        {
                            full = true
                            break
                        }
                    }
                }
                
                if containsTime && (containsKewords || keywords[0] == "")
                {
                    var from = rawPost["from"] as FBGraphObject
                    var senderName = from["name"] as String
                    var senderID = from["id"] as String
                    var time = rawPost["created_time"] as String
                    
                    var post = Post(senderName: senderName, senderID: senderID, post: message, time:convertFacebookTimeStringToNSDate(time), full:full)
                    
                    if !posts.contains(post)
                    {
                        posts.insert(post, atIndex: 0)
                        newPosts = true
                    }
                }
            }
            
            if newPosts
            {
                vibrate()
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.tableView.reloadData()
            }
        }
    }
    
    func vibrate()
    {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func notifyPost(post:Post)
    {
        println("new post")
        
        /*var notification = UILocalNotification()
        notification.fireDate = NSDate()
        notification.alertBody = post.post
        notification.soundName = UILocalNotificationDefaultSoundName;

        UIApplication.sharedApplication().scheduleLocalNotification(notification)*/
    }
    
    func start()
    {
        queue.addOperationWithBlock()
        {
            while true
            {
                dispatch_async(dispatch_get_main_queue()) {
                    self.reCheckDeletingRecentPosts(false)
                }
                NSThread.sleepForTimeInterval(30)
            }
        }
    }
    
    func stop()
    {
        queue.cancelAllOperations()
    }
    
    func sendMessageToUser(userID:String)
    {
        var params = FBLinkShareParams()
        
    }
    
    func goToProfilePageOfPersonWithID(ID: String)
    {
        FBRequestConnection.startWithGraphPath("/?id=https://facebook.com/"+ID, completionHandler: { (connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            
            if (error == nil)
            {
                var ngObject = result["og_object"] as FBGraphObject
                var profilePageID = ngObject["id"] as String
                
                var facebookURL = NSURL(string:"fb://profile/" + profilePageID)!
                
                
                if UIApplication.sharedApplication().canOpenURL(facebookURL)
                {
                    UIApplication.sharedApplication().openURL(facebookURL)
                }
                else
                {
                    UIApplication.sharedApplication().openURL( NSURL(string:"http://facebook.com/")! )
                }
            }
        })
    }
    
    func convertFacebookTimeStringToNSDate(time:String) -> NSDate
    {
        var df = NSDateFormatter()
        df.dateFormat = "yyyy'-'MM'-'dd'T'HH:mm:ssZ"
        
        var date = df.dateFromString(time)
        return date!
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return posts.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var post = posts[indexPath.row]
        
        var cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
        cell.textField.text = post.post
        cell.label.text = post.senderName
        cell.full = post.full
        
        var df = NSDateFormatter()
        df.dateFormat = "MMMM dd hh:mm a"
        
        var dateString = df.stringFromDate(post.time!)
        
        cell.timeLabel.text = dateString
        
        //cell.background.layer.borderColor = UIColor.lightGrayColor().CGColor
        //cell.background.layer.borderWidth = 0.2;
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var post = posts[indexPath.row]
        
        goToProfilePageOfPersonWithID(post.senderID)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent)
    {
        keywordsTextField.endEditing(true)
        timeTextField.endEditing(true)
    }
    
    func textFieldDidEndEditing(textField: UITextField)
    {
        reCheckDeletingRecentPosts(true)
    }
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        //reCheck()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        keywordsTextField.endEditing(true)
        timeTextField.endEditing(true)
        return true
    }
}


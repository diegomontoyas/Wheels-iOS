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

func synced(lock: AnyObject, closure: () -> ())
{
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

class PostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate
{
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var keywordsTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    var posts = [Post]()
    var postsDictionary = [String:Post]()
    var currentlyChecking = false
    
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
        objc_sync_enter(currentlyChecking)
        
        if !currentlyChecking
        {
            currentlyChecking = true
            
            FBRequestConnection.startWithGraphPath("429208293784763/feed?limit=50", completionHandler: { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                
                self.receivedFacebookPostsInfoWithConnection(connection, result: result, error: error, deleteRecentPosts:deletingRecentPosts)
            })
        }
        
        objc_sync_exit(currentlyChecking)
    }
    
    func receivedFacebookPostsInfoWithConnection(connection: FBRequestConnection!, result: AnyObject!, error: NSError!, deleteRecentPosts:Bool)
    {
        println("receiving...")
        
        if deleteRecentPosts
        {
            self.posts = []
            self.postsDictionary = [:]
        }
        
        if (error == nil)
        {
            var postsJSON = result["data"] as Array<AnyObject>
            var newPosts = false
            
            for rawPost in postsJSON
            {
                var comments = [Comment]()
                
                var possibleMessageJSON = rawPost["message"] as String?
                
                if let messageJSON = possibleMessageJSON
                {
                    var possibleCommentsJSON = rawPost["comments"]? as FBGraphObject?
                    var postID = rawPost["id"] as String
                    
                    var keywords = keywordsTextField.text.componentsSeparatedByString(" ")
                    var containsKewords = false
                    var containsTime = messageJSON.contains(timeTextField.text) || timeTextField.text.isEmpty
                    
                    for word in keywords
                    {
                        if messageJSON.contains(word)
                        {
                            containsKewords = true
                            break
                        }
                    }
                    
                    var full = false
                    
                    if let commentsJSON = possibleCommentsJSON
                    {
                        var dataJSON = commentsJSON["data"] as Array<AnyObject>
                        
                        for commentJSON in dataJSON
                        {
                            var messageCommentJSON = commentJSON["message"] as String
                            
                            var comment = Comment(comment: messageCommentJSON)
                            comments.append(comment)
                            
                            if messageCommentJSON.contains("lleno") || messageCommentJSON.contains("llena")
                                || ( messageCommentJSON.contains("no") && (messageCommentJSON.contains("quedan") || messageCommentJSON.contains("hay") || messageCommentJSON.contains("tengo")) && messageCommentJSON.contains("cupos") )
                            {
                                full = true
                            }
                        }
                    }
                    
                    if containsTime && (containsKewords || keywords[0] == "")
                    {
                        if let existingPost = postsDictionary[postID]
                        {
                            existingPost.comments = comments
                            existingPost.full = full
                        }
                        else
                        {
                            var from = rawPost["from"] as FBGraphObject
                            var senderName = from["name"] as String
                            var senderID = from["id"] as String
                            var time = rawPost["created_time"] as String
                            
                            var post = Post(ID:postID, senderName: senderName, senderID: senderID, post: messageJSON, time:convertFacebookTimeStringToNSDate(time), full:full)
                            
                            post.comments = comments
                            posts.insert(post, atIndex: 0)
                            postsDictionary[postID] = post
                            newPosts = true
                        }
                    }
                }
            }
            
            if deleteRecentPosts
            {
                posts.sort({ (postA:Post, postB:Post) -> Bool in
                    
                    return postA.time?.compare(postB.time!) == NSComparisonResult.OrderedDescending
                })
            }
            
            if newPosts
            {
                vibrate()
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.tableView.reloadData()
            }
        }
        
        objc_sync_enter(currentlyChecking)
        
        objc_sync_exit(currentlyChecking)
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
        self.reCheckDeletingRecentPosts(true)
        
        queue.addOperationWithBlock()
        {
            while true
            {
                NSThread.sleepForTimeInterval(20)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.reCheckDeletingRecentPosts(false)
                }
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
                
                var facebookURL = NSURL(string:"fb://profile/" + profilePageID)
                
                
                if UIApplication.sharedApplication().canOpenURL(facebookURL!)
                {
                    UIApplication.sharedApplication().openURL(facebookURL!)
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
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return posts.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        var post = posts[section]

        return post.comments.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        var post = posts[indexPath.section]
        
        var cell: PostCell
        
        if indexPath.row == 0
        {
            cell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
            cell.textField.text = post.post
            cell.label.text = post.senderName
            cell.full = post.full
            
            var df = NSDateFormatter()
            df.dateFormat = "MMMM dd hh:mm a"
            
            var dateString = df.stringFromDate(post.time!)
            
            cell.timeLabel.text = dateString
        }
        else
        {
            var comment = post.comments[indexPath.row-1]
            
            cell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as PostCell
            cell.textField.text = comment.comment
            cell.userInteractionEnabled = false
        }
        
        //cell.background.layer.borderColor = UIColor.lightGrayColor().CGColor
        //cell.background.layer.borderWidth = 0.2;
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        var height:CGFloat = 0
        var post = posts[indexPath.section]
        
        if (indexPath.row == 0)
        {
            height = 146
        }
        else
        {
            var comment = post.comments[indexPath.row-1]
            
            height = 64
        }
        
        return height
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        var post = posts[indexPath.section]
        
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


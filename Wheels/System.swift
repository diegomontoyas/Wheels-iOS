//
//  System.swift
//  Wheels
//
//  Created by Diego on 10/30/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation
import AudioToolbox

protocol PostsDelegate: class
{
    func systemDidReceiveNewPosts()
}

private let _systemSharedInstance = System()
let system =  System.S()

let kWheelsGroupID = "429208293784763"

class System
{
    init()
    {
    }
    
    class func S() -> System
    {
        return _systemSharedInstance
    }
    
    weak var postsDelegate:PostsDelegate?
    
    private(set) var posts = [Post]()
    private(set) var postsDictionary = [String:Post]()
    
    private(set) var filters = [String]()
    
    private(set) var currentlyChecking = false
    
    let queue = NSOperationQueue()
    private var numberOfChecks = 0
    private(set) var started = false
    
    func reCheckDeletingRecentPosts(deletingRecentPosts:Bool)
    {
        objc_sync_enter(currentlyChecking)
        
        if !currentlyChecking
        {
            currentlyChecking = true
            
            FBRequestConnection.startWithGraphPath("\(kWheelsGroupID)/feed?limit=100", completionHandler: { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                
                self.receivedFacebookPostsInfoWithConnection(connection, result: result, error: error, deleteRecentPosts:deletingRecentPosts)
            })
        }
        
        objc_sync_exit(currentlyChecking)
    }
    
    func receivedFacebookPostsInfoWithConnection(connection: FBRequestConnection!, result: AnyObject!, error: NSError!, deleteRecentPosts:Bool)
    {
        numberOfChecks++
        println("receiving: \(numberOfChecks)")
        
        if deleteRecentPosts
        {
            self.posts = []
            self.postsDictionary = [:]
        }
        
        if error == nil
        {
            let postsJSON = result["data"] as Array<AnyObject>
            var newPosts = false
            
            for rawPost in postsJSON
            {
                var comments = [Comment]()
                
                let possibleMessageJSON = rawPost["message"] as String?
                
                if let messageJSON = possibleMessageJSON
                {
                    let possibleCommentsJSON = rawPost["comments"]? as FBGraphObject?
                    let postID = rawPost["id"] as String
                    
                    var containsFilters = false
                    var containsTime = true /*= messageJSON.contains(timeTextField.text) || timeTextField.text.isEmpty*/
                    
                    for filter in filters
                    {
                        if messageJSON.contains(filter)
                        {
                            containsFilters = true
                            break
                        }
                    }
                    
                    var full = false
                    
                    if let commentsJSON = possibleCommentsJSON
                    {
                        let dataJSON = commentsJSON["data"] as Array<AnyObject>
                        
                        for commentJSON in dataJSON
                        {
                            let messageCommentJSON = commentJSON["message"] as String
                            
                            var comment = Comment(comment: messageCommentJSON)
                            comments.append(comment)
                            
                            if messageCommentJSON.contains("lleno") || messageCommentJSON.contains("llena")
                                || ( messageCommentJSON.contains("no") && (messageCommentJSON.contains("quedan") || messageCommentJSON.contains("hay") || messageCommentJSON.contains("tengo")) && messageCommentJSON.contains("cupos") )
                            {
                                full = true
                            }
                        }
                    }
                    
                    if containsTime && (containsFilters || filters.isEmpty)
                    {
                        if let existingPost = postsDictionary[postID]
                        {
                            existingPost.comments = comments
                            existingPost.full = full
                        }
                        else
                        {
                            let from = rawPost["from"] as FBGraphObject
                            let senderName = from["name"] as String
                            let senderID = from["id"] as String
                            let time = rawPost["created_time"] as String
                            
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
            else if newPosts
            {
                vibrate()

            }
            
            weak var weakSelf = self
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.postsDelegate?.systemDidReceiveNewPosts()
                ()
            }
        }
        
        objc_sync_enter(currentlyChecking)
        
        currentlyChecking = false
        
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
        if !started
        {
            started = true
            
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
    }
    
    /*func stop()
    {
        queue.cancelAllOperations()
    }*/
    
    func sendMessageToUser(userID:String)
    {
        var params = FBLinkShareParams()
        
    }
    
    func addFilter(filter:String)
    {
        filters.append(filter)
    }
    
    func removeFilterAtIndex(index:Int)
    {
        filters.removeAtIndex(index)
    }
    
    func goToProfilePageOfPersonWithID(ID: String)
    {
        FBRequestConnection.startWithGraphPath("/?id=https://facebook.com/"+ID, completionHandler: { (connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            
            if error == nil
            {
                let ngObject = result["og_object"] as FBGraphObject
                let profilePageID = ngObject["id"] as String
                
                let facebookURL = NSURL(string:"fb://profile/" + profilePageID)
                
                println(profilePageID)
                println(ID)
                
                if UIApplication.sharedApplication().canOpenURL(facebookURL!)
                {
                    UIApplication.sharedApplication().openURL(facebookURL!)
                }
                else
                {
                    UIApplication.sharedApplication().openURL( NSURL(string:"http://facebook.com/"+ID)!)
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

}


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
    
    func systemDidDeleteUnnecessaryResources()
}

private let _systemSharedInstance = System()
let system =  System.S()

let serverIP = "192.168.0.15"
let serverPort = "8080"
let serverAppPath = "/WheelsServer"
let serverPath = "http://\(serverIP):\(serverPort + serverAppPath)"

let kWheelsGroupID = "429208293784763"

let kUseFacebookDeveloperConnection = true

class System: NSObject
{
    let getPostsQueue = NSOperationQueue()
    let processPostsQueue = NSOperationQueue()
    
    let reCheckInterval = 20.0
    
    weak var postsDelegate:PostsDelegate?
    
    private(set) var lastCheckPosts = [Post]()
    private var mutablePosts = [Post]()
    private var postsDictionary = [String:Post]()
    
    private(set) var filters = [String]()
    
    private(set) var currentlyChecking = false
    
    private var checkLock = NSObject()
    
    private(set) var started = false
    
    private var checkOperationCount = 0
    
    private var checkAfterFilterChangeTimer: NSTimer?
    
    override init()
    {
        super.init()
        
        getPostsQueue.maxConcurrentOperationCount = 1
        processPostsQueue.maxConcurrentOperationCount = 1
    }
    
    class func S() -> System
    {
        return _systemSharedInstance
    }
    
    func start()
    {
        if !started
        {
            started = true
            
            self.reCheckDeletingRecentPosts(true)
            
            NSTimer.scheduledTimerWithTimeInterval(self.reCheckInterval, target: self, selector: Selector("postsTimerTicked:"), userInfo: nil, repeats: true)
        }
    }
    
    func postsTimerTicked(timer:NSTimer)
    {
        let closure: () -> Void = {
            
            self.reCheckDeletingRecentPosts(false)
        }
        
        getPostsQueue.addOperationWithBlock(closure)
    }
    
    func reCheckDeletingRecentPosts(deletingRecentPosts:Bool)
    {
        checkOperationCount++
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        
        var urlString = "\(serverPath)/getFeed"
        var url = NSURL(string: urlString)
        
        var request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "GET"
        request.timeoutInterval = 2;
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response:NSURLResponse!, data:NSData!, error:NSError!) -> Void in
            
            if data != nil
            {
                println("Received: \(NSDate())")
             
                self.checkOperationCount--
                if self.checkOperationCount == 0
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
                let closure: () -> Void = {
                    
                    self.receivedFacebookPostsInfoWithResponse(response, data: data, error: error, deleteRecentPosts:deletingRecentPosts)
                }
                
                self.processPostsQueue.addOperationWithBlock(closure)
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()){
                    
                    let limit = deletingRecentPosts ? 200 : 50
                    
                    FBRequestConnection.startWithGraphPath("\(kWheelsGroupID)/feed?limit=\(limit)", completionHandler: { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                        
                        println("Received: \(NSDate())")
                        
                        self.checkOperationCount--
                        if self.checkOperationCount == 0
                        {
                            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        }
                        
                        let closure: () -> Void = {
                            
                            self.receivedFacebookPostsInfoWithConnection(connection, result: result, error: error, deleteRecentPosts:deletingRecentPosts)
                        }
                        
                        self.processPostsQueue.addOperationWithBlock(closure)
                    })
                    return
                }
            }
        })
        
    }
    
    private func receivedFacebookPostsInfoWithResponse(response:NSURLResponse!, data:NSData!, error:NSError!, deleteRecentPosts:Bool)
    {
        if deleteRecentPosts
        {
            self.mutablePosts = []
            self.postsDictionary = [:]
        }
        
        if error == nil
        {
            let JSONResponse:AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil)
            
            if JSONResponse != nil
            {
                let postsJSON = JSONResponse["data"] as [AnyObject]
                var newPosts = false
                
                for rawPost in postsJSON
                {
                    var comments = [Comment]()
                    
                    let possibleMessageJSON = rawPost["message"] as String?
                    
                    if let messageJSON = possibleMessageJSON
                    {
                        let possibleCommentsJSON = rawPost["comments"]? as [AnyObject]?
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
                            for commentJSON in commentsJSON
                            {
                                let messageCommentJSON = commentJSON["message"] as String
                                
                                if !messageCommentJSON.isEmpty
                                {
                                    var comment = Comment(comment: messageCommentJSON)
                                    comments.append(comment)
                                    
                                    if messageCommentJSON.contains("lleno") || messageCommentJSON.contains("llena")
                                        || ( messageCommentJSON.contains("no") && (messageCommentJSON.contains("quedan") || messageCommentJSON.contains("hay") || messageCommentJSON.contains("tengo")) && messageCommentJSON.contains("cupos") )
                                    {
                                        full = true
                                    }
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
                                let from = rawPost["from"] as AnyObject!
                                let senderName = from["name"] as String
                                let senderID = from["id"] as String
                                let time = rawPost["createdTime"] as String
                                
                                var post = Post(ID:postID, senderName: senderName, senderID: senderID, post: messageJSON, time:convertServerTimeStringToNSDate(time), full:full)
                                
                                post.comments = comments
                                mutablePosts.insert(post, atIndex: 0)
                                postsDictionary[postID] = post
                                newPosts = true
                            }
                        }
                    }
                }
                
                if deleteRecentPosts
                {
                    mutablePosts.sort({ (postA:Post, postB:Post) -> Bool in
                        
                        return postA.time?.compare(postB.time!) == NSComparisonResult.OrderedDescending
                    })
                }
                else if newPosts
                {
                    vibrate()
                }
                
                lastCheckPosts = mutablePosts
                
                dispatch_async(dispatch_get_main_queue()) {
                    
                    self.postsDelegate?.systemDidReceiveNewPosts()
                    ()
                }
            }
        }
    }
    
    private func receivedFacebookPostsInfoWithConnection(connection: FBRequestConnection!, result: AnyObject!, error: NSError!, deleteRecentPosts:Bool)
    {
        if deleteRecentPosts
        {
            self.mutablePosts = []
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
                            mutablePosts.insert(post, atIndex: 0)
                            postsDictionary[postID] = post
                            newPosts = true
                        }
                    }
                }
            }
            
            if deleteRecentPosts
            {
                mutablePosts.sort({ (postA:Post, postB:Post) -> Bool in
                    
                    return postA.time?.compare(postB.time!) == NSComparisonResult.OrderedDescending
                })
            }
            else if newPosts
            {
                vibrate()
                
            }
            
            lastCheckPosts = mutablePosts
            
            dispatch_async(dispatch_get_main_queue()) {
                
                self.postsDelegate?.systemDidReceiveNewPosts()
                ()
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
    
    /*func stop()
    {
    queue.cancelAllOperations()
    }*/
    
    func addFilter(filter:String)
    {
        filters.append(filter)
        schedulePostCheckDeletingRecentPostsAfterInterval()
    }
    
    func removeFilterAtIndex(index:Int)
    {
        filters.removeAtIndex(index)
        schedulePostCheckDeletingRecentPostsAfterInterval()
    }
    
    private func schedulePostCheckDeletingRecentPostsAfterInterval ()
    {
        if checkAfterFilterChangeTimer != nil && checkAfterFilterChangeTimer!.valid
        {
            checkAfterFilterChangeTimer!.invalidate()
        }
        
        let block = NSBlockOperation {
            
            system.reCheckDeletingRecentPosts(true)
        }
        
        checkAfterFilterChangeTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: block, selector: Selector("main"), userInfo: nil, repeats: false)
    }
    
    func goToProfilePageOfPersonWithID(ID: String)
    {
        FBRequestConnection.startWithGraphPath("/?id=http://facebook.com/"+ID, completionHandler: { (connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            
            if error == nil
            {
                let ngObject = result["og_object"] as FBGraphObject
                let profilePageID = ngObject["id"] as String
                
                let facebookURL = NSURL(string:"fb://page?id=" + profilePageID)
                
                if false && UIApplication.sharedApplication().canOpenURL(facebookURL!)
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
    
    func convertServerTimeStringToNSDate(time:String) -> NSDate
    {
        var df = NSDateFormatter()
        df.dateFormat = "dd MM yyyy HH:mm:ss"
        
        var date = df.dateFromString(time)
        return date!
    }
    
    func deleteUnnecessaryResources()
    {
        for post in mutablePosts
        {
            post.senderPhoto = nil
            
            dispatch_async(dispatch_get_main_queue())
                {
                    self.postsDelegate?.systemDidReceiveNewPosts()
                    ()
            }
        }
    }
}


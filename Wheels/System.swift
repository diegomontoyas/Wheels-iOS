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

let serverIP = "157.253.238.87"
let serverPort = "8080"
let serverAppPath = ""
let serverPath = "http://\(serverIP):\(serverPort + serverAppPath)"

let kWheelsGroupID = "429208293784763"

let kUseFacebookDeveloperConnection = true

class System: NSObject
{
    let processPostsQueuePeriodic = NSOperationQueue()
    let processPostsQueueUserInvoked = NSOperationQueue()
    
    let reCheckInterval = 10.0
    
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
        
        processPostsQueuePeriodic.maxConcurrentOperationCount = 1
        processPostsQueuePeriodic.qualityOfService = NSQualityOfService.Utility
        
        processPostsQueueUserInvoked.maxConcurrentOperationCount = 1
        processPostsQueueUserInvoked.qualityOfService = NSQualityOfService.UserInitiated
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
        self.reCheckDeletingRecentPosts(false)
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
        
        let certPath = NSBundle.mainBundle().pathForResource("wheelsserver", ofType:"keystore")
        let certificateData = NSData(contentsOfFile: certPath!)
        
        let connection = WrappedNSURLConnection(request: request)
        connection.certificateData = certificateData
        
        NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue()) {(response:NSURLResponse!, data:NSData!, error:NSError!) -> Void in
            
            if data != nil
            {
                println("Received from backend: \(NSDate())")
                
                self.checkOperationCount--
                
                if self.checkOperationCount == 0
                {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                }
                
                let JSONResponse = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary!
                let postsJSON = JSONResponse["data"] as! [AnyObject]
                
                if deletingRecentPosts
                {
                    self.processPostsQueueUserInvoked.addOperationWithBlock {
                        
                        self.receivedFacebookPostsInfoWithJSONData(postsJSON, error: error, deleteRecentPosts:deletingRecentPosts)
                    }
                }
                else
                {
                    self.processPostsQueuePeriodic.addOperationWithBlock {
                        
                        self.receivedFacebookPostsInfoWithJSONData(postsJSON, error: error, deleteRecentPosts:deletingRecentPosts)
                    }
                }
            }
            else
            {
                dispatch_async(dispatch_get_main_queue()){
                    
                    let limit = deletingRecentPosts ? 100 : 20
                    
                    FBRequestConnection.startWithGraphPath("\(kWheelsGroupID)/feed?limit=\(limit)", completionHandler: { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
                        
                        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)){
                        
                            println("Didn't receive from backend, received from facebook: \(NSDate())")
                            
                            var JSONPosts = result["data"] as! [AnyObject]
                            
                            var currentJSONPaging = result["paging"] as! NSDictionary
                            var currentJSONPagingResponse = result as! NSDictionary
                            
                            while let nextPageURLString = currentJSONPaging["next"] as? String
                            {
                                let nextPageURL =  NSURL(string: nextPageURLString)!
                                var request = NSMutableURLRequest(URL: nextPageURL)
                                request.HTTPMethod = "GET"
                                request.timeoutInterval = 2
                                
                                let pagingData = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil)
                                
                                currentJSONPagingResponse = NSJSONSerialization.JSONObjectWithData(pagingData!, options: NSJSONReadingOptions.MutableContainers, error: nil) as! NSDictionary!
                                
                                let JSONArray = currentJSONPagingResponse["data"] as! [AnyObject]
                                JSONPosts += JSONArray
                                
                                if JSONPosts.count >= limit
                                {
                                    break
                                }
                                
                                currentJSONPaging = currentJSONPagingResponse["paging"] as! NSDictionary
                            }
                            
                            self.checkOperationCount--
                            
                            if self.checkOperationCount == 0
                            {
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                            }
                            
                            if deletingRecentPosts
                            {
                                self.processPostsQueueUserInvoked.addOperationWithBlock {
                                    
                                    self.receivedFacebookPostsInfoWithJSONData(JSONPosts, error: error, deleteRecentPosts:deletingRecentPosts)
                                }
                            }
                            else
                            {
                                self.processPostsQueuePeriodic.addOperationWithBlock {
                                    
                                    self.receivedFacebookPostsInfoWithJSONData(JSONPosts, error: error, deleteRecentPosts:deletingRecentPosts)
                                }
                            }
                        }
                    })
                    return
                }
            }
        }
    }
    
    /*private func receivedFacebookPostsInfoWithResponse(response:NSURLResponse!, JSONResponse:NSDictionary!, error:NSError?, deleteRecentPosts:Bool)
    {
        if deleteRecentPosts
        {
            self.mutablePosts = []
            self.postsDictionary = [:]
        }
        
        if error == nil
        {
            if JSONResponse != nil
            {
                let postsJSON = JSONResponse["data"] as! [NSDictionary]
                var newPosts = false
                
                for rawPost in postsJSON
                {
                    var comments = [Comment]()
                    
                    let possibleMessageJSON = rawPost["message"] as? String
                    
                    if let messageJSON = possibleMessageJSON
                    {
                        let possibleCommentsJSON = rawPost["comments"] as! [NSDictionary]?
                        let postID = rawPost["id"] as! String
                        
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
                                let messageCommentJSON = commentJSON["message"] as! String
                                
                                if !messageCommentJSON.isEmpty
                                {
                                    var comment = Comment(comment: messageCommentJSON)
                                    comments.append(comment)
                                    
                                    let postSenderJSON = rawPost["from"] as! NSDictionary!
                                    let postSenderID = postSenderJSON["id"] as! String
                                    
                                    let commentSenderJSON = commentJSON["from"] as! NSDictionary!
                                    let commentSenderID = commentSenderJSON["id"] as! String
                                    
                                    if commentSenderID == postSenderID
                                    {
                                        if messageCommentJSON.contains("lleno") || messageCommentJSON.contains("llena")
                                            || ( messageCommentJSON.contains("no") && (messageCommentJSON.contains("quedan") || messageCommentJSON.contains("hay") || messageCommentJSON.contains("tengo")) && messageCommentJSON.contains("cupos") )
                                        {
                                            full = true
                                        }
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
                                let from = rawPost["from"] as! NSDictionary!
                                let senderName = from["name"] as! String
                                let senderID = from["id"] as! String
                                let time = rawPost["createdTime"] as! String
                                
                                var post = Post(ID:postID, senderName: senderName, senderID: senderID, post: messageJSON, time:convertServerTimeStringToNSDate(time), full:full)
                                
                                post.comments = comments
                                mutablePosts.insert(post, atIndex: 0)
                                postsDictionary[postID] = post
                                newPosts = true
                            }
                        }
                    }
                }
                
                mutablePosts.sort({ (postA:Post, postB:Post) -> Bool in
                    
                    return postA.time?.compare(postB.time!) == NSComparisonResult.OrderedDescending
                })
                
                lastCheckPosts = mutablePosts
                
                if !deleteRecentPosts && newPosts
                {
                    self.vibrate()
                }
                
                self.postsDelegate?.systemDidReceiveNewPosts()
            }
        }
    }*/
    
    private func receivedFacebookPostsInfoWithJSONData(JSONData: [AnyObject]!, error: NSError!, deleteRecentPosts:Bool)
    {
        if deleteRecentPosts
        {
            self.mutablePosts = []
            self.postsDictionary = [:]
        }
        
        if error == nil
        {
            let postsJSON = JSONData
            var newPosts = false
            
            for rawPost in postsJSON
            {
                var comments = [Comment]()
                
                let possibleMessageJSON = rawPost["message"] as! String?
                
                if let messageJSON = possibleMessageJSON
                {
                    let possibleCommentsJSON = rawPost["comments"] as! NSDictionary?
                    let postID = rawPost["id"] as! String
                    
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
                        // if Fecebook
                        let commentDataJSON = commentsJSON["data"] as! [AnyObject]
                        
                        for commentJSON in commentDataJSON
                        {
                            let messageCommentJSON = commentJSON["message"] as! String
                            
                            var comment = Comment(comment: messageCommentJSON)
                            comments.append(comment)
                            
                            let postSenderJSON = rawPost["from"] as AnyObject!
                            let postSenderID = postSenderJSON["id"] as! String
                            
                            let commentSenderJSON = commentJSON["from"] as AnyObject!
                            let commentSenderID = commentSenderJSON["id"] as! String
                            
                            if commentSenderID == postSenderID
                            {
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
                            let from = rawPost["from"] as! NSDictionary
                            let senderName = from["name"] as! String
                            let senderID = from["id"] as! String
                            let time = rawPost["created_time"] as! String
                            
                            var post = Post(ID:postID, senderName: senderName, senderID: senderID, post: messageJSON, time:convertFacebookTimeStringToNSDate(time), full:full)
                            
                            /*var post = Post(ID:postID, senderName: senderName, senderID: senderID, post: messageJSON, time:convertServerTimeStringToNSDate(time), full:full)*/
                            
                            post.comments = comments
                            mutablePosts.insert(post, atIndex: 0)
                            postsDictionary[postID] = post
                            newPosts = true
                        }
                    }
                }
            }
            
            mutablePosts.sort({ (postA:Post, postB:Post) -> Bool in
                
                return postA.time?.compare(postB.time!) == NSComparisonResult.OrderedDescending
            })
            
            lastCheckPosts = mutablePosts
            
            if !deleteRecentPosts && newPosts
            {
                self.vibrate()
            }
            
            self.postsDelegate?.systemDidReceiveNewPosts()
        }
    }
    
    func vibrate()
    {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func notifyPost(post:Post)
    {
        println("new post")
    }
    
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
    
    func goToPostPageOfPostWithID(ID: String)
    {
        UIApplication.sharedApplication().openURL( NSURL(string:"http://facebook.com/"+ID)!)
    }
    
    func goToProfilePageOfPersonWithID(ID: String)
    {
        UIApplication.sharedApplication().openURL( NSURL(string:"http://facebook.com/"+ID)!)

        /*FBRequestConnection.startWithGraphPath("/?id=http://facebook.com/"+ID, completionHandler: { (connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            
            if error == nil
            {
                let ngObject = result["og_object"] as! FBGraphObject
                let profilePageID = ngObject["id"] as! String
                
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
        })*/
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


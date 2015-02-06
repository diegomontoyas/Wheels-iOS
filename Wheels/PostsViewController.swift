//
//  ViewController.swift
//  Wheels
//
//  Created by Diego on 10/23/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import UIKit

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

extension UIView
{
    func setCornerRadiusWithoutClipToBounds(cornerRadius:CGFloat)
    {
        let roundRectMaskPath = UIBezierPath(roundedRect: bounds, cornerRadius: CGFloat(5))
        
        let roundRectMaskLayer = CAShapeLayer()
        roundRectMaskLayer.frame = bounds
        roundRectMaskLayer.path = roundRectMaskPath.CGPath
        layer.mask = roundRectMaskLayer
    }
}

class PostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, PostsDelegate
{
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var grabber: UIView!
    @IBOutlet weak var settingsButton: UIView!
    
    weak var mainPageViewController:MainPageViewController?
    
    private(set) var prototypePostCell:PostCell!
    private(set) var prototypeCommentCell:CommentCell!
    
    let imageLoadingOperationQueue = NSOperationQueue()
    let imageProcessingOperationQueue = NSOperationQueue()

    private(set) var imageLoadingOngoingOperations = [NSIndexPath:NSBlockOperation]()
    
    let downloadedPhotoDimensions = "90"
    let photoImageViewSize:CGFloat = 52
    let nilImagePhotoImageViewSize:CGFloat = 14
    
    var postsAndComments = [AnyObject]()
    var cellHeights = [CGFloat]()
    
    var loadingData = false
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        system.postsDelegate = self
        
        imageLoadingOperationQueue.qualityOfService = NSQualityOfService.UserInteractive
        imageProcessingOperationQueue.qualityOfService = NSQualityOfService.UserInteractive
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 50.0, 0.0)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: Selector("grabberTapped:"))
        
        grabber.layer.cornerRadius = 20
        view.bringSubviewToFront(grabber)
        
        //grabber.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewWillAppear(animated: Bool)
    {
        prototypePostCell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
        prototypeCommentCell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as CommentCell
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        if let indexPath = tableView.indexPathForSelectedRow()
        {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        system.start()
    }
    
    func loadPostsInfoAndPrepareTableView()
    {
        loadingData = true
        
        var mutablePostsAndComments = [AnyObject]()
        
        for post in system.lastCheckPosts
        {
            mutablePostsAndComments.append(post)
            
            for comment in post.comments
            {
                mutablePostsAndComments.append(comment)
            }
        }
        
        var mutableCellHeights = [CGFloat]()
        var i = 0
        
        for postOrComment in mutablePostsAndComments
        {
            var height:CGFloat = 0
            
            if let post = postOrComment as? Post
            {
                let font = UIFont.systemFontOfSize(14)
                let attributedText = NSAttributedString(string: post.post, attributes: [NSFontAttributeName: font])
                
                let rect = attributedText.boundingRectWithSize(CGSizeMake(prototypePostCell.width, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
                
                let size = rect.size
                height = size.height + prototypePostCell.heightWithoutTextField
            }
            else
            {
                let comment = postOrComment as Comment
                
                let font = UIFont.systemFontOfSize(14)
                let attributedText = NSAttributedString(string: comment.comment, attributes: [NSFontAttributeName: font])
                
                let rect = attributedText.boundingRectWithSize(CGSizeMake(prototypeCommentCell.width, CGFloat.max), options: NSStringDrawingOptions.UsesLineFragmentOrigin, context: nil)
                
                let size = rect.size
                height = size.height + prototypeCommentCell.heightWithoutTextField
            }
            
            mutableCellHeights.append(height)
            i++
        }
        
        postsAndComments = mutablePostsAndComments
        cellHeights = mutableCellHeights
        
        tableView.delegate = self
        tableView.dataSource = self
        
        loadingData = false
    }
    
    func grabberTapped(sender:AnyObject)
    {
        mainPageViewController?.controllerGrabberPressed(self)
    }
    
    func systemDidReceiveNewPosts()
    {
        loadPostsInfoAndPrepareTableView()
        
        dispatch_async(dispatch_get_main_queue()){
            
            self.tableView.reloadData()
        }
    }
    
    func systemDidDeleteUnnecessaryResources()
    {
        loadPostsInfoAndPrepareTableView()

        dispatch_async(dispatch_get_main_queue()){
            
            self.tableView.reloadData()
        }
    }
    
    //TableView DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return postsAndComments.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let postOrComment: AnyObject = postsAndComments[indexPath.row]
        var cell:UITableViewCell
        
        if let post = postOrComment as? Post
        {
            let postCell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
            
            postCell.photoImageView.image = nil
            
            if postCell.photoImageView.image == nil
            {
                postCell.photoWidthConstraint.constant = nilImagePhotoImageViewSize
                postCell.photoHeightConstraint.constant = nilImagePhotoImageViewSize
                
                postCell.layoutIfNeeded()
                postCell.updateConstraintsIfNeeded()
            }
            
            findPhotoForCell(postCell, post:post, atIndexPath: indexPath)
            
            postCell.contentView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
            
            postCell.textField.text = post.post
            postCell.label.text = post.senderName
            postCell.full = post.full
            
            postCell.photoImageView.clipsToBounds = true
            
            postCell.backBorderView.layer.cornerRadius = 8
            postCell.contentBackground.layer.cornerRadius = 8
            
            var dateformatter = NSDateFormatter()
            dateformatter.dateFormat = "MMMM dd hh:mm a"
            
            var timeInterval = 60*60*24*7 as NSTimeInterval
            
            var dateString = post.time?.timeAgoWithLimit(timeInterval, dateFormatter: dateformatter)
            
            postCell.timeLabel.text = dateString
            
            cell = postCell
        }
        else
        {            
            let comment = postOrComment as Comment
            
            let commentCell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as CommentCell
            commentCell.textField.text = comment.comment
            commentCell.userInteractionEnabled = false
            
            commentCell.background.clipsToBounds = true
            commentCell.background.layer.cornerRadius = 8
            
            cell = commentCell
        }
        
        return cell
    }
        
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        return cellHeights[indexPath.row]
    }
    
    //TableView Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let post = postsAndComments[indexPath.row] as Post
        
        system.goToProfilePageOfPersonWithID(post.senderID)
    }
    
    func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as PostCell
    }
    
    func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath)
    {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as PostCell
    }
    
    func findPhotoForCell(cell:PostCell, post:Post, atIndexPath indexPath:NSIndexPath)
    {
        if let cachedPhoto = post.senderPhoto
        {
            cell.photoImageView?.image = cachedPhoto
            
            cell.photoWidthConstraint.constant = self.photoImageViewSize
            cell.photoHeightConstraint.constant = self.photoImageViewSize
            cell.photoImageView.layer.cornerRadius = self.photoImageViewSize/2
        }
        else
        {
            let blockOperation = NSBlockOperation()
            blockOperation.qualityOfService = NSQualityOfService.UserInteractive
            blockOperation.queuePriority = NSOperationQueuePriority.VeryHigh
            weak var weakBlockOperation = blockOperation
            
            blockOperation.addExecutionBlock()
                {
                    dispatch_async(dispatch_get_main_queue())
                        {
                            if weakBlockOperation != nil && !weakBlockOperation!.cancelled
                            {
                                /*var url = NSURL(string: "http://graph.facebook.com/\(post.senderID)/picture?redirect=false&height=\(self.downloadedPhotoDimensions)&width=\(self.downloadedPhotoDimensions)&type=normal")
                                
                                var request = NSMutableURLRequest(URL: url!)
                                request.HTTPMethod = "GET"
                                
                                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response:NSURLResponse!, data:NSData!, error:NSError!) -> Void in
                                
                                
                                })*/
                                
                                let params = ["redirect":"false","height":self.downloadedPhotoDimensions, "width":self.downloadedPhotoDimensions, "type":"normal"]
                                
                                FBRequestConnection.startWithGraphPath("/\(post.senderID)/picture", parameters:params, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                                    
                                    
                                    if error == nil
                                    {
                                        let data = result["data"] as FBGraphObject
                                        let photoURLString = data["url"] as String
                                        let photoURL = NSURL(string: photoURLString)
                                        
                                        if weakBlockOperation != nil && !weakBlockOperation!.cancelled
                                        {
                                            var request = NSMutableURLRequest(URL: photoURL!)
                                            request.HTTPMethod = "GET"
                                            request.timeoutInterval = 2;
                                            
                                            NSURLConnection.sendAsynchronousRequest(request, queue: self.imageProcessingOperationQueue, completionHandler: { (response:NSURLResponse!, photoData:NSData!, error:NSError!) -> Void in
                                                
                                                if photoData != nil
                                                {
                                                    let photo = photoData != nil ? UIImage(data: photoData!) : nil
                                                    
                                                    if photo != nil
                                                    {
                                                        dispatch_async(dispatch_get_main_queue()){
                                                            
                                                            post.senderPhoto = photo
                                                            
                                                            if weakBlockOperation != nil && !weakBlockOperation!.cancelled
                                                            {
                                                                cell.photoImageView.image = photo
                                                                cell.photoImageView.layer.cornerRadius = self.photoImageViewSize/2
                                                                
                                                                cell.layoutIfNeeded()
                                                                
                                                                
                                                                UIView.animateWithDuration(0.2, animations: {
                                                                    
                                                                    cell.photoWidthConstraint.constant = self.photoImageViewSize
                                                                    cell.photoHeightConstraint.constant = self.photoImageViewSize
                                                                    
                                                                    cell.layoutIfNeeded()
                                                                    
                                                                    }, completion: {(_) -> Void in
                                                                        
                                                                        cell.photoImageView.layer.cornerRadius = cell.photoImageView.frame.size.height/2
                                                                })
                                                            }
                                                            
                                                            self.imageLoadingOngoingOperations.removeValueForKey(indexPath)
                                                        }
                                                    }
                                                }
                                            })
                                        }
                                        else
                                        {
                                            self.imageLoadingOngoingOperations.removeValueForKey(indexPath)
                                        }
                                    }
                                })
                            }
                            else
                            {
                                self.imageLoadingOngoingOperations.removeValueForKey(indexPath)
                            }
                    }
            }
            
            self.imageLoadingOngoingOperations[indexPath] = blockOperation
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC))), dispatch_get_main_queue())
                {
                    self.imageLoadingOperationQueue.addOperationAtFrontOfQueue(blockOperation)
            }
        }
    }
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath)
    {
        if let operation = imageLoadingOngoingOperations[indexPath]
        {
            operation.cancel()
        }
    }
    
    override func didReceiveMemoryWarning()
    {
        system.deleteUnnecessaryResources()
    }
}


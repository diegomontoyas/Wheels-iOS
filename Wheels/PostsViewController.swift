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
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
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
                
        prototypePostCell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
        prototypeCommentCell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as CommentCell
    }
    
    override func viewWillAppear(animated: Bool)
    {
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
    
    func grabberTapped(sender:AnyObject)
    {
        mainPageViewController?.controllerGrabberPressed(self)
    }
    
    func systemDidReceiveNewPosts()
    {
        tableView.reloadData()
    }
    
    func systemDidDeleteUnnecessaryResources()
    {
        tableView.reloadData()
    }
    
    //TableView DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return system.lastCheckPosts.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let post = system.lastCheckPosts[section]

        return post.comments.count + 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let post = system.lastCheckPosts[indexPath.section]
        var cell:UITableViewCell
        
        if indexPath.row == 0
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
            let comment = post.comments[indexPath.row-1]
            
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
        var height:CGFloat = 0
        let post = system.lastCheckPosts[indexPath.section]
        
        if (indexPath.row == 0)
        {
            var textView = UITextView()
            textView.text = post.post
            textView.font = prototypePostCell.textField.font
            let size = textView.sizeThatFits(CGSizeMake(prototypePostCell.width, CGFloat.max))
            
            height = size.height + prototypePostCell.heightWithoutTextField
        }
        else
        {
            var comment = post.comments[indexPath.row-1]
            
            var textView = UITextView()
            textView.text = comment.comment
            textView.font = prototypeCommentCell.textField.font
            let size = textView.sizeThatFits(CGSizeMake(prototypeCommentCell.width, CGFloat.max))
            
            height = size.height + prototypeCommentCell.heightWithoutTextField
        }
        
        return height
    }
    
    //TableView Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let post = system.lastCheckPosts[indexPath.section]
        
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
        if indexPath.row == 0
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


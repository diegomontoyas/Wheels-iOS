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

func synced(lock: AnyObject, closure: () -> ())
{
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

class PostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, PostsDelegate
{
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var grabber: UIView!
    
    weak var mainPageViewController:MainPageViewController?
    
    private(set) var prototypePostCell:PostCell!
    private(set) var prototypeCommentCell:CommentCell!
    
    let imageLoadingOperationQueue = NSOperationQueue()
    private(set) var imageLoadingOngoingOperations = [NSIndexPath:NSBlockOperation]()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        system.postsDelegate = self
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.addTarget(self, action: Selector("grabberTapped:"))
        
        grabber.layer.cornerRadius = 20
        view.bringSubviewToFront(grabber)
        
        grabber.addGestureRecognizer(tapGestureRecognizer)
        
        prototypePostCell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
        prototypeCommentCell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as CommentCell
    }
    
    override func viewWillAppear(animated: Bool)
    {
        view.setNeedsLayout()
        view.setNeedsDisplay()
        view.setNeedsUpdateConstraints()
    }
    
    override func viewDidAppear(animated: Bool)
    {
        super.viewDidAppear(animated)
        
        //UIAlertView(title: "Push Notifications", message: "Once you start adding filters you will be automatically notified of new posts containing those filters, no need to do anything additional ;). If you wish to stop receiving notifications, simply remove all filters", delegate: self, cancelButtonTitle: "OK").show()
        
        
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
    
    //TableView DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int
    {
        return system.posts.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let post = system.posts[section]

        return post.comments.count + 1
    }
    
    let nilImagePhotoImageViewSize:CGFloat = 14
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let post = system.posts[indexPath.section]
        var cell:UITableViewCell
        
        if indexPath.row == 0
        {
            let postCell = tableView.dequeueReusableCellWithIdentifier("PostCell") as PostCell
            
            postCell.photoImageView.image = nil

            findPhotoForCell(postCell, atIndexPath: indexPath)
            
            if postCell.photoImageView.image == nil
            {
                postCell.photoWidthConstraint.constant = nilImagePhotoImageViewSize
                postCell.photoHeightConstraint.constant = nilImagePhotoImageViewSize
            
                postCell.layoutIfNeeded()
                postCell.setNeedsUpdateConstraints()
            }
            
            postCell.contentView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
            
            postCell.textField.text = post.post
            postCell.label.text = post.senderName
            postCell.full = post.full
            
            postCell.photoImageView.clipsToBounds = true
            
            postCell.backBorderView.layer.cornerRadius = 8
            postCell.contentBackground.layer.cornerRadius = 8
            
            var df = NSDateFormatter()
            df.dateFormat = "MMMM dd hh:mm a"
            
            var dateString = df.stringFromDate(post.time!)
            
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
        let post = system.posts[indexPath.section]
        
        if (indexPath.row == 0)
        {
            var textView = UITextView()
            textView.text = post.post
            textView.font = prototypePostCell.textField.font
            let size = textView.sizeThatFits(CGSizeMake(prototypePostCell.textField.frame.size.width, CGFloat.max))
            
            height = size.height + prototypePostCell.heightWithoutTextField
        }
        else
        {
            var comment = post.comments[indexPath.row-1]
            
            var textView = UITextView()
            textView.text = comment.comment
            textView.font = prototypeCommentCell.textField.font
            let size = textView.sizeThatFits(CGSizeMake(prototypeCommentCell.frame.size.width, CGFloat.max))
            
            height = size.height + prototypeCommentCell.heightWithoutTextField
        }
        
        return height
    }
    
    //TableView Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let post = system.posts[indexPath.section]
        
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
    
    let downloadedPhotoDimensions = "90"
    let photoImageViewSize:CGFloat = 52
    
    func findPhotoForCell(cell:PostCell, atIndexPath indexPath:NSIndexPath)
    {
        let post = system.posts[indexPath.section]
        
        if indexPath.row == 0
        {
            if let cachedPhoto = post.senderPhoto
            {
                cell.photoImageView?.image = cachedPhoto
                
                cell.photoWidthConstraint.constant = self.photoImageViewSize
                cell.photoHeightConstraint.constant = self.photoImageViewSize
                cell.photoImageView.layer.cornerRadius = self.photoImageViewSize/2
                
                cell.setNeedsUpdateConstraints()
                cell.layoutIfNeeded()
            }
            else
            {
                let params = ["redirect":"false","height":self.downloadedPhotoDimensions, "width":self.downloadedPhotoDimensions, "type":"normal"]
                
                FBRequestConnection.startWithGraphPath("/\(post.senderID)/picture", parameters:params, HTTPMethod: "GET", completionHandler: { (connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
                    
                    if error == nil
                    {
                        let blockOperation = NSBlockOperation()
                        weak var weakBlockOperation = blockOperation
                        
                        blockOperation.addExecutionBlock()
                        {
                            let data = result["data"] as FBGraphObject
                            let photoURLString = data["url"] as String
                            let photoURL = NSURL(string: photoURLString)
                            
                            let photo = UIImage(data: NSData(contentsOfURL: photoURL!)!)
                            
                            NSOperationQueue.mainQueue().addOperationWithBlock()
                            {
                                post.senderPhoto = photo
                                
                                if let nonNilblockOperation = weakBlockOperation
                                {
                                    if !nonNilblockOperation.cancelled
                                    {
                                        self.imageLoadingOngoingOperations.removeValueForKey(indexPath)
                                        
                                        cell.photoImageView?.image = photo
                                        cell.photoImageView.layer.cornerRadius = self.photoImageViewSize/2
                                        
                                        cell.setNeedsUpdateConstraints()
                                        cell.layoutIfNeeded()
                                        
                                        UIView.animateWithDuration(0.2, animations: {
                                            
                                            cell.photoWidthConstraint.constant = self.photoImageViewSize
                                            cell.photoHeightConstraint.constant = self.photoImageViewSize
                                            
                                            cell.setNeedsUpdateConstraints()
                                            cell.layoutIfNeeded()
                                            
                                            }, completion: {(_) -> Void in
                                                
                                                cell.photoImageView.layer.cornerRadius = cell.photoImageView.frame.size.height/2
                                        })
                                    }
                                }
                            }
                        }
                        self.imageLoadingOperationQueue.addOperation(blockOperation)
                        self.imageLoadingOngoingOperations[indexPath] = blockOperation
                    }
                })
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
}


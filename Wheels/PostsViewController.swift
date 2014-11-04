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

func synced(lock: AnyObject, closure: () -> ())
{
    objc_sync_enter(lock)
    closure()
    objc_sync_exit(lock)
}

let kWheelsGroupID = "429208293784763"

class PostsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate, PostsDelegate
{
    @IBOutlet var timeTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var grabber: UIView!
 
    var index:Int? = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        system.postsDelegate = self
        
        //timeTextField.delegate = self
        
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        grabber.layer.cornerRadius = 20
        view.bringSubviewToFront(grabber)
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
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let post = system.posts[indexPath.section]
        
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
            let comment = post.comments[indexPath.row-1]
            
            cell = tableView.dequeueReusableCellWithIdentifier("CommentCell") as PostCell
            cell.textField.text = comment.comment
            cell.userInteractionEnabled = false
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        var height:CGFloat = 0
        let post = system.posts[indexPath.section]
        
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
    
    //TableView Delegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath)
    {
        let post = system.posts[indexPath.section]
        
        system.goToProfilePageOfPersonWithID(post.senderID)
    }
    
    
}


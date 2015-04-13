//
//  PostsTopBarViewController.swift
//  Wheels
//
//  Created by Diego on 11/3/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

protocol PostsTopBarViewControllerDelegate:class
{
    func postsTopBarViewControllerNoFiltersSpecified(controller:PostsTopBarViewController)
    
    func postsTopBarViewControllerFiltersSpecified(controller:PostsTopBarViewController)
}

class PostsTopBarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate
{
    @IBOutlet var keywordsTextField: UITextField!
    @IBOutlet var filtersCollectionView: UICollectionView!
    @IBOutlet var addFilterButton: UIButton!
    
    @IBOutlet var topSpaceToTextFieldConstraint: NSLayoutConstraint!
    
    var initialTopSpaceToTextFieldConstraint:CGFloat!
    
    weak var delegate:PostsTopBarViewControllerDelegate?
        
    let addFilterButtonEnabledColor = UIColor(red: 90/255.0, green: 130/255.0, blue: 200/255.0, alpha: 1)
    let addFilterButtonDisabledColor = UIColor(red: 117/255.0, green: 150/255.0, blue: 200/255.0, alpha: 1)
    
    var postViewControllerTitleLabel:UILabel?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        //(view as UIToolbar).translucent = true
        
        filtersCollectionView.dataSource = self
        filtersCollectionView.delegate = self
        filtersCollectionView.scrollsToTop = false
        
        keywordsTextField.delegate = self
        keywordsTextField.keyboardAppearance = UIKeyboardAppearance.Dark
        
        addFilterButton.layer.cornerRadius = 5
        
        keywordsTextField.setNeedsUpdateConstraints()
        
        enableAddFilterButton()
        
        initialTopSpaceToTextFieldConstraint = topSpaceToTextFieldConstraint.constant
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("pageViewControllerDidScroll:"), name: "pageViewControllerDidScroll", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("pageViewControllerDidChangeViewController:"), name: "pageViewControllerDidChangeViewController", object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("rightViewControllerViewDidAppear:"), name: "rightViewControllerViewDidAppear", object: nil)
    }
    
    @IBAction func addFilterButtonPressed(sender: AnyObject)
    {
        addFilter(keywordsTextField.text)
    }
    
    func addFilter(filter:String)
    {
        if filter != "" && filter != " "
        {
            if system.filters.isEmpty
            {
                delegate?.postsTopBarViewControllerFiltersSpecified(self)
            }
            
            system.addFilter(filter)
            
            self.keywordsTextField.layoutIfNeeded()
            
            UIView.animateWithDuration(0.1, delay:0, options:UIViewAnimationOptions.CurveEaseInOut, animations:{
                
                //self.keyWordsTextFieldTopVerticalSpacing.constant += 10
                
                self.keywordsTextField.text = nil
                let indexPathForLastItem = NSIndexPath(forItem: system.filters.count-1, inSection: 0)
                
                self.filtersCollectionView.insertItemsAtIndexPaths([indexPathForLastItem])
                self.filtersCollectionView.scrollToItemAtIndexPath(indexPathForLastItem, atScrollPosition: UICollectionViewScrollPosition.Right, animated: true)
                
                self.keywordsTextField.layoutIfNeeded()
                
                }) { (_) -> Void in
                    
                    self.keywordsTextField.layoutIfNeeded()
                    
                    UIView.animateWithDuration(0.1, delay:0, options:UIViewAnimationOptions.CurveEaseInOut, animations: {
                        
                        //self.keyWordsTextFieldTopVerticalSpacing.constant -= 10
                        
                        self.keywordsTextField.layoutIfNeeded()
                        
                        }, completion: {(_) -> Void in                            
                    })
            }
        }
    }
    
    func removeFilterAtIndexPath(indexPath:NSIndexPath)
    {
        system.removeFilterAtIndex(indexPath.item)
        filtersCollectionView.deleteItemsAtIndexPaths([indexPath])
        
        if system.filters.isEmpty
        {
            delegate?.postsTopBarViewControllerNoFiltersSpecified(self)
        }
    }
    
    func enableAddFilterButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.addFilterButton.enabled = true
            self.addFilterButton.backgroundColor = self.addFilterButtonEnabledColor
        })
    }
    
    func disableAddFilterButton()
    {
        UIView.animateWithDuration(0.2, animations: {
            
            self.addFilterButton.enabled = false
            self.addFilterButton.backgroundColor = self.addFilterButtonDisabledColor
        })
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return system.filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = filtersCollectionView.dequeueReusableCellWithReuseIdentifier("FilterCell", forIndexPath: indexPath) as! FilterCell
        
        cell.contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        cell.label.text = system.filters[indexPath.item]
        
        cell.layer.cornerRadius = 10
        
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }

    let filtersCollectionViewHeight:CGFloat = 32
    let fontSize:CGFloat = 17
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        var label = UILabel()
        label.text = system.filters[indexPath.item]
        label.font = UIFont.systemFontOfSize(fontSize)
        var size = label.sizeThatFits(CGSizeMake(CGFloat.max, filtersCollectionViewHeight))
        
        return CGSizeMake(size.width + 30, filtersCollectionViewHeight)
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath)
    {
        removeFilterAtIndexPath(indexPath)
    }
    
    override func touchesEnded(touches: Set<NSObject>, withEvent event: UIEvent)
    {
        keywordsTextField.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        keywordsTextField.endEditing(true)
        //timeTextField.endEditing(true)
        
        addFilter(textField.text)
        
        return true
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool
    {
        let textViewRange = NSMakeRange(0, count(textField.text))
        
        if (NSEqualRanges(range, textViewRange) && string.isEmpty)
        {
            //disableAddFilterButton()
        }
        else
        {
            //enableAddFilterButton()
        }
        
        if string == " "
        {
            addFilter(textField.text)
            return false
        }
        else
        {
            return true
        }
    }
    
    func rightViewControllerViewDidAppear(notification:NSNotification)
    {
        if postViewControllerTitleLabel == nil
        {
            let frame =  view.frame
            let label = UILabel(frame: CGRectMake(frame.size.width/2 - 150/2, frame.size.height/2 - 20/2, 150, 20 ))
            label.text = "Información"
            label.textColor = UIColor.darkTextColor()
            label.textAlignment = .Center
            label.alpha = 0
            label.opaque = false
            postViewControllerTitleLabel = label
        }
        view.addSubview(postViewControllerTitleLabel!)
        
        dispatch_async(dispatch_get_main_queue())
        {
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                
                self.postViewControllerTitleLabel!.alpha = 1
            })
        }
    }
    
    func pageViewControllerDidChangeViewController(notification:NSNotification)
    {
        let userInfo = notification.userInfo as! Dictionary<String,AnyObject>
        let controller = userInfo["controller"]
        
        if controller is PostViewController
        {
            
        }
    }
    
    let componentsVerticaldisplacementForAnimation:CGFloat = 90
    
    func pageViewControllerDidScroll (notification:NSNotification)
    {
        let userInfo = notification.userInfo as! Dictionary<String,AnyObject>
        let percentage = userInfo["percentage"]! as! CGFloat
        
        if (userInfo["controller"] is PostsViewController && percentage >= 0) || (userInfo["controller"] is PostViewController && percentage <= 1)
        {
            topSpaceToTextFieldConstraint.constant = initialTopSpaceToTextFieldConstraint - componentsVerticaldisplacementForAnimation*percentage
            view.layoutIfNeeded()
            
            dispatch_async(dispatch_get_main_queue())
            {
                if self.postViewControllerTitleLabel != nil
                {
                    UIView.animateWithDuration(0.4, animations: { () -> Void in
                        
                        self.postViewControllerTitleLabel!.alpha = 0
                        
                        }, completion: { (_) -> Void in
                            
                            self.postViewControllerTitleLabel!.removeFromSuperview()
                    })
                }
            }
        }
    }
}
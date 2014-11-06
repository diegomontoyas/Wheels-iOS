//
//  PostsTopBarViewController.swift
//  Wheels
//
//  Created by Diego on 11/3/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class PostsTopBarViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITextFieldDelegate
{
    @IBOutlet var keywordsTextField: UITextField!
    @IBOutlet var filtersCollectionView: UICollectionView!
    @IBOutlet var addFilterButton: UIButton!
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        filtersCollectionView.dataSource = self
        filtersCollectionView.delegate = self
        
        keywordsTextField.delegate = self
        keywordsTextField.keyboardAppearance = UIKeyboardAppearance.Dark
        
        addFilterButton.layer.cornerRadius = 5
        
        keywordsTextField.setNeedsUpdateConstraints()
        
        view.setNeedsLayout()
        view.setNeedsUpdateConstraints()
    }
    
    @IBAction func addFilterButtonPressed(sender: AnyObject)
    {
        addFilter(keywordsTextField.text)
    }
    
    func addFilter(filter:String)
    {
        if filter != "" && filter != " "
        {
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
                            
                            system.reCheckDeletingRecentPosts(true)
                    })
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return system.filters.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = filtersCollectionView.dequeueReusableCellWithReuseIdentifier("FilterCell", forIndexPath: indexPath) as FilterCell
        
        cell.contentView.autoresizingMask = UIViewAutoresizing.FlexibleWidth
        cell.label.text = system.filters[indexPath.item]
        
        cell.layer.cornerRadius = 3
        
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
        system.filters.removeAtIndex(indexPath.item)
        filtersCollectionView.deleteItemsAtIndexPaths([indexPath])
        system.reCheckDeletingRecentPosts(true)
    }
    
    override func touchesBegan(touches: NSSet, withEvent event: UIEvent)
    {
        keywordsTextField.endEditing(true)
        //timeTextField.endEditing(true)
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

}
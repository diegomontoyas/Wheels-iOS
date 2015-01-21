//
//  MainViewController.swift
//  Wheels
//
//  Created by Diego on 11/2/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class LeftRightViewController: Tssl, UIGestureRecognizerDelegate, UIScrollViewDelegate
{
    @IBOutlet weak var scrollView: UIScrollView!
    var panGestureRecognzier = UIPanGestureRecognizer()
    var viewControllers: Array<UIViewController>!  = nil
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        viewControllers = [UIViewController]()
        viewControllers.append(storyboard?.instantiateViewControllerWithIdentifier("PostsViewController") as UIViewController)
        viewControllers.append(storyboard?.instantiateViewControllerWithIdentifier("PostViewController") as UIViewController)
        
        panGestureRecognzier.delegate = self
        //view.addGestureRecognizer(panGestureRecognzier)
        
        scrollView.pagingEnabled = true
        scrollView.alwaysBounceVertical = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.backgroundColor = UIColor.grayColor()
        pageWidth = view.frame.size.width
        layoutPages()
    }
    
    var pageWidth: CGFloat = 1.0
    
    var currentPage:Int = 0
    {
        didSet
        {
            if (currentPage >= viewControllers?.count)
            {
                currentPage = viewControllers!.count - 1
            }
            
            scrollView.delegate = nil
            scrollView.contentOffset = CGPointMake(CGFloat(currentPage) * view.bounds.size.width, 0.0)
            // Set the fully switched page in order to notify the delegates about it if needed.
        }
    }
    
    func willMoveToParentViewController()
    {
        let page = Int((scrollView.contentOffset.x - pageWidth / 2.0) / pageWidth) + 1
        if currentPage != page
        {
            currentPage = page
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        for var i = 0; i < viewControllers?.count; i += 1
        {
            let pageX:CGFloat = CGFloat(i) * view.bounds.size.width
            viewControllers?[i].view.frame = CGRectMake(pageX, 0.0, view.bounds.size.width, view.bounds.size.height)
        }
        
        // It is important to set the pageWidth property before the contentSize and contentOffset,
        // in order to use the new width into scrollView delegate methods.
        pageWidth = view.bounds.size.width
        scrollView.contentSize = CGSizeMake(CGFloat(viewControllers!.count) * view.bounds.size.width, 1.0)
        scrollView.contentOffset = CGPointMake(CGFloat(currentPage) * view.bounds.size.width, 0.0)
    }
    
    func layoutPages()
    {
        for var i = 0; i < viewControllers?.count; i++
        {
            let page = viewControllers?[i]
            addChildViewController(page!)
            let nextFrame:CGRect = CGRectMake(CGFloat(i) * view.bounds.size.width, view.frame.origin.y, view.frame.size.width, view.frame.size.height)
            page?.view.frame = nextFrame
            scrollView.addSubview(page!.view)
            page?.didMoveToParentViewController(self)
        }
        scrollView.contentSize = CGSizeMake(view.bounds.size.width * CGFloat(viewControllers!.count)+200.0, 1.0)
    }
    
    // UIScrollViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView!)
    {
        // Update the page when more than 50% of the previous/next page is visible
        let page = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        
        if (currentPage != Int(page))
        {
            // Check the page to avoid "index out of bounds" exception.
            if (page >= 0 && Int(page) < viewControllers?.count)
            {
                
            }
        }
    }
    
    /*func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if gestureRecognizer === panGestureRecognzier
        {
            let locationInView = gestureRecognizer.locationInView(view)
            
            let y = locationInView.y
            let x = locationInView.x
            
            if x > 100 && x < 320 && y > 400
            {
                return true
            }
            else
            {
                return false
            }
        }
        return false
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool
    {
        return false
    }*/
}

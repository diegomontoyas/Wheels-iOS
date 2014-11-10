//
//  LoginViewController.swift
//  Wheels
//
//  Created by Diego on 10/30/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class LoginViewController: UIViewController, FBLoginViewDelegate
{
    @IBOutlet var fbLoginView : FBLoginView!
    @IBOutlet var wheel: UIImageView!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        fbLoginView.delegate = self
        fbLoginView.readPermissions = ["user_groups"]
        fbLoginView.publishPermissions = ["publish_actions"]
    }
    
    override func viewDidAppear(animated: Bool)
    {
        var animation = CABasicAnimation(keyPath: "transform.rotation.z")
        animation.fromValue = 0.0
        animation.toValue = 2*M_PI
        animation.duration = 6
        animation.repeatCount = 1000
        wheel.layer.addAnimation(animation, forKey:"rotation")
    }
    
    // Facebook Delegate Methods
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!)
    {
        println("User Logged In")
        
        transitionToPostsViewController()
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser)
    {
        println("User: \(user)")
        println("User ID: \(user.objectID)")
        println("User Name: \(user.name)")
    }
    
    func loginViewShowingLoggedOutUser(loginView : FBLoginView!)
    {
        println("User Logged Out")
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError)
    {
        println("Error: \(handleError.localizedDescription)")
    }

    func transitionToPostsViewController()
    {
        var viewController = storyboard?.instantiateViewControllerWithIdentifier("MainViewController") as MainViewController
        navigationController?.pushViewController(viewController, animated: true)
    }
}
//
//  Post.swift
//  Wheels
//
//  Created by Diego on 10/23/14.
//  Copyright (c) 2014 Diego. All rights reserved.
//

import Foundation

class Post: Equatable
{
    var ID = ""
    var senderName = ""
    var senderID = ""
    var senderPhoto:UIImage? = nil
    var post = ""
    var time: NSDate?
    var comments = [Comment]()
    var full = false
    
    init(ID:String, senderName:String, senderID:String, post:String, time:NSDate, full:Bool)
    {
        self.ID = ID
        self.senderName = senderName
        self.senderID = senderID
        self.post = post
        self.time = time
        self.full = full
    }
}

func ==(lhs: Post, rhs: Post) -> Bool
{
    return lhs.senderID == rhs.senderID && lhs.post == rhs.post
}
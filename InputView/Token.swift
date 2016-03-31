//
//  File.swift
//  TokenInputView
//
//  Created by SergioDan on 3/29/16.
//  Copyright © 2016 SergioDan. All rights reserved.
//

import Foundation

class Token: NSObject {
    var displayText:NSString!
    var context: NSObject!
    
    override init(){
        
    }
    
    init(displayText:NSString, context:NSObject){
        self.displayText = displayText
        self.context = context
    }
    
    override func isEqual(object: AnyObject?) -> Bool {
        if !(object is Token) {
            return false
        }
        
        let otherObject: Token! = object as! Token
        if otherObject.displayText.isEqualToString(self.displayText as String) && otherObject.context.isEqual(self.context) {
            return true
        }
        
        return false
    }
    
    override var hash : Int {
        return self.displayText.hash + self.context.hash
    }
}
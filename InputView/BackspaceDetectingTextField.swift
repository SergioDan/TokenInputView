//
//  BackspaceDetectingTextField.swift
//  TokenInputView
//
//  Created by SergioDan on 3/29/16.
//  Copyright © 2016 SergioDan. All rights reserved.
//

import UIKit

@objc protocol BackspaceDetectingTextFieldDelegate : UITextFieldDelegate {
    func textFieldDidDeleteBackwards(textField: UITextField)
}

class BackspaceDetectingTextField : UITextField {
    var backspaceDelegate: BackspaceDetectingTextFieldDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delegate = self.backspaceDelegate
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func deleteBackward() {
        if self.backspaceDelegate != nil {
            self.backspaceDelegate?.textFieldDidDeleteBackwards(self)
        }
        super.deleteBackward()
    }
}

//
//  ViewController.swift
//  TokenInputView
//
//  Created by SergioDan on 3/29/16.
//  Copyright © 2016 SergioDan. All rights reserved.
//

import UIKit

class ViewController: UIViewController, TokenInputViewDelegate {
    
    @IBOutlet var tokenInputView : TokenInputView!
    var names: NSArray = ["Brenden Mulligan",
    "Cluster Labs, Inc.",
    "Pat Fives",
    "Rizwan Sattar",
    "Taylor Hughes"];
    var selectedNames:NSMutableArray!

    @IBOutlet var heightConstraint: NSLayoutConstraint!
    var height:CGFloat = 40.0;
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.tokenInputView.setFieldNameLocal("To:")
        self.tokenInputView.setPlaceholderTextLocal("Enter a name")
        self.tokenInputView.setAccessoryViewLocal(contactAddButton())
        self.tokenInputView.setDrawBottomBorder(true)
        self.tokenInputView.delegate = self
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(onTapBeginTokenInputView))
        self.tokenInputView.addGestureRecognizer(tapGesture)
        
        selectedNames = NSMutableArray()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    func onAccessoryContactAddButtonTapped(sender: AnyObject) {
        print("accessoryContact")
    }
    /*
    - (void)onAccessoryContactAddButtonTapped:(id)sender
    {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Accessory View Button"
    message:@"This view is optional and can be a UIButton, etc."
    delegate:nil
    cancelButtonTitle:@"Okay"
    otherButtonTitles:nil];
    [alertView show];
    }
    */
    
    func contactAddButton()-> UIButton {
        tokenInputViewDidEndEditing(self.tokenInputView)
        let contactAddButton:UIButton = UIButton.init(type: UIButtonType.ContactAdd)
        contactAddButton.addTarget(self, action: #selector(onAccessoryContactAddButtonTapped), forControlEvents: UIControlEvents.TouchUpInside)
        return contactAddButton
    }

    /*
     
     - (UIButton *)contactAddButton
     {
     UIButton *contactAddButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
     [contactAddButton addTarget:self action:@selector(onAccessoryContactAddButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
     return contactAddButton;
     }
 */
    
    func onTapBeginTokenInputView(sender:AnyObject) {
        heightConstraint.constant = self.height
        tokenInputView.scrollView.frame.size.height = self.height
        tokenInputView.textField.becomeFirstResponder()
    }
    
    func tokenInputViewDidEndEditing(view: TokenInputView) {
        if selectedNames != nil && selectedNames.count > 0 {
            heightConstraint.constant = ConstantsTokenInputView.STANDARD_ROW_HEIGHT+15.0
            //tokenInputView.additionalTextFieldYOffset = ConstantsTokenInputView.STANDARD_ROW_HEIGHT+15.0;
            tokenInputView.scrollView.frame.size.height = ConstantsTokenInputView.STANDARD_ROW_HEIGHT+15.0
        }
    }
    
    func tokenInputViewDidBeginEditing(view: TokenInputView) {
        heightConstraint.constant = self.height
        tokenInputView.scrollView.frame.size.height = self.height
    }
    
    func tokenInputViewDidChangeText(view: TokenInputView, text: NSString) {
        if text.isEqualToString(""){
        }
//        } else {
//            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"self contains[cd] %@", text];
//            self.filteredNames = [self.names filteredArrayUsingPredicate:predicate];
//            self.tableView.hidden = NO;
//        }
//        [self.tableView reloadData];
    }
    
    func tokenInputViewDidAddToken(view: TokenInputView, token: Token) {
        let name:NSString = token.displayText;
        selectedNames.addObject(name);
    }
    
    func tokenInputViewDidRemoveToken(view: TokenInputView, token: Token) {
        let name:NSString = token.displayText
        selectedNames.removeObject(name)
    }
    
    func tokenInputViewShouldReturn(view: TokenInputView) -> Bool {
        return false
    }
    
    func tokenInputViewDidChangeHeightTo(view: TokenInputView, height: CGFloat) {
        self.height = height
        heightConstraint.constant = self.height
        
    }
    
    func tokenInputViewTokenForText(view: TokenInputView, text: NSString) -> Token {
        if (self.names.count > 0) {
            let matchingName:NSString = self.names[0] as! NSString;
            let match:Token = Token.init(displayText: matchingName, context: NSObject())//[[CLToken alloc] initWithDisplayText:matchingName context:nil];
            return match;
        }
        // TODO: Perhaps if the text is a valid phone number, or email address, create a token
        // to "accept" it.
        return Token();
    }
    
}


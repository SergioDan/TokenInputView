
//
//  TokenInputView.swift
//  TokenInputView
//
//  Created by SergioDan on 3/29/16.
//  Copyright © 2016 SergioDan. All rights reserved.
//

import UIKit
import Foundation

struct ConstantsTokenInputView {
    static let HSPACE:CGFloat = 0.0
    static let TEXT_FIELD_HSPACE:CGFloat = 4.0
    static let VSPACE:CGFloat = 4.0
    static let MINIMUM_TEXTFIELD_WIDTH:CGFloat = 56.0
    static let PADDING_TOP:CGFloat = 10.0
    static let PADDING_BOTTOM:CGFloat = 10.0
    static let PADDING_LEFT:CGFloat = 8.0
    static let PADDING_RIGHT:CGFloat = 16.0
    static let STANDARD_ROW_HEIGHT:CGFloat = 25.0
    static let FIELD_MARGIN_X:CGFloat = 4.0
    static let TEXT_FIELD_MAX_HEIGHT: CGFloat = 150.0
}

@objc protocol TokenInputViewDelegate {
    optional func tokenInputViewDidEndEditing(view: TokenInputView)
    optional func tokenInputViewDidBeginEditing(view:TokenInputView)
    optional func tokenInputViewShouldReturn(view: TokenInputView)->Bool
    optional func tokenInputViewDidChangeText(view: TokenInputView, text:NSString)
    optional func tokenInputViewDidAddToken(view:TokenInputView,token:Token)
    optional func tokenInputViewDidRemoveToken(view:TokenInputView,token:Token)
    optional func tokenInputViewTokenForText(view:TokenInputView, text:NSString) -> Token
    optional func tokenInputViewDidChangeHeightTo(view:TokenInputView,height:CGFloat)
}

class TokenInputView : UIView, TokenViewDelegate, BackspaceDetectingTextFieldDelegate {
    var delegate:TokenInputViewDelegate!
    
    var fieldView:UIView!
    var fieldName:NSString!
    
    @IBInspectable var fieldColor:UIColor!
    @IBInspectable var placeholderText:NSString!
    @IBInspectable var accessoryView:UIView!
    @IBInspectable var keyboardType:UIKeyboardType!
    @IBInspectable var autocapitalizationType:UITextAutocapitalizationType!
    @IBInspectable var autocorrectionType:UITextAutocorrectionType!
    @IBInspectable var keyboardAppearance:UIKeyboardAppearance!
    
    var tokenizationCharacters:NSSet!
    @IBInspectable var drawBottomBorder:Bool!
    
//    var allTokens:NSArray {
//        get{
//            self.allTokens()
//        }
//    }
    
    var editing:Bool {
        get{
            return self.isEditing()
        }
    }
    
    var tokens:NSMutableArray! //token
    var tokenViews:NSMutableArray! //tokenview
    var textField:BackspaceDetectingTextField!
    var fieldLabel:UILabel!
    
    var intrinsicContentHeight:CGFloat!
    var additionalTextFieldYOffset:CGFloat!
    
    var scrollView:UIScrollView!
    
    
    func isEditing() -> Bool {
        return self.textField.editing
    }
    
//    var textFieldDisplayOffset : CGFloat!
//    var text:NSString!
    
    func commonInit(){
        self.scrollView = UIScrollView.init(frame: self.bounds)
        self.scrollView.backgroundColor = UIColor.clearColor()
        self.addSubview(scrollView)
        
        self.textField = BackspaceDetectingTextField.init(frame: self.bounds)
        self.textField.backgroundColor = UIColor.clearColor()
        self.textField.keyboardType = UIKeyboardType.Alphabet
        self.textField.autocorrectionType = UITextAutocorrectionType.No
        self.textField.autocapitalizationType = UITextAutocapitalizationType.None
        self.textField.delegate = self
        self.textField.backspaceDelegate = self
        self.additionalTextFieldYOffset = 0.0
        
        self.textField.addTarget(self, action: #selector(onTextFieldDidChange), forControlEvents: UIControlEvents.EditingChanged)
        
        self.scrollView.addSubview(self.textField)
        
        self.tokens = NSMutableArray.init(capacity: 20)
        self.tokenViews = NSMutableArray.init(capacity: 20)
        
        self.fieldColor = UIColor.lightGrayColor()
        self.fieldLabel = UILabel.init(frame:CGRectZero)
        
        self.fieldLabel.textColor = self.fieldColor
        self.scrollView.addSubview(self.fieldLabel)
        self.fieldLabel.hidden = true
        
        self.drawBottomBorder = false
        self.tokenizationCharacters = NSSet()
        self.intrinsicContentHeight = ConstantsTokenInputView.STANDARD_ROW_HEIGHT
        
        self.accessoryView = UIView()
        self.fieldName = ""
        self.placeholderText = ""
        
        repositionViews()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    override func intrinsicContentSize() -> CGSize {
        return CGSizeMake(UIViewNoIntrinsicMetric, max(45, self.intrinsicContentHeight))
    }
    
    override func tintColorDidChange() {
        for i in 0 ..< self.tokenViews.count {
            let tokenView:TokenView = self.tokenViews[i] as! TokenView
            tokenView.tintColor = self.tintColor
        }
    }
    
    //MARK: add and remove tokens
    func addToken(token:Token){
        if self.tokens.containsObject(token) {
            return;
        }
        
        self.tokens.addObject(token)
        let tokenView : TokenView = TokenView.init(token: token, font: self.textField.font!)
        if  self.respondsToSelector(Selector("tintColor")) {
            tokenView.tintColor = self.tintColor
        }
        tokenView.delegate = self
        let intrinsicSize:CGSize = tokenView.intrinsicContentSize()
        tokenView.frame = CGRectMake(0, 0, intrinsicSize.width, intrinsicSize.height)
        self.tokenViews.addObject(tokenView)
        scrollView.addSubview(tokenView)
        
        self.textField.text = ""
        
        self.delegate.tokenInputViewDidAddToken!(self, token: token)
        
        self.onTextFieldDidChange(self.textField)
        updatePlaceholderTextVisibility()
        repositionViews()
    }
    
    func removeToken(token:Token){
        if let index:Int = self.tokens.indexOfObject(token){
            removeTokenAtIndex(index)
        }
    }
    
    func removeTokenAtIndex(index:Int) {
        if index == NSNotFound {
            return
        }
        
        let tokenView: TokenView = self.tokenViews[index] as! TokenView
        tokenView.removeFromSuperview()
        
        self.tokenViews.removeObjectAtIndex(index)
        
        let removedToken:Token = self.tokens[index] as! Token
        self.tokens .removeObjectAtIndex(index)
        
        self.delegate.tokenInputViewDidRemoveToken!(self, token: removedToken)
        updatePlaceholderTextVisibility()
        repositionViews()
    }
    
    func allTokens() -> NSArray {
        return self.tokens.copy() as! NSArray
    }
    
    func tokenizeTextfieldText() -> Token {
        var token:Token = Token()
        let text:NSString = self.textField.text!
        if text.length > 0 {
            if self.delegate != nil {
                token = self.delegate.tokenInputViewTokenForText!(self, text: text)
            }
            
            if token.hash != NSNotFound {
                addToken(token)
                self.textField.text = ""
                self.onTextFieldDidChange(self.textField)
            }
        }
        
        return token
    }
    
    //MARK : updating and repositioning view 
    func repositionViews() {
        let bounds: CGRect = self.bounds
        let rightBoundary : CGFloat = CGRectGetWidth(bounds) - ConstantsTokenInputView.PADDING_RIGHT
        var firstLineRightBoundary:CGFloat = rightBoundary
        
        var curX:CGFloat = ConstantsTokenInputView.PADDING_LEFT
        var curY:CGFloat = ConstantsTokenInputView.PADDING_TOP
        
        var totalHeight:CGFloat = ConstantsTokenInputView.STANDARD_ROW_HEIGHT
        
        var isOnFirstLine:Bool = true
        
        // Position field view (if set)
        if (self.fieldView != nil) {
            var fieldViewRect:CGRect = self.fieldView.frame
            fieldViewRect.origin.x = curX + ConstantsTokenInputView.FIELD_MARGIN_X
            fieldViewRect.origin.y = curY + ((ConstantsTokenInputView.STANDARD_ROW_HEIGHT - CGRectGetHeight(fieldViewRect))/2.0)
            
            self.fieldView.frame = fieldViewRect
            
            curX = CGRectGetMaxX(fieldViewRect) + ConstantsTokenInputView.FIELD_MARGIN_X
        }
        
        // Position field label (if field name is set)
        if !self.fieldLabel.hidden {
            let labelSize: CGSize = self.fieldLabel.intrinsicContentSize()
            var fieldLabelRect:CGRect = CGRectZero
            fieldLabelRect.size = labelSize
            fieldLabelRect.origin.x = curX + ConstantsTokenInputView.FIELD_MARGIN_X
            fieldLabelRect.origin.y = curY + ((ConstantsTokenInputView.STANDARD_ROW_HEIGHT-CGRectGetHeight(fieldLabelRect))/2.0)
            self.fieldLabel.frame = fieldLabelRect
            
            curX = CGRectGetMaxX(fieldLabelRect) + ConstantsTokenInputView.FIELD_MARGIN_X
        }
        
        // Position accessory view (if set)
        if self.accessoryView != nil {
            var accessoryRect:CGRect = self.accessoryView.frame
            accessoryRect.origin.x = CGRectGetWidth(bounds) - ConstantsTokenInputView.PADDING_RIGHT - CGRectGetWidth(accessoryRect)
            accessoryRect.origin.y = curY
            self.accessoryView.frame = accessoryRect
            
            firstLineRightBoundary = CGRectGetMinX(accessoryRect)-ConstantsTokenInputView.HSPACE
        }
        
        //position token views
        var tokenRect:CGRect = CGRectNull
        for i in 0 ..< self.tokenViews.count {
            let tokenView:UIView = self.tokenViews[i] as! UIView
            tokenRect = tokenView.frame
            
            var tokenBoundary:CGFloat = -1.0
            if isOnFirstLine {
                tokenBoundary = firstLineRightBoundary
            } else {
                tokenBoundary = rightBoundary
            }
            
            if curX+CGRectGetWidth(tokenRect) > tokenBoundary {
                //need a new line
                curX = ConstantsTokenInputView.PADDING_LEFT
                curY += ConstantsTokenInputView.STANDARD_ROW_HEIGHT + ConstantsTokenInputView.VSPACE
                totalHeight += ConstantsTokenInputView.STANDARD_ROW_HEIGHT
                isOnFirstLine = false
            }
            
            tokenRect.origin.x = curX
            //center our tokenview vertically within STANDARD_ROW_HEIGHT
            tokenRect.origin.y = curY + ((ConstantsTokenInputView.STANDARD_ROW_HEIGHT-CGRectGetHeight(tokenRect))/2.0)
            
            tokenView.frame = tokenRect
            
            curX = CGRectGetMaxX(tokenRect) + ConstantsTokenInputView.HSPACE
        }
        
        //Always indent textfield by a little bit
        curX += ConstantsTokenInputView.TEXT_FIELD_HSPACE
        
        
        var textBoundary:CGFloat = -1.0
        if isOnFirstLine {
            textBoundary = firstLineRightBoundary
        } else {
            textBoundary = rightBoundary
        }
        
        var availableWidtForTextField:CGFloat = textBoundary - curX
        
        if availableWidtForTextField < ConstantsTokenInputView.MINIMUM_TEXTFIELD_WIDTH {
            isOnFirstLine = false
            // If in the future we add more UI elements below the tokens,
            // isOnFirstLine will be useful, and this calculation is important.
            // So leaving it set here, and marking the warning to ignore it
            //unused(isOnFirstLine)
            curX = ConstantsTokenInputView.PADDING_LEFT + ConstantsTokenInputView.TEXT_FIELD_HSPACE
            curY += ConstantsTokenInputView.STANDARD_ROW_HEIGHT + ConstantsTokenInputView.VSPACE
            totalHeight += ConstantsTokenInputView.STANDARD_ROW_HEIGHT
            //adjust the width
            availableWidtForTextField = rightBoundary-curX
        }
        
        var textFieldRect: CGRect = self.textField.frame
        textFieldRect.origin.x = curX
        textFieldRect.origin.y = curY + self.additionalTextFieldYOffset
        textFieldRect.size.width = availableWidtForTextField
        textFieldRect.size.height = ConstantsTokenInputView.STANDARD_ROW_HEIGHT
        self.textField.frame = textFieldRect
        
        let oldContentHeight = self.intrinsicContentHeight
        self.intrinsicContentHeight = max(totalHeight, CGRectGetMaxY(textFieldRect)+ConstantsTokenInputView.PADDING_BOTTOM)
        self.invalidateIntrinsicContentSize()
        
        if oldContentHeight != self.intrinsicContentHeight {
            if self.delegate != nil {
                    self.delegate.tokenInputViewDidChangeHeightTo!(self, height: self.intrinsicContentSize().height)
            }
            
        }
        
        self.scrollView.frame = bounds
        
        self.setNeedsDisplay()
    }
    
    func updatePlaceholderTextVisibility() {
        if self.tokens.count > 0 {
            self.textField.placeholder = nil
        } else {
            self.textField.placeholder = self.placeholderText as String
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        repositionViews()
    }
    
    //MARK:backspace detectingtextfielddelegate
    func textFieldDidDeleteBackwards(textField: UITextField) {
        dispatch_async(dispatch_get_main_queue(), {
            if (textField.text! as NSString).length == 0 {
                if self.tokenViews.count > 0 {
                    let tokenView:TokenView = self.tokenViews.lastObject as! TokenView
                    if tokenView.hash != NSNotFound {
                        self.selectTokenView(tokenView, animated:true)
                        self.textField.resignFirstResponder()
                    }
                }
            }
        })
    }
    
    //MARK: UItextFieldDelegate
    func textFieldDidBeginEditing(textField: UITextField) {
        if self.delegate != nil {
                self.delegate.tokenInputViewDidEndEditing!(self)
        }
        if self.tokenViews.count > 0 {
            let tokenView:TokenView = self.tokenViews.lastObject as! TokenView
            tokenView.hideUnselectedComma = false
        }
        
        unselectAllTokenViewsAnimated(true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.delegate.tokenInputViewDidEndEditing!(self)
        (self.tokenViews.lastObject as! TokenView).hideUnselectedComma = true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        tokenizeTextfieldText()
        let shouldDoDefaultBehavior:Bool = self.delegate.tokenInputViewShouldReturn!(self)
        return shouldDoDefaultBehavior
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        if (string as NSString).length > 0 && self.tokenizationCharacters.member(string) != nil{
            tokenizeTextfieldText()
            return false
        }
        return true
    }
    
    //MARK: textfield changes
    func onTextFieldDidChange(sender:AnyObject) {
        if self.delegate != nil {
            self.delegate.tokenInputViewDidChangeText!(self, text: self.textField.text!)
        }
    }
    
    //MARK:Text field customization
    func setKeyboardType(keyboardType:UIKeyboardType) {
        self.keyboardType = keyboardType
        self.textField.keyboardType = self.keyboardType
    }
    
    func setAutoCapitalizationType(autocapitalizationType:UITextAutocapitalizationType) {
        self.autocapitalizationType = autocapitalizationType
        self.textField.autocapitalizationType = self.autocapitalizationType
    }
    
    func setAutocorrectionType(autocorrectionType:UITextAutocorrectionType){
        self.autocorrectionType = autocorrectionType
        self.textField.autocorrectionType = self.autocorrectionType
    }
    
    func setKeyboardAppearance(keyboardAppearance:UIKeyboardAppearance) {
        self.keyboardAppearance = keyboardAppearance
        self.textField.keyboardAppearance = self.keyboardAppearance
    }
    
    //MARK: measurements (text field offset, etc.)
    func textFieldDisplayOffset() -> CGFloat {
        return CGRectGetMinY(self.textField.frame)-ConstantsTokenInputView.PADDING_TOP
    }
    
    //MARK: textfield text
    func text() -> NSString {
        return self.textField.text! as NSString
    }
    
    //MARK: tokenviewdelegate
    func tokenViewDidRequestDelete(tokenView: TokenView, replaceText: NSString) {
        
        //first refocus the text field
        self.textField.becomeFirstResponder()
        if replaceText.length > 0 {
            self.textField.text = replaceText as String
        }
        
        //then remove the view from our data
        if let index:Int = self.tokenViews.indexOfObject(tokenView) {
            removeTokenAtIndex(index)
        }
        
    }
    
    func tokenViewDidRequestSelection(tokenView: TokenView) {
        selectTokenView(tokenView, animated: true)
    }
    
    //MARK: token selection
    func selectTokenView(tokenView:TokenView, animated:Bool) {
        tokenView.setSelected(true, animated: animated)
        for i in 0 ..< self.tokenViews.count {
            let otherTokenView:TokenView = self.tokenViews[i] as! TokenView
            if otherTokenView != tokenView {
                otherTokenView.setSelected(false, animated: animated)
            }
        }
    }
    
    func unselectAllTokenViewsAnimated(animated:Bool){
        for i in 0 ..< self.tokenViews.count {
            let tokenView:TokenView = self.tokenViews[i] as! TokenView
            tokenView .setSelected(false, animated: animated)
        }
    }
    
    //MARK: editing
    func beginEditing() {
        self.textField.becomeFirstResponder()
        unselectAllTokenViewsAnimated(false)
    }
    
    func endEditing() {
        // NOTE: We used to check if .isFirstResponder
        // and then resign first responder, but sometimes
        // we noticed that it would be the first responder,
        // but still return isFirstResponder=NO. So always
        // attempt to resign without checking.
        self.textField.resignFirstResponder()
    }
    
    //MARK: optional views
    func setFieldNameLocal(fieldName:NSString) {
        if self.fieldName == fieldName {
            return
        }
        
        let oldFieldName:NSString = self.fieldName
        self.fieldName = fieldName
        
        self.fieldLabel.text = self.fieldName as String
        self.fieldLabel.invalidateIntrinsicContentSize()
        let showField:Bool = (self.fieldName.length > 0)
        self.fieldLabel.hidden = !showField
        
        if showField && self.fieldLabel.superview == nil {
            scrollView.addSubview(self.fieldLabel)
        } else if !showField && self.fieldLabel.superview != nil {
            self.fieldLabel.removeFromSuperview()
        }
        
        if !oldFieldName.isEqualToString(fieldName as String) {
            repositionViews()
        }
    }
    
    func setFieldColorLocal(fieldColor:UIColor) {
        self.fieldColor = fieldColor
        self.fieldLabel.textColor = self.fieldColor
    }
    
    func setFieldViewLocal(fieldView:UIView) {
        if self.fieldView == fieldView {
            return
        }
        
        self.fieldView.removeFromSuperview()
        self.fieldView = fieldView
        if self.fieldView != nil {
            self.scrollView.addSubview(self.fieldView)
        }
        repositionViews()
    }
    
    func setPlaceholderTextLocal(placeholder:NSString) {
        if self.placeholderText == placeholder {
            return
        }
        
        self.placeholderText = placeholder
        updatePlaceholderTextVisibility()
    }
    
    func setAccessoryViewLocal(accessoryView:UIView) {
        if self.accessoryView == accessoryView {
            return
        }
        self.accessoryView.removeFromSuperview()
        self.accessoryView = accessoryView
        
        if self.accessoryView != nil {
            self.scrollView.addSubview(self.accessoryView)
        }
        
        repositionViews()
    }
    
    func setDrawBottomBorder(drawBottomBorder:Bool) {
        if self.drawBottomBorder == drawBottomBorder {
            return
        }
        
        self.drawBottomBorder = drawBottomBorder
        self.setNeedsDisplay()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        if self.drawBottomBorder == true{
            let context:CGContextRef = UIGraphicsGetCurrentContext()!
            let bounds: CGRect = self.bounds
            CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
            CGContextSetLineWidth(context, 0.5)
            
            CGContextMoveToPoint(context, 0, bounds.size.height)
            CGContextAddLineToPoint(context, CGRectGetWidth(bounds), bounds.size.height)
            CGContextStrokePath(context)
        }
    }
}

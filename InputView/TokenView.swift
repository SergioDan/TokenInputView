//
//  TokenView.swift
//  TokenInputView
//
//  Created by SergioDan on 3/29/16.
//  Copyright © 2016 SergioDan. All rights reserved.
//

import UIKit
struct ConstantsTokenView {
    static let PADDING_X:CGFloat = 4.0
    static let PADDING_Y:CGFloat = 2.0
    
    static let UNSELECTED_LABEL_FORMAT:NSString = "%@,";
    static let UNSELECTED_LABEL_NO_COMMA_FORMAT:NSString = "%@";
}


protocol TokenViewDelegate {
    func tokenViewDidRequestDelete(tokenView:TokenView, replaceText:NSString)
    func tokenViewDidRequestSelection(tokenView:TokenView)
}

class TokenView:UIView, UIKeyInput {
    var delegate: TokenViewDelegate!
    var selected:Bool!
    var hideUnselectedComma:Bool!
    
    var backgroundView:UIView!
    var label: UILabel!
    var selectedBackgroundView:UIView!
    var selectedLabel:UILabel!
    
    var displayText:NSString!
    
    override var tintColor: UIColor! {
        didSet {
            self.label.textColor = tintColor
            self.selectedBackgroundView.backgroundColor = tintColor
        }
    }
    
    
    init(token:Token, font:UIFont){
        super.init(frame: CGRectZero)
        
        let tintColor:UIColor = UIColor.init(colorLiteralRed: 0.0823, green: 0.4941, blue: 0.9843, alpha: 1.0)
        self.label = UILabel.init(frame: CGRectMake(ConstantsTokenView.PADDING_X, ConstantsTokenView.PADDING_Y, 0, 0))
        self.label.font = font
        self.label.textColor = tintColor
        self.label.backgroundColor = UIColor.clearColor()
        
        self.addSubview(self.label)
        
        self.selectedBackgroundView = UIView.init(frame: CGRectZero)
        self.selectedBackgroundView.backgroundColor = tintColor
        self.selectedBackgroundView.layer.cornerRadius = 3.0
        self.addSubview(self.selectedBackgroundView)
        self.selectedBackgroundView.hidden = true
        
        self.selectedLabel = UILabel.init(frame: CGRectMake(ConstantsTokenView.PADDING_X, ConstantsTokenView.PADDING_Y, 0, 0))
        self.selectedLabel.font = font
        self.selectedLabel.textColor = UIColor.whiteColor()
        self.selectedLabel.backgroundColor = UIColor.clearColor()
        self.addSubview(self.selectedLabel)
        self.selectedLabel.hidden = true
        
        self.displayText = token.displayText
        
        self.hideUnselectedComma = false
        
        updateLabelAttributedText()
        self.selectedLabel.text = token.displayText as String
        
        self.backgroundView = UIView()
        self.selected = false
        
        let tapRecognizer: UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(TokenView.handleTapGestureRecognizer(_:)))
        
        self.addGestureRecognizer(tapRecognizer)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setSelected(selected:Bool) {
        self.setSelected(selected, animated: false)
    }
    
    func setSelected(selected:Bool, animated:Bool){
        if self.selected == selected {
            return
        }
        
        self.selected = selected
        if selected && !self.isFirstResponder() {
           self.becomeFirstResponder()
        } else if !selected && self.isFirstResponder() {
            self.resignFirstResponder()
        }
        
        var selectedAlpha:CGFloat = 0.0
        
        if self.selected == true {
            selectedAlpha = 1.0
        }
        
        if animated == true {
            if self.selected == true {
                self.selectedBackgroundView.alpha = 0.0
                self.selectedBackgroundView.hidden = false
                self.selectedLabel.alpha = 0.0
                self.selectedLabel.hidden = false
            }
            
            UIView.animateWithDuration(0.25, animations: {
                self.selectedBackgroundView.alpha = selectedAlpha
                self.selectedLabel.alpha = selectedAlpha
                }, completion: { finished in
                    if self.selected == false {
                        self.selectedBackgroundView.hidden = true
                        self.selectedLabel.hidden = true
                    }
                    
            })
        } else {
            self.selectedBackgroundView.hidden = !self.selected
            self.selectedLabel.hidden = !self.selected
        }
        
        
    }
    
    //MARK: taps
    
    func handleTapGestureRecognizer(sender: AnyObject){
        self.delegate.tokenViewDidRequestSelection(self)
    }
    
    //MARK: Size Measurements 
    override func intrinsicContentSize() -> CGSize {
        let labelIntrinsicSize: CGSize = self.selectedLabel.intrinsicContentSize()
        return CGSizeMake(labelIntrinsicSize.width+(2.0*ConstantsTokenView.PADDING_X), labelIntrinsicSize.height+(2.0*ConstantsTokenView.PADDING_Y))
    }
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        let fittingSize: CGSize = CGSizeMake(size.width-(2.0*ConstantsTokenView.PADDING_X), size.height - (2.0*ConstantsTokenView.PADDING_Y))
        let labelSize: CGSize = self.selectedLabel.sizeThatFits(fittingSize)
        
        return CGSizeMake(labelSize.width+(2.0*ConstantsTokenView.PADDING_X), labelSize.height+(2.0*ConstantsTokenView.PADDING_Y))
    }
    
    func setHideUnselectedComma(hideUnselectedComma:Bool) {
        if self.hideUnselectedComma == hideUnselectedComma {
            return;
        }
        
        self.hideUnselectedComma = hideUnselectedComma
        
    }
    
    //MARK: attributedtext
    func updateLabelAttributedText() {
        var format:NSString = ConstantsTokenView.UNSELECTED_LABEL_FORMAT
        if self.hideUnselectedComma == true {
            format = ConstantsTokenView.UNSELECTED_LABEL_NO_COMMA_FORMAT
        }
        
        let labelString:NSString = NSString(format: format, self.displayText)
        let attrString: NSMutableAttributedString = NSMutableAttributedString.init(string: labelString as String, attributes: [NSFontAttributeName:self.label.font, NSForegroundColorAttributeName:UIColor.lightGrayColor()])
        
        let tintRange:NSRange = labelString.rangeOfString(self.displayText as String)
        let tintColor:UIColor = self.selectedBackgroundView.backgroundColor!
        attrString.setAttributes([NSForegroundColorAttributeName: tintColor], range: tintRange)
        
        self.label.attributedText = attrString
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bounds:CGRect = self.bounds
        
        self.backgroundView.frame = bounds
        self.selectedBackgroundView.frame = bounds
        
        var labelFrame = CGRectInset(bounds, ConstantsTokenView.PADDING_X, ConstantsTokenView.PADDING_Y)
        self.selectedLabel.frame = labelFrame
        labelFrame.size.width += ConstantsTokenView.PADDING_X*2.0
        self.label.frame = labelFrame
    }
    
    //MARK: uikeyinput protocol
    func hasText() -> Bool {
        return true
    }
    
    func insertText(text: String) {
        self.delegate.tokenViewDidRequestDelete(self, replaceText: text)
    }
    
    func deleteBackward() {
        self.delegate.tokenViewDidRequestDelete(self, replaceText: "")
    }
    
    //MARK: uitextinputtraits protocol 
//    var autocorrectionType: UITextAutocorrectionType {
//        get{ return UITextAutocorrectionTypeNo }
//    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func resignFirstResponder() -> Bool {
        let didResignFirstResponder:Bool = super.resignFirstResponder()
        self.setSelected(false)
        return didResignFirstResponder
    }
    
    override func becomeFirstResponder() -> Bool {
        let didBecomeFirstResponder:Bool = super.becomeFirstResponder()
        self.setSelected(true)
        return didBecomeFirstResponder
    }
    
}
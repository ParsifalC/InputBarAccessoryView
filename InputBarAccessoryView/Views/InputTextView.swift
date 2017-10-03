//
//  InputTextView.swift
//  InputBarAccessoryView
//
//  Copyright © 2017 Nathan Tannar.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//
//  Created by Nathan Tannar on 8/18/17.
//

import Foundation
import UIKit

open class InputTextView: UITextView {
    
    // MARK: - Properties
    
    open override var text: String! {
        didSet {
            resetTypingAttributes()
            textViewTextDidChange()
            highlightSubstrings(with: previousPrefixCharacters)
        }
    }

    open let placeholderLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .lightGray
        label.text = "Aa"
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    open var placeholder: String? = "Aa" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }
    
    open var placeholderTextColor: UIColor? = .lightGray {
        didSet {
            placeholderLabel.textColor = placeholderTextColor
        }
    }
    
    override open var font: UIFont! {
        didSet {
            placeholderLabel.font = font
        }
    }
    
    override open var textAlignment: NSTextAlignment {
        didSet {
            placeholderLabel.textAlignment = textAlignment
        }
    }
    
    open override var textContainerInset: UIEdgeInsets {
        didSet {
            placeholderLabelInsets = textContainerInset
        }
    }

    open var placeholderLabelInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4) {
        didSet {
            updateConstraintsForPlaceholderLabel()
        }
    }
    
    open override var scrollIndicatorInsets: UIEdgeInsets {
        didSet {
            // When .zero a rendering issue can occur
            if scrollIndicatorInsets == .zero {
                scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                                     left: .leastNonzeroMagnitude,
                                                     bottom: .leastNonzeroMagnitude,
                                                     right: .leastNonzeroMagnitude)
            }
        }
    }
    
    open weak var inputBarAccessoryView: InputBarAccessoryView?
    
    private var previousPrefixCharacters = [Character]()
    private var placeholderLabelConstraintSet: NSLayoutConstraintSet?
 
    // MARK: - Initializers
    
    public convenience init() {
        self.init(frame: .zero)
    }
    
    override public init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    open func setup() {
        
        font = UIFont.preferredFont(forTextStyle: .body)
        isScrollEnabled = false
        scrollIndicatorInsets = UIEdgeInsets(top: .leastNonzeroMagnitude,
                                             left: .leastNonzeroMagnitude,
                                             bottom: .leastNonzeroMagnitude,
                                             right: .leastNonzeroMagnitude)
        addSubviews()
        addObservers()
        addConstraints()
    }
    
    private func addSubviews() {
        
        addSubview(placeholderLabel)
    }
    
    private func addConstraints() {
        
        placeholderLabelConstraintSet = NSLayoutConstraintSet(
            top:    placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: placeholderLabelInsets.top),
            bottom: placeholderLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -placeholderLabelInsets.bottom),
            left:   placeholderLabel.leftAnchor.constraint(equalTo: leftAnchor, constant: placeholderLabelInsets.left),
            right:  placeholderLabel.rightAnchor.constraint(equalTo: rightAnchor, constant: -placeholderLabelInsets.right)
        ).activate()
    }
    
    private func updateConstraintsForPlaceholderLabel() {
        
        placeholderLabelConstraintSet?.top?.constant = placeholderLabelInsets.top
        placeholderLabelConstraintSet?.bottom?.constant = -placeholderLabelInsets.bottom
        placeholderLabelConstraintSet?.left?.constant = placeholderLabelInsets.left
        placeholderLabelConstraintSet?.right?.constant = -placeholderLabelInsets.right
    }
    
    private func addObservers() {
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(InputTextView.textViewTextDidChange),
                                               name: Notification.Name.UITextViewTextDidChange,
                                               object: nil)
    }
    
    // MARK: - Attributed Text Highlighting
    
    open func resetTypingAttributes() {
        typingAttributes = [
            NSAttributedStringKey.font.rawValue : font,
            NSAttributedStringKey.foregroundColor.rawValue : UIColor.black
        ]
    }
    
    /// Finds the ranges of all substrings that start with the provided prefixes and sets those ranges background color to the InputTextView's tintColor
    ///
    /// - Parameter prefixes: The prefix the substring must begin with
    open func highlightSubstrings(with prefixes: [Character]) {
        
        previousPrefixCharacters = prefixes
        let substrings = text.components(separatedBy: " ").filter {
            var hasPrefix = false
            for prefix in prefixes {
                if $0.hasPrefix(String(prefix)) && $0.count > 1 {
                    hasPrefix = true
                    break
                }
            }
            return hasPrefix
        }
        var ranges = [NSRange]()
        substrings.map { return rangesOf($0, in: text) }.flatMap { return $0 }.forEach {
            text.enumerateSubstrings(in: $0, options: .substringNotRequired) {
                (substring, substringRange, _, _) in
                let range = NSRange(substringRange, in: self.text)
                ranges.append(range)
            }
        }
        let attrs: [NSAttributedStringKey:AnyObject] = [
            NSAttributedStringKey.font : font,
            NSAttributedStringKey.foregroundColor : textColor ?? .black
        ]
        let attributedString = NSMutableAttributedString(string: text, attributes: attrs)
        let highlightAttrs: [NSAttributedStringKey:AnyObject] = [
            NSAttributedStringKey.foregroundColor : tintColor,
            NSAttributedStringKey.backgroundColor : tintColor.withAlphaComponent(0.2)
        ]
        ranges.forEach { attributedString.addAttributes(highlightAttrs, range: $0) }
        attributedText = attributedString
    }
    
    /// A helper method that returns all the ranges of a provided string in another string
    ///
    /// - Parameters:
    ///   - string: Substrings to filter the ranges
    ///   - text: The String to find ranges in
    /// - Returns: The ranges of the string in text
    private func rangesOf(_ string: String, in text: String) -> [Range<String.Index>] {
        var ranges = [Range<String.Index>]()
        var searchStartIndex = text.startIndex
        
        while searchStartIndex < text.endIndex, let range = text.range(of: string, range: searchStartIndex..<text.endIndex), !range.isEmpty {
            ranges.append(range)
            searchStartIndex = range.upperBound
        }
        return ranges
    }

    
    // MARK: - Notifications
    
    @objc open func textViewTextDidChange() {
        
        placeholderLabel.isHidden = !text.isEmpty
    }
}


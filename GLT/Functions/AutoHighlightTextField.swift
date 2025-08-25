//
//  AutoHighlightTextField.swift
//  GLT
//
//  Created by Player_1 on 4/10/25.
//


import SwiftUI
import UIKit

struct AutoHighlightTextField: UIViewRepresentable {
    typealias UIViewType = UITextField
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var onCommit: (() -> Void)? = nil
    var textColor: UIColor? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.delegate = context.coordinator
        textField.borderStyle = .roundedRect
        if let clr = textColor {
            textField.textColor = clr
        }
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
        if let clr = textColor { uiView.textColor = clr }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: AutoHighlightTextField
        init(_ parent: AutoHighlightTextField) {
            self.parent = parent
        }
        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.onEditingChanged?(true)
            DispatchQueue.main.async { textField.selectAll(nil) }
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.onEditingChanged?(false)
            let trimmed = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let rawDecimal = NSDecimalNumber(string: trimmed)
            var finalText = trimmed
            if rawDecimal == NSDecimalNumber.notANumber {
                finalText = "0.0"
            } else {
                let doubleValue = rawDecimal.doubleValue
                let cappedDouble = max(0, min(doubleValue, 24))
                finalText = "\(cappedDouble)"
            }
            textField.text = finalText
            parent.text = finalText
        }
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            parent.text = updatedText
            return true
        }
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            parent.onCommit?()
            textField.resignFirstResponder()
            return true
        }
    }
}

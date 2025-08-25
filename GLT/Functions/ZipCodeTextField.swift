//
//  ZipCodeTextField.swift
//  GLT
//
//  Created by Player_1 on 4/8/25.
//


import SwiftUI
import UIKit

struct ZipCodeTextField: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.placeholder = "Enter Zip Code"
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text { uiView.text = text }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ZipCodeTextField
        init(_ parent: ZipCodeTextField) {
            self.parent = parent
        }
        func textFieldDidEndEditing(_ textField: UITextField) {
            let trimmed = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let digits = trimmed.filter { $0.isNumber }
            // If there are 9 or more digits, take the first 9 digits and format.
            if digits.count >= 9 {
                let validDigits = String(digits.prefix(9))
                let formatted = String(validDigits.prefix(5)) + "-" + String(validDigits.suffix(4))
                textField.text = formatted
                parent.text = formatted
            } else {
                // Otherwise, update the binding with the trimmed text.
                parent.text = trimmed
            }
        }
        
        // Let the text field update normally while editing.
        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let currentText = textField.text ?? ""
            guard let textRange = Range(range, in: currentText) else { return false }
            let updatedText = currentText.replacingCharacters(in: textRange, with: string)
            // Update binding while editing without formatting
            parent.text = updatedText
            return true
        }
    }
}

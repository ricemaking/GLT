import SwiftUI

struct CustomDateTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType

    init(text: Binding<String>, placeholder: String, keyboardType: UIKeyboardType = .default) {
        self._text = text
        self.placeholder = placeholder
        self.keyboardType = keyboardType
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomDateTextField

        init(_ parent: CustomDateTextField) {
            self.parent = parent
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Automatically highlight all text when editing begins
            textField.selectAll(nil)
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            // Live updates to parent binding while typing
            parent.text = textField.text ?? ""
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            // Apply formatting when editing ends
            let formatted = formatDate(textField.text ?? "")
            textField.text = formatted
            parent.text = formatted
        }
        
        /// Helper to format input like "MMddyyyy" to "MM/dd/yyyy"
        private func formatDate(_ input: String) -> String {
            let digits = input.filter { $0.isNumber }
            guard digits.count == 8 else { return input } // Return unformatted if invalid
            
            let month = digits.prefix(2)
            let day = digits.dropFirst(2).prefix(2)
            let year = digits.suffix(4)
            return "\(month)/\(day)/\(year)"
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.borderStyle = .roundedRect
        textField.delegate = context.coordinator
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
}

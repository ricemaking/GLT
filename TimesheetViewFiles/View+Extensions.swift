// View+Extensions.swift
import SwiftUI

#if canImport(UIKit)
extension View {
    /// Dismisses the keyboard by locating the key window and ending editing.
    func hideKeyboard() {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .endEditing(true)
    }
}
#endif

//
//  UIExtensions.swift
//  GLT
//
//  Created by Player_1 on 4/6/25.
//

import UIKit

extension UIApplication {
    func endEditing() {
        self.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

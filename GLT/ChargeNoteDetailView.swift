//
//  ChargeNoteDetailView.swift
//  GLT
//
//  Created by Player_1 on 4/6/25.
//

import SwiftUI
import CoreData

struct ChargeNoteDetailView: View {
    @ObservedObject var tsCharge: TSCharge
    var context: NSManagedObjectContext
    @Environment(\.presentationMode) var presentationMode
    
    @State private var workPerformedText: String
    
    init(tsCharge: TSCharge, context: NSManagedObjectContext) {
        self.tsCharge = tsCharge
        self.context = context
        _workPerformedText = State(initialValue: tsCharge.workPerformed ?? "")
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Work Performed")
                    .font(.headline)
                    .padding()
                
                TextEditor(text: $workPerformedText)
                    .frame(height: 200)
                    .border(Color.gray, width: 1)
                    .padding()
                
                Button(action: {
                    tsCharge.workPerformed = workPerformedText
                    tsCharge.noted = true  // Mark as saved.
                    do {
                        try context.save()
                        presentationMode.wrappedValue.dismiss()
                    } catch {
                        NSLog("Error saving notes: \(error.localizedDescription)")
                    }
                }) {
                    Text("Save Notes")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .navigationBarTitle("Charge Notes", displayMode: .inline)
        }
    }
}

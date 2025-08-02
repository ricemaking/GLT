//
//  ChargeLineRow.swift
//  GLT
//
//  Created by Player_1 on [Date].
//

import SwiftUI
import CoreData

struct ChargeLineRow: View {
    // MARK: - Input Properties
    @Binding var chargeLine: ChargeLine
    var previouslyAssignedIDs: Set<Int32>
    var day: (day: Int, weekday: String)
    var curID: Int32
    var month: Int16
    var year: Int16
    var context: NSManagedObjectContext

    // MARK: - View & State Management
    @StateObject private var viewModel: ChargeLineRowViewModel
    @State private var showingNotesSheet = false
    @State private var selectedTSCharge: TSCharge? = nil
    @State private var isEditingHours = false
    @State private var hoursColumnWidth: CGFloat = 50
    @State private var noteColumnWidth: CGFloat = 50
    
    @State private var displayText: String = "0.0"
    @State private var isEditingManually: Bool = false


    // Custom initializer to set up the view model.
    init(chargeLine: Binding<ChargeLine>,
         day: (day: Int, weekday: String),
         curID: Int32,
         month: Int16,
         year: Int16,
         context: NSManagedObjectContext,
         previouslyAssignedIDs: Set<Int32>) {
        _chargeLine = chargeLine
        self.day = day
        self.curID = curID
        self.month = month
        self.year = year
        self.context = context
        self.previouslyAssignedIDs = previouslyAssignedIDs
        _viewModel = StateObject(wrappedValue: ChargeLineRowViewModel(
            chargeLine: chargeLine.wrappedValue,
            day: day,
            curID: curID,
            month: month,
            year: year,
            context: context,
            previouslyAssignedIDs: previouslyAssignedIDs))
    }
    
    // MARK: - View Body
    var body: some View {
        ZStack {
            VStack(alignment: .center, spacing: 8) {
                // Charge line name with dynamic width measurement.
                Text(chargeLine.clName ?? "Unnamed Charge Line")
                    .font(.system(size: 14))
                    .padding(4)
                    .background(Color(hex: "#555555").opacity(0.9))
                    .cornerRadius(5)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: ChargeLineNameWidthKey.self, value: proxy.size.width)
                        }
                    )
                
                // Layout for input controls.
                HStack {
                    // Hours text field on the left.
                    AutoHighlightTextField(
                        text: Binding(
                            get: { displayText },
                            set: { newValue in
                                displayText = newValue
                                if isEditingManually {
                                    viewModel.saveTempHours(newValue: newValue)
                                }
                            }
                        ),
                        placeholder: "Hours",
                        keyboardType: .decimalPad,
                        textColor: viewModel.currentColor,
                        onEditingChanged: { editing in
                            isEditingHours = editing
                            isEditingManually = editing
                        }
                    )
                    .disabled(viewModel.isDisabled())
                    .frame(width: hoursColumnWidth, height: 35)
                    
                    Spacer()
                    
                    // Note button on the right.
                    Button(action: {
                        viewModel.handleNotesButtonPress { tsCharge in
                            selectedTSCharge = tsCharge
                            showingNotesSheet = true
                        }
                    }) {
                        Text("📝")
                            .font(.system(size: 18))
                            .padding(4)
                            .foregroundColor(.white)
                            .background(notesButtonColor)
                            .cornerRadius(4)
                    }
                    .disabled(viewModel.isDisabled())
                    .frame(width: max(noteColumnWidth, 44), height: 40, alignment: .trailing)
                    .overlay(
                        GeometryReader { geometry in
                            Color.clear.preference(key: NoteWidthKey.self, value: geometry.size.width)
                        }
                        .allowsHitTesting(false)
                    )
                    .onPreferenceChange(NoteWidthKey.self) { value in
                        noteColumnWidth = max(noteColumnWidth, value)
                    }
                }
                .padding(.horizontal, 12)
                
                Text("Total: \(viewModel.totalHours(), specifier: "%.2f") hours")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            .padding(4)
            .contentShape(Rectangle())
        }
        .onTapGesture {
            hideKeyboard()
        }
        .onAppear {
            if let tsCharge = viewModel.fetchTSCharge() {
                displayText = tsCharge.tempHours?.stringValue ?? tsCharge.hours?.stringValue ?? "0.0"
            }
            viewModel.updateCurrentColor()
        }

        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSManagedObjectContextObjectsDidChange)) { _ in
            if !isEditingManually {
                if let tsCharge = viewModel.fetchTSCharge() {
                    displayText = tsCharge.tempHours?.stringValue ?? tsCharge.hours?.stringValue ?? "0.0"
                }
                viewModel.updateCurrentColor()
            }
        }

        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in hideKeyboard() }
        )
        // Present a sheet using your existing ChargeNoteDetailView.
        .sheet(isPresented: $showingNotesSheet) {
            if let tsCharge = selectedTSCharge {
                ChargeNoteDetailView(tsCharge: tsCharge, context: context)
            }
        }
    }
    
    private var notesButtonColor: Color {
        if let tsCharge = viewModel.fetchTSCharge() {
            return tsCharge.noted ? .blue : Color(hex: "8c3731")
        }
        return Color(hex: "5d5658")
    }
}

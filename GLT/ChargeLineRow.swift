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
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var chargeLine: ChargeLine
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

    // MARK: - Computed properties

    private var assignmentWindow: (assigned: Date?, unassigned: Date?) {
        let tsCharge = viewModel.fetchTSCharge()
        print("ts charge:", tsCharge)
        return (tsCharge?.dateAssigned, tsCharge?.dateUnassigned)
    }

    private var isDisabled: Bool {
        guard let cellDate = Calendar.current.date(from: DateComponents(year: Int(year), month: Int(month), day: day.day)) else {
            return false
        }
        let (assigned, unassigned) = assignmentWindow
        
//        print("celldate:", cellDate)
//        print("assignment window:", assignmentWindow)

        if let assigned = assigned, cellDate < assigned {
            return true
        }
        if let unassigned = unassigned, cellDate > unassigned {
            return true
        }
        return false
    }

    private var effectiveTextColor: UIColor {
        isDisabled ? UIColor.gray : viewModel.currentColor
    }

    private var effectiveNotesButtonColor: Color {
        if isDisabled {
            return Color.gray
        }
        return notesButtonColor
    }

    // MARK: - Custom initializer
    init(chargeLine: Binding<ChargeLine>,
         day: (day: Int, weekday: String),
         curID: Int32,
         month: Int16,
         year: Int16,
         context: NSManagedObjectContext) {
        _chargeLine = chargeLine
        self.day = day
        self.curID = curID
        self.month = month
        self.year = year
        self.context = context
        _viewModel = StateObject(wrappedValue: ChargeLineRowViewModel(
            chargeLine: chargeLine.wrappedValue,
            day: day,
            curID: curID,
            month: month,
            year: year,
            context: context))
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
                    // Hours text field
                    AutoHighlightTextField(
                        text: Binding(
                            get: {
                                if let tsCharge = viewModel.fetchTSCharge() {
                                    if let tempHours = tsCharge.tempHours {
                                        return tempHours.stringValue
                                    }
                                    if let hours = tsCharge.hours {
                                        return hours.stringValue
                                    }
                                }
                                return "0.0"
                            },
                            set: { newValue in
                                viewModel.saveTempHours(newValue: newValue)
                            }
                        ),
                        placeholder: "Hours",
                        keyboardType: .decimalPad,
                        textColor: effectiveTextColor,
                        onEditingChanged: { editing in
                            isEditingHours = editing
                        }
                    )
                    .disabled(isDisabled)
                    .frame(width: hoursColumnWidth, height: 35)

                    Spacer()

                    // Notes button
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
                            .background(effectiveNotesButtonColor)
                            .cornerRadius(4)
                    }
                    .disabled(isDisabled)
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
        .onTapGesture { hideKeyboard() }
        .onAppear { viewModel.updateCurrentColor() }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name.NSManagedObjectContextObjectsDidChange)) { _ in
            if !isEditingHours {
                viewModel.updateCurrentColor()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onEnded { _ in hideKeyboard() }
        )
        .sheet(isPresented: $showingNotesSheet) {
            if let tsCharge = selectedTSCharge {
                ChargeNoteDetailView(tsCharge: tsCharge, context: context)
            }
        }
    }

    // MARK: - Helpers
    private var notesButtonColor: Color {
        if let tsCharge = viewModel.fetchTSCharge() {
            return tsCharge.noted ? .blue : Color(hex: "8c3731")
        }
        return Color(hex: "5d5658")
    }
}

//
//  TimesheetView.swift
//  GLT
//
//  Created by Player_1 on [Date].
//
// hours charged to this line (make sure all the hours are being accounted for when removing  achargline)
// make sure user can see how many hours they have in total, including the hours from the chargelines they were removedf from
// theres a check in the tschargeline that checks the date and checks for a date disabled
// user can edit hours prior to date disable, but from that point on date disabled they cant edit their hours

import SwiftUI
import CoreData

struct TimesheetView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var loginID: String?
    @Binding var curTimesheet: Timesheet?
    @Binding var targetid: Int32
    @Binding var timesheet: Timesheet?
    @Binding var previousRunTimestamp: Date?

    @State private var employee: Employee?
    @State private var chargeLines: [ChargeLine] = []
    @State private var welcomeMessage: String = ""
    @State private var month: Int16 = 0
    @State private var year: Int16 = 0
    @State private var days: [(day: Int, weekday: String)] = []
    @State private var cellWidth: CGFloat = 150  // Shared dynamic cell width (minimum 150)

    var weekends: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return [formatter.weekdaySymbols[6], formatter.weekdaySymbols[0]]
    }
    
    var body: some View {
        VStack {
            if let curTimesheet = curTimesheet {
                Text("Timesheet for: \(GLTFunctions.convertIntToMonth(from: Int(curTimesheet.month))), \(Int(curTimesheet.year))")
                Text("Current Timesheet ID: \(curTimesheet.id)")
                Text("Days in Timesheet Month: \(GLTFunctions.numberOfDaysInCurrentMonth())")
            }
            else {
                Text("Select a timesheet from your timesheet list")
                    .foregroundStyle(.red)
            }
            
            if let lastRun = previousRunTimestamp {
                Text("Previous Run: \(lastRun, formatter: dateFormatter)")
            }
            
            ScrollView {
                ScrollView(.horizontal) {
                    HStack(spacing: 16) {  // Spacing between day columns.
                        ForEach(days, id: \.day) { (day: (day: Int, weekday: String)) in
                            DayView(
                                day: day,
                                month: month,
                                year: year,
                                curID: employee?.id ?? 0,  // Use the employee id if available.
                                chargeLines: $chargeLines,
                                weekends: weekends,
                                context: managedObjectContext,
                                cellWidth: $cellWidth  // Pass the binding for uniform dynamic width.
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
            
            // Bottom area: Save and Submit buttons.
            HStack {
                Button(action: {
                    saveAllChargeLines()
                }) {
                    Text("Save Hours")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal, 4)
                }
                
                Button(action: {
                    submitTimesheet()
                }) {
                    Text("Submit Timesheet")
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .padding(.horizontal, 4)
                }
            }
            .padding(.vertical, 8)
        }
        .onAppear(perform: setupView)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("GL Time Tracker (Month)")
                    .font(.headline)
                    .padding()
            }
        }
    }

    private func setupView() {
        let empID = targetid
        employee = GLTFunctions.fetchTarEmp(byID: empID, context: managedObjectContext)
        chargeLines = GLTFunctions.fetchChargeLines(for: empID, in: managedObjectContext)

        if let cur = curTimesheet {
            month = Int16(cur.month)
            year = Int16(cur.year)
            days = GLTFunctions.dayName(year: Int(year), month: Int(month))
        } else {
            welcomeMessage = "Error: Timesheet data unavailable"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
    
    // MARK: - Save and Submit Functions

    private func saveAllChargeLines() {
        managedObjectContext.perform {
            let currentEmpID = employee?.id ?? 0
            let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d", currentEmpID, month, year)
            
            do {
                let tsCharges = try managedObjectContext.fetch(fetchRequest)
                for tsCharge in tsCharges {
                    if let tempHours = tsCharge.tempHours {
                        tsCharge.hours = tempHours
                        tsCharge.tempHours = nil
                    }
                    tsCharge.saved = true
                    tsCharge.dateSaved = Date()
                }
                try managedObjectContext.save()
                managedObjectContext.refreshAllObjects()
                NSLog("Successfully saved all TSCharge hours, marking them as saved.")
            } catch {
                NSLog("Error saving TSCharge: \(error.localizedDescription)")
            }
        }
    }
    
    private func submitTimesheet() {
        managedObjectContext.perform {
            let currentEmpID = employee?.id ?? 0
            let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d", currentEmpID, month, year)
            
            do {
                let tsCharges = try managedObjectContext.fetch(fetchRequest)
                for tsCharge in tsCharges {
                    if let tempHours = tsCharge.tempHours {
                        tsCharge.hours = tempHours
                        tsCharge.tempHours = nil
                    }
                    tsCharge.saved = true
                    tsCharge.dateSaved = Date()
                }
                if let cur = curTimesheet {
                    cur.submitted = true
                    cur.dateSubmitted = Date()
                    cur.enabled = false
                }
                try managedObjectContext.save()
                managedObjectContext.refreshAllObjects()
                NSLog("Successfully submitted timesheet and saved all TSCharge hours.")
            } catch {
                NSLog("Error submitting timesheet: \(error.localizedDescription)")
            }
        }
    }
}

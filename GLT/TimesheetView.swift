//
//  TimesheetView.swift
//  GLT
//
//  Created by Player_1 on [Date].
//

import SwiftUI
import CoreData

func hasInternetConnection() -> Bool {
    let config = URLSessionConfiguration.default
    config.timeoutIntervalForRequest = 5
    let session = URLSession(configuration: config)
    let url = URL(string: "https://www.apple.com")!

    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"

    let semaphore = DispatchSemaphore(value: 0)
    var reachable = false

    let task = session.dataTask(with: request) { _, response, error in
        if let httpResp = response as? HTTPURLResponse, httpResp.statusCode == 200 {
            reachable = true
        }
        semaphore.signal()
    }
    task.resume()
    _ = semaphore.wait(timeout: .now() + 5)

    return reachable
}

struct DayChargeKey: Hashable, Comparable {
    let day: Int
    let chargeID: Int

    // For sorting
    static func < (lhs: DayChargeKey, rhs: DayChargeKey) -> Bool {
        if lhs.day != rhs.day {
            return lhs.day < rhs.day
        } else {
            return lhs.chargeID < rhs.chargeID
        }
    }
}



struct TimesheetView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @Binding var offlineLogin: Bool
    @Binding var path: NavigationPath
    @Binding var loginID: String?
    @Binding var curTimesheet: Timesheet?
    @Binding var targetid: Int32
    @Binding var timesheet: Timesheet?
    @Binding var previousRunTimestamp: Date?

    @State private var employee: Employee?
    @State private var chargeLines: [ChargeLine] = []
    @State private var chargeLineHistory: [ChargeLine] = []
    @State private var welcomeMessage: String = ""
    @State private var month: Int16 = 0
    @State private var year: Int16 = 0
    @State private var days: [(day: Int, weekday: String)] = []
    @State private var curCellWidth: CGFloat = 150  // Shared dynamic cell width (minimum 150)
    @State private var prevCellWidth: CGFloat = 150
    @State private var pendingOfflineTSCharges: [TSCharge] = []
    //AUTHENTICATIONS VARS
    @State private var shouldPromptForAccount: Bool = true
    @State private var revokeRequest: Bool = false
    @State private var accessToken: String = ""
    @State private var jwtPayloadString: String = ""
    @State private var activeLogin: Bool = false
    @State private var showPrev: Bool = false
    @StateObject var authManager = AuthenticationManager.shared



    var weekends: [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return [formatter.weekdaySymbols[6], formatter.weekdaySymbols[0]]
    }
    var groupedCharges: [DayChargeKey: [TSCharge]] {
        Dictionary(grouping: pendingOfflineTSCharges) { charge in
            DayChargeKey(day: Int(charge.day), chargeID: Int(charge.chargeID))
        }
    }
    var sortedKeys: [DayChargeKey] {
        groupedCharges.keys.sorted()
    }
    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium // e.g., "Jun 25, 2025"
        formatter.timeStyle = .none
        return formatter
    }()


    
    var body: some View {
        VStack {
            if let curTimesheet = curTimesheet {
                VStack {
                    Text("Timesheet for: \(GLTFunctions.convertIntToMonth(from: Int(curTimesheet.month))), \(Int(curTimesheet.year))")
                    Text("Current Timesheet ID: \(curTimesheet.id)")
                    Text("Days in Timesheet Month: \(GLTFunctions.numberOfDaysInCurrentMonth())")
                    
                    if let lastRun = previousRunTimestamp {
                        Text("Previous Run: \(lastRun, formatter: dateFormatter)")
                    }
                    
                    ScrollView {
                        ScrollView(.horizontal) {
                            HStack(spacing: 16) {
                                ForEach(days, id: \.day) { (day: (day: Int, weekday: String)) in
                                    DayView(
                                        day: day,
                                        month: month,
                                        year: year,
                                        curID: targetid,
                                        previouslyAssignedIDs: Set(chargeLineHistory.map { $0.clID }),
                                        chargeLines: $chargeLines,
                                        weekends: weekends,
                                        context: managedObjectContext,
                                        cellWidth: $curCellWidth
                                    )
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        
                        Button(action: {
                            showPrev.toggle()
                        }) {
                            Text("Show All Previous Chargelines")
                                .padding()
                                .frame(maxWidth: 250)
                                .background(showPrev ? .blue : .gray)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.horizontal, 4)
                        }
                        
                        if showPrev {
                            if chargeLineHistory.isEmpty {
                                Text("No previous charge lines to display.")
                                    .foregroundColor(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 16) {
                                        ForEach(days, id: \.day) { (day: (day: Int, weekday: String)) in
                                            DayView(
                                                day: day,
                                                month: month,
                                                year: year,
                                                curID: targetid,
                                                previouslyAssignedIDs: Set(chargeLineHistory.map { $0.clID }),
                                                chargeLines: $chargeLineHistory,
                                                weekends: weekends,
                                                context: managedObjectContext,
                                                cellWidth: $prevCellWidth
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
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
                    /*
                    if !pendingOfflineTSCharges.isEmpty {
                        Text("Offline Changes Detected")
                            .font(.headline)

                        List {
                            ForEach(pendingOfflineTSCharges, id: \.objectID) { charge in
                                VStack(alignment: .leading) {
                                    Text("Date: \(charge.month)/\(charge.day)/\(charge.year)")
                                    Text("Hours: \(charge.hours)")
                                    Text("Charge ID: \(charge.chargeID)")
                                    Text("Version:  \(charge.version)")
                                }
                            }
                        }
        */
                        
                    //}
                     
                    

                    if !pendingOfflineTSCharges.isEmpty {
                        Text("Offline Changes Detected")
                            .font(.headline)

                        OfflineChangesTabView(sortedKeys: sortedKeys, groupedCharges: groupedCharges)
                        HStack {
                            Button("Approve") {
                                //authenticateAndApproveChanges()
                                approveOfflineCharges()
                            }
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)

                            Button("Deny") {
                                denyOfflineCharges()
                            }
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                Text("Select a timesheet first")
                    .foregroundColor(.red)
                
                if let lastRun = previousRunTimestamp {
                    Text("Previous Run: \(lastRun, formatter: dateFormatter)")
                }
            }
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
        guard let loginID = loginID,
              let empID = GLTFunctions.fetchTarEmpID(byEmail: loginID, context: managedObjectContext)
        else {
            welcomeMessage = "Please log in first"
            return
        }

        employee = GLTFunctions.fetchTarEmp(byID: targetid, context: managedObjectContext)
        chargeLines = GLTFunctions.fetchChargeLines(for: targetid, in: managedObjectContext)
        chargeLineHistory = GLTFunctions.fetchAssignedOrHasHoursChargeLines(for: targetid, context: managedObjectContext).filter{!Set(chargeLines).contains($0)}

        if let cur = curTimesheet {
            month = Int16(cur.month)
            year = Int16(cur.year)
            days = GLTFunctions.dayName(year: Int(year), month: Int(month))
        } else {
            welcomeMessage = "Error: Timesheet data unavailable"
        }
    }
    
//    private func handleShowPrev() {
//        if !chargeLineHistory.isEmpty {
//            showPrev.toggle()
//        }
//    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }
    
    // MARK: - Save and Submit Functions

    private func saveAllChargeLines() {
        if hasInternetConnection() && offlineLogin == false {
            managedObjectContext.perform {
                let currentEmpID = targetid
                let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d AND saved==NO", currentEmpID, month, year)
                do {
                    let tsCharges = try managedObjectContext.fetch(fetchRequest) //fetch all unsaved tscharges
                    
                    for tsCharge in tsCharges {
                        if let tempHours = tsCharge.tempHours, tsCharge.tempHours != tsCharge.hours{
                            tsCharge.hours = tempHours
                            //tsCharge.tempHours = nil
                            tsCharge.saved = true
                            tsCharge.dateSaved = Date()
                            tsCharge.offline = false
                            print("marked tsCharge as saved online, version: \(tsCharge.version)")
                            //version?
                            let newTSCharge = TSCharge(context: managedObjectContext)
                            newTSCharge.employeeID = tsCharge.employeeID
                            newTSCharge.chargeID = tsCharge.chargeID
                            newTSCharge.month = tsCharge.month
                            newTSCharge.year = tsCharge.year
                            newTSCharge.day = tsCharge.day
                            newTSCharge.tempHours = tsCharge.tempHours
                            newTSCharge.saved = false
                            newTSCharge.hours = tsCharge.tempHours
                            newTSCharge.version = tsCharge.version + 1
                            newTSCharge.offline = false
                            newTSCharge.verified = true
                            print("created new online tsCharge, version: \(newTSCharge.version)")
                            do {
                                try managedObjectContext.save()
                            } catch {
                                print("Error saving new TSCharge: \(error.localizedDescription)")
                            }
                        }
                    }
                    try managedObjectContext.save()
                    managedObjectContext.refreshAllObjects()
                    NSLog("Successfully saved all TSCharge hours, marking them as saved.")
                } catch {
                    NSLog("Error saving TSCharge: \(error.localizedDescription)")
                }
            }
        }
        else if !hasInternetConnection()/* && offlineLogin == true*/{
            offlineLogin=true
            print("offline login true, no internet connection")
             managedObjectContext.perform {
                 let currentEmpID = targetid
                 let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                 fetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d AND saved==NO AND denied == NO", currentEmpID, month, year)
                 print("fetched charges")
                 do {
                     let tsCharges = try managedObjectContext.fetch(fetchRequest) //fetch all unsaved tscharges
                     
                     for tsCharge in tsCharges {
                         if let tempHours = tsCharge.tempHours, tsCharge.tempHours != tsCharge.hours{
                             tsCharge.hours = tempHours
                             //tsCharge.tempHours = nil
                             tsCharge.saved = true
                             tsCharge.dateSaved = Date()
                             tsCharge.offline = true
                             print("marked tsCharge as saved offline, version: \(tsCharge.version)")
                             //version?
                             let newTSCharge = TSCharge(context: managedObjectContext)
                             newTSCharge.employeeID = tsCharge.employeeID
                             newTSCharge.chargeID = tsCharge.chargeID
                             newTSCharge.month = tsCharge.month
                             newTSCharge.year = tsCharge.year
                             newTSCharge.day = tsCharge.day
                             newTSCharge.tempHours = tsCharge.tempHours
                             newTSCharge.saved = false
                             newTSCharge.hours = tsCharge.tempHours
                             newTSCharge.version = tsCharge.version + 1
                             newTSCharge.offline = true
                             newTSCharge.denied = false
                             newTSCharge.verified = false
                             print("created new (offline) tsCharge, version: \(newTSCharge.version)")
                             do {
                                 try managedObjectContext.save()
                             } catch {
                                 print("Error saving new TSCharge: \(error.localizedDescription)")
                             }
                         }
                     }
                     try managedObjectContext.save()
                     managedObjectContext.refreshAllObjects()
                     NSLog("Successfully saved all TSCharge hours, marking them as saved.")
                 } catch {
                     NSLog("Error saving TSCharge: \(error.localizedDescription)")
                 }
             }
        }
        else if hasInternetConnection() && offlineLogin == true{
            managedObjectContext.perform {
                let currentEmpID = employee?.id ?? 0
                let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d AND saved==NO", currentEmpID, month, year)
                do {
                    let tsCharges = try managedObjectContext.fetch(fetchRequest) //fetch all unsaved tscharges
                    
                    for tsCharge in tsCharges {
                        if let tempHours = tsCharge.tempHours, tsCharge.tempHours != tsCharge.hours{
                            tsCharge.hours = tempHours
                            //tsCharge.tempHours = nil
                            tsCharge.saved = true
                            tsCharge.dateSaved = Date()
                            tsCharge.offline = false
                            print("marked tsCharge as saved online, version: \(tsCharge.version)")
                            //version?
                            let newTSCharge = TSCharge(context: managedObjectContext)
                            newTSCharge.employeeID = tsCharge.employeeID
                            newTSCharge.chargeID = tsCharge.chargeID
                            newTSCharge.month = tsCharge.month
                            newTSCharge.year = tsCharge.year
                            newTSCharge.day = tsCharge.day
                            newTSCharge.tempHours = tsCharge.tempHours
                            newTSCharge.saved = false
                            newTSCharge.hours = tsCharge.tempHours
                            newTSCharge.version = tsCharge.version + 1
                            newTSCharge.offline = false
                            newTSCharge.verified = true
                            print("created new online tsCharge, version: \(newTSCharge.version)")
                            do {
                                try managedObjectContext.save()
                            } catch {
                                print("Error saving new TSCharge: \(error.localizedDescription)")
                            }
                        }
                    }
                    try managedObjectContext.save()
                    managedObjectContext.refreshAllObjects()
                    NSLog("Successfully saved all TSCharge hours, marking them as saved.")
                } catch {
                    NSLog("Error saving TSCharge: \(error.localizedDescription)")
                }
            }
            managedObjectContext.perform {
                let currentEmpID = employee?.id ?? 0
                let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "employeeID==%d AND offline==YES AND saved==YES AND verified == NO", currentEmpID)
                fetchRequest.sortDescriptors = [
                    NSSortDescriptor(key: "day", ascending: true),
                    NSSortDescriptor(key: "chargeID", ascending: true),
                    NSSortDescriptor(key: "version", ascending: true)
                ]
                        
                do {
                    let tsCharges = try managedObjectContext.fetch(fetchRequest) //fetch all unsaved tscharges
                    DispatchQueue.main.async {
                        self.pendingOfflineTSCharges = tsCharges
                    }
                    NSLog("Successfully fetched all offline TSCharges.")
                } catch {
                    NSLog("Error fetching all offline TSCharges.")
                }
            }
                     
        }
    }
    
    private func generateAndSaveCSV(for charges: [TSCharge], employeeID: Int32, month: Int16, year: Int16) throws {
        var csvText = "Day,ChargeID,Hours,Work Performed,Version\n"

        for charge in charges {
            let day = charge.day
            let chargeID = charge.chargeID
            let hours = charge.hours ?? 0
            let workPerformed = charge.workPerformed ?? ""
            let version = charge.version
            csvText.append("\(day),\(chargeID),\(hours),\(workPerformed), \(version)\n")
        }

        let fileName = "Timesheet_\(employeeID)_\(month)_\(year).csv"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)

        try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
        NSLog("CSV saved at \(fileURL)")
    }

    private func submitTimesheet() {
        managedObjectContext.perform {
            let currentEmpID = targetid
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

                // change this to create cloud date
                // let csvData = generateCSVData(for: tsCharges) // CSV in memory
                // cloudUploadCSV(csvData: csvData, filename: "Timesheet_\(currentEmpID)_\(month)_\(year).csv")
                try self.generateAndSaveCSV(for: tsCharges, employeeID: currentEmpID, month: month, year: year)

            } catch {
                NSLog("Error submitting timesheet: \(error.localizedDescription)")
            }
        }
    }

    
    private func authenticateAndApproveChanges() {
        print("current: \(loginID)")

        AuthenticationManager.shared.signIn(shouldPromptForAccount: shouldPromptForAccount, revokeRequest: revokeRequest) { success, error in
            if success {
                AuthenticationManager.shared.acquireTokenSilently { token, silentError in
                    if let token = token {
                        accessToken = token
                        jwtPayloadString = AuthenticationManager.shared.extractJWTPayloadString(from: token) ?? "Unknown jwtPayloadString"
                        let currentLoginID = AuthenticationManager.shared.extractValue(from: jwtPayloadString, using: "\"unique_name\"\\s*:\\s*\"([^\"]*)\"") ?? "Unknown"
                        activeLogin = true
                        revokeRequest = false
                        
                        AuthenticationManager.shared.checkOneDriveAccess(accessToken: token) { accessSuccess, accessError in
                            DispatchQueue.main.async {
                                //if accessSuccess {
                                print("current: \(loginID)")
                                print("new: \(currentLoginID)")
                                if currentLoginID.lowercased() == loginID?.lowercased(){
                                    authManager.fileAccessResultOD = "Access to OneDrive granted."
                                    AuthenticationManager.shared.fetchDirectoryContents(accessToken: token)
                                    AuthenticationManager.shared.fetchSharedItems(accessToken: token)
                                    
                                    // ✅ Only approve if authentication fully succeeds:
                                    approveOfflineCharges()
                                    offlineLogin=false
                                    print("logged in as correct user, approving")
                                } else {
                                    print("failed to login as correct user, approve failed")
                                    authManager.fileAccessResult = accessError ?? "Access to OneDrive failed."
                                }
                            }
                        }
                    } else {
                        authManager.activeLogin = false
                        authManager.fileAccessResult = "Silent token acquisition failed."
                    }
                }
            } else {
                offlineLogin = true
                activeLogin = false
            }
        }
    }

    private func approveOfflineCharges() {
        managedObjectContext.perform {
            for charge in pendingOfflineTSCharges {
                charge.offline = false
                charge.verified = true
                print("approved day \(charge.day): \(charge.hours ?? 0) hours, \(charge.tempHours ?? 0) tempHours, offline: \(charge.offline), verified: \(charge.verified), denied: \(charge.denied), saved: \(charge.saved)")
            }
            do {
                try managedObjectContext.save()
                DispatchQueue.main.async {
                    pendingOfflineTSCharges.removeAll()
                }
                NSLog("Approved all offline TSCharges.")
            } catch {
                NSLog("Error approving charges: \(error.localizedDescription)")
            }
        }
    }
    
    private func denyOfflineCharges() {
        managedObjectContext.perform {
            for charge in pendingOfflineTSCharges {
                
                let tempFetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                tempFetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d AND day == %d AND chargeID == %d AND saved == NO", charge.employeeID, charge.month, charge.year, charge.day, charge.chargeID)
                tempFetchRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
                tempFetchRequest.fetchLimit = 1
                
                let approvedFetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                approvedFetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d AND day == %d AND chargeID == %d AND saved == YES AND ((offline == NO AND verified == YES AND denied == NO))", charge.employeeID, charge.month, charge.year, charge.day, charge.chargeID)
                approvedFetchRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
                approvedFetchRequest.fetchLimit = 1
                
                /*OR (offline == YES AND verified == NO AND denied == NO)*/
                    
                do{
                    if let tempTSCharge = try managedObjectContext.fetch(tempFetchRequest).first,
                       let approvedTSCharge = try managedObjectContext.fetch(approvedFetchRequest).first {
                        
                        print("approved charge day \(approvedTSCharge.day): \(approvedTSCharge.hours ?? 0) hours, \(approvedTSCharge.tempHours ?? 0) tempHours, offline: \(approvedTSCharge.offline), verified: \(approvedTSCharge.verified), denied: \(approvedTSCharge.denied), saved: \(approvedTSCharge.saved), version: \(approvedTSCharge.version)")
                        
                        
                        tempTSCharge.hours = approvedTSCharge.tempHours
                        tempTSCharge.tempHours = approvedTSCharge.tempHours
                        print("updated temp charge day \(tempTSCharge.day): \(tempTSCharge.hours ?? 0) hours, \(tempTSCharge.tempHours ?? 0) tempHours, offline: \(tempTSCharge.offline), verified: \(tempTSCharge.verified), denied: \(tempTSCharge.denied), saved: \(tempTSCharge.saved), version: \(tempTSCharge.version)")
                        
                    }

                    charge.denied = true
                    charge.offline=false
                    charge.verified = true
                    print("Denied version: \(charge.version) for chargeID: \(charge.chargeID) day: \(charge.day)")
                    
                    NSLog("Updated tempCharge")

                }
                catch{
                    NSLog("Error updating tempCharge: \(error.localizedDescription)")
                }
            }
            do {
                try managedObjectContext.save()
                DispatchQueue.main.async {
                    pendingOfflineTSCharges.removeAll()
                }
                NSLog("Denied all offline TSCharges.")
            }
            catch {
                NSLog("Error denying charges: \(error.localizedDescription)")
            }
        }
    }
    

}

struct OfflineChangesTabView: View {
    let sortedKeys: [DayChargeKey]
    let groupedCharges: [DayChargeKey: [TSCharge]]

    var body: some View {
        TabView {
            ForEach(sortedKeys, id: \.self) { key in
                let charges = groupedCharges[key] ?? []

                if let firstCharge = charges.first {
                    ScrollView { // 👈 Add this ScrollView to make tab scrollable
                        VStack(alignment: .leading, spacing: 10) {
                            if let formattedDate = Calendar.current.date(from: DateComponents(year: Int(firstCharge.year), month: Int(firstCharge.month), day: Int(firstCharge.day))) {
                                Text("\(TimesheetView.displayDateFormatter.string(from: formattedDate)) - Charge \(key.chargeID)")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                            } else {
                                Text("Invalid Date - Charge \(key.chargeID)")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                            }

                            ForEach(charges.sorted(by: { $0.version < $1.version }), id: \.objectID) { charge in
                                VStack(alignment: .leading) {
                                    Text("Hours: \(charge.hours ?? 0)")
                                    Text("Version: \(charge.version)")
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        .frame(height: 300) // Optional: remove if you want dynamic height
    }
}

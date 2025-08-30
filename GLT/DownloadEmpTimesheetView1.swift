import Foundation
import SwiftUI
import CoreData

public struct DownloadEmpTimesheetView1: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var curEmployee: Int32
    @Binding var loginID: String?
    
    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    
    @State private var selectedEmployeeIDs: Set<Int32> = []
    @State private var csvURLs: [URL] = [] // could be cloud URLs instead
    @State private var showingExporter = false
    @State private var selectedMonth: Int16 = Int16(Calendar.current.component(.month, from: Date()))
    @State private var selectedYear: Int16 = Int16(Calendar.current.component(.year, from: Date()))
    
    public var body: some View {
        VStack {
            HStack {
                Picker("Month", selection: $selectedMonth) {
                    ForEach(1...12, id: \.self) { month in
                        Text(Calendar.current.monthSymbols[month - 1]).tag(Int16(month))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
                
                Picker("Year", selection: $selectedYear) {
                    let currentYear = Calendar.current.component(.year, from: Date())
                    ForEach((currentYear - 5)...(currentYear + 1), id: \.self) { year in
                        Text("\(year)").tag(Int16(year))
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.horizontal)
            }
            
            List {
                ForEach(employees.filter { ($0.nameFirst?.isEmpty == false) && ($0.nameLast?.isEmpty == false) }, id: \.self) { employee in
                    let isSelected = selectedEmployeeIDs.contains(employee.id)
                    Button(action: {
                        if isSelected { selectedEmployeeIDs.remove(employee.id) }
                        else { selectedEmployeeIDs.insert(employee.id) }
                    }) {
                        HStack {
                            Text("\(employee.nameLast ?? ""), \(employee.nameFirst ?? "")")
                            Spacer()
                            if isSelected { Image(systemName: "checkmark.circle.fill").foregroundColor(.blue) }
                        }
                        .padding()
                        .background(isSelected ? Color.blue : Color.gray)
                        .cornerRadius(10)
                    }
                }
            }
            
            Button("Retrieve Timesheets") {

//              TEST EMAIL:
                
//                AuthenticationManager.shared.getAccessToken { token in
//                    if let token = token {
//                        AuthenticationManager.shared.sendEmail(accessToken: token, recipientEmail: "dylandomingo57@gmail.com")
//                    } else {
//                        print("Failed to get access token")
//                    }
//                }

//                    // fetch TSCharge data for this employee
////                    let tsCharges = fetchChargesFromCoreData(employeeID: employeeID, month: selectedMonth, year: selectedYear) // change to fetch from cloud
//                    
//                    // convert charges to CSV in memory
////                    let csvData = generateCSVData(for: tsCharges)
//                    
//                    // upload CSV to cloud storage (OneDrive / SharePoint / Azure Blob)
//                    // implement this: cloudUploadCSV(csvData: csvData, filename: "Timesheet_\(employeeID)_\(selectedMonth)_\(selectedYear).csv")
//                    
//                    // store returned cloud URL in csvURLs for tracking / ShareLink
//                    // csvURLs.append(cloudFileURL)
//                    
//                    // send email with the CSV attached via Microsoft Graph API
//                    // sendEmailWithCSV(to: managerEmail, csvData: csvData, filename: ...)
//                }
            }
            .disabled(selectedEmployeeIDs.isEmpty)
            .padding()
        }
    }
    
    private func fetchChargesFromCoreData(employeeID: Int32, month: Int16, year: Int16) -> [TSCharge] {
        let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d", employeeID, month, year)
        do { return try managedObjectContext.fetch(fetchRequest) }
        catch { return [] }
    }
    
    private func generateCSVData(for charges: [TSCharge]) -> Data {
        var csvText = "Day,ChargeID,Hours,Work Performed,Version\n"
        for charge in charges {
            csvText.append("\(charge.day),\(charge.chargeID),\(charge.hours ?? 0),\(charge.workPerformed ?? ""),\(charge.version)\n")
        }
        return csvText.data(using: .utf8) ?? Data()
    }
    
    // send email with CSV attached using OAuth2 + Graph API
    private func sendEmailWithCSV(to recipient: String, csvData: Data, filename: String) {
        // implement sending email via Microsoft Graph API
    }
}

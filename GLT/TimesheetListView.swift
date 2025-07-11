import SwiftUI
import CoreData

struct TimesheetListView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var curEmployee: Int32
    @Binding var curTimesheet: Timesheet?
    @Binding var loginID: String?
    var isManagingOthers: Bool = false
    
    @State private var curDate = Date()
    @State private var startDate: Date?
    @State private var firstOfMonthDate = GLTFunctions.firstDateOfCurrentMonth(from: Date())
    @State private var lastOfMonthDate = GLTFunctions.firstDateOfNextMonth(from: Date())
    @State private var timesheets: [Timesheet] = [] // Fixed initialization
    @State private var noTimesheets: Bool = false
    @State private var welcomeMessage: String = ""
    
    
    var body: some View {
        VStack {
            Text("\(welcomeMessage)")
                .padding()
                    List {
                    ForEach(timesheets, id: \.self) { ts in // Ensure Timesheet conforms to Identifiable or use `id`
                        let month = GLTFunctions.convertIntToMonth(from: Int(ts.month))
                        let year = Text(String(ts.year))
                        let submitted = ts.submitted
//                        Text("One more")
                        switch submitted {
                        case true:
                            Button("Edit") {
                                curTimesheet = ts
                                path.append(AppView.timesheet)
                            }
                            .font(.caption)
                            .foregroundStyle(Color(hex: "1136cc"))
                            .background(Color(hex: "000000"))
                        case false:
                            Button("\(month)/\(year)") {
                                curTimesheet = ts
                                path.append(AppView.timesheet)
                            }
                            .font(.system(size: 14))
                            .foregroundColor(Color(hex: "FF6600"))
                            //.background(Color(hex: "000000"))
                        }
                    }
                }
        }
        .onAppear {
            if isManagingOthers {
                if let employee = GLTFunctions.fetchTarEmp(byID: curEmployee, context: viewContext) {
                    let first = employee.nameFirst ?? "Unknown"
                    let last  = employee.nameLast  ?? ""
                    welcomeMessage = "Managing timesheets for: \(first) \(last)"
                } else {
                    welcomeMessage = "Managing timesheets for Employee #\(curEmployee)"
                }
                fetchTimesheets()
            } else if let empEmail = loginID {
                curEmployee = GLTFunctions.fetchTarEmpID(byEmail: empEmail, context: viewContext)!
                fetchTimesheets()
                welcomeMessage = "Timesheets for \(loginID!)"
            } else {
                welcomeMessage = "🥷Please log in first🥷"
            }
        }

    }
    
    func fetchTimesheets() {
        do {
            // Fetch existing timesheets for the employee
            timesheets = try GLTFunctions.fetchFilteredTimesheets(
                for: curEmployee,
                sortKey: "enabled",
                ascending: false,
                startMonth: Int16(GLTFunctions.fetchCurMonth()),
                startYear: Int16(GLTFunctions.fetchCurYear()),
                context: viewContext
            ) ?? []
            
            // Determine the start date for creating timesheets
            let employeeStartDate = GLTFunctions.fetchEMPFirstTSDate(empID: curEmployee, empContext: viewContext) ?? Date()
            let startMonth = Calendar.current.component(.month, from: employeeStartDate)
            let startYear = Calendar.current.component(.year, from: employeeStartDate)
            
            // Loop through months from start date to the current month
            var currentYear = startYear
            var currentMonth = startMonth
            let now = Date()
            let currentCalendar = Calendar.current

            while currentCalendar.date(from: DateComponents(year: currentYear, month: currentMonth))! <= now {
                // Check if a timesheet exists for the current month and year
                let exists = timesheets.contains { ts in
                    ts.year == Int16(currentYear) && ts.month == Int16(currentMonth)
                }
                
                // If not, create a missing timesheet
                if !exists {
                    if let newTimesheet = GLTFunctions.addTimesheet(
                        byID: curEmployee,
                        month: Int16(currentMonth), year: Int16(currentYear),
                        context: viewContext
                    ) {
                        timesheets.append(newTimesheet)
                        print("Created a missing timesheet for \(currentMonth)/\(currentYear)")
                    }
                }
                
                // Increment month and year as needed
                if currentMonth == 12 {
                    currentMonth = 1
                    currentYear += 1
                } else {
                    currentMonth += 1
                }
            }
            
        } catch {
            print("Error fetching timesheets: \(error.localizedDescription)")
            welcomeMessage = "🥷Please log in first🥷"
        }
        
        // Handle case where no timesheets exist
        if timesheets.isEmpty {
            if let newTimesheet = GLTFunctions.addTimesheet(byID: curEmployee, context: viewContext) {
                timesheets.append(newTimesheet)
            }
        }
        
        timesheets.sort {
            if $0.year == $1.year {
                return $0.month > $1.month
            } else {
                return $0.year > $1.year
            }
        }
    }

}

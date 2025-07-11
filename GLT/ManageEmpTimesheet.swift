import Foundation
import SwiftUI
import CoreData

public struct ManageEmpTimesheet: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var curEmployee: Int32
    @Binding var loginID: String?
    @Binding var curTimesheet: Timesheet?

    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    @State private var selectedEmployeeID: Int32? = nil

    public var body: some View {
        VStack {
            List {
                ForEach(employees.filter { $0.nameFirst?.isEmpty == false && $0.nameLast?.isEmpty == false }, id: \.self) { employee in
                    let isSelected = selectedEmployeeID == employee.id
                    Button(action: {
                        selectedEmployeeID = isSelected ? nil : employee.id
                    }) {
                        Text("\(employee.nameLast ?? "No Last Name"), \(employee.nameFirst ?? "No First Name")")
                            .padding()
                            .foregroundColor(.white)
                            .background(isSelected ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
            Button("View Timesheets") {
                if let id = selectedEmployeeID {
                    curEmployee = id
                    path = NavigationPath()
                    path.append(AppView.management)
                    path.append(AppView.manageEmpTimesheetList)
                }
            }
            .disabled(selectedEmployeeID == nil)
            .padding()
        }
    }
}

import Foundation
import SwiftUI
import CoreData

public struct Emp2CLView1: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var selectedEmployeeIDs: [Int32]
    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    @State var selectedEmployees: [Int32: Bool] = [:]

    private var selectedCount: Int {
        selectedEmployees.values.filter { $0 }.count
    }

    public var body: some View {
        VStack {
            List {
                ForEach(employees.filter { $0.nameFirst?.isEmpty == false && $0.nameLast?.isEmpty == false }, id: \.self) { employee in
                    let isSelected = selectedEmployees[employee.id] ?? false
                    Button(action: {
                        selectedEmployees[employee.id] = !(selectedEmployees[employee.id] ?? false)
                    }) {
                        Text("\(employee.nameLast ?? "No Last Name"), \(employee.nameFirst ?? "No First Name")")
                            .padding()
                            .foregroundColor(.white)
                            .background(isSelected ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
            Text("Total Selected: \(selectedCount)")
                .padding()
                .font(.headline)
            Button("Proceed to Charge Lines") {
                if selectedCount > 0 {
                    selectedEmployeeIDs = selectedEmployees.filter { $0.value }.map { $0.key }
                    path = NavigationPath() // Reset the navigation path to go back
                    path.append(AppView.management)
                    path.append(AppView.emp2cl1)
                    path.append(AppView.emp2cl2)
                }
            }
            .disabled(selectedCount == 0)
        }
    }
}

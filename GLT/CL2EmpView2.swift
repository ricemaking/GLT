import SwiftUI
import CoreData

public struct CL2EmpView2: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var selectedChargeLineIDs: [Int32]
    @State private var selectedEmployees: [Int32: Bool] = [:]
    @State private var selectedEmployeeIDs: [Int32] = []

    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    @FetchRequest(entity: ChargeLine.entity(), sortDescriptors: []) var chargeLines: FetchedResults<ChargeLine>

    private var selectedCount: Int {
        selectedEmployees.values.filter { $0 }.count
    }

    public var body: some View {
        VStack {
            List {
                ForEach(employees.filter { ($0.nameFirst?.isEmpty == false) && ($0.nameLast?.isEmpty == false) }, id: \.self) { employee in
                    let isSelected = selectedEmployees[employee.id] ?? false
                    Button(action: {
                        selectedEmployees[employee.id] = !isSelected
                    }) {
                        Text("\(employee.nameLast ?? ""), \(employee.nameFirst ?? "")")
                            .padding()
                            .foregroundColor(.white)
                            .background(isSelected ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }

            Button("Assign Selected Employees to Charge Lines") {
                selectedEmployeeIDs = selectedEmployees.filter { $0.value }.map { $0.key }

                for chargeLineID in selectedChargeLineIDs {
                    guard let chargeLine = chargeLines.first(where: { $0.clID == chargeLineID }) else { continue }

                    for employeeID in selectedEmployeeIDs {
                        guard let employee = employees.first(where: { $0.id == employeeID }) else { continue }

                        employee.addToChargeLine(chargeLine)
                        chargeLine.addToEmployee(employee)

                        GLTFunctions.assignTSChargeAssignmentDates(
                            employeeID: employeeID,
                            year: Int16(GLTFunctions.fetchCurYear()),
                            month: Int16(GLTFunctions.fetchCurMonth()),
                            day: Int16(GLTFunctions.fetchCurDay()),
                            clID: chargeLineID,
                            dateAssigned: Date(),
                            dateUnassigned: nil,
                            context: managedObjectContext
                        )
                    }
                }

                do {
                    try managedObjectContext.save()
                } catch {
                    print("Failed to save context: \(error)")
                }

                path = NavigationPath()
                path.append(AppView.management)
                path.append(AppView.cl2emp1)
            }

            if selectedChargeLineIDs.isEmpty {
                Text("No charge lines selected")
                    .padding()
            }
        }
        .onAppear {
            for employee in employees {
                selectedEmployees[employee.id] = false
            }
        }
    }
}

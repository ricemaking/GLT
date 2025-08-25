import Foundation
import SwiftUI
import CoreData

public struct Emp2CLView2: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var selectedEmployeeIDs: [Int32]
    @State var selectedChargeLines: [Int32: Bool] = [:]
    @State var selectedChargeIDs: [Int32] = []

    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    @FetchRequest(entity: ChargeLine.entity(), sortDescriptors: []) var cls: FetchedResults<ChargeLine>
    
    private var selectedCount: Int {
        selectedChargeLines.values.filter { $0 }.count
    }

    public var body: some View {
        List {
            ForEach(cls.filter { $0.clName?.isEmpty == false }, id: \.self) { chargeLine in
                let isSelected = selectedChargeLines[chargeLine.clID] ?? false
                Button(action: {
                    selectedChargeLines[chargeLine.clID] = !(selectedChargeLines[chargeLine.clID] ?? false)
                }) {
                    Text("\(chargeLine.clName ?? "No Name"), ID:\(String(format: "%05d", chargeLine.clID))")
                        .padding()
                        .foregroundColor(.white)
                        .background(isSelected ? Color.blue : Color.gray)
                        .cornerRadius(10)
                }
            }

            Button("Assign Selected") {
                if selectedCount > 0 {
                    selectedChargeIDs = selectedChargeLines.filter { $0.value }.map { $0.key }
                    for id in selectedChargeIDs {
                        for employeeID in selectedEmployeeIDs {
                            if let employee = employees.first(where: { $0.id == employeeID }),
                               let chargeLine = cls.first(where: { $0.clID == id }) {
                                // Add employee to chargeLine
                                chargeLine.addToEmployee(employee)
                                employee.addToChargeLine(chargeLine)
                            }
                        }
                    }
                    do {
                        try managedObjectContext.save()
                    } catch {
                        print("Failed to save context: \(error)")
                    }
                    path = NavigationPath() // Reset the navigation path to go back
                    path.append(AppView.management)
                    path.append(AppView.emp2cl1)
                }
            }

            if filteredEmployees.isEmpty {
                Text("No employees selected")
                    .padding()
            }
        }
    }

    private var filteredEmployees: [Employee] {
        employees.filter { employee in
            selectedEmployeeIDs.contains(employee.id)
        }
    }
}

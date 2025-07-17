import Foundation
import SwiftUI
import CoreData

public struct Emp2CLView2: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var selectedEmployeeIDs: [Int32]
    @State var selectedChargeLines: [Int32: Bool] = [:]
    @State var selectedChargeIDs: [Int32] = []
    @State var confirmAssignment: Bool = false
    @State var initialSelection: [Int32: Bool] = [:]
    @State private var changeLogMessage: String = ""
    @State private var previousAssignments: [Int32: Set<Int32>] = [:]

    @FetchRequest(entity: Employee.entity(), sortDescriptors: []) var employees: FetchedResults<Employee>
    @FetchRequest(entity: ChargeLine.entity(), sortDescriptors: []) var cls: FetchedResults<ChargeLine>
    
    private var selectedCount: Int {
        selectedChargeLines.values.filter { $0 }.count
    }


    public var body: some View {
        VStack {
            List {
                ForEach(cls.filter { $0.clName?.isEmpty == false }, id: \.self) { chargeLine in
                    let isSelected = selectedChargeLines[chargeLine.clID] ?? false
                    Button(action: {
                        selectedChargeLines[chargeLine.clID] = !isSelected
                    }) {
                        Text("\(chargeLine.clName ?? "No Name"), ID:\(String(format: "%05d", chargeLine.clID))")
                            .padding()
                            .foregroundColor(.white)
                            .background(isSelected ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }
            Button("Assign Selected") {
                generateChangeLog()
                confirmAssignment = true
            }
            .alert("Confirm Assignment", isPresented: $confirmAssignment) {
                Button("Cancel", role: .cancel) {}
                Button("Confirm", role: .destructive) {
                    selectedChargeIDs = selectedChargeLines.filter { $0.value }.map { $0.key }
                    for chargeLine in cls {
                        let isSelected = selectedChargeLines[chargeLine.clID] ?? false
                        for employeeID in selectedEmployeeIDs {
                            if let employee = employees.first(where: { $0.id == employeeID }) {
                                if isSelected {
                                    chargeLine.addToEmployee(employee)
                                    employee.addToChargeLine(chargeLine)
                                    
                                    GLTFunctions.assignTSChargeAssignmentDates(
                                        employeeID: employeeID,
                                        year: Int16(GLTFunctions.fetchCurMonth()),
                                        month: Int16(GLTFunctions.fetchCurYear()),
                                        day: Int16(GLTFunctions.fetchCurDay()),
                                        clID: chargeLine.clID,
                                        dateAssigned: Date(),
                                        dateUnassigned: nil,
                                        context: managedObjectContext
                                    )
                                    
                                } else {
                                    chargeLine.removeFromEmployee(employee)
                                    employee.removeFromChargeLine(chargeLine)
                                    
                                    GLTFunctions.assignTSChargeAssignmentDates(
                                        employeeID: employeeID,
                                        year: Int16(GLTFunctions.fetchCurMonth()),
                                        month: Int16(GLTFunctions.fetchCurYear()),
                                        day: Int16(GLTFunctions.fetchCurDay()),
                                        clID: chargeLine.clID,
                                        dateAssigned: nil,
                                        dateUnassigned: Date(),
                                        context: managedObjectContext
                                    )
                                }
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
            } message: {
                Text(changeLogMessage)
            }

            if filteredEmployees.isEmpty {
                Text("No employees selected")
                    .padding()
            }
        }
        .onAppear {
            initSelections()
        }
    }

    private var filteredEmployees: [Employee] {
        employees.filter { employee in
            selectedEmployeeIDs.contains(employee.id)
        }
    }
    
    private func initSelections() {
        previousAssignments = [:]
        var assignedIDs: Set<Int32> = []

        for employeeID in selectedEmployeeIDs {
            let chargeLineIDs = Set(GLTFunctions.fetchChargeLineIDs(for: employeeID, in: managedObjectContext))
            previousAssignments[employeeID] = chargeLineIDs
            assignedIDs.formUnion(chargeLineIDs)
        }

        for chargeLine in cls {
            initialSelection[chargeLine.clID] = assignedIDs.contains(chargeLine.clID)
        }

        selectedChargeLines = initialSelection
    }
    
    private func generateChangeLog() {
        var logLines: [String] = []
        
        for employeeID in selectedEmployeeIDs {
            guard let employee = employees.first(where: { $0.id == employeeID }) else { continue }
            let employeeName = "\(employee.nameFirst ?? "") \(employee.nameLast ?? "")".trimmingCharacters(in: .whitespaces)
            let initiallyAssigned = previousAssignments[employeeID] ?? []
            var added: [String] = []
            var removed: [String] = []
            
            for chargeLine in cls {
                let clID = chargeLine.clID
                let clName = chargeLine.clName ?? "CL \(clID)"
                let isNowSelected = selectedChargeLines[clID] ?? false
                let wasAssignedToThisEmployee = initiallyAssigned.contains(clID)
                
                if !wasAssignedToThisEmployee && isNowSelected {
                    added.append("\(clName) [ID:\(clID)]")
                } else if wasAssignedToThisEmployee && !isNowSelected {
                    removed.append("\(clName) [ID:\(clID)]")
                }
            }
            
            if !added.isEmpty || !removed.isEmpty {
                logLines.append("Changes for \(employeeName):")
                if !added.isEmpty {
                    logLines.append("  + Assign: " + added.joined(separator: ", "))
                }
                if !removed.isEmpty {
                    logLines.append("  - Unassign: " + removed.joined(separator: ", "))
                }
            }
        }
        
        if logLines.isEmpty {
            changeLogMessage = "No changes detected"
        } else {
            changeLogMessage = logLines.joined(separator: "\n\n")
        }
    }


}

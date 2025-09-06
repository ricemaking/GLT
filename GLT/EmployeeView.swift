//
//  EmployeeView.swift
//  NavTrack
//
//  Created by Player_1 on 1/19/25.
//

import SwiftUI
import CoreData
import Foundation

struct EmployeeView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32

    // FetchRequest with a sortDescriptor to ensure automatic updates are detected
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Employee.id, ascending: true)]
    ) var employees: FetchedResults<Employee>
    
    @State private var isLoading: Bool = false
    @State private var reloadToggle: Bool = false // Dummy state to force List reload

    var body: some View {
        List {
            ForEach(employees) { employee in
                let _ = print("employee xists")
                let _ = print("employeenameFirst: \(String(describing: employee.nameFirst)), employee.nameLast: \(String(describing: employee.nameLast)), employee.dob: \(String(describing: employee.dob))")
                if let nameFirst = employee.nameFirst,
                   let nameLast = employee.nameLast,
                   let dob = employee.dob {
                    HStack {
                        Text("ID: \(employee.id)\nFirst Name: \(nameFirst)\nLast Name: \(nameLast)\nDate of Birth: \(dob)")
                            .padding()
                        Spacer()
                        Button("Details") {
                            targetid = employee.id
                            path.append(AppView.employeeEditView)
                        }
                    }
                }
            }
        }
        .id(reloadToggle) // Forces the List to refresh when reloadToggle changes
        .navigationTitle("Employee View")
        .toolbar {
            Button("+") {
                path.append(AppView.addEmployee)
            }
        }
        .onAppear {
            guard !isLoading else { return }
            isLoading = true
            
            // Fetch employees from backend and insert/update Core Data
            GLTFunctions.getEmployees(context: viewContext)
            
            // Toggle dummy state to force SwiftUI refresh
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                reloadToggle.toggle()
            }
        }
    }
}

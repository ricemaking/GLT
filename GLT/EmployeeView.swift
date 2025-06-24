//
//  EmployeeView.swift
//  NavTrack
//
//  Created by Player_1 on 1/19/25.
//

import SwiftUI
import CoreData
import Foundation

// Employee View
struct EmployeeView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32
    @FetchRequest(
        sortDescriptors: []
    ) var employees: FetchedResults<Employee>
    
    var body: some View {
        List {
            ForEach(employees) { employee in
                if let nameFirst = employee.nameFirst, let nameLast = employee.nameLast, let dob = employee.dob
                {
                    HStack
                    {
                        Text("ID:\(employee.id)\nFirst Name:\(nameFirst)\nLast Name:\(nameLast)\nDate of Birth:\(dob)")
                            .padding()
                        Spacer()
                        Button("Details")
                        {
                            targetid = employee.id
                            path.append(AppView.employeeEditView)

                         }
                    }
                    
                }
            }
        }
        .navigationTitle("Employee View")
        .toolbar {
            Button("+") {
                path.append(AppView.addEmployee)
            }
        }
    }
}

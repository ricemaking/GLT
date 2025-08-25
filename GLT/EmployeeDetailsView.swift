import SwiftUI
import CoreData

struct EmployeeDetailsView: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32
    @State private var employee: Employee?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) { // Adjust spacing here
            if let employee = employee {
                let tempID: String = String(format: "%05d", employee.id)
                Text("Employee Details")
                    .font(.title)
                    .padding(.leading, 20)
                Text("Name: \(employee.nameFirst ?? "") \(employee.nameLast ?? "")")
                    .padding(.leading, 20)
                Text("DOB: \(employee.dob ?? "")")
                    .padding(.leading, 20)
                Text("ID: \(tempID)")
                    .padding(.leading, 20)
                Text("Email: \(employee.email ?? "N/A")")
                    .padding(.leading, 20)
                Text("Phone: \(employee.phone ?? "N/A")")
                    .padding(.leading, 20)
                Text("Address: \(employee.streetAddress ?? "N/A")")
                    .padding(.leading, 20)
                HStack {
                    Text("City: \(employee.city ?? "N/A")")
                    Text("State: \(employee.state ?? "N/A")")
                }
                .padding(.leading, 20)
                Text("Zip Code: \(employee.zipCode ?? "N/A")")
                    .padding(.leading, 20)
                Text("Clearance Level: \(employee.clearanceLevel ?? "N/A")")
                    .padding(.leading, 20)
                Text("Charge Lines")
                    .font(.headline)
                    .padding(.top)

                if let chargeLines = employee.chargeLine as? Set<ChargeLine> {
                    List(chargeLines.sorted(by: { $0.clID < $1.clID }), id: \.self) { chargeLine in
                        Text("\(chargeLine.clName ?? "No Name"), ID: \(chargeLine.clID)")
                    }
                } else {
                    Text("No charge lines associated")
                }
            } else {
                Text("Employee not found")
            }
            Button("Edit") {
                path.append(AppView.employeeEditView)
            }
        }
        .navigationTitle("Employee Details")
        .onAppear {
            employee = GLTFunctions.fetchTarEmp(byID: targetid, context: managedObjectContext)
        }
        .padding() // This applies padding to the entire VStack
    }
}

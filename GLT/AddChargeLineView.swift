
import SwiftUI
import CoreData

struct AddChargeLineView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @State private var clName: String = ""
    @State private var clCap: String = ""
    @State private var clFunded: String = ""
    @State private var clDateStart: String = ""
    @State private var clDateEnd: String = ""
    @State private var isValid: Bool = true
    @State private var showSuccessMessage = false

    var body: some View {
        VStack {
            VStack {
                Text("Name")
                TextField("Name", text: $clName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onChange(of: clName) { validateInputs() }
            }

            HStack {
                VStack {
                    Text("Funds (Actual)")
                    TextField("$ (Actual)", text: $clFunded)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: clFunded) {validateInputs() }
                }

                VStack {
                    Text("Funds (Cap)")
                    TextField("$ (Cap)", text: $clCap)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: clCap) {validateInputs() }
                }
            }

            HStack {
                VStack {
                    Text("Start Date")
                    TextField("Enter Date Start (yyyy-MM-dd)", text: $clDateStart)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: clDateStart) {validateInputs() }
                }

                VStack {
                    Text("End Date")
                    TextField("Enter Date End (yyyy-MM-dd)", text: $clDateEnd)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: clDateEnd) {validateInputs() }
                }
            }

            Button("Add Charge Line") {
                if isValid {
                    let cap = Decimal(string: clCap)
                    let clCapNS = NSDecimalNumber(decimal: cap ?? Decimal(0))
                    let funded = Decimal(string: clFunded)
                    let clFundedNS = NSDecimalNumber(decimal: funded ?? Decimal(0))
                    clDateStart = GLTFunctions.transformDateString(clDateStart) ?? "00/00/0000"
                    clDateEnd = GLTFunctions.transformDateString(clDateEnd) ?? "00/00/0000"
                    GLTFunctions.addChargeLine(clName: clName, clCap: clCapNS, clFunded: clFundedNS, clDateStart: clDateStart, clDateEnd: clDateEnd, context: viewContext)
                    path = NavigationPath()
                    path.append(AppView.management)
                    path.append(AppView.chargeLine)
                    showSuccessMessage = true
                } else {
                    // Handle invalid date or empty nameFirst
                    print("Missing field(s) or wrong input format.\tDate input format must be\n'ddmmyyyy',\n'dd-mm-yyyy'\n'dd.mm.yyyy'\n'dd/mm/yyyy'\n\nFunding inputs must be in decimal format '0.00'")
                }
            }
            .disabled(!isValid)

            if !isValid {
                Text("Please enter valid and complete imput")
                    .foregroundColor(.red)
            }
            if showSuccessMessage {
                Text("Charge Line \(clName) added successfully and will be effective starting \(clDateStart)!")
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .padding()
    }

    private func validateInputs() {
        self.isValid = !clName.isEmpty &&
                       GLTFunctions.validDateInput(clDateStart) &&
                       GLTFunctions.validDateInput(clDateEnd) &&
                       GLTFunctions.validateDecimalInput(clCap) &&
                       GLTFunctions.validateDecimalInput(clFunded)
    }
}

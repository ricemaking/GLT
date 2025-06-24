import SwiftUI
import CoreData

struct ChargeLineEditView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32
    
    @State private var clName: String = ""
    @State private var clCap: String = ""
    @State private var clFunded: String = ""
    @State private var clDateStart: String = ""
    @State private var clDateEnd: String = ""
    @State private var isValid: Bool = true
    @State private var showSuccessMessage = false
    @State private var cl: ChargeLine? // The currently selected ChargeLine

    var body: some View {
        VStack {
            VStack {
                Text("Name")
                TextField("Name", text: $clName)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            HStack {
                VStack {
                    Text("Funds (Actual)")
                    TextField("$ (Actual)", text: $clFunded)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack {
                    Text("Funds (Cap)")
                    TextField("$ (Cap)", text: $clCap)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            HStack {
                VStack {
                    Text("Start Date")
                    TextField("Enter Date Start (yyyy-MM-dd)", text: $clDateStart)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                VStack {
                    Text("End Date")
                    TextField("Enter Date End (yyyy-MM-dd)", text: $clDateEnd)
                        .padding()
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            Button("Save Changes") {
                saveChargeLine()
            }
            .disabled(!isValid)
            if showSuccessMessage {
                Text("Charge Line updated successfully!")
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .onAppear {
            fetchChargeLineData()
        }
    }
    
    // MARK: - Fetch Existing ChargeLine Data
    private func fetchChargeLineData() {
        let request: NSFetchRequest<ChargeLine> = ChargeLine.fetchRequest()
        request.predicate = NSPredicate(format: "clID == %d", targetid)
        do {
            let results = try viewContext.fetch(request)
            if let chargeLine = results.first {
                cl = chargeLine
                clName = chargeLine.clName ?? ""
                // Convert NSDecimalNumber to String for display
                clCap = chargeLine.clCap?.stringValue ?? ""
                clFunded = chargeLine.clFunded?.stringValue ?? ""
                clDateStart = chargeLine.clDateStart ?? ""
                clDateEnd = chargeLine.clDateEnd ?? ""
            }
        } catch {
            print("Failed to fetch ChargeLine: \(error)")
        }
    }
    
    // MARK: - Save ChargeLine Changes
    private func saveChargeLine() {
        guard let chargeLine = cl else {
            print("No ChargeLine loaded for editing")
            return
        }
        
        // Validate inputs using your GLTFunctions (or other validation logic)
        if GLTFunctions.validDateInput(clDateStart),
           GLTFunctions.validDateInput(clDateEnd),
           !clName.isEmpty,
           GLTFunctions.validateDecimalInput(clCap),
           GLTFunctions.validateDecimalInput(clFunded) {
            
            // Optionally transform the date strings (or use them directly)
            let newStart = GLTFunctions.transformDateString(clDateStart) ?? clDateStart
            let newEnd = GLTFunctions.transformDateString(clDateEnd) ?? clDateEnd
            
            // Convert funding strings to NSDecimalNumber
            let capNum = NSDecimalNumber(string: clCap)
            let fundedNum = NSDecimalNumber(string: clFunded)
            
            if capNum == NSDecimalNumber.notANumber || fundedNum == NSDecimalNumber.notANumber {
                isValid = false
                print("Invalid decimal input for funding values")
                return
            }
            
            // Update the entity values
            chargeLine.clName = clName
            chargeLine.clCap = capNum
            chargeLine.clFunded = fundedNum
            chargeLine.clDateStart = newStart
            chargeLine.clDateEnd = newEnd
            
            do {
                try viewContext.save()
                showSuccessMessage = true
                // Reset the navigation path as desired:
                path = NavigationPath()
                path.append(AppView.management)
                path.append(AppView.chargeLine)
            } catch {
                print("Failed to save ChargeLine: \(error)")
            }
        } else {
            isValid = false
            print("Missing field(s) or invalid input format.")
        }
    }
}

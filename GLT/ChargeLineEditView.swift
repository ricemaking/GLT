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
    @State private var cl: ChargeLine?

    var body: some View {
        VStack {
            TextField("Name", text: $clName).textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            
            HStack {
                TextField("Funds (Actual)", text: $clFunded)
                    .textFieldStyle(RoundedBorderTextFieldStyle()).padding()
                TextField("Funds (Cap)", text: $clCap)
                    .textFieldStyle(RoundedBorderTextFieldStyle()).padding()
            }
            
            HStack {
                TextField("Start Date (yyyy-MM-dd)", text: $clDateStart)
                    .textFieldStyle(RoundedBorderTextFieldStyle()).padding()
                TextField("End Date (yyyy-MM-dd)", text: $clDateEnd)
                    .textFieldStyle(RoundedBorderTextFieldStyle()).padding()
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
        .onAppear { fetchChargeLine() }
    }
    
    private func fetchChargeLine() {
        let request: NSFetchRequest<ChargeLine> = ChargeLine.fetchRequest()
        request.predicate = NSPredicate(format: "clID == %d", targetid)
        do {
            if let result = try viewContext.fetch(request).first {
                cl = result
                clName = result.clName ?? ""
                clCap = result.clCap?.stringValue ?? ""
                clFunded = result.clFunded?.stringValue ?? ""
                clDateStart = result.clDateStart ?? ""
                clDateEnd = result.clDateEnd ?? ""
            }
        } catch {
            print("Failed to fetch ChargeLine:", error)
        }
    }
    
    private func saveChargeLine() {
        guard let chargeLine = cl else { return }
        
        if GLTFunctions.validateDecimalInput(clCap),
           GLTFunctions.validateDecimalInput(clFunded),
           GLTFunctions.validDateInput(clDateStart),
           GLTFunctions.validDateInput(clDateEnd),
           !clName.isEmpty {
            
            chargeLine.clName = clName
            chargeLine.clCap = NSDecimalNumber(string: clCap)
            chargeLine.clFunded = NSDecimalNumber(string: clFunded)
            chargeLine.clDateStart = GLTFunctions.transformDateString(clDateStart) ?? clDateStart
            chargeLine.clDateEnd = GLTFunctions.transformDateString(clDateEnd) ?? clDateEnd
            
            GLTFunctions.updateChargeLine(chargeLine: chargeLine, context: viewContext)
            
            showSuccessMessage = true
            path = NavigationPath()
            path.append(AppView.management)
            path.append(AppView.chargeLine)
        } else {
            isValid = false
            print("Invalid input")
        }
    }
}

import SwiftUI
import CoreData

struct ChargeLineView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32

    @FetchRequest(sortDescriptors: []) var cls: FetchedResults<ChargeLine>
    
    var body: some View {
        List {
            ForEach(cls) { cl in
                if let name = cl.clName, let funded = cl.clFunded, let clCap = cl.clCap {
                    let tempID: String = String(format: "%05d", cl.clID)
                    HStack {
                        Text("ID: \(tempID)\nCharge Line Name: \(name)\nFunding Amount: \(funded)\nFunding Cap: \(clCap)")
                            .padding()
                        Spacer()
                        Button("Edit") {
                            targetid = cl.clID // Set the target ID for editing
                            path.append(AppView.chargeLineEditView) // Navigate to ChargeLineEditView
                        }
                    }
                }
            }
        }
        .navigationTitle("ChargeLine View")
        .toolbar {
            Button("+") {
                path.append(AppView.addChargeLine) // Navigate to AddChargeLineView
            }
        }
    }
}

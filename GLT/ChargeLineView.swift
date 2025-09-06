import SwiftUI
import CoreData

struct ChargeLineView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ChargeLine.clID, ascending: true)]
    ) var cls: FetchedResults<ChargeLine>
    
    @State private var isLoading: Bool = false

    var body: some View {
        List {
            ForEach(cls) { cl in
                let tempID = String(format: "%05d", cl.clID)
                HStack {
                    Text("""
                        ID: \(tempID)
                        Name: \(cl.clName ?? "")
                        Funded: \(cl.clFunded?.stringValue ?? "")
                        Cap: \(cl.clCap?.stringValue ?? "")
                        """)
                        .padding()
                    Spacer()
                    Button("Edit") {
                        targetid = cl.clID
                        path.append(AppView.chargeLineEditView)
                    }
                }
            }
        }
        .navigationTitle("Charge Lines")
        .toolbar {
            Button("+") {
                path.append(AppView.addChargeLine)
            }
        }
        .onAppear {
            if !isLoading {
                isLoading = true
                GLTFunctions.getChargeLines(context: viewContext)
            }
        }
    }
}

import SwiftUI
import CoreData

public struct CL2EmpView1: View {
    @Environment(\.managedObjectContext) var managedObjectContext
    @Binding var path: NavigationPath
    @Binding var selectedChargeLineIDs: [Int32]
    @FetchRequest(entity: ChargeLine.entity(), sortDescriptors: []) var chargeLines: FetchedResults<ChargeLine>
    @State var selectedChargeLines: [Int32: Bool] = [:]

    private var selectedCount: Int {
        selectedChargeLines.values.filter { $0 }.count
    }

    public var body: some View {
        VStack {
            List {
                ForEach(chargeLines.filter { $0.clName?.isEmpty == false }, id: \.self) { cl in
                    let isSelected = selectedChargeLines[cl.clID] ?? false
                    Button(action: {
                        selectedChargeLines[cl.clID] = !isSelected
                    }) {
                        Text("\(cl.clName ?? "No Name") (ID: \(String(format: "%05d", cl.clID)))")
                            .padding()
                            .foregroundColor(.white)
                            .background(isSelected ? Color.blue : Color.gray)
                            .cornerRadius(10)
                    }
                }
            }

            Text("Total Selected: \(selectedCount)")
                .padding()
                .font(.headline)

            Button("Proceed to Employee Selection") {
                if selectedCount > 0 {
                    selectedChargeLineIDs = selectedChargeLines.filter { $0.value }.map { $0.key }
                    path = NavigationPath()
                    path.append(AppView.management)
                    path.append(AppView.cl2emp1)
                    path.append(AppView.cl2emp2)
                }
            }
            .disabled(selectedCount == 0)
        }
    }
}

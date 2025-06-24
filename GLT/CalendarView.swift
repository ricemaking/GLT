import SwiftUI
import CoreData

struct CalendarView: View {
    // Example array of days (adjust according to your actual data)
    let days: [(day: Int, weekday: String)]
    
    @Binding var chargeLines: [ChargeLine]
    var weekends: [String]
    var curID: Int32
    var month: Int16
    var year: Int16
    var context: NSManagedObjectContext

    // Provide a state for cellWidth, with a default value that may be updated dynamically.
    @State private var cellWidth: CGFloat = 110

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(days, id: \.day) { day in
                    DayView(
                        day: day,
                        month: month,
                        year: year,
                        curID: curID,
                        chargeLines: $chargeLines,
                        weekends: weekends,
                        context: context,
                        cellWidth: $cellWidth   // Pass the binding to DayView.
                    )
                }
            }
            .padding()
        }
    }
}

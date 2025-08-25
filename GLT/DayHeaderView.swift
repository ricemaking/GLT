import SwiftUI

struct DayHeaderView: View {
    var day: (day: Int, weekday: String)
    
    var body: some View {
        // Determine the header text.
        let isSunday = day.weekday.lowercased() == "sunday"
        let headerText = isSunday ? "Sunday" : "\(day.day) \(day.weekday)"
        // Use a custom color – you can replace this with your desired hex color.
        let bgColor: Color = Color(hex: "555555")
      
        ZStack(alignment: .leading) {
            // Background with blur.
            // The key here is to constrain the view’s height and then clip the blurred background,
            // so that any undesired gray “bleed” is removed.

            // Header text over the background.
            Text(headerText)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .frame(height: 40, alignment: .leading)
        }
        // Set a fixed height for the header.
        .frame(height: 40)
        // Add horizontal padding to create space between columns.
        .padding(.horizontal, 8)
    }
}

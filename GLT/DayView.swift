//
//  DayView.swift
//  GLT
//
//  Created by Player_1 on [Date].
//

import SwiftUI
import CoreData

struct DayView: View {
    var day: (day: Int, weekday: String)
    var month: Int16
    var year: Int16
    var curID: Int32
    var previouslyAssignedIDs: Set<Int32>
    @Binding var chargeLines: [ChargeLine]
    var weekends: [String]
    var context: NSManagedObjectContext
    @Binding var cellWidth: CGFloat  // Binding for the dynamic cell width

    var body: some View {
        ZStack(alignment: .top) {
            // Base background rectangle.
            Rectangle()
                .fill(weekends.contains(day.weekday) ? Color(hex: "#555555").opacity(0.8)
                                                     : Color(hex: "#555555").opacity(0.8))
                .cornerRadius(8)
                .blur(radius: 4)
            
            // Overlay colored blur.
            Rectangle()
                .fill(weekends.contains(day.weekday) ? Color(hex: "#007700").opacity(0.8)
                                                     : Color(hex: "#091c53").opacity(0.8))
                .cornerRadius(10)
                .padding(.top, 32)
                .padding(.bottom, 2)
                .blur(radius: 2)
            
            // Content area.
            VStack(spacing: 0) {
                DayHeaderView(day: day)
                    .frame(maxWidth: .infinity)
                
                VStack(alignment: .leading, spacing: 8) {
                    ForEach($chargeLines, id: \.self) { $chargeLine in
                        ChargeLineRow(
                            chargeLine: $chargeLine,
                            day: day,
                            curID: curID,
                            month: month,
                            year: year,
                            context: context,
                            previouslyAssignedIDs: previouslyAssignedIDs
                        )
                    }
                }
                .padding(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                // Update the cellWidth when charge line names are measured.
                .onPreferenceChange(ChargeLineNameWidthKey.self) { newWidth in
                    let extraPadding: CGFloat = 24  // additional padding for left/right spacing
                    let measuredWidth = newWidth + extraPadding
                    let minimumWidth: CGFloat = 150  // set this to your desired minimum cell width
                    cellWidth = max(minimumWidth, measuredWidth)
                }
            }
            .padding(0)
        }
        .frame(width: cellWidth)
        .onAppear {
            NSLog("DayView appeared for day: \(day.day) with cellWidth: \(cellWidth)")
        }
    }
}

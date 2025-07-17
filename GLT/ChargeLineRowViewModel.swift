//
//  ChargeLineRowViewModel.swift
//  GLT
//
//  Created by Player_1 on 4/10/25.
//


import Foundation
import CoreData
import SwiftUI

class ChargeLineRowViewModel: ObservableObject {
    
    // MARK: - Properties
    @Published var currentColor: UIColor = .gray
    
    private var chargeLine: ChargeLine
    private var curID: Int32
    private var month: Int16
    private var year: Int16
    private var day: Int
    private let context: NSManagedObjectContext
    
    // MARK: - Initializer
    init(chargeLine: ChargeLine,
         day: (day: Int, weekday: String),
         curID: Int32,
         month: Int16,
         year: Int16,
         context: NSManagedObjectContext) {
        self.chargeLine = chargeLine
        self.curID = curID
        self.month = month
        self.year = year
        self.day = day.day
        self.context = context
        updateCurrentColor()
    }
    
    // MARK: - Methods
    
    /// Updates the current text color based on TSCharge values.
    func updateCurrentColor() {
        if let tsCharge = fetchTSCharge() {
            if tsCharge.tempHours != nil {
                self.currentColor = UIColor.systemRed
            } else if tsCharge.hours != nil {
                self.currentColor = UIColor.systemBlue
            } else {
                self.currentColor = UIColor.gray
            }
        } else {
            self.currentColor = UIColor.gray
        }
    }
    
    /// Fetches the TSCharge record for the given charge line and day.
    func fetchTSCharge() -> TSCharge? {
        let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
        fetchRequest.predicate = NSPredicate(
            format: "employeeID == %d AND chargeID == %d AND month == %d AND year == %d AND day == %d AND ((offline == NO AND verified == YES AND denied == NO) OR (offline == YES AND verified == NO AND denied == NO)) ",
            curID, chargeLine.clID, month, year, Int16(day)
        )
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "version", ascending: false)
        ]

        do {
            let results = try context.fetch(fetchRequest)
            if let finalResults = results.first{
                print("charge: \(finalResults.chargeID), day: \(finalResults.day), tempHours: \(finalResults.tempHours ?? 0), version: \(finalResults.version ?? 0)")
            }
            return results.first
        } catch {
            print("Fetch error: \(error)")
            return nil
        }
    }
    
     /*
    func fetchTSCharge() -> TSCharge? {
        let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
        
        let basePredicate = NSPredicate(
            format: "employeeID == %d AND chargeID == %d AND month == %d AND year == %d AND day == %d",
            curID, chargeLine.clID, month, year, Int16(day)
        )

        // Allowed combinations:
        let case1 = NSPredicate(format: "offline == NO AND verified == YES AND denied == NO")
        let case2 = NSPredicate(format: "offline == YES AND verified == NO AND denied == NO")

        // Just OR them together (case1 and case3 are same, but kept here for clarity)
        let allowedPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [case1, case2])

        // Combine base and allowed logic
        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, allowedPredicate])
        
        fetchRequest.predicate = finalPredicate
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "version", ascending: false)
        ]
        
        return try? context.fetch(fetchRequest).first
    }
*/

    
    /// Computes the total hours for the charge line.
    func totalHours() -> Double {
        let request: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
        request.predicate = NSPredicate(
            format: "employeeID == %d AND chargeID == %d AND month == %d AND year == %d",
            curID, chargeLine.clID, month, year
        )
        if let tsCharges = try? context.fetch(request) {
            return tsCharges.reduce(0.0) { sum, tsCharge in
                let value = (tsCharge.tempHours?.doubleValue) ?? (tsCharge.hours?.doubleValue ?? 0)
                return sum + value
            }
        }
        return 0.0
    }
    
    /// Saves the entered hours into Core Data (as tempHours).
    func saveTempHours(newValue: String) {
        let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawDecimal = NSDecimalNumber(string: trimmed)
        if rawDecimal == NSDecimalNumber.notANumber { return }
        
        let doubleValue = rawDecimal.doubleValue
        let cappedDouble = max(0, min(doubleValue, 24))
        let cappedValue = NSDecimalNumber(value: cappedDouble)
        
        context.perform {
            if let tsCharge = self.fetchTSCharge() {
                // If the saved hours equal the new value, clear tempHours.
                if let savedHours = tsCharge.hours,
                   savedHours.compare(cappedValue) == .orderedSame {
                    tsCharge.tempHours = nil
                } else {
                    tsCharge.tempHours = cappedValue
                }
                do {
                    try self.context.save()
                } catch {
                    print("Error saving changes: \(error.localizedDescription)")
                }
            } else {
                // Create a new TSCharge if needed and the value is non-zero.
                if cappedDouble != 0.0 {
                    let newTSCharge = TSCharge(context: self.context)
                    newTSCharge.employeeID = self.curID
                    newTSCharge.chargeID = self.chargeLine.clID
                    newTSCharge.month = self.month
                    newTSCharge.year = self.year
                    newTSCharge.day = Int16(self.day)
                    newTSCharge.tempHours = cappedValue
                    newTSCharge.saved = false
                    newTSCharge.hours = 0.0
                    newTSCharge.denied = false
                    newTSCharge.verified = false//
                    newTSCharge.offline = true
                    /*
                    // Fetch the latest version for this employee/charge/day
                    let versionRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
                    versionRequest.predicate = NSPredicate(
                        format: "employeeID == %d AND chargeID == %d AND month == %d AND year == %d AND day == %d",
                        self.curID, self.chargeLine.clID, self.month, self.year, Int16(self.day)
                    )
                    versionRequest.sortDescriptors = [NSSortDescriptor(key: "version", ascending: false)]
                    versionRequest.fetchLimit = 1

                    let latest = try? self.context.fetch(versionRequest).first
                    let nextVersion = (latest?.version ?? 0) + 1
                    newTSCharge.version = nextVersion
*/
                    
                    do {
                        try self.context.save()
                    } catch {
                        print("Error saving new TSCharge: \(error.localizedDescription)")
                    }
                     
                }
            }
            DispatchQueue.main.async {
                self.updateCurrentColor()
            }
        }
    }
    
    /// Handles the Notes button press. If a TSCharge record exists, it returns that.
    /// Otherwise, it creates one and returns it.
    func handleNotesButtonPress(completion: @escaping (TSCharge?) -> Void) {
        if let tsCharge = fetchTSCharge() {
            completion(tsCharge)
        } else {
            context.performAndWait {
                let newTSCharge = TSCharge(context: context)
                newTSCharge.employeeID = curID
                newTSCharge.chargeID = chargeLine.clID
                newTSCharge.month = month
                newTSCharge.year = year
                newTSCharge.day = Int16(day)
                do {
                    try context.save()
                    completion(newTSCharge)
                } catch {
                    print("Error saving new TSCharge (notes): \(error.localizedDescription)")
                    completion(nil)
                }
            }
        }
    }
}

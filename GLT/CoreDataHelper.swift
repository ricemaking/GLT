//
//  CoreDataHelper.swift
//  GLT
//
//  Created by Player_1 on 4/10/25.
//


import CoreData

struct CoreDataHelper {
    static func fetchTSCharge(context: NSManagedObjectContext,
                              employeeID: Int32,
                              chargeID: Int32,
                              month: Int16,
                              year: Int16,
                              day: Int16? = nil) -> TSCharge? {
        let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
        var predicateString = "employeeID == %d AND chargeID == %d AND month == %d AND year == %d"
        var args: [Any] = [employeeID, chargeID, month, year]
        if let day = day {
            predicateString += " AND day == %d"
            args.append(day)
        }
        fetchRequest.predicate = NSPredicate(format: predicateString, argumentArray: args)
        return try? context.fetch(fetchRequest).first
    }
}

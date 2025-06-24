//
//  Timesheet+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 4/5/25.
//
//

import Foundation
import CoreData


extension Timesheet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Timesheet> {
        return NSFetchRequest<Timesheet>(entityName: "Timesheet")
    }

    @NSManaged public var dateCreated: Date?
    @NSManaged public var dateSubmitted: Date?
    @NSManaged public var employeeID: Int32
    @NSManaged public var enabled: Bool
    @NSManaged public var id: Int32
    @NSManaged public var month: Int16
    @NSManaged public var submitted: Bool
    @NSManaged public var version: Int16
    @NSManaged public var year: Int16
    @NSManaged public var chargeLine: NSSet?
    @NSManaged public var toEmployee: Employee?
    @NSManaged public var tsCharge: NSSet?

}

// MARK: Generated accessors for chargeLine
extension Timesheet {

    @objc(addChargeLineObject:)
    @NSManaged public func addToChargeLine(_ value: ChargeLine)

    @objc(removeChargeLineObject:)
    @NSManaged public func removeFromChargeLine(_ value: ChargeLine)

    @objc(addChargeLine:)
    @NSManaged public func addToChargeLine(_ values: NSSet)

    @objc(removeChargeLine:)
    @NSManaged public func removeFromChargeLine(_ values: NSSet)

}

// MARK: Generated accessors for tsCharge
extension Timesheet {

    @objc(addTsChargeObject:)
    @NSManaged public func addToTsCharge(_ value: TSCharge)

    @objc(removeTsChargeObject:)
    @NSManaged public func removeFromTsCharge(_ value: TSCharge)

    @objc(addTsCharge:)
    @NSManaged public func addToTsCharge(_ values: NSSet)

    @objc(removeTsCharge:)
    @NSManaged public func removeFromTsCharge(_ values: NSSet)

}

extension Timesheet : Identifiable {

}

//
//  ChargeLine+CoreDataProperties.swift
//  GLT
//
//  Created by dylan domingo on 9/3/25.
//
//

import Foundation
import CoreData


extension ChargeLine {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChargeLine> {
        return NSFetchRequest<ChargeLine>(entityName: "ChargeLine")
    }

    @NSManaged public var clCap: NSDecimalNumber?
    @NSManaged public var clDateEnd: String?
    @NSManaged public var clDateStart: String?
    @NSManaged public var clFunded: NSDecimalNumber?
    @NSManaged public var clID: Int32
    @NSManaged public var clName: String?
    @NSManaged public var employeeIDs: [Int32]?
    @NSManaged public var employee: NSSet?
    @NSManaged public var task: Task?
    @NSManaged public var timesheet: NSSet?
    @NSManaged public var tsCharge: NSSet?

}

// MARK: Generated accessors for employee
extension ChargeLine {

    @objc(addEmployeeObject:)
    @NSManaged public func addToEmployee(_ value: Employee)

    @objc(removeEmployeeObject:)
    @NSManaged public func removeFromEmployee(_ value: Employee)

    @objc(addEmployee:)
    @NSManaged public func addToEmployee(_ values: NSSet)

    @objc(removeEmployee:)
    @NSManaged public func removeFromEmployee(_ values: NSSet)

}

// MARK: Generated accessors for timesheet
extension ChargeLine {

    @objc(addTimesheetObject:)
    @NSManaged public func addToTimesheet(_ value: Timesheet)

    @objc(removeTimesheetObject:)
    @NSManaged public func removeFromTimesheet(_ value: Timesheet)

    @objc(addTimesheet:)
    @NSManaged public func addToTimesheet(_ values: NSSet)

    @objc(removeTimesheet:)
    @NSManaged public func removeFromTimesheet(_ values: NSSet)

}

// MARK: Generated accessors for tsCharge
extension ChargeLine {

    @objc(addTsChargeObject:)
    @NSManaged public func addToTsCharge(_ value: TSCharge)

    @objc(removeTsChargeObject:)
    @NSManaged public func removeFromTsCharge(_ value: TSCharge)

    @objc(addTsCharge:)
    @NSManaged public func addToTsCharge(_ values: NSSet)

    @objc(removeTsCharge:)
    @NSManaged public func removeFromTsCharge(_ values: NSSet)

}

extension ChargeLine : Identifiable {
    public var id: Int32 { clID }
}

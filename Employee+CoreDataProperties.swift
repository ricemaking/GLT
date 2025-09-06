//
//  Employee+CoreDataProperties.swift
//  GLT
//
//  Created by dylan domingo on 9/3/25.
//
//

import Foundation
import CoreData


extension Employee {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Employee> {
        return NSFetchRequest<Employee>(entityName: "Employee")
    }

    @NSManaged public var authenticated: Bool
    @NSManaged public var city: String?
    @NSManaged public var clearanceLevel: String?
    @NSManaged public var dob: String?
    @NSManaged public var email: String?
    @NSManaged public var endDate: Date?
    @NSManaged public var id: Int32
    @NSManaged public var manager_ChargeLine: Bool
    @NSManaged public var manager_HR: Bool
    @NSManaged public var manager_TimeCard: Bool
    @NSManaged public var nameFirst: String?
    @NSManaged public var nameLast: String?
    @NSManaged public var phone: String?
    @NSManaged public var startDate: Date?
    @NSManaged public var state: String?
    @NSManaged public var streetAddress: String?
    @NSManaged public var zipCode: String?
    @NSManaged public var chargeLineIDs: [Int32]?
    @NSManaged public var timesheetIDs: [Int32]?
    @NSManaged public var chargeLine: NSSet?
    @NSManaged public var timesheet: NSSet?
    @NSManaged public var tsCharge: NSSet?

}

// MARK: Generated accessors for chargeLine
extension Employee {

    @objc(addChargeLineObject:)
    @NSManaged public func addToChargeLine(_ value: ChargeLine)

    @objc(removeChargeLineObject:)
    @NSManaged public func removeFromChargeLine(_ value: ChargeLine)

    @objc(addChargeLine:)
    @NSManaged public func addToChargeLine(_ values: NSSet)

    @objc(removeChargeLine:)
    @NSManaged public func removeFromChargeLine(_ values: NSSet)

}

// MARK: Generated accessors for timesheet
extension Employee {

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
extension Employee {

    @objc(addTsChargeObject:)
    @NSManaged public func addToTsCharge(_ value: TSCharge)

    @objc(removeTsChargeObject:)
    @NSManaged public func removeFromTsCharge(_ value: TSCharge)

    @objc(addTsCharge:)
    @NSManaged public func addToTsCharge(_ values: NSSet)

    @objc(removeTsCharge:)
    @NSManaged public func removeFromTsCharge(_ values: NSSet)

}

extension Employee : Identifiable {

}

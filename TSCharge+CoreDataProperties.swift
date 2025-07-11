//
//  TSCharge+CoreDataProperties.swift
//  GLT
//
//  Created by dylan domingo on 7/10/25.
//
//

import Foundation
import CoreData


extension TSCharge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TSCharge> {
        return NSFetchRequest<TSCharge>(entityName: "TSCharge")
    }

    @NSManaged public var chargeID: Int32
    @NSManaged public var cost: Double
    @NSManaged public var date: Date?
    @NSManaged public var dateAssigned: Date?
    @NSManaged public var dateSaved: Date?
    @NSManaged public var dateUnassigned: Date?
    @NSManaged public var day: Int16
    @NSManaged public var employeeID: Int32
    @NSManaged public var hours: NSDecimalNumber?
    @NSManaged public var month: Int16
    @NSManaged public var noted: Bool
    @NSManaged public var rate: Double
    @NSManaged public var saved: Bool
    @NSManaged public var tempHours: NSDecimalNumber?
    @NSManaged public var timesheetID: Int32
    @NSManaged public var version: Int16
    @NSManaged public var workPerformed: String?
    @NSManaged public var year: Int16
    @NSManaged public var chargeLine: ChargeLine?
    @NSManaged public var employee: Employee?
    @NSManaged public var timesheet: Timesheet?
    @NSManaged public var offline: Bool


}

extension TSCharge : Identifiable {

}

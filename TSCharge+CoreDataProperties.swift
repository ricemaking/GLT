//
//  TSCharge+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 4/6/25.
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
    @NSManaged public var dateSaved: Date?
    @NSManaged public var day: Int16
    @NSManaged public var employeeID: Int32
    @NSManaged public var hours: NSDecimalNumber?
    @NSManaged public var month: Int16
    @NSManaged public var rate: Double
    @NSManaged public var saved: Bool
    @NSManaged public var tempHours: NSDecimalNumber?
    @NSManaged public var timesheetID: Int32
    @NSManaged public var version: Int16
    @NSManaged public var year: Int16
    @NSManaged public var workPerformed: String?
    @NSManaged public var noted: Bool
    @NSManaged public var chargeLine: ChargeLine?
    @NSManaged public var employee: Employee?
    @NSManaged public var timesheet: Timesheet?
    @NSManaged public var offline: Bool
    @NSManaged public var denied: Bool
    @NSManaged public var verified: Bool



}

extension TSCharge : Identifiable {

}

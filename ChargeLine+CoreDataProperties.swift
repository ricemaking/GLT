//
//  ChargeLine+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
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
    @NSManaged public var employee: NSSet?
    @NSManaged public var charge: NSSet?

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

// MARK: Generated accessors for charge
extension ChargeLine {

    @objc(addChargeObject:)
    @NSManaged public func addToCharge(_ value: TSCharge)

    @objc(removeChargeObject:)
    @NSManaged public func removeFromCharge(_ value: TSCharge)

    @objc(addCharge:)
    @NSManaged public func addToCharge(_ values: NSSet)

    @objc(removeCharge:)
    @NSManaged public func removeFromCharge(_ values: NSSet)

}

extension ChargeLine : Identifiable {

}

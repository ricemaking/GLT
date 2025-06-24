//
//  Paycheck+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Paycheck {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Paycheck> {
        return NSFetchRequest<Paycheck>(entityName: "Paycheck")
    }

    @NSManaged public var amount: Double
    @NSManaged public var date_to_payroll: Date?
    @NSManaged public var pay_period_start: String?
    @NSManaged public var pay_period_end: String?
    @NSManaged public var voided: Bool
    @NSManaged public var correction: Bool

}

extension Paycheck : Identifiable {

}

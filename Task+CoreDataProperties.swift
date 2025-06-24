//
//  Task+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Task {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Task> {
        return NSFetchRequest<Task>(entityName: "Task")
    }

    @NSManaged public var name: String?
    @NSManaged public var funding_required_total: NSDecimalNumber?
    @NSManaged public var pop_start: String?
    @NSManaged public var pop_end: String?
    @NSManaged public var funding_required_ODC: NSDecimalNumber?
    @NSManaged public var funding_remaining_total: NSDecimalNumber?
    @NSManaged public var funding_required_labor: NSDecimalNumber?
    @NSManaged public var funding_remaining_ODC: NSDecimalNumber?
    @NSManaged public var funding_remaining_labor: NSDecimalNumber?

}

extension Task : Identifiable {

}

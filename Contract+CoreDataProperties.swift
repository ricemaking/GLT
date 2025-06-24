//
//  Contract+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Contract {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Contract> {
        return NSFetchRequest<Contract>(entityName: "Contract")
    }

    @NSManaged public var name: String?
    @NSManaged public var pop_start: String?
    @NSManaged public var pop_end: String?
    @NSManaged public var funding_ceiling: Double
    @NSManaged public var funding_allocated: NSDecimalNumber?

}

extension Contract : Identifiable {

}

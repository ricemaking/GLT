//
//  Funding_Allocation+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Funding_Allocation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Funding_Allocation> {
        return NSFetchRequest<Funding_Allocation>(entityName: "Funding_Allocation")
    }

    @NSManaged public var amount: Double
    @NSManaged public var date_allocated: Date?
    @NSManaged public var allocation_reason: String?

}

extension Funding_Allocation : Identifiable {

}

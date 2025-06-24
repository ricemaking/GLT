//
//  Audit_TSCharge+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Audit_TSCharge {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Audit_TSCharge> {
        return NSFetchRequest<Audit_TSCharge>(entityName: "Audit_TSCharge")
    }


}

extension Audit_TSCharge : Identifiable {

}

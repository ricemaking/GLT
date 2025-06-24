//
//  Audit_Paycheck_Correction+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Audit_Paycheck_Correction {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Audit_Paycheck_Correction> {
        return NSFetchRequest<Audit_Paycheck_Correction>(entityName: "Audit_Paycheck_Correction")
    }


}

extension Audit_Paycheck_Correction : Identifiable {

}

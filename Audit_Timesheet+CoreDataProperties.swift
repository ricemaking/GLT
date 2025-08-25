//
//  Audit_Timesheet+CoreDataProperties.swift
//  GLT
//
//  Created by Player_1 on 3/8/25.
//
//

import Foundation
import CoreData


extension Audit_Timesheet {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Audit_Timesheet> {
        return NSFetchRequest<Audit_Timesheet>(entityName: "Audit_Timesheet")
    }


}

extension Audit_Timesheet : Identifiable {

}

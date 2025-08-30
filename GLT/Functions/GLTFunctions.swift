//
//  GLTFunctions.swift
//  NavTrack
//
//  Created by Player_1 on 1/19/25.
//

import Foundation
import CoreData
import SwiftUI
import Security


//url session functions:

class ClientCertificateAuth: NSObject, URLSessionDelegate {
    private let identity: SecIdentity
    private let certs: [SecCertificate]

    init?(p12Name: String, p12Password: String) {
        guard let path = Bundle.main.path(forResource: p12Name, ofType: "p12"),
              let p12Data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("❌ Could not find p12 file in bundle")
            return nil
        }
        
        var importResult: CFArray?
        let options: NSDictionary = [kSecImportExportPassphrase as NSString: p12Password]
        
        let status = SecPKCS12Import(p12Data as NSData, options, &importResult)
        guard status == errSecSuccess,
              let items = importResult as? [[String: Any]],
              let certArray = items[0][kSecImportItemCertChain as String] as? [SecCertificate] else {
            print("❌ Failed to import p12: \(status)")
            return nil
        }
        
        // 🔑 No optional binding here — just force cast because SecIdentity is guaranteed if key exists
        let identity = items[0][kSecImportItemIdentity as String] as! SecIdentity
        
        self.identity = identity
        self.certs = certArray
    }



    // 🔑 Handle TLS handshake and provide client cert
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            let credential = URLCredential(identity: identity, certificates: certs, persistence: .forSession)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}



/*******************************/
struct EmployeePayload: Codable {
    let id: Int
    let firstName: String
    let lastName: String
    let phone: String
    let email: String
    let dob: String

    let city: String
    let state: String
    let streetAddress: String
    let zipcode: String

    let startDate: String
    let endDate: String?

    let clearanceLevel: String
    let authenticated: Bool
    let chargeline_ids: [Int]
    let timesheet_ids: [Int]
}

struct ChargeLinePayload: Codable {
    let id: Int32
    let name: String
    let cap: Decimal
    let funded: Decimal
    let dateStart: String
    let dateEnd: String
    let employee_ids: [Int]?
}

struct TimesheetPayload: Codable{
    let id: Int
    let employeeID: Int
    let month: Int
    let year: Int
    let dateCreated: Date?
    let dateSubmitted: Date?
    let submitted: Bool
    let enabled: Bool
    let version: Int
}


public struct GLTFunctions {
    
    // Function to add a new employee
    public static func addEmployee(nameFirst: String, nameLast: String, dob: String, endDate: Date? = nil, email: String, phone: String, streetAddress: String, city: String, state: String, startDate: Date? = Date(), zipCode: String, clearanceLevel: String, context: NSManagedObjectContext){
        let newEmployee = Employee(context: context)
        let highestID = fetchHighestEmployeeID(context: context)
        let newID = highestID + 1
                
        newEmployee.id = newID
        newEmployee.nameFirst = nameFirst
        newEmployee.nameLast = nameLast
        newEmployee.email = email
        newEmployee.phone = phone
        newEmployee.streetAddress = streetAddress
        newEmployee.city = city
        newEmployee.state = state
        newEmployee.zipCode = zipCode
        newEmployee.clearanceLevel = clearanceLevel
        newEmployee.dob = dob
        newEmployee.startDate = startDate
        if endDate != nil {
            newEmployee.endDate = endDate
        }
        
        do {
            try context.save()
            print("Employee added successfully")
        } catch {
            print("Failed to save the new employee: \(error)")
            return
        }
        // Step 2: Prepare data for backend API
        //let dateFormatter = ISO8601DateFormatter()
        let simpleDateFormatter = DateFormatter()
        simpleDateFormatter.dateFormat = "yyyy-MM-dd"
        simpleDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)

                
        //let dobFormatted = dob // make sure this is already in "yyyy-MM-dd" or convert from Date

        let startDateString = startDate != nil ? simpleDateFormatter.string(from: startDate!) : ""
        let endDateString = endDate != nil ? simpleDateFormatter.string(from: endDate!) : nil


                
                // For authenticated, chargeline_ids, and timesheet_ids, fill with default values or adapt as needed
        let employeePayload = EmployeePayload(
            id: Int(newID),
            firstName: nameFirst,
            lastName: nameLast,
            phone: phone,
            email: email,
            dob: dob, // Assuming this is a string already formatted properly
                    
            city: city,
            state: state,
            streetAddress: streetAddress,
            zipcode: zipCode,
                
            startDate: startDateString,
            endDate: endDateString,
            
            clearanceLevel: clearanceLevel,
            authenticated: true, // or false depending on your logic
                    
            chargeline_ids: [],
            timesheet_ids: []
        )
        //on server:
        guard let auth = ClientCertificateAuth(p12Name: "client1", p12Password: "STEMWorks2026!") else {
            print("❌ Failed to load client certificate")
            return
        }

        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config, delegate: auth, delegateQueue: nil)

        guard let url = URL(string: "https://glt.glintlock.com/employees/") else {
            print("Invalid URL")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let jsonData = try JSONEncoder().encode(employeePayload)
            request.httpBody = jsonData
        } catch {
            print("Failed to encode employee for backend: \(error)")
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Backend POST failed: \(error)")
                return
            }
            if let data = data {
                print("Backend response: \(String(data: data, encoding: .utf8) ?? "No response body")")
            }
        }.resume()

        }
    
    // Function to add a new employee
    
    public static func addChargeLine(clName: String, clCap: NSDecimalNumber, clFunded: NSDecimalNumber, clDateStart: String, clDateEnd: String, context: NSManagedObjectContext) {
        let newCL = ChargeLine(context: context)
            
            // Auto-increment ID locally or fetch highest for Core Data purposes
            let highestID = fetchHighestCLID(context: context)
            newCL.clID = highestID + 1
            newCL.clName = clName
            newCL.clCap = clCap
            newCL.clFunded = clFunded
            newCL.clDateStart = clDateStart
            newCL.clDateEnd = clDateEnd
            
            do {
                try context.save()
                print("✅ ChargeLine saved locally")
            } catch {
                print("❌ Failed to save locally: \(error)")
            }
            
            
            let payload = ChargeLinePayload(
                id: highestID + 1,
                name: clName,
                cap: clCap as Decimal,
                funded: clFunded as Decimal,
                dateStart: clDateStart,
                dateEnd: clDateEnd,
                employee_ids: nil
            )

            
            // --- 3. Send POST request to Go backend ---
            guard let auth = ClientCertificateAuth(p12Name: "client1", p12Password: "STEMWorks2026!") else {
                print("❌ Failed to load client certificate")
                return
            }
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: auth, delegateQueue: nil)
            
            guard let url = URL(string: "https://glt.glintlock.com/chargelines") else {
                print("❌ Invalid URL")
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                request.httpBody = try JSONEncoder().encode(payload)
            } catch {
                print("❌ Failed to encode payload: \(error)")
                return
            }
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("❌ Backend POST failed: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Backend status code: \(httpResponse.statusCode)")
                }
                if let data = data {
                    print("📦 Backend response: \(String(data: data, encoding: .utf8) ?? "No response body")")
                }
            }.resume()
    }
    
    public static func addTimesheet(byID targetID: Int32, month: Int16? = nil, year: Int16? = nil, context: NSManagedObjectContext) -> Timesheet? {
        let newTS = Timesheet(context: context)
        let EMPfetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        EMPfetchRequest.predicate = NSPredicate(format: "id == %d", targetID)
        
        do {
            let employees = try context.fetch(EMPfetchRequest)
            guard let employee = employees.first else {
                print("❌ Employee not found")
                return nil
            }
            
            // Assign Timesheet values
            let highestID = fetchHighestTSID(context: context)
            newTS.id = highestID + 1
            newTS.version = 0
            newTS.enabled = true
            newTS.submitted = false
            newTS.dateCreated = Date()
            newTS.dateSubmitted = nil
            newTS.month = month ?? Int16(fetchCurMonth())
            newTS.year = year ?? Int16(fetchCurYear())
            newTS.employeeID = employee.id
            employee.addToTimesheet(newTS)
            
            try context.save()
            
            // Prepare payload for backend
            let timesheetPayload = TimesheetPayload(
                id: Int(newTS.id),
                employeeID: Int(newTS.employeeID),
                month: Int(newTS.month),
                year: Int(newTS.year),
                dateCreated: newTS.dateCreated,
                dateSubmitted: newTS.dateSubmitted,
                submitted: newTS.submitted,
                enabled: newTS.enabled,
                version: Int(newTS.version)
            )
            
            // Client certificate auth
            guard let auth = ClientCertificateAuth(p12Name: "client1", p12Password: "STEMWorks2026!") else {
                print("❌ Failed to load client certificate")
                return newTS
            }
            
            let config = URLSessionConfiguration.default
            let session = URLSession(configuration: config, delegate: auth, delegateQueue: nil)
            
            guard let url = URL(string: "https://glt.glintlock.com/timesheets/") else {
                print("Invalid URL")
                return newTS
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let encoder = JSONEncoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            encoder.dateEncodingStrategy = .formatted(dateFormatter)
            
            request.httpBody = try encoder.encode(timesheetPayload)
            
            session.dataTask(with: request) { data, response, error in
                if let error = error {
                    print("Backend POST failed: \(error)")
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    print("🌐 Backend status code: \(httpResponse.statusCode)")
                }
                if let data = data {
                    print("Backend response: \(String(data: data, encoding: .utf8) ?? "No response body")")
                }
            }.resume()
            
            return newTS
            
        } catch {
            print("❌ Failed to add timesheet: \(error)")
            return nil
        }
    }

    
    public static func addTimesheetCharge(clName: String, clCap: NSDecimalNumber, clFunded: NSDecimalNumber, clDateStart: String, clDateEnd: String, context: NSManagedObjectContext) {
        let newCL = ChargeLine(context: context)
        let highestID = fetchHighestCLID(context: context)
        newCL.clID = highestID + 1
        newCL.clName = clName
        newCL.clCap = clCap
        newCL.clFunded = clFunded
        newCL.clDateStart = clDateStart
        newCL.clDateEnd = clDateEnd
        
        do {
            try context.save()
            print("Employee added successfully")
        } catch {
            print("Failed to save the new employee: \(error)")
        }
        
    }
    
    
    
    
    //Convert Date to a string.  Date must be in dd/MM/yyyy HH:mm:ss format
    public static func convertDate2Str(inputDate: NSDate) -> String {
        let dateFormatter = DateFormatter()
        // Specify the desired date format
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss" // Example: "01/08/2025 18:30:00"
        // Convert the NSDate to a string
        let dateString = dateFormatter.string(from: inputDate as Date)
        print("Formatted Date String: \(dateString)")
        return dateString
    }
    
    //Takes input integer (ranging from 1 to 12) and returns corresponding month.
    public static func convertIntToMonth(from monthNumber: Int) -> String {
        let months = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        
        if monthNumber >= 1 && monthNumber <= 12 {
            return months[monthNumber - 1] // Subtract 1 because arrays are zero-indexed
        } else {
            return "Invalid month number"
        }
    }
    
    public static func convertStr2Date(inputString: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        // Try different formats
        let formats = ["dd/MM/yyyy HH:mm:ss", "dd/MM/yyyy"]
        for format in formats {
            dateFormatter.dateFormat = format
            if let date = dateFormatter.date(from: inputString) {
                return date // Returning Date directly
            }
        }
        print("Invalid date format")
        return nil
    }
    
    
    
    // Function to get the days in a month and weekday names
    static func dayName(year: Int, month: Int) -> [(day: Int, weekday: String)] {
        var daysAndWeekdays: [(Int, String)] = []
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE" // Full name of the day
        
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = 1
        
        if let startDate = calendar.date(from: dateComponents) {
            if let range = calendar.range(of: .day, in: .month, for: startDate) {
                for day in range {
                    dateComponents.day = day
                    if let date = calendar.date(from: dateComponents) {
                        let weekday = dateFormatter.string(from: date)
                        daysAndWeekdays.append((day, weekday))
                    }
                }
            }
        }
        return daysAndWeekdays
    }
    
    // Function to get and return the day before a date provided (useful for accurate timesheet searches)
    private static func dayBefore(_ date: Date) -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: date)!
    }
    
    // Function to get the employee's charge lines
    public static func fetchChargeLines(for employeeID: Int32, in context: NSManagedObjectContext) -> [String] {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", employeeID) // Match Employee by ID
        
        do {
            if let employee = try context.fetch(fetchRequest).first {
                if let chargeLines = employee.chargeLine as? Set<ChargeLine> {
                    return chargeLines.map { $0.clName ?? "No Name" } // Convert to array of charge line names
                }
            }
        } catch {
            print("Failed to fetch charge lines: \(error)")
        }
        return []
    }
    
    public static func fetchChargeLineIDs(for employeeID: Int32, in context: NSManagedObjectContext) -> [Int32] {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", employeeID) // Match Employee by ID
        
        do {
            if let employee = try context.fetch(fetchRequest).first {
                if let chargeLines = employee.chargeLine as? Set<ChargeLine> {
                    return chargeLines.map { $0.clID } // Convert to array of charge line ids
                }
            }
        } catch {
            print("Failed to fetch charge lines: \(error)")
        }
        return []
    }
    
    public static func fetchChargeLines(for employeeID: Int32, in context: NSManagedObjectContext) -> [ChargeLine] {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %d", employeeID) // Match Employee by ID
        
        do {
            if let employee = try context.fetch(fetchRequest).first {
                if let chargeLines = employee.chargeLine as? Set<ChargeLine> {
                    return chargeLines.map { $0 } // Convert to array of charge lines
                }
            }
        } catch {
            return []
        }
        return []
    }
    //Function to get the credential levels of the employee
    public static func fetchCredentials(requestType: String, for employeeEmail: String, in context: NSManagedObjectContext) -> Bool {
        
        if employeeEmail == "dylan@glintlock.com" {
            return true
        }
        
        // DEVELOPMENT PURPOSES (DELETE WHEN COMES TO ACTUAL CODE)
        if employeeEmail == "john.doe@gmail.com" {
            return true
        }
        //
        
        else {
            let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "email == %@", employeeEmail)
            
            do {
                if let employee = try context.fetch(fetchRequest).first {
                    if employee.email == employeeEmail {
                        if (requestType == "CLM") && (employee.manager_ChargeLine) {
                            return true
                        } else if (requestType == "HRM") && (employee.manager_HR) {
                            return true
                        } else if (requestType == "TSM") && (employee.manager_TimeCard) {
                            return true
                        }
                        else {
                            return false
                        }
                    }
                }
            } catch {
                print("Failed to fetch employee: \(error)")
                return false // Return an empty string to maintain consistent return type
            }
            
            return false // Return an empty string to maintain consistent return type
        }
    }
    
    //Function to get the current month
    public static func fetchCurMonth() -> Int {
        let currentDate = Date() // Step 1: Get the current date
        let calendar = Calendar.current // Calendar instance for the current locale
        let currentMonth = calendar.component(.month, from: currentDate) // Step 2: Extract month
        print("Current month: \(currentMonth)") // This will print the current month as an integer (1-12)
        return currentMonth
    }
    //Function to fetch the current timesheet, using an employee ID passed, the current date, and the context.  If the current timesheet does not exist, one will be created
    
    public static func fetchCurTimesheet(empID: Int32, context: NSManagedObjectContext) -> Timesheet? {
        let curDate: Date = Date()
        //let firstOfMonth: Date = GLTFunctions.firstDateOfCurrentMonth(from: curDate)!
        //let startDate = GLTFunctions.dayBefore(firstOfMonth)
        //let lastOfMonthDate = GLTFunctions.firstDateOfNextMonth(from: Date())
        let curMonth = Int16(fetchCurMonth())
        let curYear = Int16(fetchCurYear())
        var noTimesheets: Bool = false
        do {
            let timesheets = try GLTFunctions.fetchFilteredTimesheets(
                for: empID,
                sortKey: "enabled",
                ascending: true,
                //startDate: startDate,
                //endDate: lastOfMonthDate,
                startMonth: curMonth,
                startYear:curYear,
                endMonth: curMonth,
                endYear:curYear,
                context: context
            )
            let timesheet = timesheets?.first
            if timesheet == nil {
                let timesheet = GLTFunctions.addTimesheet(byID: empID, context: context)
            }
            else {
                return timesheet
            }
        }
        catch {
            return nil
            //return timesheet
        }
        return nil
    }
    
    //Function to get the current year
    public static func fetchCurYear() -> Int {
        let currentDate = Date() // Step 1: Get the current date
        let calendar = Calendar.current // Calendar instance for the current locale
        let currentYear = calendar.component(.year, from: currentDate) // Step 2: Extract month
        print("Current year: \(currentYear)") // This will print the current month as an integer (1-12)
        return currentYear
    }
    
    public static func fetchCurDay() -> Int {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: currentDate)
        print("Current day: \(currentDay)")
        return currentDay
    }
    
    
    // Function to return the first date utilized for timesheet records, based on the day before the first daye of the month of employee's hire date
    public static func fetchEMPFirstTSDate(empID: Int32, empContext: NSManagedObjectContext) -> Date? {
        // Fetch the employee's start date
        guard let empStartDate = GLTFunctions.fetchEmpStartDate(empID: empID, empContext: empContext) else {
            print("Error: Employee start date not found.")
            return nil
        }
        
        // Get the first date of the current month
        guard let firstOfMonth = GLTFunctions.firstDateOfCurrentMonth(from: empStartDate) else {
            print("Error: Unable to calculate the first date of the current month.")
            return nil
        }
        
        // Direct assignment since dayBefore(firstOfMonth) returns a non-optional Date
        let dayBeforeFirstTS = GLTFunctions.dayBefore(firstOfMonth)
        
        return dayBeforeFirstTS
    }
    
    
    // Function to get the start date of the employee
    public static func fetchEmpStartDate(empID: Int32, empContext: NSManagedObjectContext) -> Date? {
        guard let emp = GLTFunctions.fetchTarEmp(byID: empID, context: empContext) else {
            print("Error: Employee not found")
            return nil // Return nil if the employee does not exist
        }
        
        guard let empStartDate = emp.startDate else {
            print("Error: Employee start date is nil")
            return nil // Return nil if the startDate is nil
        }
        
        return empStartDate // Return the valid start date
    }
    
    
    // Function to fetch timesheets based on starting month/year - end month year, and using a sort key to sort in ascending manner (unless ascending specified as false.  By default this only returns enabled timesheets, however, it can be configured to return not enabled timesheets.
    public static func fetchFilteredTimesheets(for employeeID: Int32,
                                               sortKey: String,
                                               ascending: Bool = true,
                                               startMonth: Int16?,
                                               startYear: Int16?,
                                               endMonth: Int16? = nil,
                                               endYear: Int16? = nil,
                                               enabledOnly: Bool = true,
                                               context: NSManagedObjectContext) throws -> [Timesheet]? {
        //context: NSManagedObjectContext) throws -> [Timesheet] {
        let fetchRequest: NSFetchRequest<Timesheet> = Timesheet.fetchRequest()
        
        // Create predicates to filter timesheets
        var predicates = [NSPredicate]()
        
        // Filter by the specific employee ID
        predicates.append(NSPredicate(format: "employeeID == %@", NSNumber(value: employeeID)))
        
        // Filter by month and year (if specified)
        if let startYear = startYear {
            predicates.append(NSPredicate(format: "year >= %d", startYear))
        }
        
        if let startMonth = startMonth {
            predicates.append(NSPredicate(format: "month >= %d", startMonth))
        }
        
        let endYear = endYear ?? Int16(fetchCurYear())
        predicates.append(NSPredicate(format: "year <= %d", endYear))
        let endMonth = endMonth ?? Int16(fetchCurMonth())
        predicates.append(NSPredicate(format: "month <= %d", endMonth))
        if enabledOnly {
            predicates.append(NSPredicate(format: "enabled == %@", NSNumber(value: enabledOnly)))
        }
        // Combine all predicates with AND
        //fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.predicate = compoundPredicate
        
        // Sort by the specified key
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: sortKey, ascending: ascending)
        ]
        var TSOutput: [Timesheet] = []
        do {
            TSOutput = try context.fetch(fetchRequest)
            return TSOutput
        } catch let error as NSError {
            return nil
        }
    }
    
    
    
    
    //Function to get properly formatted current local time (per device timezone settings) UTC time using date input, otherwise, it will return the current time in local time zone formatted as desired.
    public static func fetchLocalTime(inputDate: Date?) -> String {
        // Use the provided date, or default to the current date if nil
        let dateToFormat = inputDate ?? Date()
        
        // Create a DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current // Use the current timezone of the device
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss" // Specify your preferred format
        
        // Format the date to a string
        let formattedString = dateFormatter.string(from: dateToFormat)
        return formattedString
    }
    
    
    
    // Function to get the highest charge line ID, which is useful for determining what CLID is available for newly created charge lines.
    public static func fetchHighestCLID(context: NSManagedObjectContext) -> Int32 {
        let fetchRequest: NSFetchRequest<ChargeLine> = ChargeLine.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "clID", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first?.clID ?? 0
        } catch {
            print("Failed to fetch the highest charge line ID: \(error)")
            return 0
        }
    }
    
    
    
    // Function to get the highest employee ID
    public static func fetchHighestEmployeeID(context: NSManagedObjectContext) -> Int32 {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first?.id ?? 0
        } catch {
            print("Failed to fetch the highest employee ID: \(error)")
            return 0
        }
    }
    
    // Function to get the highest TimesheetID, which is useful for determining what TSID is available for newly created Timesheets.
    public static func fetchHighestTSID(context: NSManagedObjectContext) -> Int32 {
        let fetchRequest: NSFetchRequest<Timesheet> = Timesheet.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let result = try context.fetch(fetchRequest)
            return result.first?.id ?? 0
        } catch {
            print("Failed to fetch the highest timesheet ID: \(error)")
            return 0
        }
    }
    
    //Function to return properly formatted UTC time using date input, otherwise, it will return the current time in UTC formatted as desired.
    public static func fetchUTCTime(inputDate: Date?) -> String {
        // Use the provided date, or default to the current date if nil
        let dateToFormat = inputDate ?? Date()
        
        // Create a DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC") // Set the timezone to UTC
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss" // Specify your preferred format
        
        // Format the date to a string
        let formattedString = dateFormatter.string(from: dateToFormat)
        return formattedString
    }
    
    
    
    //Function to getch the Employee entity object associated with the target id.
    public static func fetchTarEmp(byEmail targetEmail: String, context: NSManagedObjectContext) -> Employee? {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email == %@", targetEmail)
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Could not fetch employee ID using email provided \(targetEmail): \(error)")
            return nil
        }
    }
    
    //Function to getch the Employee entity object associated with the target id.
    public static func fetchTarEmp(byID targetid: Int32, context: NSManagedObjectContext) -> Employee? {
        let predicate = NSPredicate(format: "id == %d", targetid)
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.predicate = predicate
        do {
            let results = try context.fetch(fetchRequest)
            return results.first
        } catch {
            print("Could not fetch employee using ID provided \(targetid): \(error)")
            return nil
        }
    }
    
    //Function to getch the Employee entity object associated with the target id.
    public static func fetchTarEmpID(byEmail targetEmail: String, context: NSManagedObjectContext) -> Int32? {
        let fetchRequest: NSFetchRequest<Employee> = Employee.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "email ==[c] %@", targetEmail)
        do {
            let employees = try context.fetch(fetchRequest)
            let employee = employees[0]
            let employeeID = employee.id
            return employeeID
        }
        catch {
            print("Could not fetch employee ID using email provided \(targetEmail): \(error)")
            //return Int32(606060)
            return Int32(696969)
        }
    }
    
    
    //Function to getch a specific TSCharge entity object associated with the timesheet id, month, year, and day
    public static func fetchTarTSCharge(byEmployeeID empID: Int32, year: Int16, month: Int16, day: Int16, clID: Int32, context: NSManagedObjectContext) -> TSCharge? {
        let fetchRequest: NSFetchRequest<TSCharge> = TSCharge.fetchRequest() // Define fetch request
        var predicates = [NSPredicate]()
        
        // Build predicates for filtering
        predicates.append(NSPredicate(format: "employeeID == %d", empID))
        predicates.append(NSPredicate(format: "chargeID == %d", clID))
        predicates.append(NSPredicate(format: "month == %d", month))
        predicates.append(NSPredicate(format: "year == %d", year))
        predicates.append(NSPredicate(format: "day == %d", day))
        
        // Combine all predicates with AND
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.predicate = compoundPredicate
        
        var version: Int16 = 0
        var recentCharge: TSCharge?
        
        do {
            // Fetch TSCharges using the context
            let TSCharges = try context.fetch(fetchRequest)
            if TSCharges.isEmpty {
                NSLog("No TSCharge found for employeeID: %d, chargeID: %d, month: %d, year: %d, day: %d", empID, clID, month, year, day)
                return nil // Return nil if no results
            }
            
            // Iterate through fetched TSCharges and find the most recent version
            for charge in TSCharges {
                if charge.version > version {
                    version = charge.version
                    recentCharge = charge
                }
            }
            return recentCharge // Return the most recent TSCharge
        } catch let error as NSError {
            NSLog("Error fetching TSCharge: %@", error.localizedDescription)
            return nil
        } catch {
            NSLog("Unknown error occurred while fetching TSCharge.")
            return nil
        }
    }
    
    //Function responsible for fetching the timesheet of the target employee
    
    
    public static func firstDateOfCurrentMonth(from date: Date) -> Date? {
        let calendar = Calendar.current
        // Extract the year and month components
        let components = calendar.dateComponents([.year, .month], from: date)
        
        // Create a new date with day set to 1 (the first day of the month)
        var startOfMonthComponents = DateComponents()
        startOfMonthComponents.year = components.year
        startOfMonthComponents.month = components.month
        startOfMonthComponents.day = 1
        
        return calendar.date(from: startOfMonthComponents)
    }
    
    
    
    public static func firstDateOfNextMonth(from date: Date) -> Date? {
        let calendar = Calendar.current
        // Get the current year and month components
        let components = calendar.dateComponents([.year, .month], from: date)
        
        if let currentMonth = components.month, let currentYear = components.year {
            let nextMonth: Int
            let nextYear: Int
            
            // Determine the next month and year
            if currentMonth == 12 {
                nextMonth = 1
                nextYear = currentYear + 1
            } else {
                nextMonth = currentMonth + 1
                nextYear = currentYear
            }
            
            // Create a date for the first day of the next month
            var nextMonthComponents = DateComponents()
            nextMonthComponents.year = nextYear
            nextMonthComponents.month = nextMonth
            nextMonthComponents.day = 1
            
            return calendar.date(from: nextMonthComponents)
        }
        
        return nil
    }
    
    //takes integer representation of month and returns corresponding month name.
    func monthName(from int: Int) -> String? {
        guard int >= 1 && int <= 12 else { return nil } // Ensure valid month
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        
        var dateComponents = DateComponents()
        dateComponents.month = int
        
        let calendar = Calendar.current
        if let date = calendar.date(from: dateComponents) {
            return dateFormatter.string(from: date)
        }
        return nil
    }
    
    //Function to get the number of dats in current month
    public static func numberOfDaysInCurrentMonth() -> Int {
        let calendar = Calendar.current
        let date = Date()
        
        if let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        } else {
            return 0
        }
        
    }
    
    // Function to transform a date string into a specific format
    public static func transformDateString(_ dateString: String) -> String? {
        let separators = ["-", "/", ".", "\\"]
        
        // Check for formats with separators
        for separator in separators {
            let components = dateString.split(separator: Character(separator))
            if components.count == 3,
               components[2].count == 4, components[1].count == 2, components[0].count == 2 {
                let day = components[0]
                let month = components[1]
                let year = components[2]
                return "\(day)/\(month)/\(year)"
            }
        }
        
        // Check for "ddmmyyyy" format without separators
        if dateString.count == 8,
           let _ = Int(dateString.prefix(2)), // Check dd
           let _ = Int(dateString.dropFirst(2).prefix(2)), // Check mm
           let _ = Int(dateString.dropFirst(4)) { // Check yyyy
            let day = dateString.prefix(2)
            let month = dateString.dropFirst(2).prefix(2)
            let year = dateString.dropFirst(4)
            return "\(day)/\(month)/\(year)"
        }
        
        return nil
    }
    
    // Function to validate date input format
    public static func validDateInput(_ dateString: String) -> Bool {
        let separators = ["-", "/", ".", "\\"]
        
        // Check for formats with separators
        for separator in separators {
            let components = dateString.split(separator: Character(separator))
            if components.count == 3,
               components[2].count == 4, components[1].count == 2, components[0].count == 2 {
                return true
            }
        }
        
        // Check for "ddmmyyyy" format without separators
        if dateString.count == 8,
           let _ = Int(dateString.prefix(2)), // Check dd
           let _ = Int(dateString.dropFirst(2).prefix(2)), // Check mm
           let _ = Int(dateString.dropFirst(4)) { // Check yyyy
            return true
        }
        
        return false
    }
    
    public static func validateDecimalInput(_ input: String) -> Bool {
        return Decimal(string: input) != nil
    }
    // Function to validate input
    public static func validateInput(_ input: String) -> Bool {
        return Int16(input) != nil
    }
    
    public static func assignTSChargeAssignmentDates(
        employeeID: Int32,
        year: Int16,
        month: Int16,
        day: Int16,
        clID: Int32,
        dateAssigned: Date?,
        dateUnassigned: Date?,
        context: NSManagedObjectContext
    ) {
        if let tsCharge = fetchTarTSCharge(
            byEmployeeID: employeeID,
            year: year,
            month: month,
            day: day,
            clID: clID,
            context: context
        ) {
            tsCharge.dateAssigned = dateAssigned
            tsCharge.dateUnassigned = dateUnassigned
        }
        do {
            try context.save()
            print(dateAssigned, dateUnassigned)
            NSLog("Successfully assigned assignment date to TSCharge: %d, under employee %d", clID, employeeID)
        }
        catch {
            print(dateAssigned, dateUnassigned)
            NSLog("Error occured trying to assign assignment date to TSCharge: %d, under employee %d", clID, employeeID)
        }
    }
    
    public static func fetchAssignedOrHasHoursChargeLines(
        for employeeID: Int32,
        month: Int16,
        year: Int16,
        context: NSManagedObjectContext
    ) -> [ChargeLine] {
        let tsFetch: NSFetchRequest<TSCharge> = TSCharge.fetchRequest()
        tsFetch.predicate = NSPredicate(format: "employeeID == %d AND month == %d AND year == %d", employeeID, month, year)
        
        do {
            let tsCharges = try context.fetch(tsFetch)
            
            let relevantCLIDs = tsCharges.compactMap { tsCharge -> Int32? in
                if tsCharge.dateAssigned != nil ||
                    (tsCharge.hours?.doubleValue ?? 0) > 0 ||
                    (tsCharge.tempHours?.doubleValue ?? 0) > 0 {
                    return tsCharge.chargeID
                }
                return nil
            }
            
            guard !relevantCLIDs.isEmpty else { return [] }
            
            let clFetch: NSFetchRequest<ChargeLine> = ChargeLine.fetchRequest()
            clFetch.predicate = NSPredicate(format: "clID IN %@", relevantCLIDs)
            
            return try context.fetch(clFetch)
        } catch {
            print("Error fetching relevant ChargeLines: \(error)")
            return []
        }
    }
}

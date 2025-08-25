import SwiftUI
import CoreData

struct EmployeeEditView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32
    
    // Employee Fields
    @State private var nameFirst: String = ""
    @State private var nameLast: String = ""
    @State private var dob: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var streetAddress: String = ""
    @State private var zipCode: String = ""
    @State private var city: String = ""
    @State private var stateText: String = ""
    @State private var clearanceLevel: String = "Not Cleared"
    @State private var startDateString: String = ""
    @State private var endDateString: String = ""
    
    @State private var isValid: Bool = true
    @State private var showSuccessMessage: Bool = false
    @State private var employee: Employee?
    
    // Manager Role State – using your entity property names
    @State private var manager_HR: Bool = false
    @State private var manager_TimeCard: Bool = false
    @State private var manager_ChargeLine: Bool = false
    @State private var hrBGColor: Color = Color(hex: "110000")
    @State private var hrFGColor: Color = Color(hex: "444444")
    @State private var tcBGColor: Color = Color(hex: "110000")
    @State private var tcFGColor: Color = Color(hex: "444444")
    @State private var clBGColor: Color = Color(hex: "110000")
    @State private var clFGColor: Color = Color(hex: "444444")
    
    var clearanceLevels = ["SCI", "TS", "Secret", "Interim Secret", "Not Cleared"]
    
    // Date Formatter for "MM/dd/yyyy"
    private var mmddyyyyFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MM/dd/yyyy"
        f.isLenient = false
        return f
    }
    
    // FocusState for phone formatting
    @FocusState private var phoneFieldIsFocused: Bool
    
    // MARK: - Computed Validation Properties
    
    private var isNameValid: Bool {
        !nameFirst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nameLast.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var isDOBValid: Bool {
        let trimmed = dob.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 10 && mmddyyyyFormatter.date(from: trimmed) != nil
    }
    
    private var isStartDateValid: Bool {
        let trimmed = startDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count == 10 && mmddyyyyFormatter.date(from: trimmed) != nil
    }
    
    private var isEndDateValid: Bool {
        let trimmed = endDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        return trimmed.count == 10 && mmddyyyyFormatter.date(from: trimmed) != nil
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // MARK: Employee Data Fields
                Group {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("First Name")
                            TextField("Enter First Name", text: $nameFirst)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        VStack(alignment: .leading) {
                            Text("Last Name")
                            TextField("Enter Last Name", text: $nameLast)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            Text("Date of Birth (MM/dd/yyyy)")
                            if !isDOBValid {
                                Text("❌").foregroundColor(.red)
                            }
                        }
                        TextField("Enter DOB", text: $dob)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Email")
                        TextField("Enter Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Phone")
                        TextField("Enter Phone", text: $phone)
                            .focused($phoneFieldIsFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                            .onChange(of: phoneFieldIsFocused) { focused, _ in
                                if !focused {
                                    phone = formatPhoneNumber(phone)
                                }
                            }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Street Address")
                        TextField("Enter Street Address", text: $streetAddress)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("City")
                            TextField("Enter City", text: $city)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        VStack(alignment: .leading) {
                            Text("State")
                            TextField("Enter State", text: $stateText)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Zip Code")
                        // Replace with your custom ZipCodeTextField if needed.
                        TextField("Enter Zip Code", text: $zipCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            Text("Start Date (MM/dd/yyyy)")
                            if !isStartDateValid {
                                Text("❌").foregroundColor(.red)
                            }
                        }
                        TextField("Enter Start Date", text: $startDateString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack(spacing: 5) {
                            Text("End Date (MM/dd/yyyy, optional)")
                            if !isEndDateValid {
                                Text("❌").foregroundColor(.red)
                            }
                        }
                        TextField("Enter End Date", text: $endDateString)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                    }
                }
                
                // MARK: Manager Role Section
                VStack {
                    HStack {
                        // HR Manager Button (using property manager_HR)
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(hrBGColor)
                                .blur(radius: 2)
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black)
                                .frame(width: 175, height: 40)
                                .blur(radius: 1)
                            Button(action: {
                                hrBGColor = manager_HR ? Color(hex: "110000") : Color(hex: "FF0000")
                                hrFGColor = manager_HR ? Color(hex: "444444") : Color(hex: "AA0000")
                                manager_HR.toggle()
                            }) {
                                Text("HR Manager")
                                    .fontDesign(.monospaced)
                                    .font(.system(size: 16))
                                    .textCase(.uppercase)
                                    .foregroundColor(hrFGColor)
                                    .bold()
                            }
                            .background(Color.clear)
                        }
                        .frame(width: 180, height: 45)
                        .padding()
                        
                        // Timecard Manager Button (using property manager_TimeCard)
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(tcBGColor)
                                .blur(radius: 2)
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black)
                                .frame(width: 175, height: 40)
                                .blur(radius: 1)
                            Button(action: {
                                tcBGColor = manager_TimeCard ? Color(hex: "110000") : Color(hex: "FF0000")
                                tcFGColor = manager_TimeCard ? Color(hex: "444444") : Color(hex: "AA0000")
                                manager_TimeCard.toggle()
                            }) {
                                Text("Timecard Manager")
                                    .fontDesign(.monospaced)
                                    .font(.system(size: 16))
                                    .textCase(.uppercase)
                                    .foregroundColor(tcFGColor)
                                    .bold()
                            }
                            .background(Color.clear)
                        }
                        .frame(width: 180, height: 45)
                        .padding()
                    }
                    
                    // Charge Line Manager Button (using property manager_ChargeLine)
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(clBGColor)
                            .blur(radius: 2)
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.black)
                            .frame(width: 175, height: 40)
                            .blur(radius: 0)
                        Button(action: {
                            clBGColor = manager_ChargeLine ? Color(hex: "110000") : Color(hex: "FF0000")
                            clFGColor = manager_ChargeLine ? Color(hex: "444444") : Color(hex: "AA0000")
                            manager_ChargeLine.toggle()
                        }) {
                            Text("Charge Line Manager")
                                .fontDesign(.monospaced)
                                .font(.system(size: 16))
                                .textCase(.uppercase)
                                .foregroundColor(clFGColor)
                                .bold()
                        }
                        .background(Color.clear)
                    }
                    .frame(width: 180, height: 45)
                    .padding()
                }
                
                // MARK: Clearance Level Picker & Save Button
                VStack {
                    Picker("Clearance Level", selection: $clearanceLevel) {
                        ForEach(clearanceLevels, id: \.self) { level in
                            Text(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    Button(action: handleEditEmployee) {
                        Text("Save Changes")
                    }
                    .padding()
                    .disabled(!isValid)
                    
                    if !isValid {
                        Text("Please enter a valid name, DOB, and start date.")
                            .foregroundColor(.red)
                    }
                    if showSuccessMessage {
                        Text("Employee updated successfully!")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
            }
            .padding()
            .onAppear {
                fetchEmployeeData()
                phone = formatPhoneNumber(phone)
            }
            .gesture(DragGesture().onChanged { _ in UIApplication.shared.endEditing() })
        }
    }
    
    // MARK: - Helper Functions
    
    private func fetchEmployeeData() {
        let request: NSFetchRequest<Employee> = Employee.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", targetid)
        do {
            let employees = try viewContext.fetch(request)
            if let emp = employees.first {
                employee = emp
                nameFirst = emp.nameFirst ?? ""
                nameLast = emp.nameLast ?? ""
                dob = emp.dob ?? ""
                email = emp.email ?? ""
                phone = emp.phone ?? ""
                streetAddress = emp.streetAddress ?? ""
                zipCode = emp.zipCode ?? ""
                city = emp.city ?? ""
                stateText = emp.state ?? ""
                clearanceLevel = emp.clearanceLevel ?? "Not Cleared"
                startDateString = emp.startDate != nil ? mmddyyyyFormatter.string(from: emp.startDate!) : ""
                endDateString = emp.endDate != nil ? mmddyyyyFormatter.string(from: emp.endDate!) : ""
                
                // Retrieve manager role flags from the employee.
                manager_HR = emp.manager_HR
                manager_TimeCard = emp.manager_TimeCard
                manager_ChargeLine = emp.manager_ChargeLine
                
                // Set manager button colors accordingly.
                hrBGColor = manager_HR ? Color(hex: "FF0000") : Color(hex: "110000")
                hrFGColor = manager_HR ? Color(hex: "AA0000") : Color(hex: "444444")
                tcBGColor = manager_TimeCard ? Color(hex: "FF0000") : Color(hex: "110000")
                tcFGColor = manager_TimeCard ? Color(hex: "AA0000") : Color(hex: "444444")
                clBGColor = manager_ChargeLine ? Color(hex: "FF0000") : Color(hex: "110000")
                clFGColor = manager_ChargeLine ? Color(hex: "AA0000") : Color(hex: "444444")
            }
        } catch {
            print("Failed to fetch employee: \(error)")
        }
    }
    
    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard digits.count >= 10 else { return input }
        let firstTen = String(digits.prefix(10))
        let areaCode = firstTen.prefix(3)
        let centralOffice = firstTen.dropFirst(3).prefix(3)
        let lineNumber = firstTen.dropFirst(6)
        return "(\(areaCode)) \(centralOffice)-\(lineNumber)"
    }
    
    private func handleEditEmployee() {
        let trimmedDOB = dob.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStartDate = startDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isNameValid,
              !trimmedDOB.isEmpty,
              let parsedDOB = mmddyyyyFormatter.date(from: trimmedDOB),
              !trimmedStartDate.isEmpty,
              let parsedStartDate = mmddyyyyFormatter.date(from: trimmedStartDate)
        else {
            isValid = false
            return
        }
        isValid = true
        let parsedEndDate: Date? = endDateString.isEmpty ? nil : mmddyyyyFormatter.date(from: endDateString)
        
        if let emp = employee {
            emp.nameFirst = nameFirst
            emp.nameLast = nameLast
            emp.dob = trimmedDOB
            emp.email = email
            emp.phone = phone
            emp.streetAddress = streetAddress
            emp.zipCode = zipCode
            emp.city = city
            emp.state = stateText
            emp.clearanceLevel = clearanceLevel
            emp.startDate = parsedStartDate
            emp.endDate = parsedEndDate
            
            // Save updated manager role flags.
            emp.manager_HR = manager_HR
            emp.manager_TimeCard = manager_TimeCard
            emp.manager_ChargeLine = manager_ChargeLine
            
            do {
                try viewContext.save()
                showSuccessMessage = true
                path = NavigationPath()  // Optionally reset navigation.
            } catch {
                print("Failed to save employee changes: \(error)")
            }
        }
    }
}

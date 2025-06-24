import SwiftUI
import CoreData

struct AddEmployeeView: View {
    // MARK: - Environment and Bindings
    @Environment(\.managedObjectContext) var viewContext
    
    @Binding var path: NavigationPath
    @Binding var manager_HR: Bool
    @Binding var manager_TimeCard: Bool
    @Binding var manager_ChargeLine: Bool
    @Binding var hrBGColor: Color
    @Binding var hrFGColor: Color
    @Binding var tcBGColor: Color
    @Binding var tcFGColor: Color
    @Binding var clBGColor: Color
    @Binding var clFGColor: Color

    // MARK: - Local State Variables
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
    
    // Date fields stored as strings (expecting MM/dd/yyyy format)
    @State private var startDateString: String = ""
    @State private var endDateString: String = ""
    
    @State private var isValid: Bool = true
    @State private var showSuccessMessage: Bool = false
    
    // Picker Options for Clearance Level
    var clearanceLevels = ["SCI", "TS", "Secret", "Interim Secret", "Not Cleared"]
    
    // Focus state for phone field to trigger formatting on focus loss.
    @FocusState private var phoneFieldIsFocused: Bool
    // Add a new FocusState property at the top of your view along with phoneFieldIsFocused.
    @FocusState private var zipCodeFieldIsFocused: Bool

    
    // MARK: - Date Formatter (MM/dd/yyyy)
    private var mmddyyyyFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        formatter.isLenient = false // Strict matching.
        return formatter
    }
    
    // MARK: - Helper Functions
    
    /// Formats a phone number to the (XXX) XXX-XXXX style using the first 10 digits.
    private func formatPhoneNumber(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        guard digits.count >= 10 else { return input }
        let firstTen = String(digits.prefix(10))
        let areaCode = firstTen.prefix(3)
        let centralOffice = firstTen.dropFirst(3).prefix(3)
        let lineNumber = firstTen.dropFirst(6)
        return "(\(areaCode)) \(centralOffice)-\(lineNumber)"
    }
    
    // MARK: - Computed Properties for Validation
    
    /// Both first and last names must be non‑empty.
    private var isNameValid: Bool {
        !nameFirst.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !nameLast.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// DOB must be exactly 10 characters and parse as a date.
    private var isDOBValid: Bool {
        let trimmed = dob.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 10 else { return false }
        return mmddyyyyFormatter.date(from: trimmed) != nil
    }
    
    /// Start date must be exactly 10 characters and parse as a date.
    private var isStartDateValid: Bool {
        let trimmed = startDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 10 else { return false }
        return mmddyyyyFormatter.date(from: trimmed) != nil
    }
    
    /// End date is optional; if non‑empty, it must be exactly 10 characters and parse.
    private var isEndDateValid: Bool {
        let trimmed = endDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        guard trimmed.count == 10 else { return false }
        return mmddyyyyFormatter.date(from: trimmed) != nil
    }
    
    /// Zip code is valid if it consists of exactly 5 digits or exactly 9 digits (or already formatted as "12345-6789").
    private var isZipCodeValid: Bool {
        let trimmed = zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("-") {
            let parts = trimmed.split(separator: "-")
            return parts.count == 2 &&
                   parts[0].count == 5 &&
                   parts[1].count == 4 &&
                   parts.allSatisfy { $0.allSatisfy { $0.isNumber } }
        } else {
            let digits = trimmed.filter { $0.isNumber }
            return digits.count == 5 || digits.count == 9
        }
    }
    
    /// Phone is valid if it contains exactly 10 digits.
    private var isPhoneValid: Bool {
        let digits = phone.filter { $0.isNumber }
        return digits.count == 10
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 15) {
                // MARK: Employee Input Fields
                
                // Name Fields
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
                
                // DOB Field with error emoji indication
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text("Date of Birth (mm/dd/yyyy)")
                        if !isDOBValid {
                            Text("❌").foregroundColor(.red)
                        }
                    }
                    CustomDateTextField(
                        text: $dob,
                        placeholder: "mm/dd/yyyy",
                        keyboardType: .numberPad
                    )
                }
                
                // Email Field
                VStack(alignment: .leading) {
                    Text("Email")
                    TextField("Enter Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                }
                
                // Phone Field with FocusState formatting
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text("Phone")
                        if !isPhoneValid {
                            Text("❌").foregroundColor(.red)
                        }
                    }
                    TextField("Enter Phone", text: $phone)
                        .focused($phoneFieldIsFocused)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.phonePad)
                        .onChange(of: phoneFieldIsFocused) { focused in
                            if !focused {
                                phone = formatPhoneNumber(phone)
                            }
                        }
                }
                
                // Street Address Field
                VStack(alignment: .leading) {
                    Text("Street Address")
                    TextField("Enter Street Address", text: $streetAddress)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                // City and State Fields
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
                
                // Zip Code Field with auto-hyphenation
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text("Zip Code")
                        if !isZipCodeValid {
                            Text("❌")
                                .foregroundColor(.red)
                        }
                    }
                    ZipCodeTextField(text: $zipCode)
                }



                
                // Start Date Field
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text("Start Date (mm/dd/yyyy)")
                        if !isStartDateValid {
                            Text("❌").foregroundColor(.red)
                        }
                    }
                    CustomDateTextField(
                        text: $startDateString,
                        placeholder: "mm/dd/yyyy",
                        keyboardType: .numberPad
                    )
                    .frame(height: 40)
                }
                
                // End Date Field (optional)
                VStack(alignment: .leading) {
                    HStack(spacing: 5) {
                        Text("End Date (mm/dd/yyyy, optional)")
                        if !isEndDateValid {
                            Text("❌").foregroundColor(.red)
                        }
                    }
                    CustomDateTextField(
                        text: $endDateString,
                        placeholder: "mm/dd/yyyy",
                        keyboardType: .numberPad
                    )
                    .frame(height: 40)
                }
                
                // MARK: Manager Role Buttons
                VStack {
                    HStack {
                        // HR Manager Button
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
                        
                        // Timecard Manager Button
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
                    // Charge Line Manager Button
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
                
                // MARK: Clearance Level Picker & Add Employee Button
                VStack {
                    Picker("Clearance Level", selection: $clearanceLevel) {
                        ForEach(clearanceLevels, id: \.self) { level in
                            Text(level)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    
                    Button(action: addEmployee) {
                        Text("Add Employee")
                    }
                    .padding()
                    .disabled(!isValid)
                    
                    if !isValid {
                        Text("Please enter a valid name, DOB, and start date.")
                            .foregroundColor(.red)
                    }
                    if showSuccessMessage {
                        Text("Employee added successfully!")
                            .foregroundColor(.green)
                            .padding()
                    }
                }
                .padding()
            }
            .padding()
            .onAppear {
                // Format phone on load.
                phone = formatPhoneNumber(phone)
            }
            .gesture(DragGesture().onChanged { _ in
                UIApplication.shared.endEditing()
            })
        }
    }
    
    // MARK: - Add Employee Function
    private func addEmployee() {
        // Trim the date fields before validation.
        let trimmedDOB = dob.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedStartDate = startDateString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate required fields: name, DOB, and start date.
        guard isNameValid,
              !trimmedDOB.isEmpty,
              let _ = mmddyyyyFormatter.date(from: trimmedDOB),
              !trimmedStartDate.isEmpty,
              let parsedStartDate = mmddyyyyFormatter.date(from: trimmedStartDate)
        else {
            isValid = false
            return
        }
        isValid = true
        let parsedEndDate: Date? = endDateString.isEmpty ? nil : mmddyyyyFormatter.date(from: endDateString)
        
        // Here you can call your data layer to add the employee.
        // For example, using GLTFunctions.addEmployee if desired or directly inserting into Core Data.
        // In this version, we'll assume GLTFunctions.addEmployee is available.
        
        // For the date of birth, if you have a transformation function, you can call it:
        let transformedDOB = GLTFunctions.transformDateString(dob) ?? "00/00/0000"
        
        GLTFunctions.addEmployee(
            nameFirst: nameFirst,
            nameLast: nameLast,
            dob: transformedDOB,
            endDate: parsedEndDate,
            email: email,
            phone: phone,
            streetAddress: streetAddress,
            city: city,
            state: stateText,
            startDate: parsedStartDate,
            zipCode: zipCode,
            clearanceLevel: clearanceLevel,
            context: viewContext
        )
        
        // Update navigation and display a success message.
        path = NavigationPath()
        path.append(AppView.management)
        path.append(AppView.employee)
        showSuccessMessage = true
    }
    
    // MARK: - Input Validation
    private func validateInput() -> Bool {
        guard GLTFunctions.validDateInput(dob),
              !nameFirst.isEmpty,
              !nameLast.isEmpty,
              mmddyyyyFormatter.date(from: startDateString) != nil
        else {
            return false
        }
        if !endDateString.isEmpty, mmddyyyyFormatter.date(from: endDateString) == nil {
            return false
        }
        return true
    }
    
    private func formatZipCode() {
        let digits = zipCode.filter { $0.isNumber }
        if digits.count >= 9 {
            // Take only the first 9 digits.
            let validDigits = String(digits.prefix(9))
            let formatted = String(validDigits.prefix(5)) + "-" + String(validDigits.suffix(4))
            if formatted != zipCode {
                DispatchQueue.main.async {
                    zipCode = formatted
                }
            }
        }
    }

}

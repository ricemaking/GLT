import SwiftUI
import CoreData
import Foundation
import MSAL
import os.log

// Define an enum for your views
enum AppView: Hashable {
    case employee
    case management
    case randomnameFirst
    case employeeEditView
    case addEmployee
    case chargeLine
    case addChargeLine
    case chargeLineEditView
    case emp2cl1
    case emp2cl2
    case empDetail
    case timesheet
    case timesheetList
    case loginView
    //case cl2emp1
    //case cl2emp2
}

// Random nameFirst View
struct RandomnameFirstView: View {
    var body: some View {
        Text("This is Random nameFirst View.")
            .navigationTitle("Random nameFirst")
    }
}

struct ContentView: View
{
    @Environment(\.managedObjectContext) var viewContext
    @Binding var previousRunTimestamp: Date?
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var curEmployee: Int32?
    @State private var curTimesheet: Timesheet?
    @State private var manager_HR: Bool = false
    @State private var manager_TimeCard: Bool = false
    @State private var manager_ChargeLine: Bool = false
    @State private var hrBGColor: Color = Color(hex: "110000")
    @State private var hrFGColor: Color = Color(hex: "444444")
    @State private var tcBGColor: Color = Color(hex: "110000")
    @State private var tcFGColor: Color = Color(hex: "444444")
    @State private var clBGColor: Color = Color(hex: "110000")
    @State private var clFGColor: Color = Color(hex: "444444")
    @State private var shouldPromptForAccount: Bool = false
    @State private var offlineLogin: Bool = false // offlineLogin switch
    @State private var activeLogin: Bool = false
    @State private var path = NavigationPath()
    @State private var targetid: Int32 = 0
    @State private var targetids: [Int32] = []
    @State private var timesheet: Timesheet?
    @State var selectedEmployeeIDs: [Int32] = []
    @State var loginID: String? = "" // This is the email address input by the user at sign on, which should be utilized to identify the current employee and associated management level.
    @State private var accessToken: String = ""
    @State private var jwtPayloadString: String = ""
    @State private var extractedValue: String = ""
    @State private var revokeRequest: Bool = false
    @State private var message: String? = ""




    @FetchRequest(
        sortDescriptors: []
    ) var employees: FetchedResults<Employee>
    
    
    var body: some View
    {
        NavigationStack(path: $path)
        {
            VStack {
                
                if let message = message, !message.isEmpty {
                    Text(message)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                if let login = loginID, !login.isEmpty, activeLogin {
                    Text("Welcome: \(login)")
                }
                    
                HStack {
                    Spacer()
                    Button("\nTimesheet     \n") {
                        if !activeLogin {
                            message = "Not logged in"
                        }
                        else {
                            message = ""
                            path = NavigationPath()
                            path.append(AppView.timesheet)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    Spacer()
                    Button("\nManagement\n") {
                        path = NavigationPath()
                        path.append(AppView.management)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Spacer()
                }
                Button("TS List")
                {
                    if !activeLogin {
                        message = "Not logged in"
                    }
                    else {
                        message = ""
                        path = NavigationPath()
                        path.append(AppView.timesheetList)
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Load SharePoint Contents") {
                    // Use appropriate methods to fetch data
                    AuthenticationManager.shared.fetchSiteId(accessToken: authManager.accessToken ?? "")
                    AuthenticationManager.shared.fetchDriveId(accessToken: authManager.accessToken ?? "")
                    AuthenticationManager.shared.listAllDrives(accessToken: authManager.accessToken ?? "")
                    AuthenticationManager.shared.fetchSharePointContents()
                    os_log("Load SharePoint Contents button clicked.", log: OSLog.default, type: .debug)
                }
                Text("SITE ID is: \(authManager.siteID ?? "No result yet")")
                ScrollView{
                    VStack{
                        Text("siteID is \(authManager.siteID ?? "No result yet")")
                        Text("driveID is \(authManager.driveID ?? "No result yet")")
                        
                        Text(authManager.fileAccessResultOD ?? "No result yet")
                        
                        Label("One Drive Files", systemImage: "folder")
                        List(authManager.directoryContentsOD, id: \.self) {
                            Text($0)
                        }
                        Text(authManager.fileAccessResultShared ?? "No result yet")
                        Label("Shared Files", systemImage: "folder")
                        List(authManager.directoryContentsShared, id: \.self) {
                            Text($0)
                        }
                        Text(authManager.fileAccessResultSP ?? "No result yet")
                        Label("Sharepoint Files", systemImage: "folder")
                        List(authManager.directoryContentsSharepoint, id: \.self) {
                            Text($0)
                        }
                        Text(authManager.fileAccessResultDrives ?? "No result yet")
                        Label("All Drives", systemImage: "folder")
                        List(authManager.directoryContentsAll, id: \.self) { driveName in
                            Text(driveName)
                        }
                        .onAppear {
                            authManager.listAllDrives(accessToken: authManager.accessToken ?? "")
                        }
                    }
                }
                Spacer()
                if offlineLogin && !activeLogin {
                    TextField("Enter your email", text: Binding(
                        get: { loginID ?? "" },
                        set: { loginID = $0 }
                    ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                }
            }
            .preferredColorScheme(.dark)
            .navigationDestination(for: AppView.self) { value in
                switch value {
                case .employee:
                    EmployeeView(path: $path, targetid: $targetid)
                case .management:
                    ManagementView(path: $path, targetid: $targetid, loginID: $loginID)
                case .randomnameFirst:
                    RandomnameFirstView()
                case .employeeEditView:
                    EmployeeEditView(path: $path, targetid: $targetid)
                case .addEmployee:
                    AddEmployeeView(path: $path, manager_HR: $manager_HR, manager_TimeCard: $manager_TimeCard, manager_ChargeLine: $manager_ChargeLine, hrBGColor: $hrBGColor, hrFGColor: $hrFGColor, tcBGColor: $tcBGColor, tcFGColor: $tcFGColor, clBGColor: $clBGColor, clFGColor: $clFGColor)
                case .addChargeLine:
                    AddChargeLineView(path: $path)
                case .chargeLine:
                    ChargeLineView(path: $path, targetid: $targetid)
                case .chargeLineEditView:
                    ChargeLineEditView(path: $path, targetid: $targetid)
                case .emp2cl1:
                    Emp2CLView1(path: $path, selectedEmployeeIDs: $selectedEmployeeIDs)
                case .emp2cl2:
                    Emp2CLView2(path: $path, selectedEmployeeIDs: $selectedEmployeeIDs)
                case .empDetail:
                    EmployeeDetailsView(path: $path, targetid: $targetid)
                case .timesheet:
                    TimesheetView(path: $path, loginID: $loginID, curTimesheet: $curTimesheet, targetid: $targetid, timesheet: $timesheet, previousRunTimestamp: $previousRunTimestamp)
                case .timesheetList:
                    TimesheetListView(path: $path, curEmployee: $targetid, curTimesheet: $curTimesheet, loginID: $loginID)
                case .loginView:
                    LoginView(path: $path, loginID: $loginID, activeLogin: $activeLogin, jwtPayloadString: $jwtPayloadString, extractedValue: $extractedValue, shouldPromptForAccount: $shouldPromptForAccount)
                }
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    if activeLogin {
                        HStack {
                            Button("Sign Out") {
                                if !offlineLogin {
                                    AuthenticationManager.shared.signOut(revokeRequest: revokeRequest) { success, error in
                                        if success {
                                            accessToken = ""
                                            activeLogin = false
                                            loginID = ""
                                        }
                                    }
                                    path = NavigationPath()
                                }
                                else {
                                    loginID = ""
                                    activeLogin = false
                                }
                            }
                            .fontDesign(.monospaced)
                            .font(.system(size: 18))
                            .textCase(.uppercase)
                            .bold()
                            .foregroundColor(Color(hex: "FF0000"))
                            Toggle("Revoke Token", isOn: $revokeRequest)
                                .fontDesign(.monospaced)
                                .font(.system(size: 18))
                                .textCase(.uppercase)
                                .bold()
                                //.foregroundColor(Color(hex: "FF0000"))
                        }
                    }
                    else
                    {
                        VStack {
                            HStack
                            {
                                Button("Sign In") {
                                // modify this block
                                    if !offlineLogin {
                                        AuthenticationManager.shared.signIn(shouldPromptForAccount: shouldPromptForAccount, revokeRequest: revokeRequest)
                                        { success, error in
                                            if success
                                            {
                                                AuthenticationManager.shared.acquireTokenSilently
                                                { token, silentError in
                                                    if let token = token
                                                    {
                                                        accessToken = token
                                                        jwtPayloadString = AuthenticationManager.shared.extractJWTPayloadString(from: token) ?? "Unknown jwtPayloadString"
                                                        loginID = AuthenticationManager.shared.extractValue(from: jwtPayloadString, using: "\"unique_name\"\\s*:\\s*\"([^\"]*)\"") ?? "Unknown"
                                                        activeLogin = true
                                                        revokeRequest = false
                                                        AuthenticationManager.shared.checkOneDriveAccess(accessToken: token) { accessSuccess, accessError in
                                                            DispatchQueue.main.async {
                                                                if accessSuccess {
                                                                    authManager.fileAccessResultOD = "Access to OneDrive granted."
                                                                    AuthenticationManager.shared.fetchDirectoryContents(accessToken: token)
                                                                    AuthenticationManager.shared.fetchSharedItems(accessToken: token)
                                                                    
                                                                } else {
                                                                    authManager.fileAccessResult = accessError ?? "Access to OneDrive failed."
                                                                }
                                                            }
                                                        }
                                                    }
                                                    else
                                                    {
                                                        authManager.activeLogin = false
                                                        authManager.fileAccessResult = "Silent token acquisition failed."
                                                    }
                                                }
                                            }
                                            else
                                            {
                                                activeLogin = false
                                                // include code here to prmopt for offline login
                                                
                                                //
                                            }
                                        }
                                    }
                                    else {
                                        print(loginID)
                                        // run function to query database for email... if email found then:
                                        activeLogin = true
                                    }
                                }
                                Toggle("Account Selection Prompt", isOn: $shouldPromptForAccount)
                                    .fontDesign(.monospaced)
                                    .font(.system(size: 18))
                                    .textCase(.uppercase)
                                    .bold()
                            }
                            .fontDesign(.monospaced)
                            .font(.system(size: 18))
                            .textCase(.uppercase)
                            .bold()
                            .foregroundColor(Color(hex: "FF6600"))
                            
                            HStack {
                                Toggle("Offline Login", isOn: $offlineLogin)
                                    .fontDesign(.monospaced)
                                    .font(.system(size: 18))
                                    .textCase(.uppercase)
                                    .bold()
                            }
                            .fontDesign(.monospaced)
                            .font(.system(size: 18))
                            .textCase(.uppercase)
                            .bold()
                            .foregroundColor(Color(hex: "FF6600"))
                        }
                    }
                }
            }
        }
        .onAppear {
            print("Total employees: \(employees.count)")
            for employee in employees {
                print(employee.email ?? "No email")
            }
            
            AuthenticationManager.shared.acquireTokenSilently { token, silentError in
                if let token = token {
                    accessToken = token
                    jwtPayloadString = AuthenticationManager.shared.extractJWTPayloadString(from: token) ?? "Unkown jwtPayloadString in LoginView"
                    loginID = AuthenticationManager.shared.extractValue(from: jwtPayloadString, using: "\"unique_name\"\\s*:\\s*\"([^\"]*)\"") ?? "Unknown Login ID"
                    activeLogin = true
                    print(loginID)
                    //extractedValue = "HELLOWWWWWW"
                }
                else
                {
                    activeLogin = false
                }
            }
        }
    }
}



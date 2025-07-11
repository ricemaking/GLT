//
//  ManagementView.swift
//  NavTrack
//
//  Created by Player_1 on 1/19/25.
//

import SwiftUI
import CoreData

// Management View
struct ManagementView: View {
    @Environment(\.managedObjectContext) var viewContext
    @Binding var path: NavigationPath
    @Binding var targetid: Int32
    @Binding var loginID: String?
    @State var showAlert: String = ""
    var body: some View {
        VStack {
            Text("\(showAlert)")
                .foregroundColor(.red)
            HStack {
                Button("\nEmployee \nManagement\n") {
                    let credCheck = GLTFunctions.fetchCredentials(requestType: "HRM", for: loginID!, in: viewContext)
                    if credCheck {
                        showAlert = ""
                        path = NavigationPath()
                        path.append(AppView.management)
                        path.append(AppView.employee)
                    } else {
                        showAlert = "Brah, you fo real?  \nYou no have access to Dakine hea - K! 🤙🏽"
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                Button("\nCharge Line \nManagement\n") {
                    let credCheck = GLTFunctions.fetchCredentials(requestType: "CLM", for: loginID!, in: viewContext)
                    if credCheck {
                        showAlert = ""
                        path = NavigationPath()
                        path.append(AppView.management)
                        path.append(AppView.chargeLine)
                    } else {
                        showAlert = "Brah, you fo real?  \nYou no have access to Dakine hea - K! 🤙🏽"
                    }

                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            HStack {
                Button("\nAssign Employees \nto \nCharge Line \n") {
                    let credCheck = GLTFunctions.fetchCredentials(requestType: "CLM", for: loginID!, in: viewContext)
                    if credCheck {
                        showAlert = ""
                        path = NavigationPath()
                        path.append(AppView.management)
                        path.append(AppView.emp2cl1)
                    } else {
                        showAlert = "Brah, you fo real?  \nYou no have access to Dakine hea - K! 🤙🏽"
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                Button("\nAssign Charge Lines \nto \nEmployee \n") {
                    let credCheck = GLTFunctions.fetchCredentials(requestType: "CLM", for: loginID!, in: viewContext)
                    if credCheck {
                        showAlert = ""
                        path = NavigationPath()
                        path.append(AppView.management)
                    } else {
                        showAlert = "Brah, you fo real?  \nYou no have access to Dakine hea - K! 🤙🏽"
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            HStack {
                Button("View Employee\nTimesheets") {
                    let credCheck = GLTFunctions.fetchCredentials(requestType: "TSM", for: loginID!, in: viewContext)
                    if credCheck {
                        showAlert = ""
                        path = NavigationPath()
                        path.append(AppView.management)
                        path.append(AppView.manageEmpTimesheet)
                    } else {
                        showAlert = "Brah, you fo real?  \nYou no have access to Dakine hea - K! 🤙🏽"
                    }
                }
                .buttonStyle(BorderedProminentButtonStyle())
                .padding()
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
            Spacer()
        }
    }
}

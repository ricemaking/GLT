import SwiftUI
import JWTDecode

struct LoginView: View {
    @Binding var path: NavigationPath
    @Binding var loginID: String?
    @Binding var activeLogin: Bool
    @Binding var jwtPayloadString: String
    @Binding var extractedValue: String
    @Binding var shouldPromptForAccount: Bool  // State to track prompt behavior
    @State var groups: String?
    @State var email: String?
    @State private var accessToken: String? = nil
    @State private var userName: String? = nil // Track user name
    @State private var errorMessage: String? = nil
    @State private var isAuthenticating = false
    @State private var debugStatus: String = ""  // Debug status text
    
    
    var body: some View {
        VStack {
            if isAuthenticating {
                ProgressView("Signing In... 🦸")
                    .padding()
            }
            else if accessToken == nil {
                VStack {
                    if let errorMessage = errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                    Toggle("Prompt for Account Selection", isOn: $shouldPromptForAccount)
                        .padding()
                    Button("Sign In with Office 365") {
                        errorMessage = nil
                        isAuthenticating = true
                        debugStatus = "Signing in... 🚀"
                        AuthenticationManager.shared.signIn(shouldPromptForAccount: shouldPromptForAccount) { success, error in
                            isAuthenticating = false
                            if success {
                                AuthenticationManager.shared.acquireTokenSilently { token, silentError in
                                    if let token = token {
                                        debugStatus = "Signed in successfully 🦄"
                                        accessToken = token
                                        //if let idToken = AuthenticationManager.shared.extractUserName(from: token) {
                                        //  userName = idToken
                                        // Usage example
                                        jwtPayloadString = AuthenticationManager.shared.extractJWTPayloadString(from: token) ?? "Unknown jwtPayloadString in LoginView"
                                        loginID = AuthenticationManager.shared.extractValue(from: jwtPayloadString, using: "\"unique_name\"\\s*:\\s*\"([^\"]*)\"") ?? "Unknown"
                                        activeLogin = true
                                    }
                                    else
                                    {
                                        errorMessage = silentError ?? "Unable to retrieve token 🫠"
                                        
                                    }
                                }
                            } else {
                                errorMessage = error ?? "Sign-in failed. Check your network connection and credential settings 🫠. Ensure Tenant ID and Client ID are correctly set up."
                                debugStatus = "Sign-in failed. No prompt received."
                            }
                        }
                    }
                    .padding()
                    .disabled(isAuthenticating)
                }
            }
            else {
                VStack {
                    ScrollView{
                        Text("Welcome: \(loginID)")
                            .padding()
                            .foregroundColor(.green)
                    }
                    ScrollView{
                        Text("Welcome: \(jwtPayloadString)")
                            .padding()
                            .foregroundColor(.green)
                    }
                    Text("Groups: \(groups ?? "Unknown")")
                        .padding()
                        .foregroundColor(.green)
                    HStack {
                        Button("Sign Out") {
                            AuthenticationManager.shared.signOut(revokeRequest: false) { success, error in
                                if success {
                                    accessToken = nil
                                    debugStatus = "Signed out successfully. 🔓"
                                    activeLogin = false
                                    loginID = ""
                                } else {
                                    errorMessage = error ?? "Sign-out failed. Please try again."
                                    debugStatus = "Sign-out failed. 📛"
                                }
                            }
                        }
                        .padding()
                        
                        Button("Main Menu") {
                            path = NavigationPath()
                            debugStatus = "Navigating to main menu. 📋"
                        }
                        .padding()
                    }
                }
                Text("\(debugStatus)")
                    .padding()
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .onAppear {
            AuthenticationManager.shared.acquireTokenSilently { token, silentError in
                if let token = token {
                    debugStatus = "Token still valid234: \(token)"
                    accessToken = token
                    jwtPayloadString = AuthenticationManager.shared.extractJWTPayloadString(from: token) ?? "Unkown jwtPayloadString in LoginView"
                    loginID = AuthenticationManager.shared.extractValue(from: jwtPayloadString, using: "\"unique_name\"\\s*:\\s*\"([^\"]*)\"") ?? "Unknown Login ID"
                    activeLogin = true
                    //extractedValue = "HELLOWWWWWW"
                    
                    
                } else {
                    debugStatus = "Token invalid, needs re-authentication."
                    errorMessage = silentError ?? "No valid token found. Please sign in again."
                    activeLogin = false
                    
                }
            }
        }
    }
}


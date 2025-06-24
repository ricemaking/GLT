
import MSAL
import JWTDecode
import SwiftUI
import os.log

@MainActor class AuthenticationManager: ObservableObject { // Conform to ObservableObject
    static let shared = AuthenticationManager() // Singleton instance
    @Published var accessToken: String? // Published properties to notify changes
    @Published var jwtPayloadString: String = ""
    @Published var loginID: String = ""
    @Published var activeLogin: Bool = false
    @Published var fileAccessResult: String?
    @Published var fileAccessResultOD: String?
    @Published var fileAccessResultShared: String?
    @Published var fileAccessResultSP: String?
    @Published var fileAccessResultDrives: String?
    @Published var directoryContentsOD: [String] = [] // Hold directory contents
    @Published var directoryContentsShared: [String] = [] // Hold directory contents
    @Published var directoryContentsSharepoint: [String] = [] // Hold directory contents
    @Published var directoryContentsAll: [String] = [] // Added this property
    @Published var siteID: String = ""
    @Published var driveID: String = ""
    @StateObject private var authManager = AuthenticationManager.shared


    private var applicationContext: MSALPublicClientApplication?

    private init() {
        do {
            let authorityUrl = URL(string: "https://login.microsoftonline.us/c7e6c7ae-cbff-4271-91d6-23cec911e0f4")!
            let authority = try MSALB2CAuthority(url: authorityUrl)
            let redirectUri = "msauth.com.GLT://auth"

            let pcaConfig = MSALPublicClientApplicationConfig(clientId: "81fb914d-95d9-43ec-90d7-82479f4a8fb8", redirectUri: redirectUri, authority: authority)
            self.applicationContext = try MSALPublicClientApplication(configuration: pcaConfig)


            print("MSAL Public Client Application created successfully")
        } catch let initError {
            print("Failed to create MSALPublicClientApplication: \(initError.localizedDescription)")
        }
    }
    
    // Existing methods like signIn, revokeTokens, signOut, acquireTokenSilently, etc.

    
    func revokeTokens(for account: MSALAccount, completion: @escaping (Bool, Error?) -> Void) {
        guard let applicationContext = applicationContext else {
            completion(false, NSError(domain: "MSAL", code: 0, userInfo: [NSLocalizedDescriptionKey: "Application context is nil"]))
            return
        }

        do {
            try applicationContext.remove(account)

            // Tokens revoked successfully
            completion(true, nil)
        } catch let error {
            completion(false, error)
        }
    }
    
    // Updated method implementation
    func fetchDirectoryContents(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.us/v1.0/me/drive/root/children")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.fileAccessResultOD = "Failed to fetch directory contents: \(error?.localizedDescription ?? "Unknown error")."
                }
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let valueArray = jsonResponse["value"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.directoryContentsOD = valueArray.compactMap { driveItem in
                            if let name = driveItem["name"] as? String {
                                if let remoteItem = driveItem["remoteItem"] as? [String: Any], let remoteName = remoteItem["name"] as? String {
                                    // This is a shortcut to a SharePoint doc library
                                    return "\(name) (shortcut to \(remoteName))"
                                }
                                return name
                            }
                            return nil
                        }
                        self.fileAccessResultOD = "Directory contents fetched successfully."
                    }
                }
            } catch let parseError {
                DispatchQueue.main.async {
                    self.fileAccessResultOD = "JSON Parsing Error: \(parseError.localizedDescription)"
                }
            }
        }
        task.resume()
    }

    func fetchSharedItems(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.us/v1.0/me/drive/sharedWithMe")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.fileAccessResultShared = "Failed to fetch shared items: \(error?.localizedDescription ?? "Unknown error")."
                }
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let valueArray = jsonResponse["value"] as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.directoryContentsShared = valueArray.compactMap { driveItem in
                            if let name = driveItem["name"] as? String {
                                return name
                            }
                            return nil
                        }
                        self.fileAccessResultShared = "Shared items fetched successfully."
                    }
                }
            } catch let parseError {
                DispatchQueue.main.async {
                    self.fileAccessResultShared = "JSON Parsing Error: \(parseError.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    
    



    func fetchSharePointContents() {
        guard let accessToken = self.accessToken else {
            DispatchQueue.main.async {
                self.fileAccessResultSP = "Authentication details missing: Access token is nil."
            }
            return
        }

        let siteId = "{b60a4154-838c-440b-901f-2631fb21e28c}"
        let driveId = "OneDrive"

        if siteId.isEmpty || driveId.isEmpty {
            DispatchQueue.main.async {
                self.fileAccessResultSP = "Authentication details missing: siteId or driveId is empty."
            }
            return
        } else {
            DispatchQueue.main.async {
                self.fileAccessResultSP = "Using Site ID: \(siteId), Drive ID: \(driveId)"
            }

            guard let url = URL(string: "https://graph.microsoft.us/v1.0/sites/\(siteId)/drives/\(driveId)/root/children") else {
                DispatchQueue.main.async {
                    self.fileAccessResultSP = "Invalid URL."
                }
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

            let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else { return }

                if let error = error {
                    DispatchQueue.main.async {
                        self.fileAccessResultSP = "Network request failed: \(error.localizedDescription)"
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    DispatchQueue.main.async {
                        self.fileAccessResultSP = "HTTP Error: \(response?.description ?? "Unknown error")"
                    }
                    return
                }

                guard let data = data else {
                    DispatchQueue.main.async {
                        self.fileAccessResultSP = "Data is nil"
                    }
                    return
                }

                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let valueArray = jsonResponse["value"] as? [[String: Any]] {
                        DispatchQueue.main.async {
                            self.directoryContentsSharepoint = valueArray.compactMap { driveItem in
                                if let name = driveItem["name"] as? String {
                                    if let remoteItem = driveItem["remoteItem"] as? [String: Any],
                                       let remoteName = remoteItem["name"] as? String {
                                        return "\(name) (shortcut to \(remoteName))"
                                    }
                                    return name
                                }
                                return nil
                            }
                            self.fileAccessResultSP = "Directory contents fetched successfully."
                        }
                    }
                } catch let parseError {
                    DispatchQueue.main.async {
                        self.fileAccessResultSP = "JSON Parsing Error: \(parseError.localizedDescription)"
                    }
                }
            }
            task.resume()
        }
    }


    func fetchSiteId(accessToken: String) {
        let siteName = "GLT" // Replace this with your actual site name if different
        guard let url = URL(string: "https://graph.microsoft.us/v1.0/sites/glintlock.sharepoint.us/:u:/s/GLT/EbZkMp-_2HVNrcgJ8QZoSDwB2gqwhIP2fkBojeIxtyVcUA?e=r0712d") else {
            // Handle invalid URL error
            DispatchQueue.main.async {
                self.fileAccessResult = "Invalid URL for fetching site ID."
            }
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.fileAccessResult = "Failed to fetch site ID: \(error?.localizedDescription ?? "Unknown error")."
                }
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let siteResults = jsonResponse["value"] as? [[String: Any]] {
                    for site in siteResults {
                        if let name = site["name"] as? String, let siteId = site["id"] as? String {
                            if name == siteName {
                                DispatchQueue.main.async {
                                    self.siteID = siteId
                                    self.fileAccessResult = "Fetched Site ID successfully: \(siteId)"
                                }
                                return
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        self.fileAccessResult = "Site ID not found for the site name \(siteName)."
                    }
                } else {
                    DispatchQueue.main.async {
                        self.fileAccessResult = "Unexpected JSON structure."
                    }
                }
            } catch let parseError {
                DispatchQueue.main.async {
                    self.fileAccessResult = "JSON Parsing Error: \(parseError.localizedDescription)"
                }
            }
        }
        task.resume()
    }


    func fetchDriveId(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.us/v1.0/sites/\(self.siteID)/drives")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    self.fileAccessResult = "Failed to fetch drive ID: \(error?.localizedDescription ?? "Unknown error")."
                }
                return
            }
            do {
                if let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let valueArray = jsonResponse["value"] as? [[String: Any]] {
                    for drive in valueArray {
                        if let name = drive["name"] as? String, name == "Documents - GLT",
                           let driveId = drive["id"] as? String {
                            DispatchQueue.main.async {
                                self.driveID = driveId
                            }
                            return
                        }
                    }
                    DispatchQueue.main.async {
                        self.fileAccessResult = "Drive ID not found in the response."
                    }
                } else {
                    DispatchQueue.main.async {
                        self.fileAccessResult = "Unexpected response format."
                    }
                }
            } catch let parseError {
                DispatchQueue.main.async {
                    self.fileAccessResult = "JSON Parsing Error: \(parseError.localizedDescription)"
                }
            }
        }
        task.resume()
    }
    
    

       
    
    func listAllDrives(accessToken: String) {
        let url = URL(string: "https://graph.microsoft.us/v1.0/me/drives")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.fileAccessResultDrives = "Failed to fetch drives: \(error.localizedDescription)"
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    self.fileAccessResultDrives = "No data received from server."
                }
                return
            }

            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                if let jsonResponse = jsonResponse {
                    DispatchQueue.main.async {
                        self.fileAccessResultDrives = "Parsed JSON successfully: \(jsonResponse)"
                        
                        if let valueArray = jsonResponse["value"] as? [[String: Any]] {
                            self.directoryContentsAll = valueArray.compactMap { drive in
                                if let name = drive["name"] as? String {
                                    return name
                                }
                                return nil
                            }
                            self.fileAccessResultDrives = "Drives fetched successfully."
                        } else {
                            self.fileAccessResultDrives = "Value key exists but its contents are not in expected format."
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.fileAccessResultDrives = "Failed to parse JSON structure."
                    }
                }
            } catch let parseError {
                DispatchQueue.main.async {
                    self.fileAccessResultDrives = "JSON Parsing Error: \(parseError.localizedDescription)"
                }
            }
        }
        task.resume()
    }



    func signOut(revokeRequest: Bool, completion: @escaping (Bool, String?) -> Void) {
        guard let applicationContext = applicationContext else {
            completion(false, "Application context is nil.")
            return
        }
        do {
            let accounts = try applicationContext.allAccounts()
            if let firstAccount = accounts.first {
                if revokeRequest {
                    revokeTokens(for: firstAccount) { success, error in
                        if success {
                            print("Tokens revoked successfully")
                            completion(true, "Tokens revoked successfully")
                        } else {
                            completion(false, error?.localizedDescription ?? "Failed to revoke tokens")
                        }
                    }
                }
                else {
                    try applicationContext.remove(firstAccount)
                    print("Signed out successfully")
                    completion(true, "Signed out successfully")
                }
            } else {
                completion(false, "No accounts signed in.")
            }
        } catch let error {
            completion(false, "Failed to sign out: \(error.localizedDescription)")
        }
    }



    func signIn(shouldPromptForAccount: Bool = true, revokeRequest: Bool = false, completion: @escaping (Bool, String?) -> Void) {
        guard let applicationContext = applicationContext else {
            completion(false, "Application context is nil.")
            return
        }

        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        guard let presentationViewController = keyWindow?.rootViewController else {
            completion(false, "No root view controller found.")
            return
        }

        let webviewParameters = MSALWebviewParameters(authPresentationViewController: presentationViewController)
        webviewParameters.webviewType = .authenticationSession
        let scopes = ["User.Read", "files.readwrite"] // Add required scopes for OneDrive
        let parameters = MSALInteractiveTokenParameters(scopes: scopes, webviewParameters: webviewParameters)

        if (shouldPromptForAccount == true) || (revokeRequest == true) {
            parameters.promptType = .login  // Force prompt every time
        }
        applicationContext.acquireToken(with: parameters) { (result, error) in
            if let error = error {
                let nsError = error as NSError
                self.accessToken = nil
                let errorMessage = "Could not acquire token: \(error.localizedDescription). User info: \(nsError.userInfo)"
                completion(false, errorMessage)
                return
            }

            guard let result = result else {
                completion(false, "Could not acquire token: result is nil.")
                return
            }
            print("Token acquired: \(result.accessToken)")
            self.accessToken = result.accessToken
            print("ID Token acquired: \(result.idToken ?? "None")")
            completion(true, nil)
        }
    }



    func acquireTokenSilently(completion: @escaping (String?, String?) -> Void) {
        guard let applicationContext = applicationContext else {
            completion(nil, "Application context is nil.")
            return
        }

        let scopes = ["User.Read", "files.readwrite"] // Add required scopes
        do {
            let accounts = try applicationContext.allAccounts()
            if let account = accounts.first {
                let silentParamaters = MSALSilentTokenParameters(scopes: scopes, account: account)
                applicationContext.acquireTokenSilent(with: silentParamaters) { (result, error) in
                    if let result = result {
                        print("ID Token acquired silently: \(result.idToken ?? "None")")
                        completion(result.accessToken, nil)
                    } else {
                        if let error = error as NSError? {
                            let errorMessage = "Silent token acquisition failed: \(error.localizedDescription). User info: \(error.userInfo)"

                            completion(nil, errorMessage)
                        } else {
                            completion(nil, "Silent token acquisition failed: An unknown error occurred.")
                        }
                    }
                }
            } else {
                completion(nil, "No accounts found.")
            }
        } catch {
            completion(nil, "Failed to get accounts: \(error.localizedDescription)")
        }
    }
    
    func checkOneDriveAccess(accessToken: String, completion: @escaping (Bool, String?) -> Void) {
        let url = URL(string: "https://graph.microsoft.com/v1.0/me/drive/root/children")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                completion(false, "No data or error: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            do {
                let jsonResponse = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                print("OneDrive Access Response: \(jsonResponse)")
                completion(true, nil) // Access successful
            } catch let parseError {
                completion(false, "JSON Parsing Error: \(parseError.localizedDescription)")
            }
        }
        task.resume()
    }

    
    func extractUserName(from idToken: String) -> String? {
        do {
            let jwt = try decode(jwt: idToken)
            return jwt.claim(name: "name").string
        } catch {
            print("Failed to decode ID token: \(error)")
            return nil
        }
    }
    
    func extractJWTClaim(inputClaim: String, from idToken: String) -> String? {
        do {
            let token = try decode(jwt: idToken)
            let claimValue = token.claim(name: inputClaim).string
            return claimValue
        } catch {
            print("Failed to decode ID token: \(error)")
            return nil
        }
    }

    func extractValue(from string: String, using pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let nsString = string as NSString
            let results = regex.matches(in: string, options: [], range: NSRange(location: 0, length: nsString.length))
            
            if let match = results.first {
                return nsString.substring(with: match.range(at: 1))
            }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
        }
        return nil
    }

    func extractJWTPayloadString(from idToken: String) -> String? {
        do {
            let token = try decode(jwt: idToken)
            if let payloadData = try? JSONSerialization.data(withJSONObject: token.body, options: .prettyPrinted),
               let payloadString = String(data: payloadData, encoding: .utf8) {
                return payloadString
            } else {
                print("Failed to convert JWT payload to string")
                return nil
            }
        } catch {
            print("Failed to decode ID token: \(error)")
            return nil
        }
    }
    
}

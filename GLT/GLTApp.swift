//
//  GLTApp.swift
//  GLT
//
//  Created by Player_1 on 1/14/25.
//

import SwiftUI

@main
struct GLTApp: App {
    let persistenceController = PersistenceController.shared
    @State private var previousRunTimestamp: Date?

    var body: some Scene
    {
        WindowGroup
        {
            ContentView(previousRunTimestamp: $previousRunTimestamp)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    // Retrieve the previously stored timestamp
                    if let lastRun = UserDefaults.standard.object(forKey: "lastRunTimestamp") as? Date {
                        previousRunTimestamp = lastRun
                    }
                    // Save the current timestamp as the new "last run" timestamp
                    UserDefaults.standard.set(Date(), forKey: "lastRunTimestamp")
                }
        }
    }
}

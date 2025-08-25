import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        let newPerson = Employee(context: viewContext)
        let newCL = ChargeLine(context: viewContext)
        //newPerson.nameFirst = "Bob" // Set required property
        //newPerson.dob = Date() // Set required property
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "GLT")
        if inMemory {
            if let description = container.persistentStoreDescriptions.first {
                description.url = URL(fileURLWithPath: "/dev/null")
            } else {
                print("Persistent store description is missing")
            }
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let _ = error as NSError? {
                print("An error occurred")
            }

        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let appBundle = Bundle(for: JournalEntry.self)
        let modelURL = appBundle.url(forResource: "Nola", withExtension: "momd")
            ?? Bundle.main.url(forResource: "Nola", withExtension: "momd")

        guard let modelURL,
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Could not load Nola.momd from the app bundle.")
        }
        guard model.entitiesByName["JournalEntry"] != nil else {
            fatalError("Nola.momd loaded, but it does not contain the JournalEntry entity.")
        }

        container = NSPersistentContainer(name: "Nola", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

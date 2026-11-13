import Combine
import CoreData

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container: NSPersistentContainer
    @Published private(set) var isStoreReady = false
    @Published private(set) var startupError: String?

    init(inMemory: Bool = false) {
        let appBundle = Bundle(for: JournalEntry.self)
        let modelURL = appBundle.url(forResource: "Nola", withExtension: "momd")
            ?? Bundle.main.url(forResource: "Nola", withExtension: "momd")

        let model: NSManagedObjectModel
        let modelError: String?
        if let modelURL,
           let loadedModel = NSManagedObjectModel(contentsOf: modelURL),
           loadedModel.entitiesByName["JournalEntry"] != nil {
            model = loadedModel
            modelError = nil
        } else {
            model = NSManagedObjectModel()
            modelError = "Nola could not load a Core Data model containing JournalEntry. The journal store was not opened."
        }

        container = NSPersistentContainer(name: "Nola", managedObjectModel: model)
        if let modelError = modelError {
            startupError = modelError
            return
        }

        if let storeDescription = container.persistentStoreDescriptions.first {
            if inMemory {
                storeDescription.url = URL(fileURLWithPath: "/dev/null")
            } else {
                // The previous builds could create an empty store. Infer a
                // lightweight migration when the corrected model is installed.
                storeDescription.shouldMigrateStoreAutomatically = true
                storeDescription.shouldInferMappingModelAutomatically = true
            }
        }

        container.loadPersistentStores { [weak self] _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.startupError = "Nola could not open its local journal store: \(error.localizedDescription)"
                    return
                }
                self?.isStoreReady = true
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func save() throws {
        let context = container.viewContext
        guard context.hasChanges else { return }
        try context.save()
    }
}


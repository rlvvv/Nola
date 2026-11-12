import XCTest
import CoreData
@testable import Nola

class CoreDataTests: XCTestCase {

    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        persistenceController = PersistenceController(inMemory: true)
        context = persistenceController.container.viewContext
    }

    override func tearDownWithError() throws {
        persistenceController = nil
        context = nil
        try super.tearDownWithError()
    }

    func testContainerInitializes() throws {
        XCTAssertNotNil(persistenceController.container)
        XCTAssertNotNil(context)
    }

    func testCreateAndFetchJournalEntry() throws {
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.title = "Test Entry"
        entry.content = "This is a test entry."
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.entryType = "daily"

        persistenceController.save()

        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        let entries = try context.fetch(request)

        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries.first?.title, "Test Entry")
        XCTAssertEqual(entries.first?.content, "This is a test entry.")
    }

    func testDeleteJournalEntry() throws {
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.title = "To Delete"
        entry.content = "Will be deleted."
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.entryType = "daily"

        persistenceController.save()

        var request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        var entries = try context.fetch(request)
        XCTAssertEqual(entries.count, 1)

        context.delete(entries[0])
        persistenceController.save()

        entries = try context.fetch(request)
        XCTAssertEqual(entries.count, 0)
    }

    func testEntryDefaults() throws {
        let entry = JournalEntry(context: context)
        entry.id = UUID()
        entry.title = nil
        entry.content = "No title"
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.entryType = "brain_dump"

        persistenceController.save()

        XCTAssertEqual(entry.safeTitle, "Untitled")
        XCTAssertEqual(entry.safeEntryType, "brain_dump")
    }
}
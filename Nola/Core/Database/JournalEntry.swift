import Foundation
import CoreData

@objc(JournalEntry)
public class JournalEntry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntry> {
        return NSFetchRequest<JournalEntry>(entityName: "JournalEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var entryType: String?
}

extension JournalEntry: Identifiable {
    public var safeId: UUID { id ?? UUID() }
    public var safeTitle: String { title ?? "Untitled" }
    public var safeContent: String { content ?? "" }
    public var safeCreatedAt: Date { createdAt ?? Date() }
    public var safeUpdatedAt: Date { updatedAt ?? Date() }
    public var safeEntryType: String { entryType ?? "daily" }
}
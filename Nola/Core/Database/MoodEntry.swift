import CoreData

@objc(MoodEntry)
public class MoodEntry: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoodEntry> {
        NSFetchRequest<MoodEntry>(entityName: "MoodEntry")
    }

    @nonobjc public class func sortedFetchRequest() -> NSFetchRequest<MoodEntry> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntry.date, ascending: false)]
        return request
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var mood: String?
    @NSManaged public var note: String?
}

extension MoodEntry: Identifiable {
    public var safeDate: Date { date ?? Date() }
    public var safeMood: String { mood ?? "okay" }
    public var safeNote: String { note ?? "" }
}

import CoreData

@objc(MemorableMoment)
public class MemorableMoment: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MemorableMoment> {
        NSFetchRequest<MemorableMoment>(entityName: "MemorableMoment")
    }

    @nonobjc public class func sortedFetchRequest() -> NSFetchRequest<MemorableMoment> {
        let request = fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MemorableMoment.date, ascending: false)]
        return request
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var date: Date?
}

extension MemorableMoment: Identifiable {
    public var safeTitle: String { title ?? "A moment to remember" }
    public var safeContent: String { content ?? "" }
    public var safeDate: Date { date ?? Date() }
}


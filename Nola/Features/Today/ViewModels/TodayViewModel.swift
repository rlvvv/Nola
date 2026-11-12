import Foundation
import CoreData

class TodayViewModel: ObservableObject {
    @Published var entries: [JournalEntry] = []
    @Published var moodLogDate: Date?
    @Published var momentTitle: String = ""
    @Published var momentContent: String = ""

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchRecentEntries()
    }

    func fetchRecentEntries() {
        let request: NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntry.createdAt, ascending: false)]
        request.fetchLimit = 5

        do {
            entries = try context.fetch(request)
        } catch {
            print("Failed to fetch recent entries: \(error)")
        }
    }

    func saveMood(value: Int, note: String?) {
        // MoodEntry will be implemented in Phase 3.
        print("Mood logged: \(value), note: \(note ?? "none")")
    }

    func saveMoment(title: String?, content: String) {
        // MemorableMoment will be implemented in Phase 3.
        print("Moment saved: \(title ?? "untitled")")
    }
}
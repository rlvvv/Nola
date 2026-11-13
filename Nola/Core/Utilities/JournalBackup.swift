import CoreData
import Foundation

struct JournalBackup: Codable {
    let formatVersion: Int
    let exportedAt: Date
    let entries: [BackupJournalEntry]
    let moodCheckIns: [BackupMoodCheckIn]
    let memorableMoments: [BackupMemorableMoment]

    static let currentFormatVersion = 1

    static func make(from context: NSManagedObjectContext) throws -> JournalBackup {
        let entries = try context.fetch(JournalEntry.fetchRequest()).map { entry in
            BackupJournalEntry(
                id: entry.id ?? UUID(),
                title: entry.title ?? "",
                content: entry.content ?? "",
                createdAt: entry.createdAt ?? Date(),
                updatedAt: entry.updatedAt ?? entry.createdAt ?? Date(),
                entryType: entry.entryType ?? "daily"
            )
        }
        let moods = try context.fetch(MoodEntry.fetchRequest()).map { mood in
            BackupMoodCheckIn(
                id: mood.id ?? UUID(),
                date: mood.date ?? Date(),
                mood: mood.mood ?? "okay",
                note: mood.note
            )
        }
        let moments = try context.fetch(MemorableMoment.fetchRequest()).map { moment in
            BackupMemorableMoment(
                id: moment.id ?? UUID(),
                title: moment.title ?? "",
                content: moment.content ?? "",
                date: moment.date ?? Date()
            )
        }
        return JournalBackup(
            formatVersion: currentFormatVersion,
            exportedAt: Date(),
            entries: entries,
            moodCheckIns: moods,
            memorableMoments: moments
        )
    }

    func encodedData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    static func decode(_ data: Data) throws -> JournalBackup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(JournalBackup.self, from: data)
        guard backup.formatVersion == currentFormatVersion else {
            throw JournalBackupError.unsupportedVersion(backup.formatVersion)
        }
        return backup
    }

    static func readFile(at url: URL) throws -> Data {
        var fileData: Data?
        var readError: Error?
        var coordinationError: NSError?
        let coordinator = NSFileCoordinator(filePresenter: nil)

        coordinator.coordinate(readingItemAt: url, options: [], error: &coordinationError) { readableURL in
            do {
                fileData = try Data(contentsOf: readableURL)
            } catch {
                readError = error
            }
        }

        if let coordinationError = coordinationError { throw coordinationError }
        if let readError = readError { throw readError }
        guard let data = fileData else { throw JournalBackupError.fileCouldNotBeRead }
        return data
    }

    func merge(into context: NSManagedObjectContext) throws -> JournalBackupImportResult {
        let existingEntryIDs = Set(try context.fetch(JournalEntry.fetchRequest()).compactMap(\.id))
        let existingMoodIDs = Set(try context.fetch(MoodEntry.fetchRequest()).compactMap(\.id))
        let existingMomentIDs = Set(try context.fetch(MemorableMoment.fetchRequest()).compactMap(\.id))
        var seenEntryIDs = existingEntryIDs
        var seenMoodIDs = existingMoodIDs
        var seenMomentIDs = existingMomentIDs
        var addedEntries = 0
        var addedMoods = 0
        var addedMoments = 0

        for item in entries where seenEntryIDs.insert(item.id).inserted {
            let entry = JournalEntry(context: context)
            entry.id = item.id
            entry.title = item.title
            entry.content = item.content
            entry.createdAt = item.createdAt
            entry.updatedAt = item.updatedAt
            entry.entryType = item.entryType
            addedEntries += 1
        }
        for item in moodCheckIns where seenMoodIDs.insert(item.id).inserted {
            let mood = MoodEntry(context: context)
            mood.id = item.id
            mood.date = item.date
            mood.mood = item.mood
            mood.note = item.note
            addedMoods += 1
        }
        for item in memorableMoments where seenMomentIDs.insert(item.id).inserted {
            let moment = MemorableMoment(context: context)
            moment.id = item.id
            moment.title = item.title
            moment.content = item.content
            moment.date = item.date
            addedMoments += 1
        }

        do {
            if context.hasChanges { try context.save() }
        } catch {
            context.rollback()
            throw error
        }

        return JournalBackupImportResult(
            entriesAdded: addedEntries,
            moodsAdded: addedMoods,
            momentsAdded: addedMoments,
            duplicatesSkipped: entries.count + moodCheckIns.count + memorableMoments.count - addedEntries - addedMoods - addedMoments
        )
    }
}

struct BackupJournalEntry: Codable {
    let id: UUID
    let title: String
    let content: String
    let createdAt: Date
    let updatedAt: Date
    let entryType: String
}

struct BackupMoodCheckIn: Codable {
    let id: UUID
    let date: Date
    let mood: String
    let note: String?
}

struct BackupMemorableMoment: Codable {
    let id: UUID
    let title: String
    let content: String
    let date: Date
}

struct JournalBackupImportResult {
    let entriesAdded: Int
    let moodsAdded: Int
    let momentsAdded: Int
    let duplicatesSkipped: Int

    var summary: String {
        "Added \(entriesAdded) journal entries, \(moodsAdded) mood check-ins, and \(momentsAdded) memorable moments. Skipped \(duplicatesSkipped) duplicate items. Existing data was kept."
    }
}

enum JournalBackupError: LocalizedError {
    case unsupportedVersion(Int)
    case fileCouldNotBeRead

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "This backup uses format version \(version), which this version of Nola doesn’t support."
        case .fileCouldNotBeRead:
            return "Nola couldn’t read data from the selected backup file. Try saving it to On My iPhone and importing it again."
        }
    }
}


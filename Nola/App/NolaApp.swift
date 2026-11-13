import SwiftUI
import CoreData

@main
struct NolaApp: App {
    @StateObject private var persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = persistence.startupError {
                    PersistenceErrorView(message: error)
                } else if persistence.isStoreReady {
                    RootView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                } else {
                    ProgressView("Opening your journal…")
                }
            }
        }
    }
}

private struct PersistenceErrorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 34))
                .foregroundColor(.orange)
            Text("Nola couldn’t open your journal")
                .font(.system(size: 22, weight: .semibold, design: .serif))
                .multilineTextAlignment(.center)
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .textSelection(.enabled)
        }
        .padding(28)
    }
}

private struct RootView: View {
    @Environment(\.managedObjectContext) private var context
    @State private var selectedTab = 0
    @State private var showingEditor = false

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayScreen(showingEditor: $showingEditor)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)
            JournalScreen()
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(1)
        }
        .tint(Color(red: 0.42, green: 0.38, blue: 0.72))
        .sheet(isPresented: $showingEditor) {
            EntryEditor(entry: nil)
                .environment(\.managedObjectContext, context)
        }
    }
}

private struct TodayScreen: View {
    @Binding var showingEditor: Bool
    @FetchRequest(fetchRequest: JournalEntry.sortedFetchRequest())
    private var entries: FetchedResults<JournalEntry>

    private var todayEntries: [JournalEntry] {
        entries.filter { Calendar.current.isDateInToday($0.safeCreatedAt) }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Date(), formatter: Self.dayFormatter)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.secondary)
                        Text("Make room\nfor your thoughts.")
                            .font(.system(size: 34, weight: .semibold, design: .serif))
                            .foregroundColor(Color(red: 0.19, green: 0.18, blue: 0.24))
                    }
                    Button { showingEditor = true } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 19, weight: .semibold))
                                .frame(width: 46, height: 46)
                                .background(Color.white.opacity(0.18))
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Write an entry").font(.system(size: 17, weight: .semibold))
                                Text("Start wherever you are").font(.system(size: 13)).opacity(0.82)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right").font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(18)
                        .background(Color(red: 0.42, green: 0.38, blue: 0.72))
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 13) {
                        HStack {
                            Text("Today").font(.system(size: 22, weight: .semibold, design: .serif))
                            Spacer()
                            Text("\(todayEntries.count) \(todayEntries.count == 1 ? "entry" : "entries")")
                                .font(.system(size: 13)).foregroundColor(.secondary)
                        }
                        if todayEntries.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("A page with possibility.")
                                    .font(.system(size: 16, weight: .medium))
                                Text("Your notes from today will find a home here.")
                                    .font(.system(size: 14)).foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                            .background(Color.white.opacity(0.75))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            ForEach(todayEntries, id: \.objectID) { entry in
                                NavigationLink(destination: EntryEditor(entry: entry)) {
                                    EntryCard(entry: entry)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(22)
            }
            .background(Color(red: 0.97, green: 0.96, blue: 0.94).ignoresSafeArea())
            .navigationBarHidden(true)
        }
        .navigationViewStyle(.stack)
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()
}

private struct JournalScreen: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(fetchRequest: JournalEntry.sortedFetchRequest())
    private var entries: FetchedResults<JournalEntry>
    @State private var showingEditor = false
    @State private var entryToDelete: JournalEntry?
    @State private var showingDeleteError = false
    @State private var deleteErrorMessage = ""

    var body: some View {
        NavigationView {
            Group {
                if entries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed").font(.system(size: 34)).foregroundColor(.secondary)
                        Text("Your journal starts here")
                            .font(.system(size: 21, weight: .semibold, design: .serif))
                        Text("Write your first entry and it will be saved on this device.")
                            .font(.system(size: 15)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    List {
                        ForEach(entries, id: \.objectID) { entry in
                            NavigationLink(destination: EntryEditor(entry: entry)) {
                                EntryCard(entry: entry).padding(.vertical, 5)
                            }
                            .swipeActions {
                                Button(role: .destructive) { entryToDelete = entry } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(Color(red: 0.97, green: 0.96, blue: 0.94))
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingEditor = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("New entry")
                }
            }
            .sheet(isPresented: $showingEditor) { EntryEditor(entry: nil) }
            .confirmationDialog("Delete this entry?", isPresented: Binding(
                get: { entryToDelete != nil }, set: { if !$0 { entryToDelete = nil } }
            ), titleVisibility: .visible) {
                Button("Delete Entry", role: .destructive) { deleteSelectedEntry() }
                Button("Cancel", role: .cancel) { entryToDelete = nil }
            } message: {
                Text("This entry will be permanently removed from this device.")
            }
        }
        .navigationViewStyle(.stack)
        .alert("Couldn’t delete entry", isPresented: $showingDeleteError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(deleteErrorMessage)
        }
    }

    private func deleteSelectedEntry() {
        guard let entry = entryToDelete else { return }
        context.delete(entry)
        do {
            try PersistenceController.shared.save()
            entryToDelete = nil
        } catch {
            context.rollback()
            deleteErrorMessage = error.localizedDescription
            showingDeleteError = true
            entryToDelete = nil
        }
    }
}

private struct EntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.safeTitle.isEmpty ? "Untitled" : entry.safeTitle)
                    .font(.system(size: 17, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.19, green: 0.18, blue: 0.24))
                    .lineLimit(1)
                Spacer(minLength: 8)
                Text(entry.safeCreatedAt, formatter: Self.dateFormatter)
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
            Text(entry.safeContent.isEmpty ? "No writing yet" : entry.safeContent)
                .font(.system(size: 14)).foregroundColor(.secondary)
                .lineLimit(3).multilineTextAlignment(.leading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.82))
        .clipShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct EntryEditor: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentationMode
    @State private var title: String
    @State private var content: String
    @State private var showingDiscardAlert = false
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    private let entry: JournalEntry?
    private let originalTitle: String
    private let originalContent: String
    private let isNewEntry: Bool

    init(entry: JournalEntry?) {
        self.entry = entry
        let title = entry?.safeTitle == "Untitled" ? "" : (entry?.safeTitle ?? "")
        let content = entry?.safeContent ?? ""
        isNewEntry = entry == nil
        originalTitle = title
        originalContent = content
        _title = State(initialValue: title)
        _content = State(initialValue: content)
    }

    private var hasChanges: Bool { title != originalTitle || content != originalContent }
    private var canSave: Bool { !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Give this entry a title", text: $title)
                    .font(.system(size: 25, weight: .semibold, design: .serif))
                    .padding(.horizontal, 20).padding(.top, 20)
                Divider().padding(.horizontal, 20).padding(.top, 15)
                TextEditor(text: $content)
                    .font(.system(size: 17))
                    .padding(.horizontal, 14).padding(.top, 10)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("What’s on your mind?")
                                .font(.system(size: 17)).foregroundColor(Color.gray.opacity(0.65))
                                .padding(.leading, 20).padding(.top, 18)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .background(Color(red: 0.99, green: 0.985, blue: 0.97))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 17, weight: .semibold))
                        .disabled(!canSave)
                }
            }
            .alert("Discard changes?", isPresented: $showingDiscardAlert) {
                Button("Keep Editing", role: .cancel) { }
                Button("Discard", role: .destructive) { presentationMode.wrappedValue.dismiss() }
            } message: { Text("Your unsaved writing will be lost.") }
        }
        .navigationViewStyle(.stack)
        .alert("Couldn’t save entry", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private func cancel() {
        if hasChanges { showingDiscardAlert = true }
        else { presentationMode.wrappedValue.dismiss() }
    }

    private func save() {
        let target = entry ?? JournalEntry(context: context)
        if isNewEntry {
            target.id = UUID()
            target.createdAt = Date()
            target.entryType = "daily"
        }
        target.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        target.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        target.updatedAt = Date()
        do {
            try PersistenceController.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            context.rollback()
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }
}

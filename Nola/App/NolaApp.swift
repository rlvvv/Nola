import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers

@main
struct NolaApp: App {
    @StateObject private var persistence = PersistenceController.shared

    init() {
        // Clear UIKit-backed editor surfaces so
        // they display the rounded SwiftUI field backgrounds in either theme.
        UITextView.appearance().backgroundColor = .clear
    }

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
    @State private var selectedTab = 0
    @AppStorage("nola.theme") private var theme = "light"

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayScreen()
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(0)
            JournalScreen()
                .tabItem { Label("Journal", systemImage: "book.closed") }
                .tag(1)
            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "sparkles") }
                .tag(2)
            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
                .tag(3)
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(4)
        }
        .tint(NolaTheme.accent)
        .preferredColorScheme(theme == "dark" ? .dark : .light)
    }
}

private struct InsightsScreen: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(NolaTheme.accent)
                Text("Insights are on the way")
                    .font(.system(size: 20, weight: .semibold, design: .serif))
                    .foregroundColor(NolaTheme.text)
                Text("Personalized suggestions will appear here when Nola can ground them in your journal, moods, and moments.")
                    .font(.system(size: 15))
                    .foregroundColor(NolaTheme.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(NolaTheme.background)
            .navigationTitle("Insights")
        }
        .navigationViewStyle(.stack)
    }
}

private struct ProgressScreen: View {
    @State private var period = "Week"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Picker("Reflection period", selection: $period) {
                        Text("Week").tag("Week")
                        Text("Month").tag("Month")
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your reflections will appear here")
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(NolaTheme.text)
                        Text("Nola will reflect on your mood, journaling, moments, and actions over time. No scores or streaks.")
                            .font(.system(size: 14))
                            .foregroundColor(NolaTheme.secondaryText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(NolaTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NolaTheme.cardBorder, lineWidth: 1))
                }
                .padding(20)
            }
            .background(NolaTheme.background)
            .navigationTitle("Progress")
        }
        .navigationViewStyle(.stack)
    }
}

private struct SettingsScreen: View {
    @AppStorage("nola.theme") private var theme = "light"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $theme) {
                        Text("White").tag("light")
                        Text("Black").tag("dark")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                Section {
                    Text("Your journal is stored on this device. Use Journal → ⋯ to export or import a backup.")
                        .font(.system(size: 14))
                        .foregroundColor(NolaTheme.secondaryText)
                }
            }
            .background(NolaTheme.background)
            .navigationTitle("Settings")
        }
        .navigationViewStyle(.stack)
    }
}

private struct TodayScreen: View {
    @FetchRequest(fetchRequest: JournalEntry.sortedFetchRequest())
    private var entries: FetchedResults<JournalEntry>
    @FetchRequest(fetchRequest: MoodEntry.sortedFetchRequest())
    private var moodEntries: FetchedResults<MoodEntry>
    @FetchRequest(fetchRequest: MemorableMoment.sortedFetchRequest())
    private var moments: FetchedResults<MemorableMoment>
    @State private var selectedDate = Calendar.current.startOfDay(for: Date())
    @State private var moodSheet: MoodCheckInSheet?
    @State private var showingEntryEditor = false
    @State private var showingMomentEditor = false
    @State private var momentToDelete: MemorableMoment?
    @State private var showingMomentDeleteConfirmation = false
    @State private var showingMomentDeleteError = false
    @State private var momentDeleteError = ""

    private var selectedDayEntries: [JournalEntry] {
        entries.filter { Calendar.current.isDate($0.safeCreatedAt, inSameDayAs: selectedDate) }
    }

    private var selectedDayMoods: [MoodEntry] {
        moodEntries.filter { Calendar.current.isDate($0.safeDate, inSameDayAs: selectedDate) }
    }

    private var selectedDayMoments: [MemorableMoment] {
        moments.filter { Calendar.current.isDate($0.safeDate, inSameDayAs: selectedDate) }
    }

    private var isShowingToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    Text(selectedDate, formatter: Self.dayFormatter)
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(NolaTheme.text)
                    dateCarousel
                    moodSection
                    journalSection
                    memorableMomentsSection
                }
                .padding(22)
            }
            .background(NolaTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(item: $moodSheet) { sheet in
                MoodCheckInView(entry: sheet.entry, date: sheet.date)
                    .id(sheet.id)
            }
            .sheet(isPresented: $showingMomentEditor) {
                MomentEditorView(date: selectedDate)
            }
            .sheet(isPresented: $showingEntryEditor) {
                EntryEditor(entry: nil, defaultDate: selectedDate)
            }
            .confirmationDialog("Delete this moment?", isPresented: $showingMomentDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Moment", role: .destructive) { deleteSelectedMoment() }
                Button("Cancel", role: .cancel) { momentToDelete = nil }
            } message: {
                Text("This moment will be permanently removed from this device.")
            }
            .alert("Couldn’t delete moment", isPresented: $showingMomentDeleteError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(momentDeleteError)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var dateCarousel: some View {
        let dates = datesInSelectedWeek
        return HStack(spacing: 8) {
            ForEach(dates, id: \.self) { date in
                let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
                let isFuture = date > Calendar.current.startOfDay(for: Date())
                Button { selectDateWithoutAnimation(date) } label: {
                    VStack(spacing: 7) {
                        Text(date, formatter: Self.weekdayFormatter)
                            .font(.system(size: 10, weight: .medium))
                        Text(date, formatter: Self.dayNumberFormatter)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(isSelected ? Color.white : NolaTheme.text)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(isSelected ? NolaTheme.accentStrong : NolaTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(isFuture)
                .opacity(isFuture ? 0.42 : 1)
                .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }

        }
        .foregroundColor(NolaTheme.accent)
        .transaction { $0.animation = nil }
        .animation(nil, value: selectedDate)
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    guard abs(value.translation.width) > abs(value.translation.height), abs(value.translation.width) > 45 else { return }
                    moveSelectedWeek(by: value.translation.width < 0 ? 1 : -1)
                }
        )
    }

    private var datesInSelectedWeek: [Date] {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: selectedDate)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let firstDay = calendar.date(byAdding: .day, value: -offset, to: selectedDate) else { return [selectedDate] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
    }

    private func weekStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: -offset, to: calendar.startOfDay(for: date)) ?? calendar.startOfDay(for: date)
    }

    private func moveSelectedWeek(by amount: Int) {
        guard let newDate = Calendar.current.date(byAdding: .day, value: amount * 7, to: selectedDate) else { return }
        let today = Calendar.current.startOfDay(for: Date())
        selectDateWithoutAnimation(min(newDate, today))
    }

    private func selectDateWithoutAnimation(_ date: Date) {
        var transaction = Transaction()
        transaction.animation = nil
        withTransaction(transaction) {
            selectedDate = date
        }
    }

    private var journalSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                Text("Journal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NolaTheme.text)
                Spacer()
                Button { showingEntryEditor = true } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(NolaTheme.accent)
            }
            if selectedDayEntries.isEmpty {
                emptyState("No notes for this day yet", detail: "Add a note whenever you’re ready.", icon: "square.and.pencil")
            } else {
                ForEach(selectedDayEntries, id: \.objectID) { entry in
                    NavigationLink(destination: EntryEditor(entry: entry)) {
                        EntryCard(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func emptyState(_ title: String, detail: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Label(title, systemImage: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(NolaTheme.text)
            Text(detail)
                .font(.system(size: 13))
                .foregroundColor(NolaTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(NolaTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NolaTheme.cardBorder, lineWidth: 1))
    }

    private var memorableMomentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Moments")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NolaTheme.text)
                Spacer()
                Button { showingMomentEditor = true } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(NolaTheme.accent)
            }

            if selectedDayMoments.isEmpty {
                emptyState("No moments for this day yet", detail: "Save something you’d like to remember.", icon: "sparkle")
            } else {
                ForEach(selectedDayMoments, id: \.objectID) { moment in
                    MomentCard(moment: moment) { requestDelete(moment) }
                }
            }
        }
    }

    private func requestDelete(_ moment: MemorableMoment) {
        momentToDelete = moment
        showingMomentDeleteConfirmation = true
    }

    private func deleteSelectedMoment() {
        guard let moment = momentToDelete else { return }
        let context = moment.managedObjectContext ?? PersistenceController.shared.container.viewContext
        context.delete(moment)
        do {
            try PersistenceController.shared.save()
            momentToDelete = nil
        } catch {
            context.rollback()
            momentDeleteError = error.localizedDescription
            showingMomentDeleteError = true
            momentToDelete = nil
        }
    }

    private func moodCheckInCard(for moodEntry: MoodEntry) -> some View {
        Button {
            moodSheet = MoodCheckInSheet(entry: moodEntry, date: selectedDate)
        } label: {
            HStack(spacing: 14) {
                Text(MoodChoice(rawValue: moodEntry.safeMood)?.emoji ?? "🌿")
                    .font(.system(size: 28))
                    .frame(width: 48, height: 48)
                    .background(NolaTheme.warmSoft)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("Feeling \(MoodChoice(rawValue: moodEntry.safeMood)?.label.lowercased() ?? "okay")")
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(NolaTheme.text)
                    Text("\(moodEntry.safeDate, formatter: Self.timeFormatter) · Tap to edit")
                        .font(.system(size: 13)).foregroundColor(NolaTheme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(NolaTheme.secondaryText)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(NolaTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NolaTheme.cardBorder, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Mood")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NolaTheme.text)
                Spacer()
                Button {
                    moodSheet = MoodCheckInSheet(entry: nil, date: selectedDate)
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(NolaTheme.accent)
            }
            if selectedDayMoods.isEmpty {
                emptyState("No mood check-in yet", detail: "Add one whenever you want to note how you feel.", icon: "face.smiling")
            } else {
                ForEach(selectedDayMoods, id: \.objectID) { moodEntry in
                    moodCheckInCard(for: moodEntry)
                }
            }
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter
    }()

    private static let weekdayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter
    }()

    private static let dayNumberFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct MoodCheckInSheet: Identifiable {
    let id = UUID()
    let entry: MoodEntry?
    let date: Date
}

private struct MomentCard: View {
    let moment: MemorableMoment
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkle")
                .foregroundColor(NolaTheme.accent)
                .frame(width: 38, height: 38)
                .background(NolaTheme.accentSoft)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(moment.safeTitle.isEmpty ? "A moment to remember" : moment.safeTitle)
                        .font(.system(size: 16, weight: .semibold, design: .serif))
                        .foregroundColor(NolaTheme.text)
                        .lineLimit(2)
                    Spacer(minLength: 4)
                    Text(moment.safeDate, formatter: Self.dateFormatter)
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
                Text(moment.safeContent)
                    .font(.system(size: 14)).foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NolaTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NolaTheme.cardBorder, lineWidth: 1))
        .simultaneousGesture(DragGesture(minimumDistance: 20).onEnded { value in
            guard value.translation.width < -70, abs(value.translation.width) > abs(value.translation.height) else { return }
            onDelete()
        })
        .accessibilityAction(named: Text("Delete moment"), onDelete)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}

private struct MomentEditorView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentationMode
    @State private var title = ""
    @State private var content = ""
    @State private var showingSaveError = false
    @State private var saveError = ""
    private let date: Date

    init(date: Date) {
        self.date = date
    }

    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Keep a little piece of today.")
                    .font(.system(size: 25, weight: .semibold, design: .serif))
                    .foregroundColor(NolaTheme.text)
                Text("A small win, a kind moment, something funny, or anything you’d like to remember.")
                    .font(.system(size: 15)).foregroundColor(.secondary)
                TextField("Give this moment a title", text: $title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(NolaTheme.text)
                    .padding(14)
                    .background(NolaTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                TextEditor(text: $content)
                    .font(.system(size: 16))
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(NolaTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .foregroundColor(NolaTheme.text)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("What happened?")
                                .font(.system(size: 15)).foregroundColor(NolaTheme.secondaryText.opacity(0.7))
                                .padding(.leading, 13).padding(.top, 16)
                                .allowsHitTesting(false)
                        }
                    }
                Spacer(minLength: 0)
            }
            .padding(22)
            .background(NolaTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 17, weight: .semibold))
                        .disabled(!canSave)
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Couldn’t save moment", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError)
        }
    }

    private func save() {
        let moment = MemorableMoment(context: context)
        moment.id = UUID()
        moment.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        moment.content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
        moment.date = Calendar.current.date(bySettingHour: now.hour ?? 12, minute: now.minute ?? 0, second: now.second ?? 0, of: date) ?? date
        do {
            try PersistenceController.shared.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            context.rollback()
            saveError = error.localizedDescription
            showingSaveError = true
        }
    }
}

private enum MoodChoice: String, CaseIterable, Identifiable {
    case rough
    case low
    case okay
    case good
    case great

    var id: String { rawValue }

    var label: String {
        switch self {
        case .rough: return "Rough"
        case .low: return "Low"
        case .okay: return "Okay"
        case .good: return "Good"
        case .great: return "Great"
        }
    }

    var emoji: String {
        switch self {
        case .rough: return "😣"
        case .low: return "😕"
        case .okay: return "😐"
        case .good: return "🙂"
        case .great: return "😄"
        }
    }
}

private struct MoodHistoryRow: View {
    let entry: MoodEntry

    private var choice: MoodChoice {
        MoodChoice(rawValue: entry.safeMood) ?? .okay
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(choice.emoji).font(.system(size: 23))
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(choice.label)
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                    Text(entry.safeDate, formatter: Self.dateFormatter)
                        .font(.system(size: 12)).foregroundColor(.secondary)
                }
                if !entry.safeNote.isEmpty {
                    Text(entry.safeNote)
                        .font(.system(size: 13)).foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(14)
        .background(NolaTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct MoodCheckInView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.presentationMode) private var presentationMode
    @State private var selectedMood: String
    @State private var note: String
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    private let entry: MoodEntry?
    private let date: Date

    init(entry: MoodEntry?, date: Date) {
        self.entry = entry
        self.date = date
        _selectedMood = State(initialValue: entry?.safeMood ?? "")
        _note = State(initialValue: entry?.safeNote ?? "")
    }

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 22) {
                Text("How are you feeling?")
                    .font(.system(size: 28, weight: .semibold, design: .serif))
                    .foregroundColor(NolaTheme.text)
                Text("There’s no right answer. Just notice where you are.")
                    .font(.system(size: 15)).foregroundColor(NolaTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 7) {
                    ForEach(MoodChoice.allCases) { mood in
                        Button { selectedMood = mood.rawValue } label: {
                            VStack(spacing: 7) {
                                Text(mood.emoji).font(.system(size: 27))
                                Text(mood.label)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(1).minimumScaleFactor(0.8)
                            }
                            .frame(maxWidth: .infinity, minHeight: 82)
                            .padding(.vertical, 5)
                            .background(selectedMood == mood.rawValue ? NolaTheme.accentSoft : NolaTheme.surface)
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(selectedMood == mood.rawValue ? NolaTheme.accent : Color.clear, lineWidth: 1.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(NolaTheme.text)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Anything behind that feeling?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(NolaTheme.text)
                    TextEditor(text: $note)
                        .frame(minHeight: 110)
                        .padding(8)
                        .background(NolaTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .foregroundColor(NolaTheme.text)
                        .overlay(alignment: .topLeading) {
                            if note.isEmpty {
                                Text("Optional note")
                                    .font(.system(size: 15)).foregroundColor(NolaTheme.secondaryText.opacity(0.7))
                                    .padding(.leading, 13).padding(.top, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                }
                Spacer(minLength: 0)
            }
            .padding(22)
            .background(NolaTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { save() }
                        .font(.system(size: 17, weight: .semibold))
                        .disabled(selectedMood.isEmpty)
                }
            }
        }
        .navigationViewStyle(.stack)
        .alert("Couldn’t save check-in", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private func save() {
        let target = entry ?? MoodEntry(context: context)
        if entry == nil {
            target.id = UUID()
            let now = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
            target.date = Calendar.current.date(bySettingHour: now.hour ?? 12, minute: now.minute ?? 0, second: now.second ?? 0, of: date) ?? date
        }
        target.mood = selectedMood
        let trimmedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
        target.note = trimmedNote.isEmpty ? nil : trimmedNote
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

private struct JournalScreen: View {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(fetchRequest: JournalEntry.sortedFetchRequest())
    private var entries: FetchedResults<JournalEntry>
    @State private var searchText = ""
    @State private var showingEditor = false
    @State private var entryToDelete: JournalEntry?
    @State private var showingJournalAlert = false
    @State private var journalAlertTitle = "Journal backup"
    @State private var journalAlertMessage = ""
    @State private var showingBackupImporter = false
    @State private var showingBackupExporter = false
    @State private var backupDocument: JournalBackupFile?

    private var visibleEntries: [JournalEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return Array(entries) }
        return entries.filter {
            $0.safeTitle.localizedCaseInsensitiveContains(query) ||
            $0.safeContent.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationView {
            Group {
                if visibleEntries.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: searchText.isEmpty ? "book.closed" : "magnifyingglass")
                            .font(.system(size: 34)).foregroundColor(.secondary)
                        Text(searchText.isEmpty ? "Your journal starts here" : "No matching entries")
                            .font(.system(size: 21, weight: .semibold, design: .serif))
                        Text(searchText.isEmpty
                             ? "Write your first entry and it will be saved on this device."
                             : "Try another word or phrase.")
                            .font(.system(size: 15)).foregroundColor(.secondary).multilineTextAlignment(.center)
                    }
                    .padding(32)
                } else {
                    List {
                        ForEach(visibleEntries, id: \.objectID) { entry in
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
            .background(NolaTheme.background)
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search titles and notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button {
                            prepareBackupExport()
                        } label: {
                            Label("Export readable backup", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            showingBackupImporter = true
                        } label: {
                            Label("Import backup", systemImage: "square.and.arrow.down")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Journal backup options")
                }
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
        .sheet(isPresented: $showingBackupImporter) {
            BackupDocumentPicker { selectedURL in
                showingBackupImporter = false
                if let selectedURL = selectedURL {
                    importBackup(from: selectedURL)
                }
            }
        }
        .fileExporter(
            isPresented: $showingBackupExporter,
            document: backupDocument,
            contentType: .json,
            defaultFilename: "Nola-Journal-Backup"
        ) { result in
            switch result {
            case .success:
                presentJournalAlert(title: "Backup exported", message: "Your readable Nola backup was saved.")
            case .failure(let error):
                presentJournalAlert(title: "Couldn’t export backup", message: error.localizedDescription)
            }
            backupDocument = nil
        }
        .alert(isPresented: $showingJournalAlert) {
            Alert(
                title: Text(journalAlertTitle),
                message: Text(journalAlertMessage),
                dismissButton: .default(Text("OK"))
            )
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
            presentJournalAlert(title: "Couldn’t delete entry", message: error.localizedDescription)
            entryToDelete = nil
        }
    }

    private func prepareBackupExport() {
        do {
            let backup = try JournalBackup.make(from: context)
            backupDocument = JournalBackupFile(data: try backup.encodedData())
            showingBackupExporter = true
        } catch {
            presentJournalAlert(title: "Couldn’t create backup", message: error.localizedDescription)
        }
    }

    private func importBackup(from url: URL) {
        let hasScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if hasScopedAccess { url.stopAccessingSecurityScopedResource() }
        }
        do {
            let backupData = try JournalBackup.readFile(at: url)
            let backup = try JournalBackup.decode(backupData)
            let imported = try backup.merge(into: context)
            presentJournalAlert(title: "Backup imported", message: imported.summary)
        } catch {
            presentJournalAlert(title: "Couldn’t import backup", message: error.localizedDescription)
        }
    }

    private func presentJournalAlert(title: String, message: String) {
        journalAlertTitle = title
        journalAlertMessage = message
        showingJournalAlert = true
    }
}

private struct JournalBackupFile: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    static var writableContentTypes: [UTType] { [.json] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

private struct BackupDocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL?) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.data], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) { }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let onPick: (URL?) -> Void

        init(onPick: @escaping (URL?) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            onPick(urls.first)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            onPick(nil)
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
                    .foregroundColor(NolaTheme.text)
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
        .background(NolaTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NolaTheme.cardBorder, lineWidth: 1))
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
    @State private var showingSaveError = false
    @State private var saveErrorMessage = ""
    @State private var entry: JournalEntry?
    @State private var lastSavedTitle: String
    @State private var lastSavedContent: String
    @State private var saveWorkItem: DispatchWorkItem?
    private let defaultDate: Date

    init(entry: JournalEntry?, defaultDate: Date = Date()) {
        _entry = State(initialValue: entry)
        let title = entry?.safeTitle == "Untitled" ? "" : (entry?.safeTitle ?? "")
        let content = entry?.safeContent ?? ""
        let normalizedDate = Calendar.current.startOfDay(for: defaultDate)
        self.defaultDate = normalizedDate
        _lastSavedTitle = State(initialValue: title)
        _lastSavedContent = State(initialValue: content)
        _title = State(initialValue: title)
        _content = State(initialValue: content)
    }

    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var trimmedContent: String { content.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var canSave: Bool { !trimmedTitle.isEmpty || !trimmedContent.isEmpty }
    private var hasUnsavedChanges: Bool { trimmedTitle != lastSavedTitle || trimmedContent != lastSavedContent }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                TextField("Give this entry a title", text: $title)
                    .font(.system(size: 25, weight: .semibold, design: .serif))
                    .foregroundColor(NolaTheme.text)
                    .padding(.horizontal, 20).padding(.top, 20)
                Divider().padding(.horizontal, 20).padding(.top, 15)
                TextEditor(text: $content)
                    .font(.system(size: 17))
                    .padding(.horizontal, 14).padding(.top, 10)
                    .foregroundColor(NolaTheme.text)
                    .overlay(alignment: .topLeading) {
                        if content.isEmpty {
                            Text("What’s on your mind?")
                                .font(.system(size: 17)).foregroundColor(NolaTheme.secondaryText.opacity(0.7))
                                .padding(.leading, 20).padding(.top, 18)
                                .allowsHitTesting(false)
                        }
                    }
            }
            .background(NolaTheme.raisedSurface)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { close() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 44, height: 44)
                            .offset(y: 5)
                    }
                    .accessibilityLabel("Back")
                }
            }
            .onChange(of: title) { _ in scheduleAutosave() }
            .onChange(of: content) { _ in scheduleAutosave() }
            .onDisappear {
                saveWorkItem?.cancel()
                saveDraft()
            }
        }
        .navigationViewStyle(.stack)
        .navigationBarBackButtonHidden(true)
        .alert("Couldn’t save entry", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { showingSaveError = false }
        } message: {
            Text(saveErrorMessage)
        }
    }

    private func close() {
        saveWorkItem?.cancel()
        saveDraft()
        if !showingSaveError {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func scheduleAutosave() {
        guard canSave else { return }
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { saveDraft() }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65, execute: workItem)
    }

    private func saveDraft() {
        guard canSave, hasUnsavedChanges else { return }
        let isNewEntry = entry == nil
        let target: JournalEntry
        if let existing = entry {
            target = existing
        } else {
            target = JournalEntry(context: context)
            target.id = UUID()
            target.entryType = "daily"
            target.createdAt = defaultDate
            entry = target
        }
        target.title = trimmedTitle
        target.content = trimmedContent
        target.updatedAt = Date()
        do {
            try PersistenceController.shared.save()
            lastSavedTitle = trimmedTitle
            lastSavedContent = trimmedContent
            showingSaveError = false
        } catch {
            context.rollback()
            if isNewEntry { entry = nil }
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }
}


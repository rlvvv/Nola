import SwiftUI
import CoreData
import UIKit
import UniformTypeIdentifiers
import Security

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
            AICompanionScreen()
                .tabItem { Label("Companion", systemImage: "bubble.left.and.bubble.right") }
                .tag(2)
            InsightsScreen()
                .tabItem { Label("Insights", systemImage: "sparkles") }
                .tag(3)
            ProgressScreen()
                .tabItem { Label("Progress", systemImage: "chart.xyaxis.line") }
                .tag(4)
            SettingsScreen()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(5)
        }
        .tint(NolaTheme.accent)
        .preferredColorScheme(theme == "dark" ? .dark : .light)
    }
}

private struct AICompanionScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @FetchRequest(fetchRequest: JournalEntry.sortedFetchRequest())
    private var entries: FetchedResults<JournalEntry>
    @FetchRequest(fetchRequest: MoodEntry.sortedFetchRequest())
    private var moods: FetchedResults<MoodEntry>
    @FetchRequest(fetchRequest: MemorableMoment.sortedFetchRequest())
    private var moments: FetchedResults<MemorableMoment>
    @StateObject private var chat = NolaChatStore()
    @State private var draft = ""
    @State private var showingConnectionSettings = false
    @State private var showingHistory = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Text("Companion")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(NolaTheme.text)
                    Spacer()
                    if !chat.messages.isEmpty {
                        GlassQuestionBadge(count: chat.displayedQuestionCount, total: chat.questionLimit)
                    }
                    Button { requestQuestion() } label: {
                        Image(systemName: "sparkle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(NolaTheme.accent)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(NolaTheme.cardBorder.opacity(0.7), lineWidth: 1))
                    }
                    .disabled(!chat.canRequestOpeningQuestion)
                    .accessibilityLabel("Request a question")
                    Button { showingHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(NolaTheme.text)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(NolaTheme.cardBorder.opacity(0.7), lineWidth: 1))
                    }
                    .disabled(chat.isWaiting)
                    .accessibilityLabel("Chat history")
                    Menu {
                        Button("End session") { chat.endSession() }
                            .disabled(chat.messages.isEmpty || chat.isWaiting)
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(NolaTheme.text)
                            .frame(width: 42, height: 42)
                            .background(.ultraThinMaterial, in: Circle())
                            .overlay(Circle().stroke(NolaTheme.cardBorder.opacity(0.7), lineWidth: 1))
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 8)

                if chat.messages.isEmpty {
                    Spacer()
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(NolaTheme.accent.opacity(0.85))
                        .padding(.bottom, 12)
                    Text(chat.hasUsedSessionToday
                             ? "You’ve already had today’s conversation."
                             : "Choose the kind of conversation you need.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(NolaTheme.secondaryText)
                    if !chat.hasUsedSessionToday {
                        VStack(spacing: 10) {
                            Button { requestQuestion(sessionType: .daily) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Regular conversation")
                                            .font(.system(size: 15, weight: .semibold))
                                        Text("7 questions · Available every day")
                                            .font(.system(size: 12))
                                            .foregroundColor(NolaTheme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(NolaTheme.text)
                                .padding(15)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                            }
                            Button { requestQuestion(sessionType: .weekly) } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Deep-dive conversation")
                                            .font(.system(size: 15, weight: .semibold))
                                        Text(chat.canStartWeeklySession
                                             ? "15 questions · Available once a week"
                                             : "15 questions · Already used this week")
                                            .font(.system(size: 12))
                                            .foregroundColor(NolaTheme.secondaryText)
                                    }
                                    Spacer()
                                    Image(systemName: "sparkles")
                                }
                                .foregroundColor(NolaTheme.text)
                                .padding(15)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .opacity(chat.canStartWeeklySession ? 1 : 0.45)
                            }
                            .disabled(!chat.canStartWeeklySession)
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 18)
                    }
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                ForEach(chat.messages) { message in
                                    ChatBubble(message: message).id(message.id)
                                }
                                if chat.isWaiting {
                                    HStack {
                                        ProgressView().tint(NolaTheme.accent)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 6)
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 16)
                        }
                        .onChange(of: chat.messages.count) { _ in
                            guard let last = chat.messages.last else { return }
                            withAnimation(.easeOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                }

                if let message = chat.statusMessage {
                    HStack(spacing: 10) {
                        Text(message)
                            .font(.system(size: 12))
                            .foregroundColor(NolaTheme.secondaryText)
                        if chat.canRetry {
                            Button("Retry") { chat.retryLastRequest() }
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(NolaTheme.accent)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 7)
                }

                HStack(spacing: 10) {
                    TextField("Message...", text: $draft)
                        .font(.system(size: 16))
                        .foregroundColor(NolaTheme.text)
                        .padding(.leading, 17)
                        .padding(.vertical, 14)
                        .disabled(!chat.canSendMessage)
                    Button { sendDraft() } label: {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(NolaTheme.accentStrong, in: Circle())
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !chat.canSendMessage)
                    .opacity(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !chat.canSendMessage ? 0.45 : 1)
                    .padding(.trailing, 7)
                }
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(NolaTheme.cardBorder.opacity(0.8), lineWidth: 1))
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
            .background(NolaTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .sheet(isPresented: $showingConnectionSettings) { VeniceSettingsScreen() }
            .sheet(isPresented: $showingHistory) { ChatHistoryScreen(chat: chat) }
            .alert("Nola needs a Venice API key", isPresented: $chat.needsAPIKey) {
                Button("Open Settings") { showingConnectionSettings = true }
                Button("Not now", role: .cancel) { }
            } message: {
                Text("Add it in Settings → Venice connection.")
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { chat.refreshForCurrentDay() }
        .onChange(of: scenePhase) { phase in
            if phase == .active { chat.refreshForCurrentDay() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
            chat.refreshForCurrentDay()
        }
        .onReceive(NotificationCenter.default.publisher(for: NolaChatStore.backupImportedNotification)) { _ in
            chat.reloadFromDefaults()
        }
    }

    private func sendDraft() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        guard !(VeniceKeychain.apiKey ?? "").isEmpty else {
            chat.needsAPIKey = true
            return
        }
        draft = ""
        chat.sendUserMessage(text, context: "")
    }

    private func requestQuestion(sessionType: NolaChatSessionType = .daily) {
        chat.requestOpeningQuestion(context: compactContext, sessionType: sessionType)
    }

    private var compactContext: String {
        let journal = entries.prefix(8).map { "Journal [\($0.safeCreatedAt.formatted(date: .abbreviated, time: .omitted))]: \($0.safeTitle) — \($0.safeContent)" }
        let mood = moods.prefix(8).map { "Mood [\($0.safeDate.formatted(date: .abbreviated, time: .shortened))]: \($0.safeMood); \($0.safeNote)" }
        let moment = moments.prefix(6).map { "Moment [\($0.safeDate.formatted(date: .abbreviated, time: .omitted))]: \($0.safeTitle) — \($0.safeContent)" }
        return (journal + mood + moment).joined(separator: "\n")
    }
}

private struct ChatBubble: View {
    let message: NolaChatMessage

    var body: some View {
        HStack {
            if message.role == .assistant { Spacer(minLength: 28) }
            Text(message.content)
                .font(.system(size: 16))
                .foregroundColor(message.role == .user ? .white : NolaTheme.text)
                .padding(13)
                .background(message.role == .user ? NolaTheme.accentStrong : NolaTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(message.role == .user ? Color.clear : NolaTheme.cardBorder, lineWidth: 1))
            if message.role == .user { Spacer(minLength: 28) }
        }
    }
}

private enum ChatRole: String, Codable {
    case user
    case assistant
}

private struct NolaChatMessage: Codable, Identifiable {
    let id: UUID
    let role: ChatRole
    let content: String
    let createdAt: Date

    init(id: UUID = UUID(), role: ChatRole, content: String, createdAt: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
    }
}

private enum NolaChatSessionType: String, Codable, Equatable {
    case daily
    case weekly

    var questionLimit: Int { self == .weekly ? 15 : 7 }
}

private struct NolaChatSession: Codable, Identifiable {
    let id: UUID
    let startedAt: Date
    let endedAt: Date
    let messages: [NolaChatMessage]
    let questionCount: Int
    let isComplete: Bool
    let sessionType: String?

    var questionLimit: Int {
        NolaChatSessionType(rawValue: sessionType ?? "")?.questionLimit ?? 7
    }

    var preview: String {
        if let userMessage = messages.first(where: { $0.role == .user }), !userMessage.content.isEmpty {
            return userMessage.content
        }
        return messages.first?.content ?? ""
    }
}

private final class NolaChatStore: ObservableObject {
    static let maxQuestions = 7
    private static let historyLimit = 50

    @Published private(set) var messages: [NolaChatMessage] = []
    @Published private(set) var isWaiting = false
    @Published private(set) var isSessionClosed = false
    @Published private(set) var isAwaitingFinalAnswer = false
    @Published private(set) var history: [NolaChatSession] = []
    @Published private(set) var canRetry = false
    @Published var needsAPIKey = false
    @Published private(set) var statusMessage: String?
    @Published private(set) var currentSessionType: NolaChatSessionType = .daily

    private enum PendingRequest {
        case question(context: String, openingQuestion: Bool)
        case closing
    }

    private var pendingRequest: PendingRequest?
    private var questionCount = 0
    private var didArchiveCurrentSession = false

    private let messagesKey = "nola.ai.messages"
    private let questionCountKey = "nola.ai.questionCount"
    private let sessionClosedKey = "nola.ai.sessionClosed"
    private let requestDateKey = "nola.ai.requestQuestionDate"
    private let awaitingFinalAnswerKey = "nola.ai.awaitingFinalAnswer"
    private let historyKey = "nola.ai.chatHistory"
    private let archivedKey = "nola.ai.currentSessionArchived"
    private let dailySessionDateKey = "nola.ai.dailySessionDate"
    private let weeklySessionWeekKey = "nola.ai.weeklySessionWeek"
    private let currentSessionTypeKey = "nola.ai.currentSessionType"
    private var requestedSessionType: NolaChatSessionType = .daily
    private let sessionStartedAtKey = "nola.ai.sessionStartedAt"
    private let currentSessionIDKey = "nola.ai.currentSessionID"

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: messagesKey),
           let saved = try? JSONDecoder().decode([NolaChatMessage].self, from: data) {
            messages = saved
        }
        questionCount = defaults.integer(forKey: questionCountKey)
        isSessionClosed = defaults.bool(forKey: sessionClosedKey)
        isAwaitingFinalAnswer = defaults.bool(forKey: awaitingFinalAnswerKey)
        didArchiveCurrentSession = defaults.bool(forKey: archivedKey)
        if let rawType = defaults.string(forKey: currentSessionTypeKey),
           let savedType = NolaChatSessionType(rawValue: rawType) {
            currentSessionType = savedType
        }
        if let data = defaults.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([NolaChatSession].self, from: data) {
            history = saved
        }

        migrateLegacySessionState()

        // Preserve the previous seven-question migration: the final question
        // still receives the user's answer before Nola writes its closing.
        if isSessionClosed,
           currentSessionType == .daily,
           !didArchiveCurrentSession,
           questionCount == Self.maxQuestions,
           messages.last?.role == .assistant {
            isSessionClosed = false
            isAwaitingFinalAnswer = true
            defaults.set(false, forKey: sessionClosedKey)
            defaults.set(true, forKey: awaitingFinalAnswerKey)
        }
        refreshForCurrentDay()
        if isAwaitingFinalAnswer, !isSessionClosed, messages.last?.role == .user {
            pendingRequest = .closing
            canRetry = true
            statusMessage = "Your closing reflection is ready to retry."
        }
    }

    var questionLimit: Int { currentSessionType.questionLimit }

    var canStartWeeklySession: Bool {
        UserDefaults.standard.string(forKey: weeklySessionWeekKey) != Self.localWeekKey(Date())
    }

    var displayedQuestionCount: Int {
        min(max(questionCount, 0), questionLimit)
    }

    var hasRequestedQuestionToday: Bool {
        guard let date = UserDefaults.standard.object(forKey: requestDateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(date)
    }

    var hasUsedSessionToday: Bool {
        let todayKey = Self.localDateKey(Date())
        if let storedKey = UserDefaults.standard.string(forKey: dailySessionDateKey) {
            return storedKey == todayKey
        }
        if let startedAt = UserDefaults.standard.object(forKey: sessionStartedAtKey) as? Date {
            return Calendar.current.isDateInToday(startedAt)
        }
        return history.contains { Calendar.current.isDateInToday($0.startedAt) }
    }

    var canSendMessage: Bool {
        guard !isWaiting, !isSessionClosed, !canRetry else { return false }
        if !messages.isEmpty { return true }
        let hasReservedEmptySession = hasUsedSessionToday
            && (UserDefaults.standard.object(forKey: sessionStartedAtKey) as? Date) != nil
            && !didArchiveCurrentSession
        return !hasUsedSessionToday || hasReservedEmptySession
    }

    var canRequestOpeningQuestion: Bool {
        guard !isWaiting, !canRetry, !isSessionClosed, !isAwaitingFinalAnswer,
              !hasRequestedQuestionToday, questionCount < questionLimit else { return false }
        return !messages.isEmpty || !hasUsedSessionToday
    }

    func refreshForCurrentDay() {
        guard let storedKey = UserDefaults.standard.string(forKey: dailySessionDateKey),
              storedKey != Self.localDateKey(Date()) else { return }

        if !messages.isEmpty {
            archiveCurrentSession()
        }
        clearCurrentSession()
    }

    func sendUserMessage(_ text: String, context: String) {
        refreshForCurrentDay()
        guard canSendMessage else { return }
        guard !(VeniceKeychain.apiKey ?? "").isEmpty else {
            needsAPIKey = true
            return
        }
        guard beginSessionIfAllowed() else { return }

        messages.append(NolaChatMessage(role: .user, content: text))
        persist()
        if isAwaitingFinalAnswer || questionCount >= questionLimit {
            requestClosing()
        } else {
            requestQuestionReply(extraContext: context)
        }
    }

    func requestOpeningQuestion(context: String, sessionType: NolaChatSessionType = .daily) {
        refreshForCurrentDay()
        guard canRequestOpeningQuestion else { return }
        if sessionType == .weekly && !canStartWeeklySession { return }
        guard !(VeniceKeychain.apiKey ?? "").isEmpty else {
            needsAPIKey = true
            return
        }
        requestedSessionType = sessionType
        guard beginSessionIfAllowed() else {
            requestedSessionType = .daily
            return
        }
        requestedSessionType = .daily
        UserDefaults.standard.set(Date(), forKey: requestDateKey)
        requestQuestionReply(extraContext: context, openingQuestion: true)
    }

    func endSession() {
        refreshForCurrentDay()
        guard !messages.isEmpty else { return }
        isSessionClosed = true
        isAwaitingFinalAnswer = false
        statusMessage = "Session ended."
        archiveCurrentSession()
    }

    func retryLastRequest() {
        refreshForCurrentDay()
        guard !isWaiting, canRetry, let pendingRequest else { return }
        canRetry = false
        switch pendingRequest {
        case .question(let context, let openingQuestion):
            requestQuestionReply(extraContext: context, openingQuestion: openingQuestion)
        case .closing:
            requestClosing()
        }
    }

    func deleteHistory(_ session: NolaChatSession) {
        history.removeAll { $0.id == session.id }
        persistHistory()
    }

    func clearHistory() {
        history = []
        persistHistory()
    }

    func reloadFromDefaults() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: messagesKey),
           let saved = try? JSONDecoder().decode([NolaChatMessage].self, from: data) {
            messages = saved
        } else {
            messages = []
        }
        questionCount = defaults.integer(forKey: questionCountKey)
        isSessionClosed = defaults.bool(forKey: sessionClosedKey)
        isAwaitingFinalAnswer = defaults.bool(forKey: awaitingFinalAnswerKey)
        didArchiveCurrentSession = defaults.bool(forKey: archivedKey)
        currentSessionType = NolaChatSessionType(rawValue: defaults.string(forKey: currentSessionTypeKey) ?? "") ?? .daily
        if let data = defaults.data(forKey: historyKey),
           let saved = try? JSONDecoder().decode([NolaChatSession].self, from: data) {
            history = saved
        } else {
            history = []
        }
        refreshForCurrentDay()
    }

    static let backupImportedNotification = Notification.Name("NolaBackupImported")

    static func makeBackupSnapshot() -> BackupCompanionData {
        let defaults = UserDefaults.standard
        let savedMessages = defaults.data(forKey: "nola.ai.messages")
            .flatMap { try? JSONDecoder().decode([NolaChatMessage].self, from: $0) } ?? []
        let savedHistory = defaults.data(forKey: "nola.ai.chatHistory")
            .flatMap { try? JSONDecoder().decode([NolaChatSession].self, from: $0) } ?? []
        let savedType = NolaChatSessionType(rawValue: defaults.string(forKey: "nola.ai.currentSessionType") ?? "") ?? .daily
        let startedAt = defaults.object(forKey: "nola.ai.sessionStartedAt") as? Date ?? savedMessages.first?.createdAt
        let currentSession: BackupCompanionSession?
        if !savedMessages.isEmpty || startedAt != nil {
            let start = startedAt ?? Date()
            let sessionID = defaults.string(forKey: "nola.ai.currentSessionID")
                .flatMap { UUID(uuidString: $0) } ?? UUID()
            if defaults.string(forKey: "nola.ai.currentSessionID") == nil {
                defaults.set(sessionID.uuidString, forKey: "nola.ai.currentSessionID")
            }
            currentSession = BackupCompanionSession(
                id: sessionID,
                startedAt: start,
                endedAt: savedMessages.last?.createdAt ?? start,
                messages: savedMessages.map {
                    BackupCompanionMessage(id: $0.id, role: $0.role.rawValue, content: $0.content, createdAt: $0.createdAt)
                },
                questionCount: defaults.integer(forKey: "nola.ai.questionCount"),
                isComplete: defaults.bool(forKey: "nola.ai.sessionClosed"),
                sessionType: savedType.rawValue,
                questionLimit: savedType.questionLimit
            )
        } else {
            currentSession = nil
        }

        return BackupCompanionData(
            history: savedHistory.map { session in
                BackupCompanionSession(
                    id: session.id,
                    startedAt: session.startedAt,
                    endedAt: session.endedAt,
                    messages: session.messages.map {
                        BackupCompanionMessage(id: $0.id, role: $0.role.rawValue, content: $0.content, createdAt: $0.createdAt)
                    },
                    questionCount: session.questionCount,
                    isComplete: session.isComplete,
                    sessionType: session.sessionType,
                    questionLimit: session.questionLimit
                )
            },
            currentSession: currentSession,
            dailySessionDateKey: defaults.string(forKey: "nola.ai.dailySessionDate"),
            weeklySessionWeekKey: defaults.string(forKey: "nola.ai.weeklySessionWeek"),
            requestQuestionDate: defaults.object(forKey: "nola.ai.requestQuestionDate") as? Date,
            currentSessionClosed: defaults.bool(forKey: "nola.ai.sessionClosed"),
            currentSessionAwaitingFinalAnswer: defaults.bool(forKey: "nola.ai.awaitingFinalAnswer"),
            currentSessionArchived: defaults.bool(forKey: "nola.ai.currentSessionArchived"),
            currentSessionType: savedType.rawValue,
            currentQuestionCount: defaults.integer(forKey: "nola.ai.questionCount"),
            currentSessionStartedAt: startedAt
        )
    }

    @discardableResult
    static func mergeBackup(_ backup: BackupCompanionData?) -> Int {
        guard let backup else { return 0 }
        let defaults = UserDefaults.standard
        let existingHistory = defaults.data(forKey: "nola.ai.chatHistory")
            .flatMap { try? JSONDecoder().decode([NolaChatSession].self, from: $0) } ?? []
        var mergedHistory = existingHistory
        var seenIDs = Set(existingHistory.map(\.id))
        let incomingHistory = backup.history.compactMap { restoreSession($0) }
        let newHistory = incomingHistory.filter { seenIDs.insert($0.id).inserted }
        mergedHistory.append(contentsOf: newHistory)

        let currentMessages = defaults.data(forKey: "nola.ai.messages")
            .flatMap { try? JSONDecoder().decode([NolaChatMessage].self, from: $0) } ?? []
        let localDailyKey = defaults.string(forKey: "nola.ai.dailySessionDate")
        let canRestoreIncomingCurrentSession = localDailyKey.map { localKey in
            backup.dailySessionDateKey.map { $0 >= localKey } ?? false
        } ?? true
        var restoredCurrentSession = false

        if currentMessages.isEmpty,
           canRestoreIncomingCurrentSession,
           let incoming = backup.currentSession {
            let restoredMessages = restoreMessages(incoming.messages)
            if restoredMessages.count == incoming.messages.count,
               let data = try? JSONEncoder().encode(restoredMessages) {
                defaults.set(data, forKey: "nola.ai.messages")
                defaults.set(incoming.questionCount, forKey: "nola.ai.questionCount")
                defaults.set(incoming.isComplete || backup.currentSessionClosed, forKey: "nola.ai.sessionClosed")
                defaults.set(backup.currentSessionAwaitingFinalAnswer, forKey: "nola.ai.awaitingFinalAnswer")
                defaults.set(backup.currentSessionArchived, forKey: "nola.ai.currentSessionArchived")
                defaults.set(incoming.sessionType ?? backup.currentSessionType, forKey: "nola.ai.currentSessionType")
                defaults.set(incoming.startedAt, forKey: "nola.ai.sessionStartedAt")
                defaults.set(incoming.id.uuidString, forKey: "nola.ai.currentSessionID")
                restoredCurrentSession = true
            }
        }

        // If the local device already has a different active chat, preserve
        // the imported active chat as a history item instead of dropping it.
        var importedActiveAsHistory = false
        if !restoredCurrentSession,
           let incoming = backup.currentSession,
           !incoming.messages.isEmpty,
           !mergedHistory.contains(where: { $0.id == incoming.id }) {
            let localSessionID = defaults.string(forKey: "nola.ai.currentSessionID")
                .flatMap { UUID(uuidString: $0) }
            let localStartedAt = defaults.object(forKey: "nola.ai.sessionStartedAt") as? Date
                ?? currentMessages.first?.createdAt
            let localFirstMessageID = currentMessages.first?.id
            let incomingFirstMessageID = incoming.messages.first?.id
            let isSameLocalSession = localSessionID == incoming.id
                || (localStartedAt == incoming.startedAt
                    && localFirstMessageID != nil
                    && localFirstMessageID == incomingFirstMessageID)

            if !isSameLocalSession, let restored = restoreSession(incoming) {
                mergedHistory.insert(restored, at: 0)
                importedActiveAsHistory = true
            }
        }

        mergedHistory.sort { $0.startedAt > $1.startedAt }
        if mergedHistory.count > Self.historyLimit {
            mergedHistory = Array(mergedHistory.prefix(Self.historyLimit))
        }
        let retainedHistoryIDs = Set(mergedHistory.map(\.id))
        let retainedNewHistoryCount = newHistory.filter { retainedHistoryIDs.contains($0.id) }.count
        let retainedImportedActiveAsHistory = importedActiveAsHistory
            && (backup.currentSession.map { retainedHistoryIDs.contains($0.id) } ?? false)
        if let data = try? JSONEncoder().encode(mergedHistory) {
            defaults.set(data, forKey: "nola.ai.chatHistory")
        }

        if let incomingKey = backup.dailySessionDateKey {
            let currentKey = defaults.string(forKey: "nola.ai.dailySessionDate")
            if currentKey.map({ incomingKey > $0 }) ?? true {
                defaults.set(incomingKey, forKey: "nola.ai.dailySessionDate")
            }
        }
        if let incomingWeek = backup.weeklySessionWeekKey {
            let currentWeek = defaults.string(forKey: "nola.ai.weeklySessionWeek")
            if currentWeek.map({ incomingWeek > $0 }) ?? true {
                defaults.set(incomingWeek, forKey: "nola.ai.weeklySessionWeek")
            }
        }
        if let incomingDate = backup.requestQuestionDate {
            let currentDate = defaults.object(forKey: "nola.ai.requestQuestionDate") as? Date
            if currentDate.map({ incomingDate > $0 }) ?? true {
                defaults.set(incomingDate, forKey: "nola.ai.requestQuestionDate")
            }
        }

        NotificationCenter.default.post(name: backupImportedNotification, object: nil)
        let activeSessionIsSeparate = restoredCurrentSession
            && (backup.currentSession.map { incoming in
                !retainedHistoryIDs.contains(incoming.id)
            } ?? false)
        return retainedNewHistoryCount
            + (retainedImportedActiveAsHistory ? 1 : 0)
            + (activeSessionIsSeparate ? 1 : 0)
    }

    static func applyBackupPreferences(_ preferences: BackupAppPreferences?) {
        guard let preferences else { return }
        let defaults = UserDefaults.standard
        if ["light", "dark"].contains(preferences.theme) {
            defaults.set(preferences.theme, forKey: "nola.theme")
        }
        if !preferences.chatModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            defaults.set(preferences.chatModel, forKey: "nola.ai.chatModel")
        }
    }

    private static func restoreSession(_ session: BackupCompanionSession) -> NolaChatSession? {
        let messages = restoreMessages(session.messages)
        guard messages.count == session.messages.count else { return nil }
        return NolaChatSession(
            id: session.id,
            startedAt: session.startedAt,
            endedAt: session.endedAt,
            messages: messages,
            questionCount: session.questionCount,
            isComplete: session.isComplete,
            sessionType: session.sessionType
        )
    }

    private static func restoreMessages(_ messages: [BackupCompanionMessage]) -> [NolaChatMessage] {
        messages.compactMap { item in
            guard let role = ChatRole(rawValue: item.role) else { return nil }
            return NolaChatMessage(id: item.id, role: role, content: item.content, createdAt: item.createdAt)
        }
    }

    private func beginSessionIfAllowed() -> Bool {
        if !messages.isEmpty { return true }
        if hasUsedSessionToday {
            return (UserDefaults.standard.object(forKey: sessionStartedAtKey) as? Date) != nil
                && !didArchiveCurrentSession
                && !isSessionClosed
        }

        let now = Date()
        let defaults = UserDefaults.standard
        let weekKey = Self.localWeekKey(now)
        let lastWeeklyWeek = defaults.string(forKey: weeklySessionWeekKey)
        currentSessionType = requestedSessionType
        if currentSessionType == .weekly && lastWeeklyWeek == weekKey {
            return false
        }
        defaults.set(UUID().uuidString, forKey: currentSessionIDKey)
        defaults.set(Self.localDateKey(now), forKey: dailySessionDateKey)
        defaults.set(now, forKey: sessionStartedAtKey)
        defaults.set(currentSessionType.rawValue, forKey: currentSessionTypeKey)
        if currentSessionType == .weekly {
            defaults.set(weekKey, forKey: weeklySessionWeekKey)
        }
        persist()
        return true
    }

    private func migrateLegacySessionState() {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: dailySessionDateKey) == nil {
            if let firstMessage = messages.first {
                defaults.set(Self.localDateKey(firstMessage.createdAt), forKey: dailySessionDateKey)
                defaults.set(firstMessage.createdAt, forKey: sessionStartedAtKey)
            } else if let latestSession = history.first {
                defaults.set(Self.localDateKey(latestSession.startedAt), forKey: dailySessionDateKey)
            }
        }
        if defaults.string(forKey: currentSessionTypeKey) == nil {
            currentSessionType = .daily
            defaults.set(currentSessionType.rawValue, forKey: currentSessionTypeKey)
        }
        if defaults.string(forKey: weeklySessionWeekKey) == nil {
            let lastWeeklySession = history.first { $0.sessionType == NolaChatSessionType.weekly.rawValue }
            if let lastWeeklySession {
                defaults.set(Self.localWeekKey(lastWeeklySession.startedAt), forKey: weeklySessionWeekKey)
            }
        }
        if defaults.object(forKey: sessionStartedAtKey) == nil, let firstMessage = messages.first {
            defaults.set(firstMessage.createdAt, forKey: sessionStartedAtKey)
        }
        if defaults.string(forKey: currentSessionIDKey) == nil, !messages.isEmpty {
            defaults.set(UUID().uuidString, forKey: currentSessionIDKey)
        }
    }

    private func requestQuestionReply(extraContext: String, openingQuestion: Bool = false) {
        guard let key = VeniceKeychain.apiKey, !key.isEmpty else {
            needsAPIKey = true
            return
        }
        let requestMessages = messages
        let countAtRequest = questionCount
        let limitAtRequest = questionLimit
        pendingRequest = .question(context: extraContext, openingQuestion: openingQuestion)
        canRetry = false
        isWaiting = true
        statusMessage = nil
        Task {
            do {
                let selectedModel = UserDefaults.standard.string(forKey: "nola.ai.chatModel") ?? VeniceClient.defaultChatModel
                let reply = try await VeniceClient.reply(
                    apiKey: key,
                    model: selectedModel,
                    messages: requestMessages,
                    context: extraContext,
                    openingQuestion: openingQuestion,
                    remainingQuestions: max(0, limitAtRequest - countAtRequest)
                )
                await MainActor.run {
                    self.messages.append(NolaChatMessage(role: .assistant, content: reply))
                    self.questionCount += 1
                    self.pendingRequest = nil
                    self.canRetry = false
                    self.isWaiting = false
                    if self.questionCount >= self.questionLimit {
                        self.isAwaitingFinalAnswer = true
                        self.statusMessage = "Answer this last one — then I’ll close our session."
                    }
                    self.persist()
                }
            } catch {
                await MainActor.run {
                    self.isWaiting = false
                    self.canRetry = true
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    private func requestClosing() {
        guard let key = VeniceKeychain.apiKey, !key.isEmpty else {
            needsAPIKey = true
            return
        }
        let requestMessages = messages
        let limitAtRequest = questionLimit
        pendingRequest = .closing
        canRetry = false
        isWaiting = true
        statusMessage = nil
        Task {
            do {
                let selectedModel = UserDefaults.standard.string(forKey: "nola.ai.chatModel") ?? VeniceClient.defaultChatModel
                let reply = try await VeniceClient.closing(
                    apiKey: key,
                    model: selectedModel,
                    messages: requestMessages,
                    questionLimit: limitAtRequest
                )
                await MainActor.run {
                    self.messages.append(NolaChatMessage(role: .assistant, content: reply))
                    self.pendingRequest = nil
                    self.canRetry = false
                    self.isWaiting = false
                    self.isAwaitingFinalAnswer = false
                    self.isSessionClosed = true
                    self.statusMessage = "Session complete."
                    self.archiveCurrentSession()
                }
            } catch {
                await MainActor.run {
                    self.isWaiting = false
                    self.canRetry = true
                    self.statusMessage = error.localizedDescription
                }
            }
        }
    }

    private func archiveCurrentSession() {
        guard !messages.isEmpty, !didArchiveCurrentSession else { return }
        didArchiveCurrentSession = true
        let startedAt = UserDefaults.standard.object(forKey: sessionStartedAtKey) as? Date
            ?? messages.first?.createdAt ?? Date()
        let defaults = UserDefaults.standard
        let sessionID = defaults.string(forKey: currentSessionIDKey)
            .flatMap { UUID(uuidString: $0) } ?? UUID()
        defaults.set(sessionID.uuidString, forKey: currentSessionIDKey)
        let session = NolaChatSession(
            id: sessionID,
            startedAt: startedAt,
            endedAt: messages.last?.createdAt ?? startedAt,
            messages: messages,
            questionCount: questionCount,
            isComplete: isSessionClosed,
            sessionType: currentSessionType.rawValue
        )
        history.insert(session, at: 0)
        if history.count > Self.historyLimit {
            history = Array(history.prefix(Self.historyLimit))
        }
        persist()
        persistHistory()
    }

    private func clearCurrentSession() {
        messages = []
        questionCount = 0
        isSessionClosed = false
        isAwaitingFinalAnswer = false
        statusMessage = nil
        pendingRequest = nil
        canRetry = false
        didArchiveCurrentSession = false
        currentSessionType = .daily
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: messagesKey)
        defaults.removeObject(forKey: questionCountKey)
        defaults.removeObject(forKey: sessionClosedKey)
        defaults.removeObject(forKey: awaitingFinalAnswerKey)
        defaults.removeObject(forKey: archivedKey)
        defaults.removeObject(forKey: currentSessionTypeKey)
        defaults.removeObject(forKey: sessionStartedAtKey)
        defaults.removeObject(forKey: currentSessionIDKey)
    }

    private func persist() {
        let defaults = UserDefaults.standard
        if let data = try? JSONEncoder().encode(messages) {
            defaults.set(data, forKey: messagesKey)
        }
        defaults.set(questionCount, forKey: questionCountKey)
        defaults.set(isSessionClosed, forKey: sessionClosedKey)
        defaults.set(isAwaitingFinalAnswer, forKey: awaitingFinalAnswerKey)
        defaults.set(didArchiveCurrentSession, forKey: archivedKey)
        defaults.set(currentSessionType.rawValue, forKey: currentSessionTypeKey)
    }

    private func persistHistory() {
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private static func localDateKey(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }

    private static func localWeekKey(_ date: Date) -> String {
        let components = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return String(format: "%04d-%02d", components.yearForWeekOfYear ?? 0, components.weekOfYear ?? 0)
    }
}

private struct GlassQuestionBadge: View {
    let count: Int
    let total: Int

    var body: some View {
        Text("\(count) / \(total)")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundColor(NolaTheme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule().fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.30), Color.white.opacity(0.0)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                    .overlay(Capsule().stroke(Color.white.opacity(0.45), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 2)
            )
    }
}

private struct ChatHistoryScreen: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var chat: NolaChatStore
    @State private var selected: NolaChatSession?
    @State private var showingClearConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if chat.history.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text("No past sessions yet")
                            .font(.system(size: 20, weight: .semibold, design: .serif))
                            .foregroundColor(NolaTheme.text)
                        Text("Past sessions will appear here.")
                            .font(.system(size: 14))
                            .foregroundColor(NolaTheme.secondaryText)
                    }
                    .padding(32)
                } else {
                    List {
                        ForEach(chat.history) { session in
                            Button { selected = session } label: {
                                HistoryRow(session: session)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) { chat.deleteHistory(session) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(NolaTheme.background)
            .navigationTitle("Chat history")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear", role: .destructive) { showingClearConfirmation = true }
                        .disabled(chat.history.isEmpty)
                }
            }
            .confirmationDialog("Clear all chat history?", isPresented: $showingClearConfirmation, titleVisibility: .visible) {
                Button("Clear History", role: .destructive) { chat.clearHistory() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Past sessions will be removed from this device. Your journal is not affected.")
            }
        }
        .navigationViewStyle(.stack)
        .sheet(item: $selected) { session in
            ChatTranscriptScreen(session: session)
        }
    }
}

private struct HistoryRow: View {
    let session: NolaChatSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.startedAt, formatter: Self.dateFormatter)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(NolaTheme.text)
                Spacer()
                Text("\(min(max(session.questionCount, 0), session.questionLimit)) / \(session.questionLimit) questions")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(NolaTheme.secondaryText)
            }
            Text(session.preview)
                .font(.system(size: 14))
                .foregroundColor(NolaTheme.secondaryText)
                .lineLimit(2)
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NolaTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(NolaTheme.cardBorder, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

private struct ChatTranscriptScreen: View {
    @Environment(\.presentationMode) private var presentationMode
    let session: NolaChatSession

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(session.messages) { message in
                        ChatBubble(message: message)
                    }
                }
                .padding(18)
            }
            .background(NolaTheme.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }
}

private enum VeniceClient {
    private static let baseURL = URL(string: "https://api.venice.ai/api/v1")!
    static let defaultChatModel = "e2ee-deepseek-v4-1-flash-1017-abliterated"
    static let defaultInsightsModel = "claude-opus-5-5"

    static func reply(apiKey: String, model: String, messages: [NolaChatMessage], context: String, openingQuestion: Bool, remainingQuestions: Int) async throws -> String {
        var apiMessages: [[String: String]] = [["role": "system", "content": systemPrompt(remainingQuestions: remainingQuestions)]]
        if openingQuestion {
            apiMessages.append(["role": "user", "content": openingQuestionPrompt(context: context)])
        } else {
            apiMessages += messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        }
        let primary = requestBody(model: model, messages: apiMessages, maxTokens: 1200, stripThinking: true, disableThinking: false)
        let object = try await complete(apiKey: apiKey, body: primary)
        if let content = content(from: object) { return content }

        // Reasoning models sometimes return an empty content block. Retry once
        // with thinking disabled so the user never has to send a second message.
        let fallback = requestBody(model: model, messages: apiMessages, maxTokens: 1200, stripThinking: true, disableThinking: true)
        let fallbackObject = try await complete(apiKey: apiKey, body: fallback)
        if let content = content(from: fallbackObject) { return content }
        throw VeniceError.invalidResponse
    }

    static func closing(apiKey: String, model: String, messages: [NolaChatMessage], questionLimit: Int) async throws -> String {
        var apiMessages: [[String: String]] = [["role": "system", "content": closingPrompt(questionLimit: questionLimit)]]
        apiMessages += messages.map { ["role": $0.role.rawValue, "content": $0.content] }
        let primary = requestBody(model: model, messages: apiMessages, maxTokens: 800, stripThinking: true, disableThinking: false)
        let object = try await complete(apiKey: apiKey, body: primary)
        if let content = content(from: object) { return content }

        let fallback = requestBody(model: model, messages: apiMessages, maxTokens: 800, stripThinking: true, disableThinking: true)
        let fallbackObject = try await complete(apiKey: apiKey, body: fallback)
        if let content = content(from: fallbackObject) { return content }
        throw VeniceError.invalidResponse
    }

    static func generateInsights(apiKey: String, context: String) async throws -> String {
        let prompt = """
        You are Nola's personal reflection analyst. Use only the supplied journal, mood, and memorable-moment records. Identify at most 3 genuinely useful observations or recommendations. Be specific and cite dates or short paraphrases as evidence. Separate observed facts from interpretations. Do not diagnose, invent patterns, moralize, or recommend productivity for its own sake. If there is insufficient evidence, say so. Keep the response clear and concise, with headings: "What I notice", "What it might mean", and "One thing to consider".
        """
        let messages: [[String: String]] = [
            ["role": "system", "content": prompt],
            ["role": "user", "content": context]
        ]
        let body = requestBody(model: defaultInsightsModel, messages: messages, maxTokens: 4096, stripThinking: true, disableThinking: false)
        let object = try await complete(apiKey: apiKey, body: body)
        guard let content = content(from: object) else { throw VeniceError.invalidResponse }
        return content
    }

    static func testConnection(apiKey: String) async throws -> String {
        let url = baseURL.appendingPathComponent("api_keys").appendingPathComponent("rate_limits")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 20
        request.setValue("Bearer \(normalizedKey(apiKey))", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VeniceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw makeHTTPError(status: http.statusCode, data: data)
        }
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let payload = object?["data"] as? [String: Any] ?? object ?? [:]
        if let permitted = payload["accessPermitted"] as? Bool, !permitted {
            throw VeniceError.requestFailed("Venice accepted the key, but this API key is not currently permitted to use inference. Check its limits and account balance.")
        }
        return "Connected. Venice accepted your API key."
    }

    private static func requestBody(model: String, messages: [[String: String]], maxTokens: Int, stripThinking: Bool, disableThinking: Bool) -> [String: Any] {
        [
            "model": model,
            "messages": messages,
            "temperature": 0.7,
            "max_tokens": maxTokens,
            "max_completion_tokens": maxTokens,
            "venice_parameters": [
                "strip_thinking_response": stripThinking,
                "disable_thinking": disableThinking
            ]
        ]
    }

    private static func complete(apiKey: String, body: [String: Any]) async throws -> [String: Any] {
        let url = baseURL.appendingPathComponent("chat").appendingPathComponent("completions")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 120
        request.setValue("Bearer \(normalizedKey(apiKey))", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw VeniceError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw makeHTTPError(status: http.statusCode, data: data)
        }
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw VeniceError.unexpectedResponse(rawSnippet(from: data) ?? "Venice returned data that wasn’t JSON.")
        }
        guard let dictionary = object as? [String: Any] else {
            throw VeniceError.unexpectedResponse(rawSnippet(from: data) ?? "Venice returned an unexpected response.")
        }
        if dictionary["choices"] == nil, let message = errorMessage(from: dictionary) {
            throw VeniceError.requestFailed(message)
        }
        return dictionary
    }

    private static func content(from object: [String: Any]) -> String? {
        guard let choices = object["choices"] as? [[String: Any]], let first = choices.first else { return nil }
        if let message = first["message"] as? [String: Any] {
            if let content = normalizedContent(message["content"]) { return content }
            if let content = normalizedContent(message["reasoning_content"]) { return content }
        }
        return normalizedContent(first["text"])
    }

    private static func normalizedContent(_ value: Any?) -> String? {
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? nil : trimmed
        }
        if let parts = value as? [[String: Any]] {
            let text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        }
        return nil
    }

    private static func errorMessage(from object: [String: Any]) -> String? {
        guard let error = object["error"] else { return nil }
        if let errorObject = error as? [String: Any] {
            return (errorObject["message"] as? String) ?? (errorObject["detail"] as? String) ?? (errorObject["code"] as? String) ?? (errorObject["type"] as? String)
        }
        return error as? String
    }

    private static func rawSnippet(from data: Data) -> String? {
        guard let string = String(data: data, encoding: .utf8) else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return String(trimmed.prefix(200))
    }

    private static func normalizedKey(_ raw: String) -> String {
        var key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.lowercased().hasPrefix("bearer ") {
            key = String(key.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return key
    }

    private static func makeHTTPError(status: Int, data: Data) -> VeniceError {
        let object = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        let detail = errorMessage(from: object ?? [:]) ?? rawSnippet(from: data)
        let fallback: String
        switch status {
        case 400:
            fallback = "Venice rejected this request (400). Check the model name and request format."
        case 401:
            fallback = "Venice rejected this API key (401). Check that it is a valid, active Inference API key and that it was copied completely."
        case 402:
            fallback = "Venice could not authorize paid inference (402). Check the account balance and this key's spending limits."
        case 403:
            fallback = "Venice denied this request (403). Check the key permissions and model access."
        case 404:
            fallback = "Venice could not find the requested model or endpoint (404)."
        case 429:
            fallback = "Venice rate limit reached (429). Wait a little and try again."
        default:
            fallback = "Venice returned HTTP \(status)."
        }
        return .requestFailed(detail.map { "\(fallback) Details: \($0)" } ?? fallback)
    }

    private static func openingQuestionPrompt(context: String) -> String {
        "Use only the following relevant local context. Ask one open-ended, interesting question that helps me notice a useful pattern. Do not mention the context source.\n\n\(context)"
    }

    private static func closingPrompt(questionLimit: Int) -> String {
        """
        You are Nola, a private guided-journaling companion. The user has just given their \(questionLimit)th and final answer, so this session is ending. Write one short closing of no more than 90 words, in plain prose with no headings or bullet points, containing:
        1. What you heard — briefly and accurately reflect the heart of what the user shared.
        2. The one tension worth sitting with — name a single tension, contradiction, or open loop you noticed, without resolving it.
        3. Either a question for the user to sit with themselves, or one small suggested offline action. Not a verdict, not advice, not a solution.
        Do not ask a new question that requires a reply. Do not label, diagnose, or judge the user. Do not give a verdict. Be warm, calm, and direct.
        """
    }

    private static func systemPrompt(remainingQuestions: Int) -> String {
        """
        You are Nola, a private guided-journaling companion. Help the user understand their situation and reach their own answer. Ask exactly one challenging, open-ended question. Keep it between 4 and 10 words. Be concise, honest, and specific to what they said. Look for blind spots, excuses, patterns, and limiting beliefs, but do not claim certainty. Do not give generic advice, lecture, agree just to agree, disagree just to disagree, or make decisions for the user. If they hand you a decision, return it with a short question about what they already believe or want. For difficult thoughts, remain calm and direct rather than preachy. If they clearly state immediate danger to themselves or someone else, briefly encourage urgent real-world support. Always reply with text, never an empty response. This session has \(remainingQuestions) AI question(s) remaining.
        """
    }
}

private enum VeniceError: LocalizedError {
    case invalidResponse
    case unexpectedResponse(String)
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse: return "Nola couldn’t read Venice’s response."
        case .unexpectedResponse(let detail): return "Nola couldn’t read Venice’s response. \(detail)"
        case .requestFailed(let message): return message
        }
    }
}

private enum VeniceKeychain {
    private static let service = "com.example.Nola.venice"
    private static let account = "apiKey"

    static var apiKey: String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecReturnData as String: true]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func save(_ key: String) throws {
        let data = Data(key.utf8)
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
        let attributes = query.merging([kSecValueData as String: data]) { _, new in new }
        guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else { throw VeniceError.requestFailed("Nola couldn’t securely save the Venice API key.") }
    }

    static func remove() {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account]
        SecItemDelete(query as CFDictionary)
    }
}

private struct VeniceSettingsScreen: View {
    @Environment(\.presentationMode) private var presentationMode
    @State private var apiKey = VeniceKeychain.apiKey ?? ""
    @AppStorage("nola.ai.chatModel") private var chatModel = VeniceClient.defaultChatModel
    @State private var errorMessage: String?
    @State private var connectionMessage: String?
    @State private var isTestingConnection = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Venice API key")) {
                    SecureField("Paste your API key", text: $apiKey)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                    Button {
                        testConnection()
                    } label: {
                        HStack {
                            Text("Test connection")
                            Spacer()
                            if isTestingConnection { ProgressView() }
                        }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTestingConnection)
                    if let connectionMessage = connectionMessage {
                        Text(connectionMessage)
                            .font(.system(size: 13))
                            .foregroundColor(connectionMessage.hasPrefix("Connected") ? .green : .red)
                    }
                    Text("Paste the key exactly as Venice issued it. Nola also removes an accidental “Bearer ” prefix and surrounding whitespace.")
                        .font(.system(size: 13))
                        .foregroundColor(NolaTheme.secondaryText)
                }

                Section(header: Text("Models")) {
                    Picker("Daily chat", selection: $chatModel) {
                        Text("DeepSeek V4.1 Flash 1017 Abliterated").tag(VeniceClient.defaultChatModel)
                        Text("DeepSeek V4.1 Flash 1017").tag("deepseek-v4-1-flash-1017")
                        Text("DeepSeek V4.1 Flash").tag("deepseek-v4-1-flash")
                    }
                    Text("Insights & Recommendations use Claude Opus 5.5.")
                        .font(.system(size: 13))
                        .foregroundColor(NolaTheme.secondaryText)
                }

                Section(header: Text("Privacy")) {
                    Text("Your API key is stored in iOS Keychain. When you chat, the conversation is sent to Venice. When you explicitly request AI insights, selected journal, mood, and moment records are sent to Claude Opus 5.5 through Venice. Claude Opus 5.5 is listed as anonymized, not private. Do not send anything you are not comfortable sharing with the provider.")
                        .font(.system(size: 13))
                        .foregroundColor(NolaTheme.secondaryText)
                }

                if VeniceKeychain.apiKey != nil {
                    Section {
                        Button("Remove API key", role: .destructive) {
                            VeniceKeychain.remove()
                            apiKey = ""
                            connectionMessage = "API key removed from this device."
                        }
                    }
                }
            }
            .navigationTitle("Venice connection")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Close") { presentationMode.wrappedValue.dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        do {
                            try VeniceKeychain.save(apiKey)
                            presentationMode.wrappedValue.dismiss()
                        } catch { errorMessage = error.localizedDescription }
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Couldn’t save API key", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { }
            } message: { Text(errorMessage ?? "") }
        }
        .navigationViewStyle(.stack)
    }

    private func testConnection() {
        isTestingConnection = true
        connectionMessage = nil
        Task {
            do {
                let result = try await VeniceClient.testConnection(apiKey: apiKey)
                await MainActor.run {
                    connectionMessage = result
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    connectionMessage = error.localizedDescription
                    isTestingConnection = false
                }
            }
        }
    }
}

private struct InsightsScreen: View {
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Insights")
                    .font(.system(size: 34, weight: .bold, design: .default))
                    .foregroundColor(NolaTheme.text)
                Spacer()
            }
            .padding(22)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(NolaTheme.background.ignoresSafeArea())
            .navigationBarHidden(true)
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
    @State private var showingVeniceSettings = false

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
                Section(header: Text("AI")) {
                    Button("Venice connection") { showingVeniceSettings = true }
                    Text(VeniceKeychain.apiKey == nil ? "Add your Venice API key to use Nola’s AI." : "Venice is configured on this device.")
                        .font(.system(size: 14))
                        .foregroundColor(NolaTheme.secondaryText)
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
        .sheet(isPresented: $showingVeniceSettings) {
            VeniceSettingsScreen()
        }
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
                VStack(alignment: .leading, spacing: 24) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Today")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(NolaTheme.text)
                        Spacer()
                        Text(selectedDate, formatter: Self.dayFormatter)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(NolaTheme.secondaryText)
                    }
                    dateCarousel
                    VStack(alignment: .leading, spacing: 25) {
                        moodSection
                        journalSection
                        memorableMomentsSection
                    }
                    .id(selectedDate)
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
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(datesInCarousel, id: \.self) { date in
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
                            .frame(width: 48, height: 58)
                            .background(isSelected ? NolaTheme.accentStrong : NolaTheme.surface.opacity(0.72))
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(isSelected ? Color.clear : NolaTheme.cardBorder.opacity(0.65), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        .disabled(isFuture)
                        .opacity(isFuture ? 0.42 : 1)
                        .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
                        .accessibilityAddTraits(isSelected ? .isSelected : [])
                        .id(date)
                    }
                }
                .padding(.horizontal, 1)
            }
            .onAppear {
                proxy.scrollTo(selectedDate, anchor: .center)
            }
            .onChange(of: selectedDate) { date in
                withAnimation(.easeOut(duration: 0.2)) {
                    proxy.scrollTo(date, anchor: .center)
                }
            }
        }
        .foregroundColor(NolaTheme.accent)
    }

    private var datesInCarousel: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let defaultStart = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        let recordDates = entries.map { calendar.startOfDay(for: $0.safeCreatedAt) }
            + moodEntries.map { calendar.startOfDay(for: $0.safeDate) }
            + moments.map { calendar.startOfDay(for: $0.safeDate) }
        let earliestRecord = recordDates.min() ?? defaultStart
        let start = [defaultStart, earliestRecord, selectedDate].min() ?? defaultStart
        let end = calendar.date(byAdding: .day, value: 7, to: today) ?? today
        let dayCount = max(0, calendar.dateComponents([.day], from: start, to: end).day ?? 0)
        return (0...dayCount).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
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
                    .font(.system(size: 18, weight: .semibold))
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
                    .font(.system(size: 18, weight: .semibold))
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
                    .font(.system(size: 18, weight: .semibold))
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
        formatter.dateFormat = "EEE, MMMM d"
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
    @ObservedObject var moment: MemorableMoment
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
    @State private var moment: MemorableMoment?
    @State private var lastSavedTitle = ""
    @State private var lastSavedContent = ""
    @State private var saveWorkItem: DispatchWorkItem?
    @State private var showingSaveError = false
    @State private var saveError = ""
    private let date: Date

    init(date: Date) {
        self.date = date
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasContent: Bool {
        !trimmedTitle.isEmpty || !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var hasUnsavedChanges: Bool {
        trimmedTitle != lastSavedTitle || content != lastSavedContent
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { finish() }
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .onChange(of: title) { _ in scheduleAutosave() }
            .onChange(of: content) { _ in scheduleAutosave() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                saveWorkItem?.cancel()
                saveDraft()
            }
            .onDisappear {
                saveWorkItem?.cancel()
                saveDraft()
            }
        }
        .navigationViewStyle(.stack)
        .alert("Couldn’t save moment", isPresented: $showingSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveError)
        }
    }

    private func scheduleAutosave() {
        guard hasContent || moment != nil else { return }
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { saveDraft() }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    private func finish() {
        saveWorkItem?.cancel()
        saveDraft()
        if !showingSaveError {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func saveDraft() {
        guard hasUnsavedChanges else { return }

        if !hasContent {
            guard let existing = moment else { return }
            context.delete(existing)
            do {
                if context.hasChanges { try context.save() }
                moment = nil
                lastSavedTitle = ""
                lastSavedContent = ""
                showingSaveError = false
            } catch {
                context.rollback()
                saveError = error.localizedDescription
                showingSaveError = true
            }
            return
        }

        let target: MemorableMoment
        if let existing = moment {
            target = existing
        } else {
            target = MemorableMoment(context: context)
            target.id = UUID()
            let now = Calendar.current.dateComponents([.hour, .minute, .second], from: Date())
            target.date = Calendar.current.date(
                bySettingHour: now.hour ?? 12,
                minute: now.minute ?? 0,
                second: now.second ?? 0,
                of: date
            ) ?? date
            moment = target
        }

        target.title = trimmedTitle
        target.content = content

        do {
            if context.hasChanges { try context.save() }
            lastSavedTitle = trimmedTitle
            lastSavedContent = content
            showingSaveError = false
        } catch {
            context.rollback()
            moment = nil
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
                        Text(searchText.isEmpty ? "No entries yet" : "No matching entries")
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
                            Label("Export all Nola data", systemImage: "square.and.arrow.up")
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
            defaultFilename: "Nola-Complete-Backup"
        ) { result in
            switch result {
            case .success:
                presentJournalAlert(title: "Backup exported", message: "Your backup includes journal entries, mood check-ins, memorable moments, saved Companion history and the current conversation, plus app preferences. Insights and feedback have no saved records in this build. Your Venice API key is not included.")
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
            let preferences = BackupAppPreferences(
                theme: UserDefaults.standard.string(forKey: "nola.theme") ?? "light",
                chatModel: UserDefaults.standard.string(forKey: "nola.ai.chatModel") ?? VeniceClient.defaultChatModel
            )
            let backup = try JournalBackup.make(
                from: context,
                companion: NolaChatStore.makeBackupSnapshot(),
                preferences: preferences
            )
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
            let importedChats = NolaChatStore.mergeBackup(backup.companion)
            NolaChatStore.applyBackupPreferences(backup.preferences)
            let chatSummary = importedChats == 0
                ? ""
                : " Also restored or merged \(importedChats) Companion session(s)."
            presentJournalAlert(title: "Backup imported", message: imported.summary + chatSummary)
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
    @ObservedObject var entry: JournalEntry

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
    @State private var didLoadExistingEntry = false
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
    private var hasUnsavedChanges: Bool { trimmedTitle != lastSavedTitle || content != lastSavedContent }

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
            .onAppear { loadLatestEntryIfNeeded() }
            .onChange(of: title) { _ in scheduleAutosave() }
            .onChange(of: content) { _ in scheduleAutosave() }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
                saveWorkItem?.cancel()
                saveDraft()
            }
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

    private func loadLatestEntryIfNeeded() {
        guard !didLoadExistingEntry else { return }
        didLoadExistingEntry = true

        // Today uses an eager VStack, so NavigationLink can construct this
        // destination before the user opens it. Refresh @State from Core Data
        // when the destination actually appears.
        guard let existing = entry else { return }
        let latestTitle = existing.safeTitle == "Untitled" ? "" : existing.safeTitle
        let latestContent = existing.safeContent
        title = latestTitle
        content = latestContent
        lastSavedTitle = latestTitle
        lastSavedContent = latestContent
    }
    private func close() {
        saveWorkItem?.cancel()
        saveDraft()
        if !showingSaveError {
            presentationMode.wrappedValue.dismiss()
        }
    }

    private func scheduleAutosave() {
        guard canSave || entry != nil else { return }
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { saveDraft() }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: workItem)
    }

    private func saveDraft() {
        guard (canSave || entry != nil), hasUnsavedChanges else { return }
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
        target.content = content
        target.updatedAt = Date()
        do {
            if context.hasChanges { try context.save() }
            lastSavedTitle = trimmedTitle
            lastSavedContent = content
            showingSaveError = false
        } catch {
            context.rollback()
            if isNewEntry { entry = nil }
            saveErrorMessage = error.localizedDescription
            showingSaveError = true
        }
    }
}


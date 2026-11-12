import SwiftUI
import CoreData

struct TodayView: View {
    @EnvironmentObject var navigation: AppNavigation
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TodayViewModel

    init() {
        _viewModel = StateObject(wrappedValue: TodayViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    quickActionsSection
                    recentEntriesSection
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Date().formatted())
                .font(.appDisplay)
                .foregroundColor(.appText)
            Text("A simple overview of your current day.")
                .font(.appSecondary)
                .foregroundColor(.appMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.appTitle)
                .foregroundColor(.appText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                QuickActionCard(
                    title: "Log Mood",
                    subtitle: "Record how you feel",
                    icon: "heart.fill",
                    color: .appAccent
                )
                QuickActionCard(
                    title: "Capture Moment",
                    subtitle: "Save a memory",
                    icon: "star.fill",
                    color: .appAccent
                )
                QuickActionCard(
                    title: "New Entry",
                    subtitle: "Write a journal entry",
                    icon: "square.and.pencil",
                    color: .appAccent
                )
                QuickActionCard(
                    title: "Brain Dump",
                    subtitle: "Unrestricted writing",
                    icon: "doc.on.doc",
                    color: .appAccent
                )
            }
        }
    }

    private var recentEntriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Entries")
                    .font(.appTitle)
                    .foregroundColor(.appText)
                Spacer()
                Button("View All") {
                    navigation.selectedTab = .journal
                }
                .font(.appMeta)
                .foregroundColor(.appAccent)
            }

            if viewModel.entries.isEmpty {
                EmptyEntriesView()
            } else {
                ForEach(viewModel.entries) { entry in
                    EntryRow(entry: entry)
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            Text(title)
                .font(.appBody)
                .foregroundColor(.appText)
            Text(subtitle)
                .font(.appMeta)
                .foregroundColor(.appMuted)
        }
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .padding()
        .background(Color.appSurface)
        .cornerRadius(16)
    }
}

struct EntryRow: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.safeTitle)
                .font(.appBody)
                .foregroundColor(.appText)
            Text(entry.safeContent)
                .font(.appSecondary)
                .foregroundColor(.appMuted)
                .lineLimit(2)
            Text(entry.safeCreatedAt.formattedRelative())
                .font(.appMeta)
                .foregroundColor(.appMuted)
        }
        .padding()
        .background(Color.appSurfaceRaised)
        .cornerRadius(12)
    }
}

struct EmptyEntriesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.appMuted)
            Text("No entries yet")
                .font(.appBody)
                .foregroundColor(.appText)
            Text("Create your first journal entry to get started.")
                .font(.appSecondary)
                .foregroundColor(.appMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.appSurface)
        .cornerRadius(16)
    }
}

struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
import SwiftUI
import CoreData

@main
struct NolaApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var navigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            TodayView()
                .environmentObject(appState)
                .environmentObject(navigation)
                .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
        }
    }
}
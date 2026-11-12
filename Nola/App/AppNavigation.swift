import SwiftUI

class AppNavigation: ObservableObject {
    @Published var selectedTab: Tab = .today

    enum Tab: String, CaseIterable, Identifiable {
        case today = "Today"
        case journal = "Journal"
        case aiCompanion = "AI Companion"
        case insights = "Insights"
        case settings = "Profile"

        var id: String { rawValue }
    }
}
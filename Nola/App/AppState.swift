import Foundation
import CoreData

class AppState: ObservableObject {
    @Published var isOnboardingComplete = false
    @Published var hasError = false
    @Published var errorMessage = ""

    let persistentContainer: NSPersistentContainer

    init() {
        self.persistentContainer = PersistenceController.shared.container
    }

    func presentError(_ message: String) {
        errorMessage = message
        hasError = true
    }

    func dismissError() {
        hasError = false
        errorMessage = ""
    }
}
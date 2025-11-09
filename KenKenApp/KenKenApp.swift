import SwiftUI

// Ensure PuzzleProvider and shared UI helpers are visible to the main target and tests.
// This fix addresses CI build errors where these symbols were not found on the runner.
@main
struct KenKenApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

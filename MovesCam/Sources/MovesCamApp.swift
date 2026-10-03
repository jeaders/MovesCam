import SwiftUI

@main
struct MovesCamApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(TitleBarWindowStyle())
        .windowResizability(.contentSize)
    }
}

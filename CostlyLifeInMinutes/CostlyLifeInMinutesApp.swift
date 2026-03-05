import SwiftUI

@main
struct CostlyLifeInMinutesApp: App {
    init() {
        SatoshiFont.registerFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

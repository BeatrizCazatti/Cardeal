import SwiftUI

@main
struct CardealApp: App {
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.defaultTheme.rawValue

    private var theme: AppTheme {
        AppTheme(storedValue: storedTheme)
    }

    var body: some Scene {
        WindowGroup {
            //TestView()
            DashboardView()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
        }
    }
}

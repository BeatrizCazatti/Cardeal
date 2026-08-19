import SwiftUI

@main
struct CardealApp: App {
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.violet.rawValue

    private var theme: AppTheme {
        AppTheme(rawValue: storedTheme) ?? .violet
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
        }
    }
}

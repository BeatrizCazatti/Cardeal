import SwiftUI

@main
struct CardealApp: App {
    @AppStorage(AppTheme.storageKey) private var storedTheme = AppTheme.defaultTheme.rawValue
    @AppStorage(InterfaceAppearance.storageKey) private var storedAppearance = InterfaceAppearance.system.rawValue

    private var theme: AppTheme {
        AppTheme(storedValue: storedTheme)
    }

    private var appearance: InterfaceAppearance {
        InterfaceAppearance(rawValue: storedAppearance) ?? .system
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
                .preferredColorScheme(appearance.colorScheme)
        }

        Window("Configurações", id: "settings") {
            SettingsWindow()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
                .preferredColorScheme(appearance.colorScheme)
        }
        .windowResizability(.contentMinSize)
        .commands {
            // Mantém ⌘, como atalho padrão para abrir Configurações
            CommandGroup(after: .appSettings) {
                Button("Configurações…") {
                    NSApp.sendAction(
                        Selector(("showSettingsWindow:")),
                        to: nil,
                        from: nil
                    )
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
}

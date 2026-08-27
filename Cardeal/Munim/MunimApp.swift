import SwiftUI

@main
struct MunimApp: App {
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
//                .preferredColorScheme(appearance.colorScheme)
                // Teto de Dynamic Type no accessibility2: garante que a escala
                // do texto respeita preferência do usuário sem estourar layouts
                // fixos (cards do board, cápsula do botão "Novo item", chips).
                .dynamicTypeSize(.medium ... .accessibility2)
        }

        Window("Configurações", id: "settings") {
            SettingsWindow()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
//                .preferredColorScheme(appearance.colorScheme)
                .dynamicTypeSize(.medium ... .accessibility2)
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

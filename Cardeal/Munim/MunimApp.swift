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
            AppFlowView()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
                .preferredColorScheme(appearance.colorScheme)
                // A base `large` melhora a legibilidade sem alterar a
                // hierarquia semântica dos estilos. Preferências maiores do
                // usuário continuam válidas até accessibility2.
                .dynamicTypeSize(.large ... .accessibility2)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        Window("Configurações", id: "settings") {
            SettingsWindow()
                .environment(\.appTheme, theme)
                .tint(theme.accentColor)
//                .preferredColorScheme(appearance.colorScheme)
                .dynamicTypeSize(.large ... .accessibility2)
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

private struct AppFlowView: View {
    private enum Screen: Equatable {
        case onboarding
        case loading
        case ready
        case dashboard
    }

//    @State private var screen: Screen = .onboarding
    @State private var screen: Screen = .dashboard


    var body: some View {
        Group {
            switch screen {
            case .onboarding:
                OnboardingView {
                    screen = .loading
                }
            case .loading:
                LoadingView {
                    screen = .ready
                }
            case .ready:
                ReadySuccessView {
                    screen = .dashboard
                }
            case .dashboard:
                DashboardView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: screen)
    }
}

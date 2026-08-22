import SwiftUI

/// Temas disponíveis para o aplicativo. Cada tema aponta somente para tokens
/// semânticos do catálogo de assets, mantendo a mudança de paleta centralizada.
enum AppTheme: String, CaseIterable, Identifiable {
    case standard
    case ocean
    case nature

    static let storageKey = "appTheme"
    static let defaultTheme: Self = .standard

    var id: String { rawValue }

    init(storedValue: String) {
        switch storedValue {
        case Self.ocean.rawValue, "blue": self = .ocean
        case Self.nature.rawValue, "green": self = .nature
        case Self.standard.rawValue, "violet": self = .standard
        default: self = Self.defaultTheme
        }
    }

    var accentColor: Color {
        switch self {
        case .standard: Color.Token.themeStandardAccent
        case .ocean: Color.Token.themeOceanAccent
        case .nature: Color.Token.themeNatureAccent
        }
    }

    /// Cor difusa central do cabeçalho do modal de detalhes da equipe.
    var modalGlowColor: Color {
        accentColor.opacity(0.52)
    }

    /// Cor suave na borda oposta, criando profundidade sem prejudicar a leitura.
    var modalEdgeColor: Color {
        accentColor.opacity(0.18)
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .defaultTheme
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

/// Fundo do cabeçalho do modal de equipe. A combinação de gradiente linear e
/// radial reproduz a transição luminosa da referência sem depender de imagens.
struct TeamDetailHeaderBackground: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.Token.surfaceRaised, theme.modalEdgeColor],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            RadialGradient(
                colors: [theme.modalGlowColor, .clear],
                center: UnitPoint(x: 0.36, y: 1.0),
                startRadius: 12,
                endRadius: 440
            )
        }
        .accessibilityHidden(true)
    }
}

extension Color {
    /// Tokens de cor semânticos. Os nomes do asset existem somente aqui,
    /// eliminando strings repetidas e erros de digitação nas views.
    enum Token {
        static let backgroundPrimary = Color("Background/Primary")
        static let borderSubtle = Color("Border/Subtle")
        static let textPrimary = Color("Text/Primary")
        static let textSecondary = Color("Text/Secondary")
        static let textBrand = Color("Text/Brand")
        static let textNavigation = Color("Text/Navigation")
        static let textOnAccent = Color("Text/OnAccent")
        static let interactiveAccent = Color("Interactive/Accent")
        static let surfaceRaised = Color("Surface/Raised")
        static let surfaceAttention = Color("Surface/Attention")
        static let iconAccent = Color("Icon/Accent")
        static let statusAttention = Color("Status/Attention")
        static let statusNotification = Color("Status/Notification")
        static let statusSuccess = Color("Status/Success")
        static let statusWarning = Color("Status/Warning")
        static let themeStandardAccent = Color("Theme/Standard/Accent")
        static let themeOceanAccent = Color("Theme/Ocean/Accent")
        static let themeNatureAccent = Color("Theme/Nature/Accent")
    }
}

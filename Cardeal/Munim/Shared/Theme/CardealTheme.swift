import SwiftUI

/// Temas disponíveis para o aplicativo. Cada tema aponta somente para tokens
/// semânticos do catálogo de assets, mantendo a mudança de paleta centralizada.
enum AppTheme: String, CaseIterable, Identifiable {
    case standard
    case ocean
    case nature

    static let storageKey = "appTheme"
    static let defaultTheme: Self = .ocean

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

    /// Paleta integral dos gradientes definidos no layout. As mesmas cores
    /// delimitam o Dashboard e compõem o cabeçalho do detalhe da equipe.
    var gradientColors: [Color] {
        switch self {
        case .ocean:
            [
                Color(hex: 0x1148D1).opacity(0.5),
                Color(hex: 0xB3FC2E).opacity(0.5),
                Color(hex: 0xD8F295).opacity(0.5),
                Color(hex: 0xFAFF73).opacity(0.5)
            ]
        case .nature:
            [
                Color(hex: 0xFF865C).opacity(0.5),
                Color(hex: 0xFF95CC).opacity(0.5),
                Color(hex: 0xFFA875).opacity(0.5),
                Color(hex: 0xFFD66D).opacity(0.5)
            ]
        case .standard:
            [
                Color(hex: 0x3A1ACB).opacity(0.5),
                Color(hex: 0x6BA4FF).opacity(0.5),
                Color(hex: 0x95B6FF).opacity(0.5),
                Color(hex: 0xD8AFEA).opacity(0.5),
                Color(hex: 0xFF4CDB).opacity(0.5)
            ]
        }
    }

    /// Cores exclusivas dos cards recém-criados, visíveis até a revisão.
    var newCardFillColor: Color {
        switch self {
        case .ocean: Color(hex: 0xEEFFD4)
        case .nature: Color(hex: 0xFFF7E9)
        case .standard: Color(hex: 0xEFEBFF)
        }
    }

    var newCardStrokeColor: Color {
        switch self {
        case .ocean: Color(hex: 0x75BC08)
        case .nature: Color(hex: 0xFF9365)
        case .standard: Color(hex: 0x361AA8)
        }
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

/// Gradiente multicolorido do layout. Ele é reutilizado em todos os pontos
/// onde a identidade do tema aparece, mantendo a transição coerente.
struct ThemeGradientBackground: View {
    let theme: AppTheme

    var body: some View {
        LinearGradient(
            colors: theme.gradientColors,
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
        .accessibilityHidden(true)
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: 1
        )
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

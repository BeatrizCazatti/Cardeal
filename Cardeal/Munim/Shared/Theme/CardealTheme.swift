import SwiftUI

/// Temas disponíveis para o aplicativo. Cada tema aponta somente para tokens
/// semânticos do catálogo de assets, mantendo a mudança de paleta centralizada.
enum AppTheme: String, CaseIterable, Identifiable {
    case plum
    case munim
    case peach
    case blueberry

    static let storageKey = "appTheme"
    static let defaultTheme: Self = .blueberry

    var id: String { rawValue }

    /// Nome exibido na interface (Configurações → Aparência).
    var title: String {
        switch self {
        case .munim: "Munim"
        case .peach: "Peach"
        case .plum: "Plum"
        case .blueberry: "Blueberry"
        }
    }

    init(storedValue: String) {
        switch storedValue {
        case Self.munim.rawValue, "blue": self = .munim
        case Self.peach.rawValue, "green": self = .peach
        case Self.plum.rawValue, "violet": self = .plum
        case Self.blueberry.rawValue: self = .blueberry
        default: self = Self.defaultTheme
        }
    }

    var accentColor: Color {
        switch self {
        case .plum: Color.Token.themePlumAccent
        case .munim: Color.Token.themeMunimAccent
        case .peach: Color.Token.themePeachAccent
        case .blueberry: Color.Token.themeBlueberryAccent
        }
    }

    /// Paleta integral dos gradientes definidos no layout. As mesmas cores
    /// delimitam o Dashboard e compõem o cabeçalho do detalhe da equipe.
    var gradientColors: [Color] {
        switch self {
        case .munim:
            [
                Color(hex: 0x1148D1).opacity(0.5),
                Color(hex: 0xB3FC2E).opacity(0.5),
                Color(hex: 0xD8F295).opacity(0.5),
                Color(hex: 0xFAFF73).opacity(0.5)
            ]
        case .peach:
            [
                Color(hex: 0xFF865C).opacity(0.5),
                Color(hex: 0xFF95CC).opacity(0.5),
                Color(hex: 0xFFA875).opacity(0.5),
                Color(hex: 0xFFD66D).opacity(0.5)
            ]
        case .plum:
            [
                Color(hex: 0x3A1ACB).opacity(0.5),
                Color(hex: 0x6BA4FF).opacity(0.5),
                Color(hex: 0x95B6FF).opacity(0.5),
                Color(hex: 0xD8AFEA).opacity(0.5),
                Color(hex: 0xFF4CDB).opacity(0.5)
            ]
        case .blueberry:
            [
                Color(hex: 0x3B82F6).opacity(0.5),
                Color(hex: 0xADCCFD).opacity(0.5),
                Color(hex: 0x8DABF4).opacity(0.5),
                Color(hex: 0xC7D2FE).opacity(0.5),
                Color(hex: 0xE0E7FF).opacity(0.5)
            ]
        }
    }

    /// Cores exclusivas dos cards recém-criados, visíveis até a revisão.
    var newCardFillColor: Color {
        switch self {
        case .munim: Color(hex: 0xEEFFD4)
        case .peach: Color(hex: 0xFFF7E9)
        case .plum: Color(hex: 0xEFEBFF)
        case .blueberry: Color(hex: 0xF1FBFF)
        }
    }

    var newCardStrokeColor: Color {
        switch self {
        case .munim: Color(hex: 0x75BC08)
        case .peach: Color(hex: 0xFF9365)
        case .plum: Color(hex: 0x361AA8)
        case .blueberry: Color(hex: 0x8DABF4)
        }
    }

    /// Ícone de pasta usado no módulo de anexos.
    var attachmentFolderImage: Image {
        switch self {
        case .munim: Image(.munimFolder)
        case .peach: Image(.peachFolder)
        case .plum: Image(.plumFolder)
        case .blueberry: Image(.blueberryFolder)
        }
    }

    
    var calendar: Color {
        switch self {
        case .munim: Color(hex: 0x4973DF)
        case .peach: Color(hex: 0xC25744)
        case .plum: Color(hex: 0x523BB2)
        case .blueberry: Color(hex: 0x4973DF)
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
        static let themePlumAccent = Color("Theme/Plum/Accent")
        static let themeMunimAccent = Color("Theme/Munim/Accent")
        static let themePeachAccent = Color("Theme/Peach/Accent")
        static let themeBlueberryAccent = Color("Theme/Blueberry/Accent")
    }
}

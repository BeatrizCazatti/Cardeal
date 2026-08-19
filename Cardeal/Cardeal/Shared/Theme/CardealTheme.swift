import SwiftUI

/// Paletas disponíveis para o aplicativo. Novos temas devem ser adicionados
/// aqui, mantendo a cor de destaque e o tratamento visual das superfícies no
/// mesmo lugar.
enum AppTheme: String, CaseIterable, Identifiable {
    case violet
    case blue
    case green

    static let storageKey = "appTheme"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .violet: .cardealPurple
        case .blue: .cardealBlue
        case .green: .cardealGreen
        }
    }

    /// Cor difusa central do cabeçalho do modal de detalhes da equipe.
    var modalGlowColor: Color {
        switch self {
        case .violet: Color(red: 0.78, green: 0.70, blue: 0.98)
        case .blue: Color(red: 0.61, green: 0.77, blue: 0.98)
        case .green: Color(red: 0.62, green: 0.88, blue: 0.76)
        }
    }

    /// Cor suave na borda oposta, criando profundidade sem prejudicar a leitura.
    var modalEdgeColor: Color {
        switch self {
        case .violet: Color(red: 0.81, green: 0.89, blue: 1.0)
        case .blue: Color(red: 0.74, green: 0.88, blue: 1.0)
        case .green: Color(red: 0.78, green: 0.95, blue: 0.87)
        }
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .violet
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
                colors: [.white, theme.modalEdgeColor.opacity(0.58)],
                startPoint: .bottomLeading,
                endPoint: .topTrailing
            )

            RadialGradient(
                colors: [theme.modalGlowColor.opacity(0.52), .clear],
                center: UnitPoint(x: 0.36, y: 1.0),
                startRadius: 12,
                endRadius: 440
            )
        }
        .accessibilityHidden(true)
    }
}

extension Color {
    static let cardealBlue = Color(red: 0.16, green: 0.43, blue: 0.89)
    static let cardealPurple = Color(red: 0.36, green: 0.24, blue: 0.82)
    static let cardealGreen = Color(red: 0.04, green: 0.55, blue: 0.41)
    static let cardealOrange = Color(red: 0.88, green: 0.39, blue: 0.13)
    static let cardealPink = Color(red: 0.94, green: 0.86, blue: 0.99)
    static let cardealInk = Color(red: 0.12, green: 0.13, blue: 0.18)
    static let cardealMuted = Color(red: 0.42, green: 0.44, blue: 0.51)
    static let cardealLine = Color(red: 0.89, green: 0.90, blue: 0.93)
    static let cardealCanvas = Color(red: 0.975, green: 0.975, blue: 0.985)
}

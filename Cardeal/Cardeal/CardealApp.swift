import SwiftUI

@main
struct CardealApp: App {
    var body: some Scene {
        WindowGroup {
            //TesteView()
            DashboardView()
        }
    }
}

//@main
//struct MeuApp: App {
//    // Permite que o usuário escolha a cor ou use nil para a cor do sistema
//    @AppStorage("accentThemeColor") private var selectedTheme: CustomTheme = .yellow
//
//    var body: some Scene {
//        WindowGroup {
//            ContentView()
//                // Aplica a cor de destaque em toda a hierarquia de views
//                .tint(selectedTheme.color)
//        }
//    }
//}
//
//enum CustomTheme: String, CaseIterable, Identifiable {
//    case system, yellow, blue, green, orange
//    
//    var id: String { rawValue }
//    
//    var color: Color? {
//        switch self {
//        case .system: return nil // Respeita a cor definida nas Configurações do Mac
//        case .yellow: return .yellow
//        case .blue: return .blue
//        case .green: return .green
//        case .orange: return .orange
//        }
//    }
//}

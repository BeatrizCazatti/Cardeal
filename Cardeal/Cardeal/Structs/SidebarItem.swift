import SwiftUI

/// Item de navegação da sidebar recolhível.
struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
}

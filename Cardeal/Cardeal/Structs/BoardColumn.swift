import SwiftUI

/// Uma coluna do board (ex.: "Atendimento", "Design"...).
struct BoardColumn: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let items: [BoardItem]
}

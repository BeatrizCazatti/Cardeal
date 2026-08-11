
import SwiftUI


/// Uma aba de filtro no topo (ex.: "Geral", "Reuniões"...), com contador.
struct FilterTab: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let count: Int
}

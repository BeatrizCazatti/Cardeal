import SwiftUI

/// Uma pessoa (ou grupo) atribuída a um item do board.
struct Assignee: Identifiable, Hashable {
    let id = UUID()
    let name: String
    /// Se `true`, usa o símbolo "person.2.fill" (grupo). Caso contrário, "person.fill".
    let isGroup: Bool
}

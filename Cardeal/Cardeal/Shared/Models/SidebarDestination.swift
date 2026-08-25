import SwiftUI

enum SidebarDestination: Hashable {
    case dashboard
    case archived
    case deleted
    case attachments
}

struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
}

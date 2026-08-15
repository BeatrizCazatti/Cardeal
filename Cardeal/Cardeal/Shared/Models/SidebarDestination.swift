import SwiftUI

enum SidebarDestination: Hashable {
    case dashboard
    case attachments
}

struct SidebarItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let systemImage: String
}

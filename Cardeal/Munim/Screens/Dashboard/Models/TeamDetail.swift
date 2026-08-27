import Foundation

/// Dados exibidos na folha de detalhes de uma equipe do dashboard.
struct TeamDetail: Identifiable {
    var id: String { name }
    let name: String
    let members: [TeamMember]
    let timeline: [TeamActivity]
}

struct TeamMember: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let role: String
    let email: String
    let hiredDate: String
    let relatedProjects: [String]
    let recentActivities: [String]

    var initials: String {
        name
            .split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }
}

struct TeamActivity: Identifiable {
    let id = UUID()
    let category: TeamActivityCategory
    let title: String
    let detail: String
    let date: String
    let participants: [String]
}

enum TeamActivityCategory: String {
    case decision = "Decisão"
    case task = "Tarefa"
    case meeting = "Reunião"

    var systemImage: String {
        switch self {
        case .decision: "arrow.triangle.branch"
        case .task: "checkmark.circle"
        case .meeting: "person.2"
        }
    }
}

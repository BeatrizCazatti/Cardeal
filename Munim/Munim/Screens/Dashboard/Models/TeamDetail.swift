import Foundation

/// Dados exibidos na folha de detalhes de uma equipe do dashboard.
struct TeamDetail: Identifiable {
    var id: String { name }
    let name: String
    let members: [TeamMember]
    let timeline: [TeamActivity]

    init(
        name: String,
        members: [TeamMember],
        timeline: [TeamActivity]
    ) {
        self.name = name
        self.members = members
        self.timeline = timeline
    }

    init(
        column: BoardColumn,
        people: [PersonDTO] = []
    ) {
        self.name = column.title

        let teamID = column.id
        // Filtrar pessoas cujo teamID é o deste time OU que aparecem como responsáveis/participantes nos cards deste time
        let teamMemberNames = Set(column.items.flatMap { $0.assignees.map(\.name) })
        let teamPeople = people.filter { p in
            p.teamID == teamID || teamMemberNames.contains(p.name)
        }

        self.members = teamPeople.map { p in
            TeamMember(
                name: p.name,
                role: p.jobTitle.isEmpty ? "Membro da equipe" : p.jobTitle,
                email: p.email ?? "",
                hiredDate: "Ativo",
                relatedProjects: [],
                recentActivities: []
            )
        }

        self.timeline = column.items.map { item in
            let cat: TeamActivityCategory
            switch item.category {
            case .meeting: cat = .meeting
            case .task: cat = .task
            case .decision: cat = .decision
            case .change: cat = .task
            }
            return TeamActivity(
                category: cat,
                title: item.title,
                detail: item.descriptionText ?? item.location ?? "",
                date: item.dateText ?? "Recente",
                participants: item.assignees.map(\.name)
            )
        }
    }
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

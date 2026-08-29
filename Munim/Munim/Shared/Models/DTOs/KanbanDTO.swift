import Foundation

// MARK: - Kanban & Team Board DTOs
// Espelha os endpoints de agregação do backend.

struct KanbanBoardDTO: Decodable {
    let team: UUID?
    let project: UUID?
    let columns: [KanbanColumnDTO]
}

struct KanbanColumnDTO: Decodable {
    let status: String
    let tasks: [TaskDTO]
}

// MARK: - DTOs de Análise de IA

struct AnalyzeRequest: Encodable {
    let question: String?
}

struct AIAnalysisDTO: Decodable {
    let id: UUID?
    let type: String
    let prompt: String?
    let content: String
    let createdAt: Date?
}

// MARK: - TeamBoardBuilder
// Construtor do quadro por EQUIPES / TIMES reais do Workspace.
// Organiza as Tarefas, Reuniões, Decisões e Mudanças em colunas correspondentes
// a cada time identificado pela IA e pelo Directory do Google Workspace.

enum TeamBoardBuilder {
    static func buildColumns(
        teams: [TeamDTO],
        people: [PersonDTO],
        tasks: [TaskDTO],
        meetings: [MeetingDTO],
        decisions: [DecisionDTO],
        changes: [ChangeDTO]
    ) -> [BoardColumn] {
        var columns: [BoardColumn] = []

        let peopleByID = Dictionary(uniqueKeysWithValues: people.compactMap { p in p.id.map { ($0, p) } })

        // 1. Criar uma coluna para cada time real cadastrado no backend
        for team in teams {
            guard let teamID = team.id else { continue }
            let teamNameLower = team.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            var items: [BoardItem] = []

            // A) Tarefas: por teamID, por responsável, ou por menção ao time no título/descrição
            let teamTasks = tasks.filter { task in
                if task.team == teamID { return true }
                if let ownerID = task.owner, let person = peopleByID[ownerID], person.teamID == teamID {
                    return true
                }
                if !teamNameLower.isEmpty && (
                    task.title.lowercased().contains(teamNameLower) ||
                    task.description.lowercased().contains(teamNameLower)
                ) {
                    return true
                }
                return false
            }
            items.append(contentsOf: teamTasks.map { $0.toBoardItem(people: people, teams: teams) })

            // B) Reuniões: por participantes do time OU por menção ao time no título/pauta
            let teamMeetings = meetings.filter { meeting in
                let hasParticipant = meeting.participants.contains { participantID in
                    peopleByID[participantID]?.teamID == teamID
                }
                if hasParticipant { return true }
                if !teamNameLower.isEmpty && (
                    meeting.title.lowercased().contains(teamNameLower) ||
                    (meeting.agenda?.lowercased().contains(teamNameLower) ?? false)
                ) {
                    return true
                }
                return false
            }
            items.append(contentsOf: teamMeetings.map { $0.toBoardItem(people: people, team: team) })

            // C) Decisões: por pessoas vinculadas OU por menção ao time no resumo/justificativa
            let teamDecisions = decisions.filter { decision in
                let hasPerson = decision.people.contains { personID in
                    peopleByID[personID]?.teamID == teamID
                }
                if hasPerson { return true }
                if !teamNameLower.isEmpty && (
                    decision.summary.lowercased().contains(teamNameLower) ||
                    decision.rationale.lowercased().contains(teamNameLower)
                ) {
                    return true
                }
                return false
            }
            items.append(contentsOf: teamDecisions.map { $0.toBoardItem(allPeople: people, team: team) })

            // D) Mudanças: por projeto associado OU por menção ao time na descrição
            let teamChanges = changes.filter { change in
                if let relatedProject = team.relatedProject, change.relatedProject == relatedProject {
                    return true
                }
                if !teamNameLower.isEmpty && change.description.lowercased().contains(teamNameLower) {
                    return true
                }
                return false
            }
            items.append(contentsOf: teamChanges.map { $0.toBoardItem(team: team) })

            columns.append(BoardColumn(id: teamID, title: team.name, items: items))
        }

        // 2. Coletar itens que não pertencem a nenhuma equipe específica
        let allTeamNames = teams.map { $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }.filter { !$0.isEmpty }

        let unassignedTasks = tasks.filter { task in
            task.team == nil &&
            (task.owner == nil || peopleByID[task.owner!]?.teamID == nil) &&
            !allTeamNames.contains { task.title.lowercased().contains($0) || task.description.lowercased().contains($0) }
        }

        let unassignedMeetings = meetings.filter { meeting in
            !meeting.participants.contains { peopleByID[$0]?.teamID != nil } &&
            !allTeamNames.contains {
                meeting.title.lowercased().contains($0) || (meeting.agenda?.lowercased().contains($0) ?? false)
            }
        }

        let unassignedDecisions = decisions.filter { decision in
            !decision.people.contains { peopleByID[$0]?.teamID != nil } &&
            !allTeamNames.contains {
                decision.summary.lowercased().contains($0) || decision.rationale.lowercased().contains($0)
            }
        }

        var unassignedItems: [BoardItem] = []
        unassignedItems.append(contentsOf: unassignedTasks.map { $0.toBoardItem(people: people, teams: teams) })
        let fallbackTeam = TeamDTO(name: "Geral")
        unassignedItems.append(contentsOf: unassignedMeetings.map { $0.toBoardItem(people: people, team: fallbackTeam) })
        unassignedItems.append(contentsOf: unassignedDecisions.map { $0.toBoardItem(allPeople: people, team: fallbackTeam) })

        // Só adicionar a coluna "Geral" se houver de fato itens sem time
        if !unassignedItems.isEmpty {
            if let generalIdx = columns.firstIndex(where: { $0.title.lowercased() == "geral" }) {
                columns[generalIdx].items.append(contentsOf: unassignedItems)
            } else {
                columns.append(BoardColumn(title: "Geral", items: unassignedItems))
            }
        }

        return columns
    }
}

// MARK: - Mapeamento de DTOs para BoardItem

extension TaskDTO {
    func toBoardItem(people: [PersonDTO], teams: [TeamDTO]) -> BoardItem {
        let ownerName: String?
        if let ownerID = owner,
           let person = people.first(where: { $0.id == ownerID }) {
            ownerName = person.name
        } else {
            ownerName = nil
        }

        let teamName: String?
        if let teamID = team,
           let t = teams.first(where: { $0.id == teamID }) {
            teamName = t.name
        } else {
            teamName = nil
        }

        var assignees: [Assignee] = []
        if let name = ownerName {
            if let tName = teamName {
                assignees.append(Assignee(name: "\(name) & \(tName)", isGroup: true))
            } else {
                assignees.append(Assignee(name: name, isGroup: false))
            }
        } else if let tName = teamName {
            assignees.append(Assignee(name: tName, isGroup: true))
        }

        let dateText: String?
        if let dl = deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "pt_BR")
            dateText = formatter.string(from: dl)
        } else {
            dateText = nil
        }

        let mappedPriority: BoardItemPriority
        switch priority.lowercased() {
        case "critical", "high": mappedPriority = .high
        case "medium":           mappedPriority = .medium
        case "low":              mappedPriority = .low
        default:                 mappedPriority = .unset
        }

        let mappedCategory: DashboardItemCategory
        switch origin?.lowercased() {
        case "meeting":  mappedCategory = .meeting
        case "decision": mappedCategory = .decision
        case "change":   mappedCategory = .change
        default:         mappedCategory = .task
        }

        let persistentKey = id?.uuidString ?? "task_\(title)"
        let isReviewed = ReviewedItemsStore.shared.isReviewed(id: persistentKey)

        return BoardItem(
            id: id ?? UUID(),
            persistentKey: persistentKey,
            title: title,
            badgeCount: isReviewed ? nil : 1,
            assignees: assignees.isEmpty
                ? [Assignee(name: teamName ?? "Equipe", isGroup: true)]
                : assignees,
            rawDate: deadline,
            dateText: dateText,
            location: modality,
            descriptionText: description.isEmpty ? nil : description,
            priority: mappedPriority,
            category: mappedCategory
        )
    }
}

extension MeetingDTO {
    func toBoardItem(people: [PersonDTO], team: TeamDTO) -> BoardItem {
        let peopleByID = Dictionary(uniqueKeysWithValues: people.compactMap { p in p.id.map { ($0, p) } })
        let participantNames = participants.compactMap { peopleByID[$0]?.name }

        var assignees: [Assignee] = []
        if let leadName = participantNames.first {
            if participantNames.count > 1 {
                assignees.append(Assignee(name: "\(leadName) & \(team.name)", isGroup: true))
            } else {
                assignees.append(Assignee(name: leadName, isGroup: false))
            }
        } else {
            assignees.append(Assignee(name: team.name, isGroup: true))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"
        let dateStr = formatter.string(from: date)
        let dateText = "\(dateStr) - \(time)"

        let persistentKey = id?.uuidString ?? "meeting_\(title)"
        let isReviewed = ReviewedItemsStore.shared.isReviewed(id: persistentKey)

        return BoardItem(
            id: id ?? UUID(),
            persistentKey: persistentKey,
            title: title,
            badgeCount: isReviewed ? nil : 1,
            assignees: assignees,
            rawDate: date,
            dateText: dateText,
            location: location ?? meetingType,
            descriptionText: agenda,
            priority: .high,
            category: .meeting
        )
    }
}

extension DecisionDTO {
    func toBoardItem(allPeople: [PersonDTO], team: TeamDTO) -> BoardItem {
        let peopleByID = Dictionary(uniqueKeysWithValues: allPeople.compactMap { p in p.id.map { ($0, p) } })
        let personNames = people.compactMap { peopleByID[$0]?.name }

        var assignees: [Assignee] = []
        if let first = personNames.first {
            assignees.append(Assignee(name: "\(first) & \(team.name)", isGroup: true))
        } else {
            assignees.append(Assignee(name: team.name, isGroup: true))
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"

        let persistentKey = id?.uuidString ?? "decision_\(summary)"
        let isReviewed = ReviewedItemsStore.shared.isReviewed(id: persistentKey)

        return BoardItem(
            id: id ?? UUID(),
            persistentKey: persistentKey,
            title: summary,
            badgeCount: isReviewed ? nil : 1,
            assignees: assignees,
            rawDate: date,
            dateText: formatter.string(from: date),
            descriptionText: rationale,
            priority: .medium,
            category: .decision
        )
    }
}

extension ChangeDTO {
    func toBoardItem(team: TeamDTO) -> BoardItem {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "dd/MM"

        let persistentKey = id?.uuidString ?? "change_\(description)"
        let isReviewed = ReviewedItemsStore.shared.isReviewed(id: persistentKey)

        return BoardItem(
            id: id ?? UUID(),
            persistentKey: persistentKey,
            title: description,
            badgeCount: isReviewed ? nil : 1,
            assignees: [Assignee(name: team.name, isGroup: true)],
            rawDate: date,
            dateText: formatter.string(from: date),
            isRescheduled: changeType.lowercased().contains("reschedul") || changeType.lowercased().contains("data"),
            location: changeType,
            priority: .medium,
            category: .change
        )
    }
}

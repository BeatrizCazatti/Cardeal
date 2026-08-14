import SwiftUI

enum WorkspaceSection: String, CaseIterable, Identifiable {
    case overview = "Visão geral", memories = "Memória", projects = "Projetos"
    case actions = "Ações", documents = "Documentos", settings = "Configurações"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .overview: return "square.grid.2x2"
        case .memories: return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .projects: return "folder"
        case .actions: return "checklist"
        case .documents: return "doc.text"
        case .settings: return "gearshape"
        }
    }
}

enum MemoryKind: String, CaseIterable, Identifiable, Codable {
    case decision = "Decisão", conversation = "Conversa"
    case document = "Documento", event = "Acontecimento"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .decision: return "arrow.triangle.branch"
        case .conversation: return "bubble.left.and.bubble.right"
        case .document: return "doc.text"
        case .event: return "flag"
        }
    }

    var color: Color {
        switch self {
        case .decision: return .cardealPurple
        case .conversation: return .cardealGreen
        case .document: return .cardealBlue
        case .event: return .cardealOrange
        }
    }
}

struct MemoryItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let detail: String
    let kind: MemoryKind
    let project: String
    let time: String

    init(id: UUID = UUID(), title: String, detail: String, kind: MemoryKind, project: String, time: String) {
        self.id = id
        self.title = title
        self.detail = detail
        self.kind = kind
        self.project = project
        self.time = time
    }
}

enum TaskStatus: Codable {
    case scheduled, attention
    var color: Color { self == .attention ? .cardealOrange : .cardealMuted }
}

struct OperationalTask: Identifiable, Codable {
    let id: UUID
    let title: String
    let dueDate: Date
    let owner: String
    let status: TaskStatus
    let symbol: String
    var isDone: Bool

    init(id: UUID = UUID(), title: String, dueDate: Date, owner: String, status: TaskStatus, symbol: String, isDone: Bool = false) {
        self.id = id
        self.title = title
        self.dueDate = dueDate
        self.owner = owner
        self.status = status
        self.symbol = symbol
        self.isDone = isDone
    }
}

struct Project: Identifiable {
    let id = UUID()
    let name: String
    let description: String
    let status: String
    let progress: Double
    let memories: Int
    let color: Color
}

struct DocumentRecord: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

extension MemoryItem {
    static let samples = [
        MemoryItem(title: "Aprovada a expansão para o Chile", detail: "O comitê executivo aprovou o início da operação no quarto trimestre.", kind: .decision, project: "Expansão LATAM", time: "10:42"),
        MemoryItem(title: "Reunião de alinhamento comercial", detail: "Definidos os critérios de qualificação e a nova cadência de follow-up.", kind: .conversation, project: "Receita 2026", time: "09:15"),
        MemoryItem(title: "Nova versão do planejamento", detail: "Documento consolidado com metas, riscos e responsáveis do trimestre.", kind: .document, project: "Planejamento 2026", time: "Ontem"),
        MemoryItem(title: "Marco de projeto concluído", detail: "Pesquisa com clientes finalizada e resultados anexados ao projeto.", kind: .event, project: "Produto Atlas", time: "Ontem")
    ]
}

extension OperationalTask {
    static let samples = [
        OperationalTask(title: "Enviar ata para o comitê", dueDate: .now.addingTimeInterval(7_200), owner: "Beatriz", status: .attention, symbol: "bell"),
        OperationalTask(title: "Revisar proposta da Orion", dueDate: .now.addingTimeInterval(86_400), owner: "Rafael", status: .scheduled, symbol: "person"),
        OperationalTask(title: "Agendar check-in do projeto", dueDate: .now.addingTimeInterval(172_800), owner: "Você", status: .scheduled, symbol: "calendar")
    ]
}

extension Project {
    static let samples = [
        Project(name: "Expansão LATAM", description: "Preparação para entrada no mercado chileno.", status: "Em andamento", progress: 0.72, memories: 64, color: .cardealPurple),
        Project(name: "Receita 2026", description: "Estratégia comercial e previsibilidade de vendas.", status: "Em andamento", progress: 0.48, memories: 51, color: .cardealBlue),
        Project(name: "Produto Atlas", description: "Redesenho da experiência do cliente.", status: "Em revisão", progress: 0.88, memories: 39, color: .cardealGreen)
    ]
}

extension DocumentRecord {
    static let samples = [
        DocumentRecord(title: "Planejamento estratégico 2026", detail: "Vinculado ao projeto • atualizado hoje"),
        DocumentRecord(title: "Ata — Comitê de produto", detail: "Vinculado ao projeto • atualizado hoje"),
        DocumentRecord(title: "Proposta comercial — Orion", detail: "Vinculado ao projeto • atualizado hoje")
    ]
}


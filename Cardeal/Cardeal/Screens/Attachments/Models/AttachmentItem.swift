import Foundation

/// Representa um arquivo encontrado nas fontes conectadas ao workspace.
struct AttachmentItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let owner: String
    let location: String
    let team: String
    let type: AttachmentType
    let folder: AttachmentFolder
    let details: AttachmentDetails

    init(
        name: String,
        owner: String,
        location: String,
        team: String,
        type: AttachmentType,
        folder: AttachmentFolder,
        details: AttachmentDetails? = nil
    ) {
        self.name = name
        self.owner = owner
        self.location = location
        self.team = team
        self.type = type
        self.folder = folder
        self.details = details ?? AttachmentDetails(
            participants: "\(owner) e \(team)",
            deadline: "09 de agosto, 2026",
            modality: "Presencial",
            project: team,
            source: location,
            excerpt: "Estamos oficialmente entrando na fase de implementação. A atualização seguirá o planejamento definido pela equipe.",
            notes: "As informações foram consolidadas a partir da conversa e dos documentos relacionados."
        )
    }
}

extension AttachmentItem {
    /// Pesquisa pelos metadados que ajudam a identificar um arquivo, inclusive
    /// quando a busca começa na visualização de pastas.
    func matches(searchQuery: String) -> Bool {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let searchableText = [
            name,
            owner,
            location,
            team,
            type.rawValue,
            folder.rawValue,
            details.participants,
            details.project,
            details.source,
            details.excerpt,
            details.notes
        ]

        return searchableText.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

/// Informações complementares mostradas ao abrir um arquivo.
struct AttachmentDetails: Hashable {
    let participants: String
    let deadline: String
    let modality: String
    let project: String
    let source: String
    let excerpt: String
    let notes: String
}

/// Pastas de primeiro nível disponíveis no navegador de arquivos.
enum AttachmentFolder: String, CaseIterable, Identifiable {
    case meetingMinutes = "Atas de reunião"
    case productAnalysis = "Análise de Produto"
    case contracts = "Contratos"
    case commercial = "Comercial"

    var id: Self { self }
}

enum AttachmentType: String, CaseIterable, Identifiable {
    case document = "Documento"
    case spreadsheet = "Planilha"
    case presentation = "Apresentação"

    var id: Self { self }
}

enum AttachmentResultScope: String, CaseIterable, Identifiable {
    case data = "Dados"
    case files = "Arquivos"

    var id: Self { self }
}

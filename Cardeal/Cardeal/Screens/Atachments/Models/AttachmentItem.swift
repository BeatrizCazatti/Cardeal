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

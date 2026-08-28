enum SortOption: String, CaseIterable, Identifiable {
    case newest
    case oldest
    case name
    case priority

    var id: Self { self }

    var title: String {
        switch self {
        case .newest:
            "Mais recente"
        case .oldest:
            "Mais antigo"
        case .name:
            "Nome"
        case .priority:
            "Prioridade"
        }
    }
}

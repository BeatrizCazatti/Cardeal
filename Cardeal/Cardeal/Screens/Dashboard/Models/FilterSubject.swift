enum FilterSubject: String, CaseIterable, Identifiable {
    case payments = "Pagamentos"
    case goals = "Metas e planos"
    case contracts = "Contratos"
    case deliveries = "Entregas"
    case sales = "Vendas"
    case humanResources = "Recursos Humanos"

    var id: Self { self }
}

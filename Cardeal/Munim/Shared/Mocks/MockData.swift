// MARK: - Dados de exemplo (mock)

enum MockData {
    static let sidebarItems: [SidebarItem] = [
        SidebarItem(title: "Resumo semanal", systemImage: "square.grid.2x2"),
        SidebarItem(title: "Calendário", systemImage: "calendar"),
        SidebarItem(title: "Equipe", systemImage: "person.3"),
        SidebarItem(title: "Relatórios", systemImage: "chart.bar.doc.horizontal"),
        SidebarItem(title: "Configurações", systemImage: "gearshape")
    ]

    static let filterTabs: [FilterTab] = [
        FilterTab(title: "Geral", count: 3),
        FilterTab(title: "Reuniões", count: 1, destination: .active(.meeting)),
        FilterTab(title: "Tarefas", count: 1, destination: .active(.task)),
        FilterTab(title: "Mudanças", count: 0, destination: .active(.change)),
        FilterTab(title: "Decisões", count: 1, destination: .active(.decision))
    ]

    static let attachments: [AttachmentItem] = [
        AttachmentItem(
            name: "Ata de reunião Financeiro (07/05/26)",
            owner: "Fabíola Machado",
            location: "Google Drive > pasta Financeiro",
            team: "Financeiro",
            type: .document,
            folder: .meetingMinutes
        ),
        AttachmentItem(
            name: "Ata de reunião Design (07/05/26)",
            owner: "Eduarda Vieira",
            location: "Google Chat > grupo Design",
            team: "Design",
            type: .document,
            folder: .meetingMinutes,
            details: AttachmentDetails(
                participants: "Eduarda Vieira e Design",
                deadline: "09 de agosto, 2026",
                modality: "Presencial",
                project: "Identidade Visual",
                source: "Design / Google Chat",
                excerpt: "Estamos oficialmente entrando na fase de implementação, que ocorrerá até final de setembro.",
                notes: "Iniciaremos dia 8 e vamos preparar o último brandbook e os posts de atualização. Aline vai encaminhar os últimos posts ainda esta semana."
            )
        ),
        AttachmentItem(
            name: "Ata de reunião Atendimento (07/05/26)",
            owner: "Leonardo Drummond",
            location: "Google Drive > pasta Atendimento",
            team: "Atendimento",
            type: .document,
            folder: .meetingMinutes
        ),
        AttachmentItem(
            name: "Ata de reunião geral (07/05/26)",
            owner: "Leonardo Drummond",
            location: "Google Drive > pasta Reuniões",
            team: "Operações",
            type: .document,
            folder: .meetingMinutes
        ),
        AttachmentItem(
            name: "Ata de reunião Financeiro (07/04/26)",
            owner: "Fabíola Machado",
            location: "Google Drive > pasta Financeiro",
            team: "Financeiro",
            type: .document,
            folder: .meetingMinutes
        ),
        AttachmentItem(
            name: "Ata de reunião Operações (07/04/26)",
            owner: "Fabíola Machado",
            location: "Google Chat > grupo Operações",
            team: "Operações",
            type: .document,
            folder: .meetingMinutes
        ),
        AttachmentItem(
            name: "Ata de reunião Atendimento (14/08/25)",
            owner: "Eduarda Vieira",
            location: "Google Drive > pasta Atendimento",
            team: "Atendimento",
            type: .document,
            folder: .meetingMinutes
        ),
        AttachmentItem(
            name: "Análise de conversão do produto",
            owner: "Eduarda Vieira",
            location: "Google Drive > Produto > Análises",
            team: "Design",
            type: .spreadsheet,
            folder: .productAnalysis
        ),
        AttachmentItem(
            name: "Contrato de prestação de serviços",
            owner: "Fabíola Machado",
            location: "Google Drive > Jurídico > Contratos",
            team: "Financeiro",
            type: .document,
            folder: .contracts
        ),
        AttachmentItem(
            name: "Proposta comercial - Agosto",
            owner: "Leonardo Drummond",
            location: "Google Drive > Comercial > Propostas",
            team: "Atendimento",
            type: .presentation,
            folder: .commercial
        )
    ]

    static let columns: [BoardColumn] = [
        BoardColumn(
            title: "Atendimento",
            items: [
                BoardItem(
                    title: "Criação de post para Instagram",
                    badgeCount: 1,
                    assignees: [Assignee(name: "Aline (Design)", isGroup: false)],
                    dateText: "Amanhã - 17h",
                    priority: .medium,
                    category: .task
                ),
                BoardItem(
                    title: "Onboarding de nova ferramenta",
                    badgeCount: 1,
                    assignees: [Assignee(name: "Fabíola Machado & Atendimento", isGroup: true)],
                    dateText: "Amanhã - 17h",
                    location: "Presencial",
                    priority: .high,
                    category: .meeting
                )
            ]
        ),
        BoardColumn(
            title: "Design",
            items: [
                BoardItem(
                    title: "Criação de post para Instagram",
                    assignees: [Assignee(name: "Aline (Design)", isGroup: false)],
                    dateText: "Amanhã - 17h",
                    priority: .low,
                    category: .meeting
                ),
                BoardItem(
                    title: "Onboarding de nova ferramenta",
                    assignees: [Assignee(name: "Fabíola Machado & Atendimento", isGroup: true)],
                    dateText: "Amanhã - 17h",
                    isRescheduled: true,
                    location: "Presencial",
                    category: .change
                )
            ]
        ),
        BoardColumn(
            title: "Financeiro",
            items: [
                BoardItem(
                    title: "Novo sistema de ticket a ser implementado",
                    badgeCount: 1,
                    assignees: [Assignee(name: "Fabíola Machado & RH", isGroup: true)],
                    descriptionText: "A decisão foi feita por motivos de melhora no custo-benefício e será implementada até o fim de agosto.",
                    category: .decision
                ),
                BoardItem(
                    title: "Aprovação do orçamento trimestral",
                    assignees: [Assignee(name: "Fabíola Machado", isGroup: false)],
                    descriptionText: "O orçamento foi aprovado para a execução das iniciativas prioritárias.",
                    category: .decision
                )
            ]
        ),
        BoardColumn(title: "Operação", items: [])
    ]

    static let teamDetails: [TeamDetail] = [
        TeamDetail(
            name: "Atendimento",
            members: [
                TeamMember(name: "Fabíola Machado", role: "Líder de atendimento", email: "fabiola@cardeal.com", hiredDate: "10 de maio, 2024", relatedProjects: ["Onboarding clientes", "Suporte prioritário"], recentActivities: ["Revisão de pauta semanal", "Aprovação de atendimento"]),
                TeamMember(name: "Leonardo Drummond", role: "Analista de atendimento", email: "leonardo@cardeal.com", hiredDate: "18 de junho, 2025", relatedProjects: ["Central de ajuda", "Relatórios de SLA"], recentActivities: ["Ata de reunião Atendimento", "Atualização de chamados"])
            ],
            timeline: teamTimeline
        ),
        TeamDetail(
            name: "Design",
            members: [
                TeamMember(name: "Eduarda Vieira", role: "Co-fundadora", email: "eduarda@cardeal.com", hiredDate: "10 de maio, 2026", relatedProjects: ["Posts Instagram", "Embalagem Fone", "Banners novos"], recentActivities: ["Implementação da nova identidade visual", "Revisão de peças para campanha"]),
                TeamMember(name: "Aline Souza", role: "Designer", email: "aline@cardeal.com", hiredDate: "12 de fevereiro, 2025", relatedProjects: ["Guia de marca", "Biblioteca de componentes"], recentActivities: ["Criação de post para Instagram", "Aprovação de layout"])
            ],
            timeline: teamTimeline
        ),
        TeamDetail(
            name: "Financeiro",
            members: [
                TeamMember(name: "Fabíola Machado", role: "Responsável financeiro", email: "fabiola@cardeal.com", hiredDate: "10 de maio, 2024", relatedProjects: ["Planejamento anual", "Controle de custos"], recentActivities: ["Ata de reunião Financeiro", "Revisão de orçamento"])
            ],
            timeline: teamTimeline
        ),
        TeamDetail(
            name: "Operação",
            members: [
                TeamMember(name: "Leonardo Drummond", role: "Analista de operações", email: "leonardo@cardeal.com", hiredDate: "18 de junho, 2025", relatedProjects: ["Novo sistema de tickets", "Melhoria de processos"], recentActivities: ["Mapeamento de processos", "Reunião de operações"])
            ],
            timeline: teamTimeline
        )
    ]

    private static let teamTimeline: [TeamActivity] = [
        TeamActivity(category: .decision, title: "Novo sistema de ticket a ser implementado", detail: "A decisão foi tomada para melhorar o custo-benefício e será implementada até o fim de agosto.", date: "29 de julho, 2026", participants: ["Leonardo Drummond", "Eduarda Vieira"]),
        TeamActivity(category: .task, title: "Novo sistema de ticket a ser implementado", detail: "Os responsáveis confirmaram ciência e iniciarão a mudança em breve.", date: "29 de julho, 2026", participants: ["Leonardo Drummond", "Eduarda Vieira"]),
        TeamActivity(category: .meeting, title: "Alinhamento da implementação", detail: "Foram definidos os próximos passos e a comunicação com as equipes.", date: "29 de julho, 2026", participants: ["Leonardo Drummond", "Eduarda Vieira"]),
        TeamActivity(category: .decision, title: "Novo sistema de ticket a ser implementado", detail: "A decisão foi tomada para melhorar o custo-benefício e será implementada até o fim de agosto.", date: "29 de julho, 2026", participants: ["Leonardo Drummond", "Eduarda Vieira"]),
        TeamActivity(category: .task, title: "Novo sistema de ticket a ser implementado", detail: "Os responsáveis confirmaram ciência e iniciarão a mudança em breve.", date: "29 de julho, 2026", participants: ["Leonardo Drummond", "Eduarda Vieira"]),
        TeamActivity(category: .meeting, title: "Alinhamento da implementação", detail: "Foram definidos os próximos passos e a comunicação com as equipes.", date: "29 de julho, 2026", participants: ["Leonardo Drummond", "Eduarda Vieira"])
    ]
    
    enum Tabs: String {
        case geral = "Geral"
        case reunioes = "Reuniões"
        case tarefas = "Tarefas"
        case mudancas = "Mudanças"
        // case decisoes = "Decisões"
        // case arquivados = "Arquivados"
        // case excluidos = "Excluídos"
    }
}

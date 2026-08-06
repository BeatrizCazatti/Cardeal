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
        FilterTab(title: "Geral", count: 2),
        FilterTab(title: "Reuniões", count: 2),
        FilterTab(title: "Tarefas", count: 1),
        FilterTab(title: "Mudanças", count: 1),
        FilterTab(title: "Decisões", count: 4)
    ]

    static let columns: [BoardColumn] = [
        BoardColumn(
            title: "Atendimento",
            items: [
                BoardItem(
                    title: "Criação de post para Instagram",
                    badgeCount: 1,
                    assignees: [Assignee(name: "Aline (Design)", isGroup: false)],
                    dateText: "Amanhã - 17h"
                ),
                BoardItem(
                    title: "Onboarding de nova ferramenta",
                    badgeCount: 1,
                    assignees: [Assignee(name: "Fabíola Machado & Atendimento", isGroup: true)],
                    dateText: "Amanhã - 17h",
                    location: "Presencial"
                )
            ]
        ),
        BoardColumn(
            title: "Design",
            items: [
                BoardItem(
                    title: "Criação de post para Instagram",
                    assignees: [Assignee(name: "Aline (Design)", isGroup: false)],
                    dateText: "Amanhã - 17h"
                ),
                BoardItem(
                    title: "Onboarding de nova ferramenta",
                    assignees: [Assignee(name: "Fabíola Machado & Atendimento", isGroup: true)],
                    dateText: "Amanhã - 17h",
                    isRescheduled: true,
                    location: "Presencial"
                )
            ]
        ),
        BoardColumn(
            title: "Financeiro",
            items: [
                BoardItem(
                    title: "Novo sistema de ticket a ser implementado",
                    assignees: [Assignee(name: "Fabíola Machado & RH", isGroup: true)],
                    descriptionText: "A decisão foi feita por motivos de melhora no custo-benefício e será implementada até o fim de agosto."
                )
            ]
        ),
        BoardColumn(title: "Operação", items: [])
    ]
}

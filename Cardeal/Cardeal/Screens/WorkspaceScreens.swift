import SwiftUI

struct OverviewScreen: View {
    let items: [MemoryItem]
    let tasks: [OperationalTask]
    let onTaskToggle: (OperationalTask.ID) -> Void
    let onAutomation: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 26) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 6) { Text("Bom dia, Beatriz").font(.system(size: 27, weight: .bold)).foregroundStyle(Color.cardealInk); Text("Aqui está o que está acontecendo na sua organização.").font(.system(size: 13)).foregroundStyle(Color.cardealMuted) }
                Spacer(); Text("02 de agosto de 2026").font(.system(size: 12)).foregroundStyle(Color.cardealMuted)
            }
            HStack(spacing: 14) {
                MetricCard(title: "Memórias registradas", value: "248", note: "+12 esta semana", icon: "square.and.pencil", tint: .cardealPurple)
                MetricCard(title: "Decisões em curso", value: "18", note: "3 precisam de atenção", icon: "arrow.triangle.branch", tint: .cardealBlue)
                MetricCard(title: "Ações pendentes", value: "07", note: "2 vencem hoje", icon: "checkmark.circle", tint: .cardealOrange)
                MetricCard(title: "Projetos ativos", value: "04", note: "Todos atualizados", icon: "folder", tint: .cardealGreen)
            }
            HStack(alignment: .top, spacing: 20) {
                VStack(alignment: .leading, spacing: 16) { SectionHeading(title: "Linha do tempo", actionTitle: "Ver toda a memória"); TimelineCard(items: Array(items.prefix(4))) }.frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeading(title: "Próximas ações", actionTitle: "Ver agenda")
                    TaskCard(tasks: tasks, onToggle: onTaskToggle)
                    Button(action: onAutomation) { Label("Criar lembrete ou automação", systemImage: "bolt.fill").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.cardealPurple).frame(maxWidth: .infinity).padding(.vertical, 10).overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.cardealPurple.opacity(0.25))) }.buttonStyle(.plain)
                }.frame(width: 335)
            }
        }
    }
}


struct MemoryScreen: View {
    let items: [MemoryItem]
    let onNewMemory: () -> Void
    var body: some View { VStack(alignment: .leading, spacing: 22) { HStack { VStack(alignment: .leading, spacing: 5) { Text("Memória organizacional").font(.system(size: 27, weight: .bold)).foregroundStyle(Color.cardealInk); Text("Decisões, conversas, documentos e acontecimentos em um único lugar.").font(.system(size: 13)).foregroundStyle(Color.cardealMuted) }; Spacer(); Button(action: onNewMemory) { Label("Registrar", systemImage: "plus").padding(.horizontal, 13).padding(.vertical, 9).foregroundStyle(.white).background(Color.cardealPurple, in: RoundedRectangle(cornerRadius: 7)) }.buttonStyle(.plain) }; HStack(spacing: 7) { Tag(text: "Todos (\(items.count))", color: .cardealPurple); Tag(text: "Decisões", color: .cardealBlue); Tag(text: "Conversas", color: .cardealGreen); Tag(text: "Documentos", color: .cardealOrange) }; TimelineCard(items: items) } }
}

struct ProjectsScreen: View {
    var body: some View { VStack(alignment: .leading, spacing: 22) { Text("Projetos").font(.system(size: 27, weight: .bold)).foregroundStyle(Color.cardealInk); HStack(spacing: 16) { ForEach(Project.samples) { ProjectCard(project: $0) } } } }
}

struct ActionsScreen: View {
    let tasks: [OperationalTask]
    let onTaskToggle: (OperationalTask.ID) -> Void
    let onAutomation: () -> Void
    var body: some View { VStack(alignment: .leading, spacing: 22) { HStack { VStack(alignment: .leading, spacing: 5) { Text("Ações e automações").font(.system(size: 27, weight: .bold)); Text("Transforme decisões em acompanhamento operacional.").font(.system(size: 13)).foregroundStyle(Color.cardealMuted) }; Spacer(); Button(action: onAutomation) { Label("Nova automação", systemImage: "bolt.fill").foregroundStyle(.white).padding(.horizontal, 13).padding(.vertical, 9).background(Color.cardealPurple, in: RoundedRectangle(cornerRadius: 7)) }.buttonStyle(.plain) }; TaskCard(tasks: tasks, onToggle: onTaskToggle); Text("Automações ativas").font(.system(size: 16, weight: .bold)); HStack(spacing: 14) { AutomationCard(icon: "calendar", title: "Resumo semanal", text: "Enviar toda segunda-feira, às 09:00", color: .cardealPurple); AutomationCard(icon: "bell", title: "Aviso de prazo", text: "Lembrar 24h antes das ações pendentes", color: .cardealOrange); AutomationCard(icon: "person.2", title: "Follow-up", text: "Cobrar responsável após 3 dias", color: .cardealBlue) } } }
}

struct DocumentsScreen: View {
    private let documents = ["Planejamento estratégico 2026", "Ata — Comitê de produto", "Proposta comercial — Orion"]
    var body: some View { VStack(alignment: .leading, spacing: 22) { Text("Documentos").font(.system(size: 27, weight: .bold)); ForEach(documents, id: \.self) { DocumentRow(title: $0) } } }
}

struct SettingsScreen: View {
    var body: some View { VStack(alignment: .leading, spacing: 10) { Text("Configurações").font(.system(size: 27, weight: .bold)); Text("As permissões de notificações permitem que as automações funcionem mesmo quando a aplicação está em segundo plano.").font(.system(size: 13)).foregroundStyle(Color.cardealMuted); Spacer() } }
}

private struct ProjectCard: View {
    let project: Project
    var body: some View { VStack(alignment: .leading, spacing: 15) { HStack { Circle().fill(project.color).frame(width: 9, height: 9); Text(project.name).font(.system(size: 14, weight: .semibold)); Spacer(); Text(project.status).font(.system(size: 10, weight: .medium)).foregroundStyle(project.color) }; Text(project.description).font(.system(size: 11)).foregroundStyle(Color.cardealMuted).lineLimit(2); ProgressView(value: project.progress).tint(project.color); HStack { Text("\(Int(project.progress * 100))% concluído").font(.system(size: 10)).foregroundStyle(Color.cardealMuted); Spacer(); Text("\(project.memories) memórias").font(.system(size: 10)).foregroundStyle(Color.cardealMuted) } }.padding(18).frame(maxWidth: .infinity, minHeight: 155, alignment: .topLeading).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardealLine)) }
}

private struct AutomationCard: View {
    let icon: String; let title: String; let text: String; let color: Color
    var body: some View { HStack(alignment: .top, spacing: 11) { Image(systemName: icon).foregroundStyle(color).padding(9).background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 7)); VStack(alignment: .leading, spacing: 4) { Text(title).font(.system(size: 12, weight: .semibold)); Text(text).font(.system(size: 10)).foregroundStyle(Color.cardealMuted).lineLimit(2) } }.padding(14).frame(maxWidth: .infinity, alignment: .leading).background(.white, in: RoundedRectangle(cornerRadius: 10)).overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.cardealLine)) }
}

private struct DocumentRow: View {
    let title: String
    var body: some View { HStack { Image(systemName: "doc.richtext").foregroundStyle(Color.cardealPurple); VStack(alignment: .leading) { Text(title).font(.system(size: 13, weight: .medium)); Text("Vinculado ao projeto • atualizado hoje").font(.system(size: 10)).foregroundStyle(Color.cardealMuted) }; Spacer(); Image(systemName: "ellipsis").foregroundStyle(Color.cardealMuted) }.padding(15).background(.white, in: RoundedRectangle(cornerRadius: 9)).overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.cardealLine)) }
}

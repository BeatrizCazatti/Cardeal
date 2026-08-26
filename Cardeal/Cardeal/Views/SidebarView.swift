import SwiftUI


// MARK: - Sidebar recolhível

/// Sidebar de navegação seguindo o padrão `NavigationSplitView` do macOS,
/// que já oferece o botão nativo de recolher/expandir na toolbar.
struct SidebarView: View {
    @Binding var selection: SidebarDestination?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        List(selection: $selection) {
            Button {
                openWindow(id: "settings")
            } label: {
                Label("Configurações", systemImage: "gearshape")
            }
            .buttonStyle(.plain)

            NavigationLink(value: SidebarDestination.dashboard) {
                Label("Dashboard", systemImage: "house")
            }

            NavigationLink(value: SidebarDestination.archived) {
                Label("Arquivados", systemImage: "archivebox")
                    .padding(.leading, 20)
            }

            NavigationLink(value: SidebarDestination.deleted) {
                Label("Excluídos", systemImage: "trash")
                    .padding(.leading, 20)
            }

            NavigationLink(value: SidebarDestination.attachments) {
                Label("Anexos", systemImage: "folder")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Painel")
    }
}

import SwiftUI


// MARK: - Sidebar recolhível

/// Sidebar de navegação seguindo o padrão `NavigationSplitView` do macOS,
/// que já oferece o botão nativo de recolher/expandir na toolbar.
struct SidebarView: View {
    @Binding var selection: SidebarDestination?

    var body: some View {
        List(selection: $selection) {
            NavigationLink(value: SidebarDestination.dashboard) {
                Label("Dashboard", systemImage: "house")
            }

//            NavigationLink(value: SidebarDestination.timeline) {
//                Label("Timeline", systemImage: "clock")
//            }

            NavigationLink(value: SidebarDestination.attachments) {
                Label("Anexos", systemImage: "folder")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Painel")
    }
}

import SwiftUI


// MARK: - Sidebar recolhível

/// Sidebar de navegação seguindo o padrão `NavigationSplitView` do macOS,
/// que já oferece o botão nativo de recolher/expandir na toolbar.
struct SidebarView: View {
    let items: [SidebarItem]
    @Binding var selection: SidebarItem?

    var body: some View {

        List(selection: $selection) {

            NavigationLink(
                value: SidebarDestination.dashboard
            ) {

                Label(
                    "Dashboard",
                    systemImage: "rectangle.grid.2x2"
                )
            }

            NavigationLink(
                value: SidebarDestination.meetings
            ) {

                Label(
                    "Reuniões",
                    systemImage: "video"
                )
            }

            NavigationLink(
                value: SidebarDestination.files
            ) {

                Label(
                    "Arquivos",
                    systemImage: "folder"
                )
            }

        }
        .listStyle(.sidebar)
        .navigationTitle("Painel")
        
    }
}

struct DetailView: View {

    let selection: SidebarDestination?

    @ViewBuilder
    var body: some View {

        switch selection {

        case .dashboard:
            DashboardView()

        case .meetings:
            MeetingsView()

        case .files:
            FilesView()

        case .people:
            PeopleView()

        case .settings:
            SettingsView()

        case nil:

            ContentUnavailableView(
                "Selecione uma opção",
                systemImage: "sidebar.left"
            )

        }

    }

}

import SwiftUI

struct ContentView: View {
    @State private var selectedSection: WorkspaceSection = .overview
    @State private var searchText = ""
    @State private var activeSheet: ActiveSheet?
    @StateObject private var workspace = WorkspaceStore()

    private var filteredItems: [MemoryItem] {
        workspace.searchMemories(matching: searchText)
    }

    var body: some View {
        HStack(spacing: 0) {
            //Sidebar(selectedSection: $selectedSection) { activeSheet = .memory }
            Divider().overlay(Color.cardealLine)

            VStack(spacing: 0) {
                TopBar(searchText: $searchText, onNewMemory: { activeSheet = .memory })
                Divider().overlay(Color.cardealLine)
                ScrollView {
                    activeScreen
                        .frame(maxWidth: 1_520, alignment: .leading)
                        .padding(.horizontal, 34)
                        .padding(.vertical, 28)
                }
                .background(Color.cardealCanvas)
            }
        }
        .frame(minWidth: 1_060, minHeight: 700)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .memory:
                CaptureSheet { workspace.add($0) }
            case .automation:
                AutomationSheet { title, date in
                    workspace.scheduleTask(title: title, dueDate: date)
                }
            }
        }
    }

    @ViewBuilder
    private var activeScreen: some View {
        switch selectedSection {
        case .overview:
            OverviewScreen(items: filteredItems, tasks: workspace.tasks, onTaskToggle: workspace.toggleCompletion, onAutomation: { activeSheet = .automation })
        case .memories:
            MemoryScreen(items: filteredItems, onNewMemory: { activeSheet = .memory })
        case .projects:
            ProjectsScreen()
        case .actions:
            ActionsScreen(tasks: workspace.tasks, onTaskToggle: workspace.toggleCompletion, onAutomation: { activeSheet = .automation })
        case .documents:
            DocumentsScreen()
        case .settings:
            SettingsScreen()
        }
    }

    private func toggleDemo() {
        workspace.isDemoMode ? workspace.clearDemoData() : workspace.loadDemoData()
    }
}

private enum ActiveSheet: Identifiable {
    case memory, automation
    var id: Self { self }
}

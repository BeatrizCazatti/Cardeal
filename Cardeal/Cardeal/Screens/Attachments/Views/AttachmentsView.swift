import SwiftUI

/// Navegador de arquivos: começa nas pastas e abre o conteúdo da pasta selecionada.
struct AttachmentsView: View {
    @State private var searchText = ""
    @State private var selectedFolder: AttachmentFolder?
    @State private var selectedAttachmentIDs = Set<AttachmentItem.ID>()
    @State private var selectedAttachment: AttachmentItem?
    @State private var selectedType: AttachmentType?
    @State private var selectedPerson: String?
    @State private var selectedTeam: String?
    @State private var sortOption: SortOption = .newest

    private let attachments = MockData.attachments

    private var filteredAttachments: [AttachmentItem] {
        let matchingAttachments = attachments.filter { attachment in
            let matchesFolder = attachment.folder == selectedFolder
            let matchesSearch = searchText.isEmpty || [attachment.name, attachment.owner, attachment.location]
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchesType = selectedType == nil || attachment.type == selectedType
            let matchesPerson = selectedPerson == nil || attachment.owner == selectedPerson
            let matchesTeam = selectedTeam == nil || attachment.team == selectedTeam

            return matchesFolder && matchesSearch && matchesType && matchesPerson && matchesTeam
        }

        switch sortOption {
        case .newest:
            return matchingAttachments
        case .oldest:
            return Array(matchingAttachments.reversed())
        case .name:
            return matchingAttachments.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        case .priority:
            return matchingAttachments.sorted { $0.type.rawValue < $1.type.rawValue }
        }
    }

    var body: some View {
        Group {
            if let selectedFolder {
                AttachmentFolderDetailView(
                    folder: selectedFolder,
                    allAttachments: attachments,
                    attachments: filteredAttachments,
                    searchText: $searchText,
                    selection: $selectedAttachmentIDs,
                    selectedAttachment: $selectedAttachment,
                    selectedType: $selectedType,
                    selectedPerson: $selectedPerson,
                    selectedTeam: $selectedTeam,
                    sortOption: $sortOption,
                    onNavigateBack: navigateToRoot
                )
            } else {
                AttachmentFolderGridView(searchText: $searchText, onSelect: select)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $selectedAttachment) { attachment in
            AttachmentDetailSheet(attachment: attachment)
        }
    }

    private func select(_ folder: AttachmentFolder) {
        selectedFolder = folder
        resetFilters()
    }

    private func navigateToRoot() {
        selectedFolder = nil
        resetFilters()
    }

    private func resetFilters() {
        searchText = ""
        selectedAttachmentIDs.removeAll()
        selectedType = nil
        selectedPerson = nil
        selectedTeam = nil
    }
}

private struct AttachmentFolderGridView: View {
    @Binding var searchText: String
    let onSelect: (AttachmentFolder) -> Void

    private var matchingFolders: [AttachmentFolder] {
        AttachmentFolder.allCases.filter {
            searchText.isEmpty || $0.rawValue.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .center, spacing: 20) {
                    Text("Arquivos e documentos")
                        .font(.largeTitle.weight(.regular))

                    Spacer(minLength: 24)

                    FinderSearchControl(text: $searchText, placeholder: "Pesquisar pastas")
                }

                if matchingFolders.isEmpty {
                    ContentUnavailableView.search
                        .frame(maxWidth: .infinity, minHeight: 280)
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 70)],
                        alignment: .leading,
                        spacing: 40
                    ) {
                        ForEach(matchingFolders) { folder in
                            AttachmentFolderTile(folder: folder) { onSelect(folder) }
                        }
                    }
                }
            }
            .padding(40)
            .frame(maxWidth: 1_600, alignment: .leading)
        }
        .navigationTitle("Arquivos e documentos")
    }
}

private struct AttachmentFolderTile: View {
    let folder: AttachmentFolder
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .center, spacing: 10) {
                Image(.folderAttachments)
                    .resizable()
                    .frame(width: 200)
                Text(folder.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(10)
            .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("Abre a pasta \(folder.rawValue)")
    }
}

private struct AttachmentFolderDetailView: View {
    let folder: AttachmentFolder
    let allAttachments: [AttachmentItem]
    let attachments: [AttachmentItem]
    @Binding var searchText: String
    @Binding var selection: Set<AttachmentItem.ID>
    @Binding var selectedAttachment: AttachmentItem?
    @Binding var selectedType: AttachmentType?
    @Binding var selectedPerson: String?
    @Binding var selectedTeam: String?
    @Binding var sortOption: SortOption
    let onNavigateBack: () -> Void

    private var people: [String] {
        Array(Set(folderAttachments.map(\.owner))).sorted()
    }

    private var teams: [String] {
        Array(Set(folderAttachments.map(\.team))).sorted()
    }

    private var folderAttachments: [AttachmentItem] {
        allAttachments.filter { $0.folder == folder }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                AttachmentFolderHeader(
                    folder: folder,
                    searchText: $searchText,
                    onNavigateBack: onNavigateBack
                )

                AttachmentFiltersView(
                    selectedType: $selectedType,
                    selectedPerson: $selectedPerson,
                    selectedTeam: $selectedTeam,
                    sortOption: $sortOption,
                    people: people,
                    teams: teams
                )

                AttachmentListView(
                    attachments: attachments,
                    selection: $selection,
                    selectedAttachment: $selectedAttachment
                )
            }
            .padding(40)
            .frame(maxWidth: 1_600, alignment: .leading)
        }
        .navigationTitle(folder.rawValue)
    }
}

private struct AttachmentFolderHeader: View {
    let folder: AttachmentFolder
    @Binding var searchText: String
    let onNavigateBack: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            Button(action: onNavigateBack) {
                Label("Arquivos e documentos", systemImage: "chevron.left")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Label(folder.rawValue, systemImage: "folder.fill")
                .font(.title)
                .foregroundStyle(.primary)

            Spacer(minLength: 24)

            FinderSearchControl(text: $searchText, placeholder: "Pesquisar arquivos")
        }
    }
}

/// Campo de busca compacto inspirado no Finder. Ele ocupa apenas o espaço da
/// lupa até ser acionado e começa a filtrar o conteúdo enquanto o usuário digita.
private struct FinderSearchControl: View {
    @Binding var text: String
    let placeholder: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @State private var isExpanded = false

    var body: some View {
        HStack(spacing: 8) {
            if isExpanded {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .focused($isFocused)
                    .onSubmit { isFocused = false }
                    .onExitCommand(perform: collapse)

                if !text.isEmpty {
                    Button("Limpar", systemImage: "xmark.circle.fill", action: clear)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Limpar pesquisa")
                }
            } else {
                Button(action: expand) {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Pesquisar")
                .accessibilityHint("Expande o campo de pesquisa")
            }
        }
        .font(.subheadline)
        .padding(.vertical, 6)
        .padding(.horizontal, isExpanded ? 10 : 4)
        .frame(width: isExpanded ? 300 : 36)
        .modifier(GlassPillModifier(tint: nil, isSelected: false))
        .animation(reduceMotion ? nil : .snappy(duration: 0.22), value: isExpanded)
    }

    private func expand() {
        isExpanded = true
        DispatchQueue.main.async { isFocused = true }
    }

    private func clear() {
        text = ""
        isFocused = true
    }

    private func collapse() {
        isFocused = false
        text = ""
        isExpanded = false
    }
}

private struct AttachmentFiltersView: View {
    @Binding var selectedType: AttachmentType?
    @Binding var selectedPerson: String?
    @Binding var selectedTeam: String?
    @Binding var sortOption: SortOption
    let people: [String]
    let teams: [String]

    @State private var isFilterPopoverPresented = false
    @State private var isSortPopoverPresented = false

    var body: some View {
        HStack(spacing: 12) {
            Spacer()

            ToolbarIconButton(systemImage: "line.3.horizontal.decrease", accessibilityLabel: "Filtrar arquivos") {
                isFilterPopoverPresented.toggle()
                isSortPopoverPresented = false
            }
            .popover(isPresented: $isFilterPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                AttachmentFilterPopover(
                    selectedType: $selectedType,
                    selectedPerson: $selectedPerson,
                    selectedTeam: $selectedTeam,
                    people: people,
                    teams: teams
                )
            }

            ToolbarIconButton(systemImage: "arrow.up.arrow.down", accessibilityLabel: "Ordenar arquivos") {
                isSortPopoverPresented.toggle()
                isFilterPopoverPresented = false
            }
            .popover(isPresented: $isSortPopoverPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                SortPopover(selection: $sortOption)
            }
        }
    }
}

private struct AttachmentFilterPopover: View {
    @Binding var selectedType: AttachmentType?
    @Binding var selectedPerson: String?
    @Binding var selectedTeam: String?
    let people: [String]
    let teams: [String]

    @State private var peopleSearchText = ""
    @State private var teamsSearchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Filtrar por")
                .font(.headline)

            Divider()

            section(title: "Tipo") {
                FlowLayout(spacing: 6) {
                    ForEach(AttachmentType.allCases) { type in
                        singleChoiceChip(title: type.rawValue, isSelected: selectedType == type) {
                            selectedType = selectedType == type ? nil : type
                        }
                    }
                }
            }

            section(title: "Pessoas") {
                FilterSearchField(placeholder: "Pesquisar pessoas", text: $peopleSearchText)
                FlowLayout(spacing: 6) {
                    ForEach(matching(people, query: peopleSearchText), id: \.self) { person in
                        singleChoiceChip(title: person, isSelected: selectedPerson == person) {
                            selectedPerson = selectedPerson == person ? nil : person
                        }
                    }
                }
            }

            section(title: "Equipes") {
                FilterSearchField(placeholder: "Pesquisar equipes e grupos", text: $teamsSearchText)
                FlowLayout(spacing: 6) {
                    ForEach(matching(teams, query: teamsSearchText), id: \.self) { team in
                        singleChoiceChip(title: team, isSelected: selectedTeam == team) {
                            selectedTeam = selectedTeam == team ? nil : team
                        }
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 366)
    }

    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
            content()
        }
    }

    private func matching(_ values: [String], query: String) -> [String] {
        values.filter { query.isEmpty || $0.localizedCaseInsensitiveContains(query) }
    }

    private func singleChoiceChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        FilterChip(title: title, isSelected: isSelected, showsCloseButton: false, action: action)
    }
}

private struct AttachmentListView: View {
    let attachments: [AttachmentItem]
    @Binding var selection: Set<AttachmentItem.ID>
    @Binding var selectedAttachment: AttachmentItem?

    var body: some View {
        if attachments.isEmpty {
            ContentUnavailableView.search
                .frame(maxWidth: .infinity, minHeight: 280)
        } else {
            VStack(spacing: 0) {
                AttachmentColumnHeader()

                ForEach(attachments) { attachment in
                    AttachmentRow(attachment: attachment, isSelected: selection.contains(attachment.id)) {
                        selection = [attachment.id]
                        selectedAttachment = attachment
                    }

                    if attachment.id != attachments.last?.id {
                        Divider()
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

}

private struct AttachmentColumnHeader: View {
    var body: some View {
        HStack(spacing: 20) {
            Text("Nome").frame(maxWidth: .infinity, alignment: .leading)
            Text("Dono").frame(width: 210, alignment: .leading)
            Text("Localização do arquivo").frame(width: 280, alignment: .leading)
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }
}

private struct AttachmentRow: View {
    let attachment: AttachmentItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                Label(attachment.name, systemImage: "doc.fill")
                    .labelStyle(AttachmentNameLabelStyle())
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(attachment.owner).frame(width: 210, alignment: .leading)
                Text(attachment.location)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(width: 280, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .primary : .secondary)
        .background(isSelected ? Color.accentColor.opacity(0.10) : .clear)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct AttachmentNameLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 16) {
            configuration.icon.foregroundStyle(.primary).frame(width: 24)
            configuration.title
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
    }
}

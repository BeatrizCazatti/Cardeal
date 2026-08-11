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

    private let attachments = MockData.attachments

    private var filteredAttachments: [AttachmentItem] {
        attachments.filter { attachment in
            let matchesFolder = attachment.folder == selectedFolder
            let matchesSearch = searchText.isEmpty || [attachment.name, attachment.owner, attachment.location]
                .contains { $0.localizedCaseInsensitiveContains(searchText) }
            let matchesType = selectedType == nil || attachment.type == selectedType
            let matchesPerson = selectedPerson == nil || attachment.owner == selectedPerson
            let matchesTeam = selectedTeam == nil || attachment.team == selectedTeam

            return matchesFolder && matchesSearch && matchesType && matchesPerson && matchesTeam
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
                    onNavigateBack: navigateToRoot
                )
            } else {
                AttachmentFolderGridView(onSelect: select)
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
    let onSelect: (AttachmentFolder) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                Text("Arquivos e documentos")
                    .font(.largeTitle.weight(.regular))

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 140, maximum: 170), spacing: 28)],
                    alignment: .leading,
                    spacing: 28
                ) {
                    ForEach(AttachmentFolder.allCases) { folder in
                        AttachmentFolderTile(folder: folder) { onSelect(folder) }
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
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 52))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.blue)
                Text(folder.rawValue)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(width: 140, alignment: .leading)
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
            VStack(alignment: .leading, spacing: 24) {
                AttachmentFolderHeader(
                    folder: folder,
                    searchText: $searchText,
                    onNavigateBack: onNavigateBack
                )

                AttachmentFiltersView(
                    selectedType: $selectedType,
                    selectedPerson: $selectedPerson,
                    selectedTeam: $selectedTeam,
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

            SearchFieldView(text: $searchText)
                .frame(minWidth: 260, idealWidth: 340, maxWidth: 420)
        }
    }
}

private struct AttachmentFiltersView: View {
    @Binding var selectedType: AttachmentType?
    @Binding var selectedPerson: String?
    @Binding var selectedTeam: String?
    let people: [String]
    let teams: [String]

    var body: some View {
        HStack(spacing: 12) {
            AttachmentFilterMenu(
                title: "Tipo",
                selection: $selectedType,
                values: AttachmentType.allCases,
                displayName: \.rawValue
            )
            AttachmentFilterMenu(title: "Pessoas", selection: $selectedPerson, values: people, displayName: { $0 })
            AttachmentFilterMenu(title: "Equipe", selection: $selectedTeam, values: teams, displayName: { $0 })

            Spacer()

            Button("Opções de exibição", systemImage: "line.3.horizontal.decrease") {}
                .labelStyle(.iconOnly)
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())

            Button("Ordenar", systemImage: "arrow.up.arrow.down") {}
                .labelStyle(.iconOnly)
                .buttonStyle(.borderedProminent)
                .clipShape(Circle())
        }
    }
}

private struct AttachmentFilterMenu<Value: Hashable>: View {
    let title: String
    @Binding var selection: Value?
    let values: [Value]
    let displayName: (Value) -> String

    var body: some View {
        Menu {
            Button("Todos") { selection = nil }
            Divider()
            ForEach(values, id: \.self) { value in
                Button(displayName(value)) { selection = value }
            }
        } label: {
            Label(title, systemImage: "chevron.down")
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.borderedProminent)
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

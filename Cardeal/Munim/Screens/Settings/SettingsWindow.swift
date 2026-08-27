import SwiftUI

// MARK: - Janela de Configurações (independente, não-modal)

struct SettingsWindow: View {
    @StateObject private var model = SettingsViewModel()
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(model: model)
                .tag(SettingsTab.general)
                .tabItem { Label(SettingsTab.general.title, systemImage: SettingsTab.general.icon) }

            IntegrationsSettingsView(model: model)
                .tag(SettingsTab.integrations)
                .tabItem { Label(SettingsTab.integrations.title, systemImage: SettingsTab.integrations.icon) }

            ServerSettingsView(model: model)
                .tag(SettingsTab.server)
                .tabItem { Label(SettingsTab.server.title, systemImage: SettingsTab.server.icon) }

            TeamSettingsView(model: model)
                .tag(SettingsTab.team)
                .tabItem { Label(SettingsTab.team.title, systemImage: SettingsTab.team.icon) }

            AutomationsSettingsView(model: model)
                .tag(SettingsTab.automations)
                .tabItem { Label(SettingsTab.automations.title, systemImage: SettingsTab.automations.icon) }
        }
        .frame(minWidth: 760, idealWidth: 820, minHeight: 560, idealHeight: 640)
    }
}

// MARK: - Definição das abas

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case general
    case integrations
    case server
    case team
    case automations

    var id: Self { self }

    var title: String {
        switch self {
        case .general: "Geral"
        case .integrations: "Integrações"
        case .server: "Servidor & Backend"
        case .team: "Equipe"
        case .automations: "Automações"
        }
    }

    var icon: String {
        switch self {
        case .general: "gearshape"
        case .integrations: "link.badge.plus"
        case .server: "server.rack"
        case .team: "person.2"
        case .automations: "wand.and.stars"
        }
    }
}

// MARK: - 1. Geral

private struct GeneralSettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker("Tema da interface", selection: $model.appearance) {
                    ForEach(InterfaceAppearance.allCases) { appearance in
                        Text(appearance.title).tag(appearance)
                    }
                }
                Text("Selecione “Automático” para seguir a preferência do sistema.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Aparência")
            }

            Section {
                Picker("Sincronização", selection: $model.syncInterval) {
                    ForEach(SyncInterval.allCases) { interval in
                        Text(interval.rawValue).tag(interval)
                    }
                }
                .pickerStyle(.menu)
                Text("Define a frequência com que o Munim consulta o backend por atualizações.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Sincronização & atualizações")
            }

            Section {
                Toggle("Alertas de novas decisões detectadas", isOn: $model.notifyDecisions)
                Toggle("Notificar sobre tarefas executadas", isOn: $model.notifyTasks)
            } header: {
                Text("Notificações")
            } footer: {
                Text("As notificações respeitam o modo Foco do macOS.")
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 2. Integrações

private struct IntegrationsSettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                HStack(spacing: 10) {
                    Image(systemName: "globe")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    Text("Google Workspace")
                        .font(.headline)
                    Spacer()
                    ConnectionBadge(isConnected: !model.googleEmail.isEmpty)
                }

                if model.googleEmail.isEmpty {
                    LabeledContent("Status") {
                        Text("Desconectado")
                            .foregroundStyle(.secondary)
                    }
                    Button {
                        Task { await model.connectGoogle() }
                    } label: {
                        Label("Conectar Conta", systemImage: "person.crop.circle.badge.plus")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    LabeledContent("Conta") {
                        Text(model.googleEmail)
                            .foregroundStyle(.primary)
                    }
                    LabeledContent("Status") {
                        Text("Conectado")
                            .foregroundStyle(.green)
                    }
                    Button(role: .destructive) {
                        model.disconnectGoogle()
                    } label: {
                        Label("Desconectar Conta", systemImage: "person.crop.circle.badge.minus")
                    }
                }
            } header: {
                Text("Google Workspace")
            } footer: {
                if !model.googleEmail.isEmpty {
                    Text("Escopos ativos: \(activeScopeTags)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Escopos concedidos") {
                ForEach(GoogleScope.allCases) { scope in
                    LabeledContent {
                        if model.googleScopes.contains(scope) {
                            Tag(label: "Ativo", tint: .green)
                        } else {
                            Text("Inativo")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    } label: {
                        Label(scope.rawValue, systemImage: scope.icon)
                    }
                }
            }

            Section("Outros Aplicativos") {
                ForEach(model.integrations) { account in
                    IntegrationRow(
                        account: account,
                        onToggle: { Task { await model.toggleIntegration(account.integration) } }
                    )
                }
            }
        }
        .formStyle(.grouped)
    }

    private var activeScopeTags: String {
        let active = GoogleScope.allCases.filter { model.googleScopes.contains($0) }
        return active.isEmpty ? "Nenhum" : active.map(\.rawValue).joined(separator: ", ")
    }
}

private struct ConnectionBadge: View {
    let isConnected: Bool

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isConnected ? .green : Color.secondary.opacity(0.4))
                .frame(width: 8, height: 8)
            Text(isConnected ? "Conectado" : "Desconectado")
                .font(.caption.weight(.medium))
                .foregroundStyle(isConnected ? .green : .secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            (isConnected ? Color.green : Color.secondary).opacity(0.10),
            in: Capsule()
        )
    }
}

private struct Tag: View {
    let label: String
    let tint: Color

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(tint.opacity(0.18), in: Capsule())
            .foregroundStyle(tint)
    }
}

private struct IntegrationRow: View {
    let account: IntegrationAccount
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(account.integration.accent)
                Image(systemName: account.integration.icon)
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .semibold))
            }
            .frame(width: 28, height: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.integration.rawValue)
                    .font(.body.weight(.medium))
                Text(account.isConnected ? account.workspace : "Não conectado")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if account.isConnected {
                Button("Configurar") {}
                    .buttonStyle(.bordered)
            }
            Toggle("", isOn: Binding(
                get: { account.isConnected },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - 3. Servidor & Backend

private struct ServerSettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                LabeledContent("Status") {
                    Label {
                        Text(model.connectionStatus.title)
                            .foregroundStyle(model.connectionStatus.color)
                    } icon: {
                        Image(systemName: model.connectionStatus.icon)
                            .foregroundStyle(model.connectionStatus.color)
                    }
                }

                LabeledContent("URL Base da API") {
                    TextField("https://api.exemplo.com", text: $model.apiURL)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }

                LabeledContent("Porta") {
                    HStack(spacing: 8) {
                        TextField("5432", value: $model.apiPort, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Stepper("", value: $model.apiPort, in: 1...65_535)
                            .labelsHidden()
                    }
                }

                Toggle("Sincronizar com banco de dados local", isOn: $model.syncDatabase)

                Button {
                    Task { await model.testConnection() }
                } label: {
                    if model.connectionStatus == .testing {
                        Label("Testando…", systemImage: "arrow.triangle.2.circlepath")
                    } else {
                        Label("Testar conexão", systemImage: "bolt.horizontal.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.connectionStatus == .testing)
            } header: {
                Text("Conexão com Backend (PostgreSQL / API)")
            } footer: {
                Text("A porta padrão do PostgreSQL é 5432. O token é armazenado no Keychain ao salvar.")
                    .font(.caption)
            }

            Section {
                LabeledContent("Service Account") {
                    SecureField("Token de acesso", text: $model.serverToken)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }
                HStack {
                    Button("Gerar novo token") {
                        model.serverToken = "sat_" + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24).lowercased()
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                    Button("Salvar no Keychain") {}
                        .buttonStyle(.bordered)
                        .disabled(model.serverToken.isEmpty)
                }
            } header: {
                Text("Conta Server")
            } footer: {
                Text("Recomendamos a rotação do token a cada 90 dias.")
                    .font(.caption)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 4. Equipe

private struct TeamSettingsView: View {
    @ObservedObject var model: SettingsViewModel
    @State private var isAddingMember = false
    @State private var selection: SettingsMember.ID?

    var body: some View {
        VStack(spacing: 0) {
            Table(model.members, selection: $selection) {
                TableColumn("Membro") { member in
                    HStack(spacing: 10) {
                        MemberAvatar(initials: member.initials, role: member.role)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(member.name)
                                .font(.body.weight(.medium))
                            Text(member.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                TableColumn("Time") { member in
                    Text(member.team)
                }
                .width(min: 120, ideal: 160)
                TableColumn("Papel") { member in
                    Picker("", selection: roleBinding(for: member)) {
                        ForEach(SettingsTeamRole.allCases) { role in
                            Label(role.rawValue, systemImage: role.icon).tag(role)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 160)
                }
                .width(min: 140, ideal: 180)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 240)

            Divider()

            HStack(spacing: 10) {
                Button {
                    isAddingMember = true
                } label: {
                    Label("Adicionar", systemImage: "plus")
                }
                Button {
                    if let id = selection, let member = model.members.first(where: { $0.id == id }) {
                        model.removeMember(member)
                        selection = nil
                    }
                } label: {
                    Label("Remover", systemImage: "minus")
                }
                .disabled(selection == nil)
                Spacer()
                Text("\(model.members.count) membros")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(10)
        }
        .sheet(isPresented: $isAddingMember) {
            AddMemberSheet(model: model)
        }
    }

    private func roleBinding(for member: SettingsMember) -> Binding<SettingsTeamRole> {
        Binding(
            get: { member.role },
            set: { model.updateRole($0, for: member) }
        )
    }
}

private struct MemberAvatar: View {
    let initials: String
    let role: SettingsTeamRole

    var body: some View {
        ZStack {
            Circle()
                .fill(role.tint.opacity(0.18))
            Text(initials)
                .font(.caption.weight(.semibold))
                .foregroundStyle(role.tint)
        }
        .frame(width: 30, height: 30)
    }
}

private struct AddMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var model: SettingsViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var team: String = ""
    @State private var role: SettingsTeamRole = .member

    var body: some View {
        Form {
            TextField("Nome", text: $name)
            TextField("E-mail", text: $email)
            Picker("Time", selection: $team) {
                ForEach(model.teams) { Text($0.name).tag($0.name) }
            }
            Picker("Papel", selection: $role) {
                ForEach(SettingsTeamRole.allCases) { Text($0.rawValue).tag($0) }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Adicionar membro")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Adicionar") {
                    let resolvedTeam = team.isEmpty ? (model.teams.first?.name ?? "Geral") : team
                    model.addMember(
                        SettingsMember(name: name, email: email, team: resolvedTeam, role: role)
                    )
                    dismiss()
                }
                .disabled(
                    name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .frame(width: 420, height: 280)
        .onAppear { team = model.teams.first?.name ?? "" }
    }
}

// MARK: - 5. Automações

private struct AutomationsSettingsView: View {
    @ObservedObject var model: SettingsViewModel

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Sensibilidade de captura")
                        Spacer()
                        Text(sensitivityLabel)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $model.captureSensitivity, in: 0...1, step: 0.05)
                    HStack {
                        Text("Conservador").font(.caption2).foregroundStyle(.tertiary)
                        Spacer()
                        Text("Equilibrado").font(.caption2).foregroundStyle(.tertiary)
                        Spacer()
                        Text("Agressivo").font(.caption2).foregroundStyle(.tertiary)
                    }
                }
                .padding(.vertical, 4)

                Text("Define o quão criterioso o Munim deve ser ao sugerir decisões e agendamentos a partir das conversas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Regras de Ação")
            }

            Section {
                Toggle(isOn: $model.requiresSchedulingConfirmation) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Exigir confirmação manual prévia antes de criar agendamentos no calendário")
                        Text("Quando desativado, o Munim cria eventos automaticamente. Recomendado para times pequenos.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.switch)
            } header: {
                Text("Confirmações")
            }
        }
        .formStyle(.grouped)
    }

    private var sensitivityLabel: String {
        let value = Int(model.captureSensitivity * 100)
        return "\(value)%"
    }
}

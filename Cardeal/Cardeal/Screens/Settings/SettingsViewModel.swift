import Combine
import SwiftUI

// MARK: - Aparência

enum InterfaceAppearance: String, CaseIterable, Identifiable {
    case system, light, dark

    static let storageKey = "settings.interfaceAppearance"
    var id: Self { self }
    var title: String {
        switch self {
        case .system: "Automático"
        case .light: "Claro"
        case .dark: "Escuro"
        }
    }
    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon.stars"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

// MARK: - Sincronização

enum SyncInterval: String, CaseIterable, Identifiable {
    case realtime = "Tempo real (WebSocket)"
    case fiveMinutes = "A cada 5 minutos"
    case fifteenMinutes = "A cada 15 minutos"
    case thirtyMinutes = "A cada 30 minutos"
    case manual = "Manual"

    var id: Self { self }
    var icon: String {
        switch self {
        case .realtime: "bolt.horizontal.fill"
        case .fiveMinutes: "5.circle"
        case .fifteenMinutes: "15.circle"
        case .thirtyMinutes: "30.circle"
        case .manual: "hand.raised"
        }
    }
}

// MARK: - Conexão / Backend

enum ConnectionStatus: Equatable {
    case unknown
    case testing
    case online(pingMs: Int)
    case offline(reason: String)

    var title: String {
        switch self {
        case .unknown: "Não verificado"
        case .testing: "Verificando…"
        case .online(let ping): "Online · \(ping) ms"
        case .offline: "Offline"
        }
    }

    var color: Color {
        switch self {
        case .unknown: .secondary
        case .testing: .orange
        case .online: .green
        case .offline: .red
        }
    }

    var icon: String {
        switch self {
        case .unknown: "questionmark.circle"
        case .testing: "arrow.triangle.2.circlepath"
        case .online: "checkmark.circle.fill"
        case .offline: "xmark.circle.fill"
        }
    }

    var isHealthy: Bool {
        if case .online = self { return true }
        return false
    }
}

// MARK: - Google Workspace

enum GoogleScope: String, CaseIterable, Identifiable {
    case calendar = "Google Calendar"
    case gmail = "Gmail"
    case drive = "Google Drive"
    case chat = "Google Chat"
    case meet = "Google Meet"

    var id: Self { self }
    var icon: String {
        switch self {
        case .calendar: "calendar"
        case .gmail: "envelope"
        case .drive: "externaldrive"
        case .chat: "message"
        case .meet: "video"
        }
    }
}

// MARK: - Integrações de terceiros

enum ThirdPartyIntegration: String, CaseIterable, Identifiable, Codable {
    case slack = "Slack"
    case notion = "Notion"

    var id: Self { self }
    var icon: String {
        switch self {
        case .slack: "number"
        case .notion: "doc.text"
        }
    }
    var accent: Color {
        switch self {
        case .slack: Color(red: 0.40, green: 0.22, blue: 0.91)
        case .notion: Color(red: 0.16, green: 0.16, blue: 0.18)
        }
    }
}

struct IntegrationAccount: Identifiable, Codable, Equatable {
    var id: UUID
    var integration: ThirdPartyIntegration
    var workspace: String
    var isConnected: Bool

    init(
        id: UUID = UUID(),
        integration: ThirdPartyIntegration,
        workspace: String,
        isConnected: Bool
    ) {
        self.id = id
        self.integration = integration
        self.workspace = workspace
        self.isConnected = isConnected
    }
}

// MARK: - Equipe

enum SettingsTeamRole: String, CaseIterable, Identifiable, Codable {
    case admin = "Admin"
    case member = "Membro"
    case observer = "Observador"

    var id: Self { self }

    var icon: String {
        switch self {
        case .admin: "key.fill"
        case .member: "person.fill"
        case .observer: "eye.fill"
        }
    }

    var tint: Color {
        switch self {
        case .admin: .accentColor
        case .member: .secondary
        case .observer: .gray
        }
    }
}

struct SettingsMember: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var email: String
    var team: String
    var role: SettingsTeamRole
    var isActive: Bool = true

    var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        return parts.compactMap { $0.first.map(String.init) }.joined().uppercased()
    }
}

struct SettingsTeam: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var name: String
    var channels: [String]
}

// MARK: - ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    private enum Key {
        static let palette = "appTheme"
        static let appearance = InterfaceAppearance.storageKey
        static let sync = "settings.syncInterval"
        static let decisions = "settings.notifyDecisions"
        static let tasks = "settings.notifyTasks"
        static let apiURL = "settings.apiURL"
        static let apiPort = "settings.apiPort"
        static let syncDatabase = "settings.syncDatabase"
        static let serverToken = "settings.serverToken"
        static let googleEmail = "settings.googleEmail"
        static let googleScopes = "settings.googleScopes"
        static let integrations = "settings.integrations"
        static let members = "settings.members"
        static let teams = "settings.teams"
        static let sensitivity = "settings.sensitivity"
        static let confirmation = "settings.confirmation"
    }

    private let defaults: UserDefaults

    // Geral
    @Published var palette: AppTheme { didSet { defaults.set(palette.rawValue, forKey: Key.palette) } }
    @Published var appearance: InterfaceAppearance { didSet { defaults.set(appearance.rawValue, forKey: Key.appearance) } }
    @Published var syncInterval: SyncInterval { didSet { defaults.set(syncInterval.rawValue, forKey: Key.sync) } }
    @Published var notifyDecisions: Bool { didSet { defaults.set(notifyDecisions, forKey: Key.decisions) } }
    @Published var notifyTasks: Bool { didSet { defaults.set(notifyTasks, forKey: Key.tasks) } }

    // Servidor
    @Published var apiURL: String { didSet { defaults.set(apiURL, forKey: Key.apiURL) } }
    @Published var apiPort: Int { didSet { defaults.set(apiPort, forKey: Key.apiPort) } }
    @Published var syncDatabase: Bool { didSet { defaults.set(syncDatabase, forKey: Key.syncDatabase) } }
    @Published var serverToken: String { didSet { defaults.set(serverToken, forKey: Key.serverToken) } }
    @Published var connectionStatus: ConnectionStatus = .unknown

    // Integrações
    @Published var googleEmail: String { didSet { defaults.set(googleEmail, forKey: Key.googleEmail) } }
    @Published var googleScopes: Set<GoogleScope> { didSet { save(googleScopes.map(\.rawValue), key: Key.googleScopes) } }
    @Published var integrations: [IntegrationAccount] { didSet { save(integrations, key: Key.integrations) } }

    // Equipe
    @Published var members: [SettingsMember] { didSet { save(members, key: Key.members) } }
    @Published var teams: [SettingsTeam] { didSet { save(teams, key: Key.teams) } }

    // Automações
    @Published var captureSensitivity: Double { didSet { defaults.set(captureSensitivity, forKey: Key.sensitivity) } }
    @Published var requiresSchedulingConfirmation: Bool { didSet { defaults.set(requiresSchedulingConfirmation, forKey: Key.confirmation) } }

    // MARK: Init

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        palette = AppTheme(storedValue: defaults.string(forKey: Key.palette) ?? AppTheme.defaultTheme.rawValue)
        appearance = InterfaceAppearance(rawValue: defaults.string(forKey: Key.appearance) ?? "") ?? .system
        syncInterval = SyncInterval(rawValue: defaults.string(forKey: Key.sync) ?? "") ?? .fifteenMinutes
        notifyDecisions = Self.bool(defaults, Key.decisions, true)
        notifyTasks = Self.bool(defaults, Key.tasks, true)

        apiURL = defaults.string(forKey: Key.apiURL) ?? "https://api.cardeal.local"
        apiPort = Self.int(defaults, Key.apiPort, 5432)
        syncDatabase = Self.bool(defaults, Key.syncDatabase, true)
        serverToken = defaults.string(forKey: Key.serverToken) ?? ""

        googleEmail = defaults.string(forKey: Key.googleEmail) ?? ""
        googleScopes = Set(
            Self.load([String].self, defaults, Key.googleScopes)?
                .compactMap(GoogleScope.init(rawValue:)) ?? [.calendar, .gmail]
        )
        integrations = Self.load([IntegrationAccount].self, defaults, Key.integrations) ?? Self.defaultIntegrations
        members = Self.load([SettingsMember].self, defaults, Key.members) ?? Self.defaultMembers
        teams = Self.load([SettingsTeam].self, defaults, Key.teams) ?? Self.defaultTeams

        captureSensitivity = Self.double(defaults, Key.sensitivity, 0.6)
        requiresSchedulingConfirmation = Self.bool(defaults, Key.confirmation, true)
    }

    // MARK: Ações

    func testConnection() async {
        connectionStatus = .testing
        try? await Task.sleep(for: .seconds(0.8))
        let ping = Int.random(in: 18...84)
        connectionStatus = .online(pingMs: ping)
    }

    func connectGoogle() async {
        try? await Task.sleep(for: .seconds(0.6))
        googleEmail = "beatriz@cardeal.com"
        googleScopes = [.calendar, .gmail, .drive]
    }

    func disconnectGoogle() {
        googleEmail = ""
        googleScopes = []
    }

    func toggleIntegration(_ integration: ThirdPartyIntegration) async {
        guard let index = integrations.firstIndex(where: { $0.integration == integration }) else { return }
        if integrations[index].isConnected {
            integrations[index].isConnected = false
            integrations[index].workspace = ""
        } else {
            try? await Task.sleep(for: .milliseconds(450))
            integrations[index].isConnected = true
            integrations[index].workspace = "\(integration.rawValue) · Workspace Cardeal"
        }
    }

    func addMember(_ member: SettingsMember) {
        members.append(member)
    }

    func removeMember(_ member: SettingsMember) {
        members.removeAll { $0.id == member.id }
    }

    func updateRole(_ role: SettingsTeamRole, for member: SettingsMember) {
        guard let index = members.firstIndex(where: { $0.id == member.id }) else { return }
        members[index].role = role
    }

    func addChannel(_ channel: String, to team: SettingsTeam) {
        let value = channel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty,
              let index = teams.firstIndex(where: { $0.id == team.id }),
              !teams[index].channels.contains(value) else { return }
        teams[index].channels.append(value)
    }

    func removeChannel(_ channel: String, from team: SettingsTeam) {
        guard let index = teams.firstIndex(where: { $0.id == team.id }) else { return }
        teams[index].channels.removeAll { $0 == channel }
    }

    // MARK: Persistência

    private func save<Value: Encodable>(_ value: Value, key: String) {
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<Value: Decodable>(_ type: Value.Type, _ defaults: UserDefaults, _ key: String) -> Value? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private static func bool(_ defaults: UserDefaults, _ key: String, _ fallback: Bool) -> Bool {
        defaults.object(forKey: key) as? Bool ?? fallback
    }

    private static func int(_ defaults: UserDefaults, _ key: String, _ fallback: Int) -> Int {
        defaults.object(forKey: key) as? Int ?? fallback
    }

    private static func double(_ defaults: UserDefaults, _ key: String, _ fallback: Double) -> Double {
        defaults.object(forKey: key) as? Double ?? fallback
    }

    // MARK: Defaults

    private static let defaultMembers: [SettingsMember] = [
        SettingsMember(name: "Fabíola Machado", email: "fabiola@cardeal.com", team: "Atendimento", role: .admin),
        SettingsMember(name: "Aline Souza", email: "aline@cardeal.com", team: "Design", role: .member),
        SettingsMember(name: "Rafael Lima", email: "rafael@cardeal.com", team: "Engenharia", role: .observer)
    ]

    private static let defaultTeams: [SettingsTeam] = [
        SettingsTeam(name: "Atendimento", channels: ["#atendimento-geral"]),
        SettingsTeam(name: "Design", channels: ["#design-system"]),
        SettingsTeam(name: "Engenharia", channels: ["#engenharia"])
    ]

    private static let defaultIntegrations: [IntegrationAccount] = [
        IntegrationAccount(integration: .slack, workspace: "", isConnected: false),
        IntegrationAccount(integration: .notion, workspace: "", isConnected: false)
    ]
}


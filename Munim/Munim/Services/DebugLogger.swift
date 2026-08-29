import Foundation
import SwiftUI

// MARK: - DebugLogger
// Logger em memória para acompanhar em tempo real o que está acontecendo
// entre o app Munim e o backend Vapor.

@Observable
@MainActor
final class DebugLogger {
    static let shared = DebugLogger()
    private init() {}

    struct LogEntry: Identifiable, Hashable {
        let id = UUID()
        let timestamp: Date = Date()
        let level: LogLevel
        let category: String
        let message: String
        let details: String?

        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm:ss.SSS"
            return formatter.string(from: timestamp)
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }

        static func == (lhs: LogEntry, rhs: LogEntry) -> Bool {
            lhs.id == rhs.id
        }
    }

    enum LogLevel: String, CaseIterable {
        case info = "INFO"
        case success = "SUCCESS"
        case warning = "WARN"
        case error = "ERROR"

        var color: Color {
            switch self {
            case .info: return .blue
            case .success: return .green
            case .warning: return .orange
            case .error: return .red
            }
        }

        var icon: String {
            switch self {
            case .info: return "info.circle"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            }
        }
    }

    var logs: [LogEntry] = []
    private let maxLogs = 300

    func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "App",
        details: String? = nil
    ) {
        let entry = LogEntry(level: level, category: category, message: message, details: details)
        logs.insert(entry, at: 0)
        if logs.count > maxLogs {
            logs.removeLast()
        }
        
        let prefix = "[\(entry.formattedTime)][\(entry.category)][\(entry.level.rawValue)]"
        print("\(prefix) \(message)")
        if let details {
            print("\(prefix) ↳ \(details.prefix(500))")
        }
    }

    func clear() {
        logs.removeAll()
    }
}

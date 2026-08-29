import Foundation
import Security

// MARK: - KeychainHelper
// Wrapper simples sobre o Security framework para guardar/ler/deletar
// o JWT do usuário no macOS Keychain (sem dependências externas).

enum KeychainHelper {
    private static let service = "br.com.Cardeal.Munim"

    // MARK: - Salvar
    @discardableResult
    static func save(_ value: String, forKey key: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Remover item anterior (update seguro)
        delete(forKey: key)

        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Ler
    static func read(forKey key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      key,
            kSecReturnData:       kCFBooleanTrue as Any,
            kSecMatchLimit:       kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    // MARK: - Deletar
    @discardableResult
    static func delete(forKey key: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}

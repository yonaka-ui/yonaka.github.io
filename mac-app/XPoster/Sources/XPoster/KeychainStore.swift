import Foundation
import Security

/// Stores the X (Twitter) API credentials in the macOS Keychain instead of on disk in plain text.
enum KeychainStore {
    private static let service = "com.yonaka.xposter"

    struct Credentials {
        var apiKey: String
        var apiSecret: String
        var accessToken: String
        var accessTokenSecret: String

        var isComplete: Bool {
            !apiKey.isEmpty && !apiSecret.isEmpty && !accessToken.isEmpty && !accessTokenSecret.isEmpty
        }
    }

    private static func set(_ value: String, forAccount account: String) {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)

        guard !value.isEmpty else { return }

        var attributes = query
        attributes[kSecValueData as String] = data
        SecItemAdd(attributes as CFDictionary, nil)
    }

    private static func get(forAccount account: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func load() -> Credentials {
        Credentials(
            apiKey: get(forAccount: "apiKey"),
            apiSecret: get(forAccount: "apiSecret"),
            accessToken: get(forAccount: "accessToken"),
            accessTokenSecret: get(forAccount: "accessTokenSecret")
        )
    }

    static func save(_ credentials: Credentials) {
        set(credentials.apiKey, forAccount: "apiKey")
        set(credentials.apiSecret, forAccount: "apiSecret")
        set(credentials.accessToken, forAccount: "accessToken")
        set(credentials.accessTokenSecret, forAccount: "accessTokenSecret")
    }
}

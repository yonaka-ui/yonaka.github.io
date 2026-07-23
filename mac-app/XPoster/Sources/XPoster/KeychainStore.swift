import Foundation
import Security

/// Stores API credentials in the macOS Keychain instead of on disk in plain text.
enum KeychainStore {
    private static let service = "com.yonaka.xposter"

    struct BlueskyCredentials {
        /// Handle or email, e.g. "yonaka.bsky.social"
        var identifier: String
        /// An "App Password" generated in Bluesky Settings > App Passwords (not the main account password)
        var appPassword: String

        var isComplete: Bool {
            !identifier.isEmpty && !appPassword.isEmpty
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

    static func loadBluesky() -> BlueskyCredentials {
        BlueskyCredentials(
            identifier: get(forAccount: "bsky_identifier"),
            appPassword: get(forAccount: "bsky_appPassword")
        )
    }

    static func saveBluesky(_ credentials: BlueskyCredentials) {
        set(credentials.identifier, forAccount: "bsky_identifier")
        set(credentials.appPassword, forAccount: "bsky_appPassword")
    }
}

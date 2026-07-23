import Foundation

enum BlueskyClientError: LocalizedError {
    case missingCredentials
    case unreadableImage
    case server(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "設定画面でBlueskyのアカウント情報を入力してください。"
        case .unreadableImage:
            return "画像を読み込めませんでした。"
        case .server(let status, let body):
            return "Bluesky APIエラー (\(status)): \(body)"
        }
    }
}

/// Posts to Bluesky via the AT Protocol XRPC API using an account handle + App Password.
/// Free for any Bluesky account, no developer registration or billing involved.
enum BlueskyClient {
    private static let baseURL = "https://bsky.social/xrpc"

    private struct Session {
        let accessJwt: String
        let did: String
    }

    private static func createSession(credentials: KeychainStore.BlueskyCredentials) async throws -> Session {
        let url = URL(string: "\(baseURL)/com.atproto.server.createSession")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "identifier": credentials.identifier,
            "password": credentials.appPassword
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw BlueskyClientError.server(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }

        struct SessionResponse: Decodable { let accessJwt: String; let did: String }
        let decoded = try JSONDecoder().decode(SessionResponse.self, from: data)
        return Session(accessJwt: decoded.accessJwt, did: decoded.did)
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "png": return "image/png"
        case "gif": return "image/gif"
        default: return "image/jpeg"
        }
    }

    private static func uploadBlob(fileURL: URL, session: Session) async throws -> [String: Any] {
        guard let imageData = try? Data(contentsOf: fileURL) else { throw BlueskyClientError.unreadableImage }

        let url = URL(string: "\(baseURL)/com.atproto.repo.uploadBlob")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(mimeType(for: fileURL), forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessJwt)", forHTTPHeaderField: "Authorization")
        request.httpBody = imageData

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw BlueskyClientError.server(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let blob = json["blob"] as? [String: Any]
        else {
            throw BlueskyClientError.server(status: status, body: "unexpected upload response")
        }
        return blob
    }

    static func post(text: String, imageURL: URL?, credentials: KeychainStore.BlueskyCredentials) async throws {
        guard credentials.isComplete else { throw BlueskyClientError.missingCredentials }

        let session = try await createSession(credentials: credentials)

        var record: [String: Any] = [
            "$type": "app.bsky.feed.post",
            "text": text,
            "createdAt": ISO8601DateFormatter().string(from: Date())
        ]

        if let imageURL {
            let blob = try await uploadBlob(fileURL: imageURL, session: session)
            record["embed"] = [
                "$type": "app.bsky.embed.images",
                "images": [["image": blob, "alt": ""]]
            ]
        }

        let url = URL(string: "\(baseURL)/com.atproto.repo.createRecord")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessJwt)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "repo": session.did,
            "collection": "app.bsky.feed.post",
            "record": record
        ])

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw BlueskyClientError.server(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

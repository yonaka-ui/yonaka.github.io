import Foundation
import CryptoKit

enum TwitterClientError: LocalizedError {
    case missingCredentials
    case unreadableImage
    case server(status: Int, body: String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials:
            return "設定画面でXのAPIキーを入力してください。"
        case .unreadableImage:
            return "画像を読み込めませんでした。"
        case .server(let status, let body):
            return "X APIエラー (\(status)): \(body)"
        }
    }
}

/// Minimal OAuth 1.0a request signer (HMAC-SHA1), as required by both
/// api.twitter.com/2/tweets and upload.twitter.com/1.1/media/upload.json.
private enum OAuth1 {
    static func authorizationHeader(
        method: String,
        url: URL,
        credentials: KeychainStore.XCredentials,
        extraParams: [String: String] = [:]
    ) -> String {
        var oauthParams: [String: String] = [
            "oauth_consumer_key": credentials.apiKey,
            "oauth_nonce": UUID().uuidString.replacingOccurrences(of: "-", with: ""),
            "oauth_signature_method": "HMAC-SHA1",
            "oauth_timestamp": String(Int(Date().timeIntervalSince1970)),
            "oauth_token": credentials.accessToken,
            "oauth_version": "1.0"
        ]

        var allParams = oauthParams
        for (key, value) in extraParams { allParams[key] = value }

        let paramString = allParams
            .map { (percentEncode($0.key), percentEncode($0.value)) }
            .sorted { $0.0 < $1.0 }
            .map { "\($0.0)=\($0.1)" }
            .joined(separator: "&")

        let baseString = [
            method.uppercased(),
            percentEncode(url.absoluteString),
            percentEncode(paramString)
        ].joined(separator: "&")

        let signingKey = "\(percentEncode(credentials.apiSecret))&\(percentEncode(credentials.accessTokenSecret))"

        let key = SymmetricKey(data: Data(signingKey.utf8))
        let signature = HMAC<Insecure.SHA1>.authenticationCode(for: Data(baseString.utf8), using: key)
        let signatureBase64 = Data(signature).base64EncodedString()

        oauthParams["oauth_signature"] = signatureBase64

        let headerParams = oauthParams
            .sorted { $0.key < $1.key }
            .map { "\(percentEncode($0.key))=\"\(percentEncode($0.value))\"" }
            .joined(separator: ", ")

        return "OAuth \(headerParams)"
    }

    static func percentEncode(_ string: String) -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        return string.addingPercentEncoding(withAllowedCharacters: allowed) ?? string
    }
}

enum TwitterClient {
    /// Uploads a small image (<5MB, jpg/png/gif) via the classic "simple upload" flow
    /// and returns the resulting media_id_string to attach to a tweet.
    static func uploadImage(fileURL: URL, credentials: KeychainStore.XCredentials) async throws -> String {
        guard credentials.isComplete else { throw TwitterClientError.missingCredentials }
        guard let imageData = try? Data(contentsOf: fileURL) else { throw TwitterClientError.unreadableImage }

        let uploadURL = URL(string: "https://upload.twitter.com/1.1/media/upload.json")!
        let boundary = "Boundary-\(UUID().uuidString)"

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"media\"; filename=\"\(fileURL.lastPathComponent)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(
            OAuth1.authorizationHeader(method: "POST", url: uploadURL, credentials: credentials),
            forHTTPHeaderField: "Authorization"
        )
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw TwitterClientError.server(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }

        struct UploadResponse: Decodable { let media_id_string: String }
        return try JSONDecoder().decode(UploadResponse.self, from: data).media_id_string
    }

    /// Posts a tweet via API v2, optionally attaching a previously uploaded media id.
    static func postTweet(text: String, mediaId: String?, credentials: KeychainStore.XCredentials) async throws {
        guard credentials.isComplete else { throw TwitterClientError.missingCredentials }

        let tweetURL = URL(string: "https://api.twitter.com/2/tweets")!

        var payload: [String: Any] = ["text": text]
        if let mediaId {
            payload["media"] = ["media_ids": [mediaId]]
        }

        var request = URLRequest(url: tweetURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(
            OAuth1.authorizationHeader(method: "POST", url: tweetURL, credentials: credentials),
            forHTTPHeaderField: "Authorization"
        )
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200...201).contains(status) else {
            throw TwitterClientError.server(status: status, body: String(data: data, encoding: .utf8) ?? "")
        }
    }
}

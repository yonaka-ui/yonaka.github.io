import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var apiSecret: String = ""
    @State private var accessToken: String = ""
    @State private var accessTokenSecret: String = ""

    @State private var bskyIdentifier: String = ""
    @State private var bskyAppPassword: String = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("X API 設定").font(.headline)
                    Text("developer.x.com でアプリを作成し、\"Read and Write\" 権限のキーを発行してください(有料プランが必要な場合があります)。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LabeledField(title: "API Key", text: $apiKey)
                    LabeledField(title: "API Key Secret", text: $apiSecret)
                    LabeledField(title: "Access Token", text: $accessToken)
                    LabeledField(title: "Access Token Secret", text: $accessTokenSecret)
                }

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text("Bluesky 設定").font(.headline)
                    Text("Bluesky設定 > プライバシーとセキュリティ > App Passwords で発行したパスワードを使ってください(無料、審査不要)。")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    LabeledField(title: "ハンドル (例: you.bsky.social)", text: $bskyIdentifier, isSecure: false)
                    LabeledField(title: "App Password", text: $bskyAppPassword)
                }

                HStack {
                    Spacer()
                    Button("キャンセル") { dismiss() }
                    Button("保存") {
                        KeychainStore.saveX(
                            KeychainStore.XCredentials(
                                apiKey: apiKey,
                                apiSecret: apiSecret,
                                accessToken: accessToken,
                                accessTokenSecret: accessTokenSecret
                            )
                        )
                        KeychainStore.saveBluesky(
                            KeychainStore.BlueskyCredentials(
                                identifier: bskyIdentifier,
                                appPassword: bskyAppPassword
                            )
                        )
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding(16)
        }
        .frame(width: 360, height: 420)
        .onAppear {
            let savedX = KeychainStore.loadX()
            apiKey = savedX.apiKey
            apiSecret = savedX.apiSecret
            accessToken = savedX.accessToken
            accessTokenSecret = savedX.accessTokenSecret

            let savedBluesky = KeychainStore.loadBluesky()
            bskyIdentifier = savedBluesky.identifier
            bskyAppPassword = savedBluesky.appPassword
        }
    }
}

private struct LabeledField: View {
    let title: String
    @Binding var text: String
    var isSecure: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if isSecure {
                SecureField(title, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(title, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }
}

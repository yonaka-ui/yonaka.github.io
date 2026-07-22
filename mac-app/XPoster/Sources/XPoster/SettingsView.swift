import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""
    @State private var apiSecret: String = ""
    @State private var accessToken: String = ""
    @State private var accessTokenSecret: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("X API 設定")
                .font(.headline)

            Text("developer.x.com でアプリを作成し、\"Read and Write\" 権限のキーを発行してください。")
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledField(title: "API Key", text: $apiKey)
            LabeledField(title: "API Key Secret", text: $apiSecret)
            LabeledField(title: "Access Token", text: $accessToken)
            LabeledField(title: "Access Token Secret", text: $accessTokenSecret)

            HStack {
                Spacer()
                Button("キャンセル") { dismiss() }
                Button("保存") {
                    KeychainStore.save(
                        KeychainStore.Credentials(
                            apiKey: apiKey,
                            apiSecret: apiSecret,
                            accessToken: accessToken,
                            accessTokenSecret: accessTokenSecret
                        )
                    )
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .frame(width: 340)
        .onAppear {
            let saved = KeychainStore.load()
            apiKey = saved.apiKey
            apiSecret = saved.apiSecret
            accessToken = saved.accessToken
            accessTokenSecret = saved.accessTokenSecret
        }
    }
}

private struct LabeledField: View {
    let title: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            SecureField(title, text: $text)
                .textFieldStyle(.roundedBorder)
        }
    }
}

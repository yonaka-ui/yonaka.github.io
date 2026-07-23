import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var bskyIdentifier: String = ""
    @State private var bskyAppPassword: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bluesky 設定").font(.headline)
            Text("Bluesky設定 > プライバシーとセキュリティ > App Passwords で発行したパスワードを使ってください(無料、審査不要)。")
                .font(.caption)
                .foregroundStyle(.secondary)

            LabeledField(title: "ハンドル (例: you.bsky.social)", text: $bskyIdentifier, isSecure: false)
            LabeledField(title: "App Password", text: $bskyAppPassword)

            HStack {
                Spacer()
                Button("キャンセル") { dismiss() }
                Button("保存") {
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
        .frame(width: 340)
        .onAppear {
            let saved = KeychainStore.loadBluesky()
            bskyIdentifier = saved.identifier
            bskyAppPassword = saved.appPassword
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

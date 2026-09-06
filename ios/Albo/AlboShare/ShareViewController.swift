import UIKit
import SwiftUI
import UniformTypeIdentifiers

/// The "Add to Albo" entry in every other app's share sheet.
///
/// Albo's own extension takes whatever you hand it and gets out of the way, so this does the
/// same: it reads the attachments while the sheet animates in, lets you confirm a category,
/// writes an `InboxItem` into the App Group, and closes. The real import (Claude reading the
/// page) runs in the app the next time it opens, which is also the only place the user's
/// session and credits live.
final class ShareViewController: UIViewController {
    private var payload = SharePayload()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear

        let root = ShareSheetView(
            payload: payload,
            onSave: { [weak self] item in self?.commit(item) },
            onCancel: { [weak self] in self?.close() }
        )
        let host = UIHostingController(rootView: root)
        host.view.backgroundColor = .clear
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        host.didMove(toParent: self)

        Task { await load() }
    }

    // MARK: Reading what was shared

    private func load() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            payload.finish()
            return
        }
        for item in items {
            for provider in item.attachments ?? [] {
                await read(provider)
            }
        }
        payload.finish()
    }

    private func read(_ provider: NSItemProvider) async {
        if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
            if let url = await provider.loadURL() {
                payload.set(url: url)
                return
            }
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
            if let data = await provider.loadImageData() {
                payload.add(image: data)
                return
            }
        }
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
            if let text = await provider.loadText() {
                // A bare URL pasted as text is still a link.
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if let url = URL(string: trimmed), url.scheme?.hasPrefix("http") == true {
                    payload.set(url: url)
                } else {
                    payload.set(text: text)
                }
            }
        }
    }

    // MARK: Handing it to the app

    private func commit(_ item: InboxItem) {
        ShareInbox.append(item)
        close()
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}

// MARK: - NSItemProvider bridging

private extension NSItemProvider {
    func loadURL() async -> URL? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.url.identifier) { value, _ in
                continuation.resume(returning: value as? URL)
            }
        }
    }

    func loadText() async -> String? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.plainText.identifier) { value, _ in
                continuation.resume(returning: value as? String)
            }
        }
    }

    func loadImageData() async -> Data? {
        await withCheckedContinuation { continuation in
            loadItem(forTypeIdentifier: UTType.image.identifier) { value, _ in
                if let data = value as? Data {
                    continuation.resume(returning: data)
                } else if let url = value as? URL {
                    continuation.resume(returning: try? Data(contentsOf: url))
                } else if let image = value as? UIImage {
                    continuation.resume(returning: image.jpegData(compressionQuality: 0.85))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

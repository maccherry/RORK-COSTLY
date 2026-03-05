import UIKit

struct InstagramStoriesService {
    static var canShareToStories: Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    static func shareToStories(_ image: UIImage) {
        guard let url = URL(string: "instagram-stories://share?source_application=\(Bundle.main.bundleIdentifier ?? "")") else { return }
        guard let imageData = image.pngData() else { return }

        let pasteboardItems: [[String: Any]] = [[
            "com.instagram.sharedSticker.backgroundImage": imageData
        ]]
        let pasteboardOptions: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(60 * 5)
        ]

        UIPasteboard.general.setItems(pasteboardItems, options: pasteboardOptions)
        UIApplication.shared.open(url)
    }
}

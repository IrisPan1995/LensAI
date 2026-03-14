import Foundation
import UIKit

class ClaudeService {
    static let shared = ClaudeService()

    // MARK: - Change this to your deployed backend URL
    // Local testing:  http://localhost:8000
    // Deployed:       https://your-server.railway.app  (or Render, Fly.io, etc.)
    private let backendURL = "http://localhost:8000/analyze"

    func analyze(_ image: UIImage) async throws -> ScanResult {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw LensAIError.imageFail
        }

        // Build multipart/form-data request
        let boundary = UUID().uuidString
        var request = URLRequest(url: URL(string: backendURL)!)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"scan.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw LensAIError.api("HTTP \(code): \(bodyStr)")
        }

        let parsed = try JSONDecoder().decode(ScanResult.self, from: data)
        return ScanResult(
            title: parsed.title, zhName: parsed.zhName, subtitle: parsed.subtitle,
            category: parsed.category, what: parsed.what, context: parsed.context,
            tips: parsed.tips, commonAllergens: parsed.commonAllergens,
            imageData: image.jpegData(compressionQuality: 0.5)
        )
    }
}

// MARK: - Errors

enum LensAIError: LocalizedError {
    case imageFail, api(String), noResp, parse
    var errorDescription: String? {
        switch self {
        case .imageFail: return "Failed to process image"
        case .api(let m): return "API Error: \(m)"
        case .noResp: return "No AI response"
        case .parse: return "Failed to parse AI response"
        }
    }
}

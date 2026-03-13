import Foundation
import UIKit

class ClaudeService {
    static let shared = ClaudeService()

    private let apiKey = "YOUR_ANTHROPIC_API_KEY"
    private let endpoint = "https://api.anthropic.com/v1/messages"
    private let model = "claude-sonnet-4-20250514"

    private struct APIResponse: Decodable {
        let content: [ContentBlock]
        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }

    func analyze(_ image: UIImage) async throws -> ScanResult {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw LensAIError.imageFail
        }
        let b64 = jpeg.base64EncodedString()

        let systemPrompt = """
        You are a friendly cultural guide for foreigners visiting China.
        Analyze the image and respond ONLY with valid JSON. No markdown, no backticks, no extra text.
        {"title":"Pinyin or English name","zhName":"Chinese characters","subtitle":"Brief English description","category":"Food|Sign|Product|Document|Place|Other","what":"What it is (1-2 sentences)","context":"Cultural context (2-3 sentences)","tips":"Practical tips for a foreigner (1-2 sentences)","commonAllergens":"List allergens if food, else empty string"}
        If food: taste, allergens, how to order. If sign: what action. If medicine: usage, dosage. English only. Friendly tone.
        """

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 1024,
            "system": systemPrompt,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/jpeg",
                            "data": b64
                        ]
                    ],
                    [
                        "type": "text",
                        "text": "Analyze this image. Help me understand it as a foreigner in China."
                    ]
                ]
            ]]
        ]

        var req = URLRequest(url: URL(string: endpoint)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw LensAIError.api("HTTP \(code): \(bodyStr)")
        }

        let apiResp = try JSONDecoder().decode(APIResponse.self, from: data)
        guard let text = apiResp.content.first?.text else {
            throw LensAIError.noResp
        }

        let clean = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = clean.data(using: .utf8) else {
            throw LensAIError.parse
        }

        let parsed = try JSONDecoder().decode(ScanResult.self, from: jsonData)
        return ScanResult(
            title: parsed.title, zhName: parsed.zhName, subtitle: parsed.subtitle,
            category: parsed.category, what: parsed.what, context: parsed.context,
            tips: parsed.tips, commonAllergens: parsed.commonAllergens,
            imageData: image.jpegData(compressionQuality: 0.5)
        )
    }
}

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

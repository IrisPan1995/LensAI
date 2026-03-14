import Foundation
import UIKit

class ClaudeService {
    static let shared = ClaudeService()

    private let apiKey = "YOUR_GOOGLE_API_KEY"

    private let systemPrompt = """
    You are a friendly cultural guide for foreigners visiting China.
    Analyze the image and respond ONLY with valid JSON. No markdown, no backticks, no extra text.
    {"title":"Pinyin or English name","zhName":"Chinese characters","subtitle":"Brief English description","category":"Food|Sign|Product|Document|Place|Other","what":"What it is (1-2 sentences)","context":"Cultural context (2-3 sentences)","tips":"Practical tips for a foreigner (1-2 sentences)","commonAllergens":"List allergens if food, else empty string"}
    If food: taste, allergens, how to order. If sign: what action. If medicine: usage, dosage. English only. Friendly tone.
    """

    func analyze(_ image: UIImage) async throws -> ScanResult {
        guard let jpeg = image.jpegData(compressionQuality: 0.7) else {
            throw LensAIError.imageFail
        }
        let b64 = jpeg.base64EncodedString()

        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=\(apiKey)"

        let body: [String: Any] = [
            "systemInstruction": [
                "parts": [["text": systemPrompt]]
            ],
            "contents": [[
                "parts": [
                    [
                        "inlineData": [
                            "mimeType": "image/jpeg",
                            "data": b64
                        ]
                    ],
                    [
                        "text": "Analyze this image. Help me understand it as a foreigner in China."
                    ]
                ]
            ]]
        ]

        var req = URLRequest(url: URL(string: urlString)!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        req.timeoutInterval = 30

        let (data, response) = try await URLSession.shared.data(for: req)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw LensAIError.api("HTTP \(code): \(bodyStr)")
        }

        let apiResp = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = apiResp.candidates?.first?.content?.parts?.first?.text else {
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

// MARK: - Gemini API Response

private struct GeminiResponse: Decodable {
    let candidates: [Candidate]?

    struct Candidate: Decodable {
        let content: Content?
    }
    struct Content: Decodable {
        let parts: [Part]?
    }
    struct Part: Decodable {
        let text: String?
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

import Foundation
import UIKit

actor GeminiService {
    static let shared = GeminiService()

    private let apiKey = "YOUR_GOOGLE_API_KEY"
    private let model = "gemini-2.0-flash"

    private var endpoint: String {
        "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)"
    }

    private let systemInstruction = """
    You are LensAI, a cultural visual guide for foreigners visiting China. \
    When given an image of Chinese text, menus, signs, medicine, forms, or any Chinese content, \
    analyze it and return a JSON object with these exact fields:
    - "title": short English title (e.g. "Spicy Numbing Pot")
    - "zhName": the original Chinese text (e.g. "麻辣香锅")
    - "subtitle": one-line English description
    - "category": exactly one of: Food, Sign, Product, Document, Place, Other
    - "what": 1-2 sentence identification of what this is
    - "context": 2-3 sentences of cultural background and context a foreigner should know
    - "tips": practical advice — what to do, what to say, how to order, etc.
    - "commonAllergens": array of common allergens if food (e.g. ["peanut","soy"]), empty array if not food

    IMPORTANT: Return ONLY the raw JSON object. No markdown, no backticks, no explanation outside the JSON.
    """

    func analyze(image: UIImage) async throws -> ScanResult {
        guard let jpegData = image.jpegData(compressionQuality: 0.7) else {
            throw GeminiError.imageConversionFailed
        }
        let base64 = jpegData.base64EncodedString()

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30

        let body: [String: Any] = [
            "system_instruction": [
                "parts": [["text": systemInstruction]]
            ],
            "contents": [
                [
                    "parts": [
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64
                            ]
                        ],
                        [
                            "text": "Analyze this image. What is it? Provide cultural context for a foreigner in China."
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "maxOutputTokens": 1024
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let bodyString = String(data: data, encoding: .utf8) ?? ""
            throw GeminiError.apiError(statusCode: statusCode, message: bodyString)
        }

        // Parse Gemini response
        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)

        guard let textPart = geminiResponse.candidates?.first?.content?.parts?.first?.text else {
            throw GeminiError.noTextInResponse
        }

        // Strip markdown code fences if present
        let cleaned = textPart
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleaned.data(using: .utf8) else {
            throw GeminiError.invalidJSON
        }

        let result = try JSONDecoder().decode(ScanResult.self, from: jsonData)
        return result
    }
}

// MARK: - Gemini Response Models

private struct GeminiResponse: Codable {
    let candidates: [Candidate]?
}

private struct Candidate: Codable {
    let content: ContentBlock?
}

private struct ContentBlock: Codable {
    let parts: [Part]?
}

private struct Part: Codable {
    let text: String?
}

// MARK: - Errors

enum GeminiError: LocalizedError {
    case imageConversionFailed
    case apiError(statusCode: Int, message: String)
    case noTextInResponse
    case invalidJSON

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image to JPEG."
        case .apiError(let code, let msg):
            return "API error (\(code)): \(msg)"
        case .noTextInResponse:
            return "No text content in API response."
        case .invalidJSON:
            return "Failed to parse AI response as JSON."
        }
    }
}

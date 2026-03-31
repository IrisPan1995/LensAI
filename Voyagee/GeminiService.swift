import Foundation
import UIKit

actor GeminiService {
    static let shared = GeminiService()

    private let backendURL = "https://travel-lens-backend-553916904261.asia-east1.run.app/analyze"

    /// Analyze with automatic retry (1 retry on failure, skip retry for network errors).
    func analyze(image: UIImage) async throws -> ScanResult {
        do {
            return try await sendRequest(image: image)
        } catch let error as VoyageeError where error == .network {
            // No point retrying if there's no network
            throw error
        } catch {
            // Auto-retry once on other errors
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5s delay
            return try await sendRequest(image: image)
        }
    }

    private func sendRequest(image: UIImage) async throws -> ScanResult {
        // Downscale to max 1024px on the longest side to reduce upload size
        let resized = image.resizedForUpload(maxDimension: 1024)
        guard let jpeg = resized.jpegData(compressionQuality: 0.7) else {
            throw VoyageeError.imageFail
        }

        // Build multipart form data
        let boundary = UUID().uuidString
        var body = Data()

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        var req = URLRequest(url: URL(string: backendURL)!)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        req.timeoutInterval = 60

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: req)
        } catch let urlError as URLError where urlError.code == .notConnectedToInternet
            || urlError.code == .networkConnectionLost
            || urlError.code == .dataNotAllowed {
            throw VoyageeError.network
        } catch let urlError as URLError where urlError.code == .timedOut {
            throw VoyageeError.api("Request timed out. Please try again.")
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let code = (response as? HTTPURLResponse)?.statusCode ?? 0
            let bodyStr = String(data: data, encoding: .utf8) ?? "unknown"
            throw VoyageeError.api("HTTP \(code): \(bodyStr)")
        }

        struct BackendResponse: Decodable {
            let title: String
            let zhName: String
            let subtitle: String
            let category: String
            let what: String
            let context: String
            let tips: String
            let commonAllergens: String
        }

        let parsed: BackendResponse
        do {
            parsed = try JSONDecoder().decode(BackendResponse.self, from: data)
        } catch {
            print("[Voyagee] JSON decode error: \(error)")
            print("[Voyagee] Raw response: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw VoyageeError.parse
        }

        // Filter out placeholder values like "N/A", "None", "Unknown", etc.
        func isMeaningful(_ text: String) -> Bool {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let placeholders = ["", "n/a", "na", "none", "unknown", "null", "-", "—"]
            return !placeholders.contains(trimmed)
        }

        // Reject results where the backend couldn't identify anything useful
        let titleLower = parsed.title.lowercased()
        let rejectKeywords = ["no content", "no text", "not found",
                              "unrecognized", "unidentifiable", "no identifiable",
                              "plain background", "no discernible", "unable to identify"]
        let isTitleRejected = rejectKeywords.contains(where: { titleLower.contains($0) })

        // Also check if all detail fields are just explaining "nothing found"
        let allFieldsText = (parsed.what + parsed.context + parsed.tips).lowercased()
        let isNegativeResponse = allFieldsText.contains("no discernible")
            || allFieldsText.contains("does not contain")
            || allFieldsText.contains("no identifiable")
            || allFieldsText.contains("cannot identify")

        // Validate that the response has meaningful detail content
        let hasDetails = isMeaningful(parsed.what)
            || isMeaningful(parsed.context)
            || isMeaningful(parsed.tips)

        guard hasDetails, !isTitleRejected, !isNegativeResponse else {
            throw VoyageeError.noContent
        }

        let allergens = parsed.commonAllergens
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ScanResult(
            title: parsed.title,
            zhName: parsed.zhName,
            subtitle: parsed.subtitle,
            category: parsed.category,
            what: parsed.what,
            context: parsed.context,
            tips: parsed.tips,
            commonAllergens: allergens.isEmpty ? [] : [allergens]
        )
    }
}

extension UIImage {
    nonisolated func resizedForUpload(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

enum VoyageeError: LocalizedError, Equatable {
    case imageFail, api(String), noResp, parse, noContent, network
    var errorDescription: String? {
        switch self {
        case .imageFail: return "Failed to process the image. Please try again."
        case .api(let m): return "Something went wrong. Please try again later. (\(m))"
        case .noResp: return "No response from the server. Please check your internet connection and try again."
        case .parse: return "Unable to process the result. Please try again."
        case .noContent: return "Could not recognize the content. Try again with a clearer image."
        case .network: return "No internet connection. Please check your network settings and try again."
        }
    }
}

import SwiftUI

struct ScannerView: View {
    let onResult: (ScanResult) -> Void

    @State private var capturedImage: UIImage?
    @State private var isAnalyzing = false
    @State private var progress = 0.0
    @State private var statusText = ""
    @State private var showPicker = false
    @State private var errorMsg: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            CameraPreview().ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 28)
                .padding(.top, 8)

                Spacer()

                if isAnalyzing {
                    VStack(spacing: 18) {
                        Spacer()
                        if let img = capturedImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 180, height: 180)
                                .cornerRadius(22)
                                .shadow(color: Theme.accent.opacity(0.3), radius: 20)
                        }
                        ProgressView(value: progress)
                            .tint(Theme.accent)
                            .padding(.horizontal, 40)
                        Text(statusText)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.white.opacity(0.85))
                        Text("Powered by Claude AI")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.25), lineWidth: 1.5)
                            .frame(width: 260, height: 260)

                        ScanLine().frame(width: 240)

                        VStack(spacing: 4) {
                            Text("Point at any Chinese text,")
                            Text("menu, sign, or product")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.35))
                        .multilineTextAlignment(.center)
                    }

                    Spacer()

                    HStack(spacing: 40) {
                        Button { showPicker = true } label: {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.06))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1)))
                        }

                        Button { showPicker = true } label: {
                            Circle()
                                .stroke(.white.opacity(0.85), lineWidth: 3)
                                .frame(width: 68, height: 68)
                                .overlay(Circle().fill(.white).padding(5))
                        }

                        Button {} label: {
                            Image(systemName: "arrow.triangle.2.circlepath.camera")
                                .font(.title3)
                                .foregroundStyle(.white.opacity(0.5))
                                .frame(width: 44, height: 44)
                                .background(.white.opacity(0.06))
                                .clipShape(Circle())
                                .overlay(Circle().stroke(.white.opacity(0.1)))
                        }
                    }
                    .padding(.bottom, 50)
                }
            }

            if let e = errorMsg {
                VStack {
                    Spacer()
                    Text(e)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.alert.cornerRadius(12))
                        .padding(.bottom, 120)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation { errorMsg = nil }
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker { img in
                capturedImage = img
                analyzeImage(img)
            }
        }
    }

    private func analyzeImage(_ image: UIImage) {
        isAnalyzing = true
        progress = 0
        statusText = "Detecting Chinese text..."

        let steps: [(Double, String, Double)] = [
            (0.25, "Identifying content...", 0.5),
            (0.50, "Analyzing meaning & context...", 1.0),
            (0.75, "Generating cultural explanation...", 1.5),
        ]
        for (p, msg, d) in steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + d) {
                withAnimation { progress = p; statusText = msg }
            }
        }

        Task {
            do {
                let result = try await ClaudeService.shared.analyze(image)
                await MainActor.run {
                    withAnimation { progress = 1; statusText = "Done ✓" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isAnalyzing = false
                        onResult(result)
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    withAnimation { errorMsg = error.localizedDescription }
                }
            }
        }
    }
}

struct ScanLine: View {
    @State private var offset: CGFloat = -120
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [.clear, Theme.accent, Theme.accent2, .clear],
                    startPoint: .leading, endPoint: .trailing
                )
            )
            .frame(height: 2)
            .shadow(color: Theme.accent.opacity(0.5), radius: 8)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                    offset = 120
                }
            }
    }
}

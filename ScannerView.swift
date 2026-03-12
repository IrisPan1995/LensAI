import SwiftUI
import AVFoundation

struct ScannerView: View {
    @StateObject private var camera = CameraManager()
    @State private var showLibrary = false
    @State private var libraryImage: UIImage?

    // Analysis state
    @State private var isAnalyzing = false
    @State private var analysisImage: UIImage?
    @State private var analysisProgress: Double = 0
    @State private var analysisStatus = "Detecting Chinese text..."
    @State private var errorMessage: String?

    // Scan line animation
    @State private var scanLineOffset: CGFloat = -120

    var onResult: (UIImage, ScanResult) -> Void

    var body: some View {
        ZStack {
            if isAnalyzing, let img = analysisImage {
                analysisView(image: img)
            } else {
                cameraView
            }
        }
        .onAppear {
            camera.configure()
        }
        .onDisappear {
            camera.stopSession()
        }
        .onChange(of: camera.capturedImage) { _, newImage in
            if let img = newImage {
                startAnalysis(image: img)
                camera.capturedImage = nil
            }
        }
        .onChange(of: libraryImage) { _, newImage in
            if let img = newImage {
                startAnalysis(image: img)
                libraryImage = nil
            }
        }
        .sheet(isPresented: $showLibrary) {
            ImagePicker(image: $libraryImage)
        }
    }

    // MARK: - Camera View

    private var cameraView: some View {
        GeometryReader { geo in
            let boxSize = min(geo.size.width - 60, 300.0)
            let boxOrigin = CGPoint(
                x: (geo.size.width - boxSize) / 2,
                y: (geo.size.height - boxSize) / 2 - 40
            )

            ZStack {
                // Background: camera feed or fallback
                if camera.isCameraAvailable {
                    CameraPreview(session: camera.session)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                } else {
                    // Fallback for simulator / no camera
                    LinearGradient(
                        colors: [Color(hex: "2A2A2A"), Color(hex: "1A1A1A")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

                // Semi-transparent overlay
                Color.black.opacity(0.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .reverseMask {
                        RoundedRectangle(cornerRadius: 16)
                            .frame(width: boxSize, height: boxSize)
                            .position(x: geo.size.width / 2, y: boxOrigin.y + boxSize / 2)
                    }

                // Corner brackets
                ViewfinderCorners(rect: CGRect(
                    origin: boxOrigin,
                    size: CGSize(width: boxSize, height: boxSize)
                ))

                // Scan line
                Rectangle()
                    .fill(Theme.accent.opacity(0.6))
                    .frame(width: boxSize - 20, height: 2)
                    .position(
                        x: geo.size.width / 2,
                        y: boxOrigin.y + boxSize / 2 + scanLineOffset
                    )
                    .onAppear {
                        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                            scanLineOffset = 120
                        }
                    }

                // No camera hint
                if !camera.isCameraAvailable {
                    VStack(spacing: 8) {
                        Image(systemName: "camera.badge.ellipsis")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Camera not available")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Use photo library below")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .position(x: geo.size.width / 2, y: boxOrigin.y + boxSize / 2)
                }

                // Instructions (below box)
                Text("Point at any Chinese text")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .position(x: geo.size.width / 2, y: boxOrigin.y + boxSize + 30)

                // Bottom controls
                HStack(spacing: 40) {
                    // Photo library button
                    Button {
                        showLibrary = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                            .contentShape(Circle())
                    }
                    .buttonStyle(.plain)

                    // Shutter button
                    Button {
                        camera.takePhoto()
                    } label: {
                        ZStack {
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 72, height: 72)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        }
                        .contentShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!camera.isCameraAvailable)
                    .opacity(camera.isCameraAvailable ? 1 : 0.3)

                    // Spacer for symmetry
                    Color.clear
                        .frame(width: 50, height: 50)
                }
                .position(x: geo.size.width / 2, y: geo.size.height - 60)
            }
        }
    }

    // MARK: - Analysis View

    private func analysisView(image: UIImage) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 8)

            VStack(spacing: 12) {
                ProgressView(value: analysisProgress)
                    .progressViewStyle(.linear)
                    .tint(Theme.accent)
                    .frame(width: 220)

                Text(analysisStatus)
                    .font(.subheadline)
                    .foregroundColor(Theme.ink3)
                    .animation(.easeInOut, value: analysisStatus)
            }

            if let error = errorMessage {
                VStack(spacing: 12) {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(Theme.alert)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Button("Try Again") {
                        isAnalyzing = false
                        errorMessage = nil
                    }
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(Theme.accent)
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Theme.paper)
    }

    // MARK: - Analysis Logic

    private func startAnalysis(image: UIImage) {
        analysisImage = image
        isAnalyzing = true
        analysisProgress = 0
        errorMessage = nil
        analysisStatus = "Detecting Chinese text..."

        let stages: [(Double, String, Double)] = [
            (0.3, "Identifying content...", 0.8),
            (0.5, "Analyzing meaning & context...", 1.6),
            (0.7, "Generating cultural explanation...", 2.4),
        ]

        for (progress, status, delay) in stages {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if self.isAnalyzing {
                    withAnimation {
                        self.analysisProgress = progress
                        self.analysisStatus = status
                    }
                }
            }
        }

        Task {
            do {
                let result = try await GeminiService.shared.analyze(image: image)
                await MainActor.run {
                    withAnimation {
                        analysisProgress = 1.0
                        analysisStatus = "Done ✓"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isAnalyzing = false
                        onResult(image, result)
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    analysisProgress = 0
                    analysisStatus = "Error"
                }
            }
        }
    }
}

// MARK: - Viewfinder Corners

private struct ViewfinderCorners: View {
    let rect: CGRect
    private let length: CGFloat = 24
    private let lineWidth: CGFloat = 3

    var body: some View {
        Canvas { context, _ in
            let color = Theme.accent
            let corners: [(CGPoint, CGFloat, CGFloat)] = [
                (CGPoint(x: rect.minX, y: rect.minY), 1, 1),
                (CGPoint(x: rect.maxX, y: rect.minY), -1, 1),
                (CGPoint(x: rect.minX, y: rect.maxY), 1, -1),
                (CGPoint(x: rect.maxX, y: rect.maxY), -1, -1),
            ]

            for (point, dx, dy) in corners {
                var hPath = Path()
                hPath.move(to: point)
                hPath.addLine(to: CGPoint(x: point.x + length * dx, y: point.y))
                context.stroke(hPath, with: .color(color), lineWidth: lineWidth)

                var vPath = Path()
                vPath.move(to: point)
                vPath.addLine(to: CGPoint(x: point.x, y: point.y + length * dy))
                context.stroke(vPath, with: .color(color), lineWidth: lineWidth)
            }
        }
    }
}

// MARK: - Reverse Mask

extension View {
    func reverseMask<Mask: View>(@ViewBuilder _ mask: () -> Mask) -> some View {
        self.mask(
            ZStack {
                Rectangle()
                mask()
                    .blendMode(.destinationOut)
            }
            .compositingGroup()
        )
    }
}

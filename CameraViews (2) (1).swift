import SwiftUI
import AVFoundation
import Vision
import PhotosUI

// MARK: - CAMERA VERIFICATION VIEW

struct CameraVerificationView: View {
    @ObservedObject var state: EcoManager
    @State private var actionText: String = ""
    @State private var step: Int = 1
    @State private var capturedImage: UIImage? = nil
    @State private var showImagePicker: Bool = false
    @State private var verificationMessage: String = ""
    @State private var verificationPassed: Bool = false
    @State private var detectedLabels: [String] = []
    @State private var matchedLabel: String? = nil
    @State private var scanStatus: String = "Analysing image with Apple Vision…"

    var needsPhoto: Bool { EcoObjectMatcher.requiresPhoto(for: actionText) }
    var expectedKW: [String] { EcoObjectMatcher.expectedLabels(for: actionText) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "B3E5FC"), Color(hex: "C8F5C8")],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()
            VStack(spacing: 0) {
                CameraHeader(onClose: { state.showCamera = false })
                StepDots(step: step)
                ScrollView {
                    VStack(spacing: 20) {
                        currentStepView
                    }.padding(.horizontal, 24)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            PhotoPickerView(capturedImage: $capturedImage)
        }
    }

    @ViewBuilder
    var currentStepView: some View {
        switch step {
        case 1:
            Step1View(
                actionText: $actionText,
                needsPhoto: needsPhoto,
                expectedKW: expectedKW,
                onNext: { withAnimation { step = 2 } }
            )
        case 2:
            Step2View(
                capturedImage: $capturedImage,
                showImagePicker: $showImagePicker,
                needsPhoto: needsPhoto,
                expectedKW: expectedKW,
                onSubmit: {
                    withAnimation { step = 3 }
                    runVerification()
                }
            )
        case 3:
            Step3View(scanStatus: scanStatus, expectedKW: expectedKW)
        default:
            Step4View(
                verificationPassed: verificationPassed,
                verificationMessage: verificationMessage,
                detectedLabels: detectedLabels,
                matchedLabel: matchedLabel,
                streak: state.streak,
                onClose: { state.showCamera = false },
                onRetry: {
                    withAnimation {
                        step = 1
                        capturedImage = nil
                        actionText = ""
                        detectedLabels = []
                        matchedLabel = nil
                    }
                }
            )
        }
    }

    func runVerification() {
        // If no photo needed, approve immediately
        guard needsPhoto, let img = capturedImage else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation { step = 4 }
                verificationPassed = true
                verificationMessage = "Action logged! Keep it up, eco-warrior. Your island is growing! 🌱"
                state.logAction(actionText: actionText, contribution: 40)
            }
            return
        }
        // Animate status messages
        let statuses: [String] = [
            "Loading Apple Vision model…",
            "Detecting objects in image…",
            "Matching labels to your action…",
            "Calculating environmental impact…"
        ]
        for (i, s) in statuses.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.7) {
                scanStatus = s
            }
        }
        EcoObjectMatcher.classify(image: img, expectedKeywords: expectedKW) { passed, labels, matched in
            withAnimation { step = 4 }
            detectedLabels = labels
            matchedLabel = matched
            verificationPassed = passed
            if passed {
                let m = matched ?? "eco-item"
                verificationMessage = "Detected '\(m)' — matches your action! Great work. Your island is growing! 🌱"
                state.logAction(actionText: actionText, contribution: 65)
            } else {
                let exp = expectedKW.prefix(3).joined(separator: ", ")
                verificationMessage = "Couldn't find \(exp) in your photo. Make sure the item is clearly visible and try again."
            }
        }
    }
}

struct CameraHeader: View {
    let onClose: () -> Void

    var body: some View {
        HStack {
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2).foregroundColor(Color(hex: "5A7A5A"))
            }
            Spacer()
            Text("DAILY LOG IN")
                .font(.custom("Arial-BoldMT", size: 20)).foregroundColor(Color(hex: "3D5A3E"))
            Spacer()
            Image(systemName: "leaf.fill")
                .font(.title2).foregroundColor(Color(hex: "C7EABB"))
        }
        .padding(.horizontal, 24).padding(.vertical, 20)
    }
}

struct StepDots: View {
    let step: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...3, id: \.self) { s in
                Circle()
                    .fill(step >= s ? Color(hex: "C7EABB") : Color(hex: "C7EABB"))
                    .frame(width: 10, height: 10)
            }
        }.padding(.bottom, 16)
    }
}

struct Step1View: View {
    @Binding var actionText: String
    let needsPhoto: Bool
    let expectedKW: [String]
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("What did you do for the environment today? 🌍")
                .font(.custom("Arial-BoldMT", size: 16))
                .multilineTextAlignment(.center).foregroundColor(Color(hex: "3D5A3E"))

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.9)).frame(height: 120)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(hex: "C7EABB"), lineWidth: 2))
                if actionText.isEmpty {
                    Text("e.g. I recycled 5 plastic bottles today…")
                        .font(.custom("Arial", size: 13)).foregroundColor(Color.gray.opacity(0.5)).padding(14)
                }
                TextEditor(text: $actionText)
                    .font(.custom("Arial", size: 14)).foregroundColor(.black)
                    .scrollContentBackground(.hidden).background(Color.clear).padding(8)
            }

            if !actionText.isEmpty {
                Step1PhotoNote(needsPhoto: needsPhoto, expectedKW: expectedKW)
            }
            Step1NextButton(needsPhoto: needsPhoto, isEmpty: actionText.isEmpty, onNext: onNext)
        }
    }
}

struct Step1PhotoNote: View {
    let needsPhoto: Bool
    let expectedKW: [String]

    var body: some View {
        if needsPhoto {
            VStack(spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                    Text("Photo proof required for this action")
                        .font(.custom("Arial-BoldMT", size: 13))
                }.foregroundColor(Color(hex: "3D5A3E"))
                Text("We'll scan for: \(expectedKW.prefix(4).joined(separator: ", "))")
                    .font(.custom("Arial", size: 11)).foregroundColor(Color(hex: "5A7A5A"))
            }
            .padding(12).background(Color(hex: "C7EABB")).clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text("No photo needed — just submit!")
                    .font(.custom("Arial-BoldMT", size: 13))
            }
            .foregroundColor(Color(hex: "3D5A3E"))
            .padding(12).background(Color(hex: "BBDCE5")).clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct Step1NextButton: View {
    let needsPhoto: Bool
    let isEmpty: Bool
    let onNext: () -> Void

    var body: some View {
        let label = needsPhoto ? "Next: Add Photo 📸" : "Submit Action ✅"
        let bg = isEmpty ? Color.gray.opacity(0.4) : Color(hex: "C7EABB")
        Button(action: { if !isEmpty { onNext() } }) {
            Text(label)
                .font(.custom("Arial-BoldMT", size: 16)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(bg).clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "3D6B44"), lineWidth: 2))
        }.disabled(isEmpty)
    }
}

struct Step2View: View {
    @Binding var capturedImage: UIImage?
    @Binding var showImagePicker: Bool
    let needsPhoto: Bool
    let expectedKW: [String]
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Show us proof! 📸")
                .font(.custom("Arial-BoldMT", size: 18)).foregroundColor(Color(hex: "3D5A3E"))

            if needsPhoto {
                Text("Select a photo — we'll check it for: \(expectedKW.prefix(3).joined(separator: ", ")).")
                    .font(.custom("Arial", size: 13)).foregroundColor(Color(hex: "5A7A5A"))
                    .multilineTextAlignment(.center)

                PhotoPreviewBox(capturedImage: capturedImage)

                // On Mac, camera not available — use photo picker
                Button(action: { showImagePicker = true }) {
                    Label(
                        capturedImage == nil ? "Choose Photo from Library" : "Choose Different Photo",
                        systemImage: "photo.on.rectangle"
                    )
                    .font(.custom("Arial-BoldMT", size: 15))
                    .foregroundColor(Color(hex: "3D5A3E"))
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color(hex: "C7EABB")).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(hex: "3D6B44"), lineWidth: 2))
                }

                Text("📌 Tip: On Mac, use your Photos library. On iPhone/iPad, you can take a live photo.")
                    .font(.custom("Arial", size: 11)).foregroundColor(.gray)
                    .multilineTextAlignment(.center).padding(.horizontal)
            } else {
                Text("No photo required for this action. Hit submit!")
                    .font(.custom("Arial", size: 14)).foregroundColor(Color(hex: "5A7A5A"))
                    .multilineTextAlignment(.center).padding()
                    .background(Color(hex: "BBDCE5").opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Step2SubmitButton(needsPhoto: needsPhoto, hasImage: capturedImage != nil, onSubmit: onSubmit)
        }
    }
}

struct PhotoPreviewBox: View {
    let capturedImage: UIImage?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20).fill(Color.black.opacity(0.08)).frame(height: 220)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: "C7EABB"), lineWidth: 2.5))
            if let img = capturedImage {
                Image(uiImage: img).resizable().scaledToFill().frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Label("Selected", systemImage: "checkmark.circle.fill")
                            .font(.custom("Arial-BoldMT", size: 12)).foregroundColor(.white)
                            .padding(8).background(Color(hex: "C7EABB")).clipShape(Capsule()).padding(10)
                    }
                }
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle").font(.custom("Arial", size: 50))
                        .foregroundColor(Color(hex: "C7EABB").opacity(0.5))
                    Text("No photo selected").font(.custom("Arial", size: 13)).foregroundColor(.gray)
                }
            }
        }
    }
}

struct Step2SubmitButton: View {
    let needsPhoto: Bool
    let hasImage: Bool
    let onSubmit: () -> Void

    var body: some View {
        let disabled = needsPhoto && !hasImage
        let bg = disabled ? Color.gray.opacity(0.4) : Color(hex: "C7EABB")
        Button(action: { if !disabled { onSubmit() } }) {
            Text("Submit Proof ✅")
                .font(.custom("Arial-BoldMT", size: 16)).foregroundColor(.white)
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(bg).clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: "3D6B44"), lineWidth: 2))
        }.disabled(disabled)
    }
}

struct Step3View: View {
    let scanStatus: String
    let expectedKW: [String]

    var body: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)
            ProgressView().scaleEffect(2).tint(Color(hex: "C7EABB"))
            Text("Scanning your photo… 🔍")
                .font(.custom("Arial-BoldMT", size: 18)).foregroundColor(Color(hex: "3D5A3E"))
            Text(scanStatus)
                .font(.custom("Arial", size: 13)).foregroundColor(Color(hex: "5A7A5A"))
                .multilineTextAlignment(.center).padding(.horizontal)
                .animation(.easeInOut, value: scanStatus)
            VStack(spacing: 6) {
                Label("Running Apple Vision — fully on-device", systemImage: "lock.shield")
                    .font(.custom("Arial", size: 12)).foregroundColor(Color(hex: "C7EABB"))
                Label("Looking for: \(expectedKW.prefix(3).joined(separator: ", "))", systemImage: "eye")
                    .font(.custom("Arial", size: 12)).foregroundColor(.gray)
            }
            .padding().background(Color.white.opacity(0.6)).clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct Step4View: View {
    let verificationPassed: Bool
    let verificationMessage: String
    let detectedLabels: [String]
    let matchedLabel: String?
    let streak: Int
    let onClose: () -> Void
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer().frame(height: 10)
            Text(verificationPassed ? "🎉" : "😔").font(.custom("Arial", size: 70))
            Text(verificationPassed ? "Photo Verified!" : "Verification Failed")
                .font(.custom("Arial-BoldMT", size: 24))
                .foregroundColor(verificationPassed ? Color(hex: "3D5A3E") : Color(hex: "C0392B"))
            Text(verificationMessage)
                .font(.custom("Arial", size: 14)).foregroundColor(Color(hex: "5A7A5A"))
                .multilineTextAlignment(.center).padding(.horizontal)
            if !detectedLabels.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Detected in photo:")
                        .font(.custom("Arial-BoldMT", size: 12)).foregroundColor(.gray)
                    FlowLabels(labels: detectedLabels, matched: matchedLabel)
                }
                .padding(12).frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.7)).clipShape(RoundedRectangle(cornerRadius: 12))
            }
            if verificationPassed {
                Text("Streak: \(streak) 🔥")
                    .font(.custom("Arial-BoldMT", size: 18)).foregroundColor(Color(hex: "FF8C00"))
            }
            Step4CloseButton(verificationPassed: verificationPassed, onClose: onClose, onRetry: onRetry)
        }
    }
}

struct Step4CloseButton: View {
    let verificationPassed: Bool
    let onClose: () -> Void
    let onRetry: () -> Void

    var body: some View {
        let label = verificationPassed ? "Close 🌱" : "Try Again"
        let bg = verificationPassed ? Color(hex: "C7EABB") : Color(hex: "EF5350")
        Button(action: { verificationPassed ? onClose() : onRetry() }) {
            Text(label)
                .font(.custom("Arial-BoldMT", size: 16)).foregroundColor(.white)
                .frame(width: 180, height: 50).background(bg).clipShape(Capsule())
        }
    }
}

// MARK: - PHOTO PICKER (works on Mac + iPhone + iPad)

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        init(_ p: PhotoPickerView) { parent = p }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let item = results.first else { return }
            item.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                DispatchQueue.main.async {
                    self.parent.capturedImage = obj as? UIImage
                }
            }
        }
    }
}

// MARK: - FLOW LABELS

struct FlowLabels: View {
    let labels: [String]
    let matched: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            ForEach(labels, id: \.self) { label in
                FlowLabel(label: label, matched: matched)
            }
        }
    }
}

struct FlowLabel: View {
    let label: String
    let matched: String?

    var isMatch: Bool {
        guard let m = matched else { return false }
        return label.contains(m)
    }

    var body: some View {
        Text(label)
            .font(.system(size: 11, weight: isMatch ? .bold : .regular))
            .foregroundColor(isMatch ? Color(hex: "3D5A3E") : Color(hex: "4A5A4A"))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(isMatch ? Color(hex: "C7EABB") : Color(hex: "F5F5F5"))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(
                isMatch ? Color(hex: "C7EABB") : Color.gray.opacity(0.3), lineWidth: 1))
    }
}

import SwiftUI
import AVFoundation
import Vision
import CoreText

// MARK: - REAL CAMERA (fallback, Mac uses PHPicker)

struct RealCameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: RealCameraView
        init(_ p: RealCameraView) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.capturedImage = info[.originalImage] as? UIImage
            parent.onDismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.onDismiss() }
    }
}

// MARK: - SHOP
// Each ShopItem now uses imageName for real pixel-art preview

struct ShopView: View {
    @ObservedObject var state: EcoManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedCategory: String = "Nature"
    let categories: [String] = ["Nature", "Animals", "Structures"]

    var filteredItems: [ShopItem] {
        state.shopItems.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF8DE").ignoresSafeArea()
                VStack(spacing: 0) {
                    ShopHeader(state: state)
                    ShopCategoryPicker(categories: categories, selected: $selectedCategory)
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 14
                        ) {
                            ForEach(filteredItems) { item in
                                ShopItemCard(item: item, state: state)
                            }
                        }.padding(16)
                    }
                }
            }
            .navigationTitle("Island Shop 🏪")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Color(hex: "3D5A3E"))
                }
            }
        }
    }
}

struct ShopHeader: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        HStack {
            Image(systemName: "leaf.fill").foregroundColor(Color(hex: "3D5A3E"))
            Text("\(state.contributionPoints) pts  •  🔥 \(state.streak) streak")
                .font(.custom("Arial-BoldMT", size: 14)).foregroundColor(Color(hex: "3D5A3E"))
            Spacer()
            Text("Items: \(state.placedItems.count)/\(state.maxItems)")
                .font(.custom("Arial", size: 11)).foregroundColor(Color(hex: "3D5A3E"))
        }
        .padding(14)
        .background(Color(hex: "C7EABB").opacity(0.5))
    }
}

struct ShopCategoryPicker: View {
    let categories: [String]
    @Binding var selected: String

    var body: some View {
        HStack(spacing: 0) {
            ForEach(categories, id: \.self) { cat in
                Button(action: { selected = cat }) {
                    Text(cat)
                        .font(.custom("Arial-BoldMT", size: 13))
                        .foregroundColor(selected == cat ? Color(hex: "3D5A3E") : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selected == cat ? Color(hex: "C7EABB") : Color.clear)
                }
            }
        }
        .background(Color(hex: "FFF8DE"))
        .overlay(Rectangle().frame(height: 1.5).foregroundColor(Color(hex: "C7EABB")), alignment: .bottom)
    }
}

struct ShopItemCard: View {
    let item: ShopItem
    @ObservedObject var state: EcoManager
    @State private var tapped: Bool = false

    var canAfford: Bool { state.contributionPoints >= item.cost }
    var streakMet: Bool { state.streak >= item.streakRequired }
    var islandFull: Bool { state.placedItems.count >= state.maxItems }
    var canBuy: Bool { canAfford && streakMet && !islandFull }

    var body: some View {
        VStack(spacing: 8) {
            // Real image preview
            ShopItemPreview(imageName: item.imageName, emoji: item.emoji)
            Text(item.name)
                .font(.custom("Arial-BoldMT", size: 13)).foregroundColor(Color(hex: "3D5A3E"))
            Text(item.description)
                .font(.custom("Arial", size: 10)).foregroundColor(.gray)
                .multilineTextAlignment(.center).lineLimit(2)
            Text("🌿 \(item.cost) pts")
                .font(.custom("Arial", size: 12))
                .foregroundColor(canAfford ? Color(hex: "3D5A3E") : .red)
            if item.streakRequired > 0 {
                Text("🔥 \(item.streakRequired) streak")
                    .font(.custom("Arial", size: 10))
                    .foregroundColor(streakMet ? Color(hex: "5A8A5A") : .red)
            }
            if islandFull {
                Text("Island full!").font(.custom("Arial", size: 10)).foregroundColor(.red)
            } else {
                ShopBuyButton(canBuy: canBuy, tapped: tapped) {
                    guard canBuy else { return }
                    tapped = true
                    state.buyItem(item)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { tapped = false }
                }
            }
        }
        .padding(14).background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        // NO shadow oval line -- removed overlay stroke
        .opacity(canBuy ? 1.0 : 0.6)
        .scaleEffect(tapped ? 0.97 : 1.0)
        .animation(.spring(response: 0.2), value: tapped)
    }
}

struct ShopItemPreview: View {
    let imageName: String
    let emoji: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: "F9DFDF").opacity(0.3))
                .frame(width: 72, height: 72)
            if let img = loadBundleImage(named: imageName) {
                Image(uiImage: img).resizable().scaledToFit()
                    .frame(width: 60, height: 60)
            } else {
                Text(emoji).font(.custom("Arial", size: 44))
            }
        }
    }
}

struct ShopBuyButton: View {
    let canBuy: Bool
    let tapped: Bool
    let action: () -> Void

    var bgColor: Color {
        if !canBuy { return Color(hex: "F9DFDF").opacity(0.5) }
        return Color(hex: "C7EABB")
    }

    var body: some View {
        Button(action: action) {
            Text(canBuy ? "Purchase" : "Locked")
                .font(.custom("Arial-BoldMT", size: 12))
                .foregroundColor(canBuy ? Color(hex: "3D5A3E") : .gray)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(bgColor)
                .clipShape(Capsule())
            // NO stroke border
        }
    }
}

// MARK: - STREAK PANEL

struct StreakPanelView: View {
    @ObservedObject var state: EcoManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF8DE").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 20) {
                        StreakCircle(streak: state.streak)
                        LazyVGrid(
                            columns: [GridItem(.flexible()), GridItem(.flexible())],
                            spacing: 14
                        ) {
                            AchievementCard(icon: "🌍", title: "CO2 Saved",
                                value: "\(state.contributionPoints / 20)kg", color: Color(hex: "C7EABB"))
                            AchievementCard(icon: "⭐", title: "Level",
                                value: "\(state.level)", color: Color(hex: "FFF2C6"))
                            AchievementCard(icon: "🌿", title: "Points",
                                value: "\(state.contributionPoints)", color: Color(hex: "BBDCE5"))
                            AchievementCard(icon: "🏝️", title: "Items",
                                value: "\(state.placedItems.count)", color: Color(hex: "F9DFDF"))
                        }.padding(.horizontal)
                        SeasonProgressCard(contributionPoints: state.contributionPoints)
                        BadgesCard(streak: state.streak)
                    }.padding(.vertical, 20)
                }
            }
            .navigationTitle("Achievements 🏆")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Color(hex: "3D5A3E"))
                }
            }
        }
    }
}

struct StreakCircle: View {
    let streak: Int

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: "FFF2C6")).frame(width: 150, height: 150)
            VStack {
                Text("🔥").font(.custom("Arial", size: 50))
                Text("\(streak)").font(.custom("Arial-BoldMT", size: 36)).foregroundColor(Color(hex: "3D5A3E"))
                Text("days").font(.custom("Arial", size: 14)).foregroundColor(.gray)
            }
        }
    }
}

struct AchievementCard: View {
    let icon: String; let title: String; let value: String; let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Text(icon).font(.custom("Arial", size: 36))
            Text(value).font(.custom("Arial-BoldMT", size: 22)).foregroundColor(Color(hex: "3D5A3E"))
            Text(title).font(.custom("Arial", size: 12)).foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 20)
        .background(color).clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct SeasonProgressCard: View {
    let contributionPoints: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Season Progress").font(.custom("Arial-BoldMT", size: 15)).foregroundColor(Color(hex: "3D5A3E"))
            ProgressView(value: Double(contributionPoints % 150), total: 150).tint(Color(hex: "C7EABB"))
            Text("\(contributionPoints % 150)/150 pts to next level")
                .font(.custom("Arial", size: 12)).foregroundColor(.gray)
        }
        .padding().background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct BadgesCard: View {
    let streak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Badges").font(.custom("Arial-BoldMT", size: 15)).foregroundColor(Color(hex: "3D5A3E"))
                .padding(.leading, 4)
            if streak == 0 {
                Text("Keep going to earn badges! 🌱").font(.custom("Arial", size: 13)).foregroundColor(.gray)
            } else {
                HStack(spacing: 10) {
                    if streak >= 3  { BadgePill(icon: "🥉", label: "3 Day") }
                    if streak >= 7  { BadgePill(icon: "🥈", label: "7 Day") }
                    if streak >= 14 { BadgePill(icon: "🥇", label: "14 Day") }
                    if streak >= 30 { BadgePill(icon: "🏆", label: "30 Day") }
                }
            }
        }
        .padding().background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

struct BadgePill: View {
    let icon: String; let label: String

    var body: some View {
        HStack(spacing: 4) {
            Text(icon).font(.custom("Arial", size: 18))
            Text(label).font(.custom("Arial-BoldMT", size: 12)).foregroundColor(Color(hex: "3D5A3E"))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Color(hex: "FFF2C6")).clipShape(Capsule())
    }
}

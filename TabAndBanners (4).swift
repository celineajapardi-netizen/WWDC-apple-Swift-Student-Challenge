import SwiftUI

// MARK: - BOTTOM TAB BAR

struct BottomTabBar: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(icon: "list.bullet.clipboard.fill", label: "LOG IN") {
                withAnimation(.spring()) { state.zoomedIsland = .sub(.login) }
            }
            TabBarButton(icon: "cart.fill", label: "SHOP") {
                state.showShop = true
            }
            TabBarButton(icon: "book.fill", label: "GUIDE") {
                state.showInstructions = true
            }
            TabBarButton(icon: "flame.fill", label: "STREAK") {
                state.showStreakPanel = true
            }
        }
        .padding(.vertical, 10)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1.5)
                .foregroundColor(Color(hex: "C7EABB")),
            alignment: .top
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.custom("Arial", size: 20))
                    .foregroundColor(Color(hex: "5A8A5A"))
                Text(label)
                    .font(.custom("Arial-BoldMT", size: 9))
                    .foregroundColor(Color(hex: "5A8A5A"))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - CONTRIBUTION BANNER

struct ContributionBanner: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("🌍 Real World Impact!")
                        .font(.custom("Arial-BoldMT", size: 15))
                        .foregroundColor(Color(hex: "3D5A3E"))
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                Text(message)
                    .font(.custom("Arial", size: 13))
                    .foregroundColor(Color(hex: "3D5A3E"))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color(hex: "E8F5E9"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "C7EABB"), lineWidth: 2)
            )
            .padding(.horizontal, 20)
            Spacer()
        }
        .padding(.top, 8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { onDismiss() }
            }
        }
    }
}

// MARK: - DEVASTATING FACT

struct DevastatingFactView: View {
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("😢 Oh no!")
                .font(.custom("Arial-BoldMT", size: 20))
                .foregroundColor(Color(hex: "C0392B"))
            Text(message)
                .font(.custom("Arial", size: 14))
                .foregroundColor(Color(hex: "C0392B"))
                .multilineTextAlignment(.center)
            Text("Your island lost a tree... 🌳➡️🪵")
                .font(.custom("Arial", size: 13))
                .foregroundColor(.gray)
            Button("I'll do better tomorrow!") {
                withAnimation { onDismiss() }
            }
            .font(.custom("Arial-BoldMT", size: 14))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color(hex: "EF5350"))
            .clipShape(Capsule())
        }
        .padding(24)
        .background(Color(hex: "FFEBEE"))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color(hex: "EF9A9A"), lineWidth: 2.5)
        )
        .frame(width: 290)
    }
}
import SwiftUI

// MARK: - ZOOMED ISLAND VIEW

struct ZoomedIslandView: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) { state.zoomedIsland = nil }
                }
            VStack(spacing: 12) {
                Text("Tap background to close")
                    .font(.custom("Arial", size: 11)).foregroundColor(Color.white.opacity(0.7))
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Color.black.opacity(0.3)).clipShape(Capsule())
                ZoomedIslandContent(state: state)
            }.padding(.horizontal, 16)
        }
    }
}

struct ZoomedIslandContent: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        if state.zoomedIsland == .main {
            ZoomedMainIsland(state: state)
        } else if case .sub(let type) = state.zoomedIsland {
            ZoomedSubIsland(type: type, state: state)
        }
    }
}

// MARK: - ZOOMED MAIN ISLAND

struct ZoomedMainIsland: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Your Island — Level \(state.level)")
                .font(.custom("Arial-BoldMT", size: 18)).foregroundColor(.white)
            ZoomedMainIslandShape(state: state)
            HStack(spacing: 14) {
                StatPill(label: "Health", value: "\(Int(state.islandHealth * 100))%", color: Color(hex: "C7EABB"))
                StatPill(label: "Points", value: "\(state.contributionPoints)", color: Color(hex: "FFF8DE"))
                StatPill(label: "Items",  value: "\(state.placedItems.count)",  color: Color(hex: "BBDCE5"))
            }
            if !state.placedItems.isEmpty {
                Text("Drag to move • Pinch to resize")
                    .font(.custom("Arial", size: 10))
                    .foregroundColor(Color.white.opacity(0.6))
            }
        }
    }
}

struct ZoomedMainIslandShape: View {
    @ObservedObject var state: EcoManager

    let canvasW: CGFloat = 340
    let canvasH: CGFloat = 280

    var body: some View {
        ZStack {
            // Island image — renderingMode .original preserves transparency
            if let img = loadBundleImage(named: "mainisland") {
                Image(uiImage: img)
                    .renderingMode(.original)
                    .resizable().scaledToFit()
                    .frame(width: canvasW, height: canvasH - 40)
                    .background(Color.clear)
            } else {
                VStack(spacing: 0) {
                    Ellipse()
                        .fill(LinearGradient(colors: [Color(hex: "7BC67E"), Color(hex: "5A9E5F")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 280, height: 140)
                    Rectangle()
                        .fill(LinearGradient(colors: [Color(hex: "A0907E"), Color(hex: "7D6B5A")], startPoint: .top, endPoint: .bottom))
                        .frame(width: 230, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    Ellipse().fill(Color(hex: "7D6B5A")).frame(width: 180, height: 35)
                }
            }

            // Draggable + resizable shop items
            ForEach(state.placedItems.indices, id: \.self) { i in
                DraggableIslandItem(item: $state.placedItems[i])
            }

            if state.placedItems.isEmpty {
                Text("Buy items from the Shop to place here!")
                    .font(.custom("Arial", size: 12))
                    .foregroundColor(Color.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .frame(width: canvasW, height: canvasH)
        // No bob animation — island stays still when zoomed in
    }
}

struct ZoomedMainDefaultItems: View {
    var body: some View {
        ZStack {
            HStack(spacing: 16) {
                Text("🌳").font(.custom("Arial", size: 36)).offset(y: -78)
                Text("🏠").font(.custom("Arial", size: 32)).offset(y: -92)
                Text("🌲").font(.custom("Arial", size: 30)).offset(y: -74)
            }
            Text("🐑").font(.custom("Arial", size: 26)).offset(x: -80, y: -60)
            Text("🐦").font(.custom("Arial", size: 24)).offset(x: 85, y: -65)
        }
    }
}

struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.custom("Arial-BoldMT", size: 15)).foregroundColor(Color(hex: "3D5A3E"))
            Text(label).font(.custom("Arial", size: 10)).foregroundColor(.gray)
        }
        .padding(.horizontal, 14).padding(.vertical, 8).background(color).clipShape(Capsule())
        .overlay(Capsule().stroke(Color(hex: "3D6B44").opacity(0.3), lineWidth: 1.5))
    }
}

// MARK: - ZOOMED SUB ISLAND
// Uses real pixel character images loaded from Resources

struct ZoomedSubIsland: View {
    let type: IslandType
    @ObservedObject var state: EcoManager
    @State private var dialogResult: Bool? = nil

    // Image filename in Resources for each island
    var characterImageName: String {
        switch type {
        case .achievements: return "achievementscharacter"
        case .goals:        return "goalscharacter"
        case .tasks:        return "taskcharacter"
        case .facts:        return "factscharacter"
        case .login:        return "logincharacter"
        }
    }

    // Fallback emoji if image not found
    var fallbackEmoji: String {
        switch type {
        case .achievements: return "👨‍🌾"
        case .goals:        return "👩‍💻"
        case .tasks:        return "👦"
        case .facts:        return "👩‍🔬"
        case .login:        return "🧑"
        }
    }

    var characterName: String {
        switch type {
        case .achievements: return "Alex"
        case .goals:        return "Maya"
        case .tasks:        return "Tommy"
        case .facts:        return "Rae"
        case .login:        return "Scout"
        }
    }

    var islandColor: Color {
        switch type {
        case .achievements: return Color(hex: "C7EABB")
        case .goals:        return Color(hex: "BBDCE5")
        case .tasks:        return Color(hex: "FFF2C6")
        case .facts:        return Color(hex: "F9DFDF")
        case .login:        return Color(hex: "FFE8CD")
        }
    }

    var questionText: String {
        switch type {
        case .achievements:
            return "Hi! Want to check your achievements and see how much you've contributed?"
        case .goals:
            return "Hey! Want to set some eco-goals for today? Small actions make big differences!"
        case .tasks:
            return "Hello! Ready for today's eco-tasks? Complete them to earn island accessories!"
        case .facts:
            return "Psst! Want to learn some environmental facts? Knowledge is power!"
        case .login:
            return "Did you do something for the environment today? Log your action to grow your island!"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Character banner on top
            CharacterBanner(
                imageName: characterImageName,
                fallbackEmoji: fallbackEmoji,
                name: characterName,
                islandColor: islandColor
            )
            // Black conversation box — no buttons inside
            GameDialogBox(
                characterName: characterName,
                questionText: questionText,
                islandColor: islandColor
            )
            // YES / NO buttons sit directly below the black box
            DialogButtonBar(
                islandColor: islandColor,
                dialogResult: $dialogResult,
                onYes: handleYes,
                onNo: handleNo
            )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(maxWidth: 380)
    }

    func handleYes() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring()) {
                state.zoomedIsland = nil
                switch type {
                case .login:        state.showCamera = true
                case .achievements: state.showStreakPanel = true
                case .goals:        state.showGoals = true
                case .tasks:        state.showTasks = true
                case .facts:        state.showFacts = true
                }
            }
        }
    }

    func handleNo() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { state.zoomedIsland = nil }
        }
    }
}

// Character banner: shows real pixel art image or fallback emoji
struct CharacterBanner: View {
    let imageName: String
    let fallbackEmoji: String
    let name: String
    let islandColor: Color

    var body: some View {
        ZStack {
            islandColor
            VStack(spacing: 4) {
                CharacterPortrait(imageName: imageName, fallbackEmoji: fallbackEmoji)
                Text(name)
                    .font(.custom("Arial-BoldMT", size: 12))
                    .foregroundColor(Color(hex: "3D5A3E"))
            }
            .padding(.vertical, 12)
            // Island base under feet
            Ellipse()
                .fill(Color(hex: "7BC67E").opacity(0.4))
                .frame(width: 80, height: 18)
                .offset(y: 42)
        }
        .frame(height: 110)
    }
}

struct CharacterPortrait: View {
    let imageName: String
    let fallbackEmoji: String

    var body: some View {
        if let img = loadBundleImage(named: imageName) {
            Image(uiImage: img)
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                // Remove white background from pixel art
                .background(Color.clear)
        } else {
            Text(fallbackEmoji).font(.custom("Arial", size: 52))
        }
    }
}

// Game-style black dialogue box — conversation only, no buttons
struct GameDialogBox: View {
    let characterName: String
    let questionText: String
    let islandColor: Color

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black.opacity(0.88)
            VStack(alignment: .leading, spacing: 8) {
                Text(characterName)
                    .font(.custom("Arial-BoldMT", size: 12))
                    .foregroundColor(islandColor)
                Text(questionText)
                    .font(.custom("Arial", size: 15))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(18)
        }
        .fixedSize(horizontal: false, vertical: true) // height wraps content, not stretched
    }
}

struct DialogButtonBar: View {
    let islandColor: Color
    @Binding var dialogResult: Bool?
    let onYes: () -> Void
    let onNo: () -> Void

    // Alternate pastel pairs for YES/NO
    let yesPastels: [Color] = [
        Color(hex: "C7EABB"),
        Color(hex: "BBDCE5"),
        Color(hex: "FFF2C6"),
    ]
    let noPastels: [Color] = [
        Color(hex: "F9DFDF"),
        Color(hex: "FFE8CD"),
        Color(hex: "FFF8DE"),
    ]

    var body: some View {
        if dialogResult == nil {
            HStack(spacing: 0) {
                Button(action: { withAnimation { dialogResult = true }; onYes() }) {
                    Text("YES ✅")
                        .font(.custom("Arial-BoldMT", size: 15))
                        .foregroundColor(Color(hex: "3D5A3E"))
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color(hex: "C7EABB"))
                }
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 1, height: 52)
                Button(action: { withAnimation { dialogResult = false }; onNo() }) {
                    Text("NO ❌")
                        .font(.custom("Arial-BoldMT", size: 15))
                        .foregroundColor(Color(hex: "8B3A3A"))
                        .frame(maxWidth: .infinity).frame(height: 52)
                        .background(Color(hex: "F9DFDF"))
                }
            }
            .frame(height: 52)
        } else if dialogResult == true {
            Text("Opening… 🌱")
                .font(.custom("Arial-BoldMT", size: 14)).foregroundColor(Color(hex: "3D5A3E"))
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color(hex: "C7EABB"))
        } else {
            Text("Maybe next time! 🌿")
                .font(.custom("Arial", size: 14)).foregroundColor(Color(hex: "5A5A5A"))
                .frame(maxWidth: .infinity).frame(height: 52)
                .background(Color(hex: "FFF8DE"))
        }
    }
}

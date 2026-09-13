import SwiftUI

// MARK: - MAIN ISLAND MAP VIEW
// Zoomed-out map view: just shows mainisland.jpeg image, NO items on it
// Items only appear when zoomed in (ZoomedMainIsland in ZoomedViews.swift)

struct MainIslandView: View {
    @ObservedObject var state: EcoManager
    @State private var bob: Bool = false

    // Zoomed-out display size
    let islandW: CGFloat = 280
    let islandH: CGFloat = 200

    // Must match ZoomedMainIslandShape canvasW/canvasH
    let zoomedW: CGFloat = 340
    let zoomedH: CGFloat = 280

    var scaleX: CGFloat { islandW / zoomedW }
    var scaleY: CGFloat { islandH / zoomedH }

    var body: some View {
        ZStack {
            // Island base image
            IslandBaseImage()

            // Shop items — scaled down to match zoomed-out size, NOT interactive
            ForEach(state.placedItems) { item in
                ItemImage(imageName: item.imageName, emoji: item.emoji)
                    .frame(
                        width: 48 * item.scale * scaleX,
                        height: 48 * item.scale * scaleY
                    )
                    .offset(
                        x: item.xOffset * scaleX,
                        y: item.yOffset * scaleY
                    )
                    .allowsHitTesting(false)
            }

            Text("Tap to zoom 🔍")
                .font(.custom("Arial", size: 9))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(Color.black.opacity(0.25)).clipShape(Capsule())
                .offset(y: 95)
        }
        .offset(y: bob ? -6 : 6)
        .animation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}

struct IslandBaseImage: View {
    var body: some View {
        IslandImage(name: "mainisland", width: 280, height: 200)
    }
}

struct IslandImage: View {
    let name: String
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        if let img = loadBundleImage(named: name) {
            Image(uiImage: img)
                .renderingMode(.original)
                .resizable().scaledToFit()
                .frame(width: width, height: height)
                .background(Color.clear)
        } else {
            IslandFallbackShape(width: width, height: height)
        }
    }
}

struct IslandFallbackShape: View {
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Ellipse()
                .fill(LinearGradient(
                    colors: [Color(hex: "7BC67E"), Color(hex: "5A9E5F")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: width, height: height * 0.65)
            Rectangle()
                .fill(LinearGradient(
                    colors: [Color(hex: "A0907E"), Color(hex: "7D6B5A")],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: width * 0.85, height: height * 0.35)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

// MARK: - ITEM IMAGE HELPER (used in ZoomedViews too)

struct ItemImage: View {
    let imageName: String
    let emoji: String

    var body: some View {
        if let img = loadBundleImage(named: imageName) {
            Image(uiImage: img).resizable().scaledToFit()
        } else {
            Text(emoji).font(.custom("Arial", size: 28))
        }
    }
}

// MARK: - DRAGGABLE ITEM (used in ZoomedMainIsland)

struct DraggableIslandItem: View {
    @Binding var item: PlacedItem
    @State private var dragOffset: CGSize = .zero
    @GestureState private var pinchScale: CGFloat = 1.0

    var body: some View {
        ItemImage(imageName: item.imageName, emoji: item.emoji)
            .frame(width: 48 * item.scale, height: 48 * item.scale)
            .scaleEffect(pinchScale)
            .offset(
                x: item.xOffset + dragOffset.width,
                y: item.yOffset + dragOffset.height
            )
            .gesture(
                DragGesture()
                    .onChanged { v in dragOffset = v.translation }
                    .onEnded { v in
                        item.xOffset += v.translation.width
                        item.yOffset += v.translation.height
                        dragOffset = .zero
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .updating($pinchScale) { val, state, _ in state = val }
                    .onEnded { val in
                        item.scale = max(0.4, min(3.5, item.scale * val))
                    }
            )
    }
}

// MARK: - SUB ISLAND MAP VIEW
// Each sub island uses sideisland.jpeg + character image on top

struct SubIslandView: View {
    let type: IslandType
    @ObservedObject var state: EcoManager
    @State private var bob: Bool = false

    var position: CGPoint {
        switch type {
        case .achievements: return CGPoint(x: -130, y: -185)
        case .goals:        return CGPoint(x:  130, y: -160)
        case .tasks:        return CGPoint(x: -135, y:  155)
        case .facts:        return CGPoint(x:  135, y:  130)
        case .login:        return CGPoint(x:    0, y:  230)
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

    var characterImageName: String {
        switch type {
        case .achievements: return "achievementscharacter"
        case .goals:        return "goalscharacter"
        case .tasks:        return "taskcharacter"
        case .facts:        return "factscharacter"
        case .login:        return "logincharacter"
        }
    }

    var fallbackEmoji: String {
        switch type {
        case .achievements: return "👨‍🌾"
        case .goals:        return "👩‍💻"
        case .tasks:        return "👦"
        case .facts:        return "👩‍🔬"
        case .login:        return "🧑"
        }
    }

    var labelText: String {
        switch type {
        case .achievements: return "ACHIEVEMENTS"
        case .goals:        return "SET GOALS"
        case .tasks:        return "DAILY TASKS"
        case .facts:        return "ECO FACTS"
        case .login:        return "LOG IN"
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                state.zoomedIsland = .sub(type)
            }
        }) {
            SubIslandStack(
                labelText: labelText,
                characterImageName: characterImageName,
                fallbackEmoji: fallbackEmoji,
                islandColor: islandColor
            )
        }
        .offset(x: position.x, y: position.y + (bob ? -5 : 5))
        .animation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: bob)
        .onAppear { bob = true }
    }
}

// Label on top, then ZStack: island image with character overlaid ON the grass surface
struct SubIslandStack: View {
    let labelText: String
    let characterImageName: String
    let fallbackEmoji: String
    let islandColor: Color

    var body: some View {
        VStack(spacing: 4) {
            // 1. Label pill
            Text(labelText)
                .font(.custom("Arial-BoldMT", size: 10))
                .foregroundColor(Color(hex: "3D5A3E"))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 6))

            // 2. ZStack: island is the base, character sits on top of it
            //    The sideisland image renders at 160x90.
            //    The grass surface of sideisland is roughly at y=30 from top of image.
            //    Character is 22x22. We anchor it at the grass level.
            //    In a ZStack with .bottom alignment, offset moves UP from bottom.
            //    Island height = 90. Grass top ≈ 30px from top = 60px from bottom.
            //    So character center should be at ~55px from bottom of island frame.
            ZStack {
                SubIslandMiniShape(islandColor: islandColor)

                SubIslandCharacterImage(
                    imageName: characterImageName,
                    fallbackEmoji: fallbackEmoji
                )
                .frame(width: 20, height: 20)
                // Offset: positive y moves DOWN, negative moves UP.
                // Island renders 160x90. Grass is ~30px from top of image.
                // From center of ZStack (y=0 = middle = 45px from top):
                // Grass is at 30px from top = 15px above center = offset y: -15
                .offset(y: 10)
            }
            .frame(width: 160, height: 90)
        }
    }
}

struct SubIslandCharacterImage: View {
    let imageName: String
    let fallbackEmoji: String

    var body: some View {
        if let img = loadBundleImage(named: imageName) {
            Image(uiImage: img).resizable().scaledToFit()
        } else {
            Text(fallbackEmoji).font(.custom("Arial", size: 14))
        }
    }
}

// sideisland.png — 160x90 display size
struct SubIslandMiniShape: View {
    let islandColor: Color

    var body: some View {
        if let img = loadBundleImage(named: "sideisland") {
            Image(uiImage: img)
                .resizable().scaledToFit()
                .frame(width: 160, height: 90)
        } else {
            ZStack {
                Ellipse()
                    .fill(LinearGradient(
                        colors: [islandColor, islandColor.opacity(0.7)],
                        startPoint: .top, endPoint: .bottom))
                    .frame(width: 160, height: 80)
            }
        }
    }
}

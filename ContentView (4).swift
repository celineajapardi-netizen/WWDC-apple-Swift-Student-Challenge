import SwiftUI

// MARK: - ROOT VIEW

struct ContentView: View {
    @StateObject private var state: EcoManager = EcoManager()

    init() { registerCustomFonts() }

    var body: some View {
        Group {
            if state.currentPage == .start {
                StartPageView(state: state)
            } else {
                MainGameView(state: state)
            }
        }
    }
}

// MARK: - START PAGE

struct StartPageView: View {
    @ObservedObject var state: EcoManager
    @State private var showSaveDialog: Bool = false
    @State private var islandName: String = ""

    var body: some View {
        ZStack {
            StartPageBackground()
            StartPageContent(
                state: state,
                showSaveDialog: $showSaveDialog,
                islandName: $islandName
            )
        }
        .sheet(isPresented: $state.showLoadIsland) {
            LoadIslandView(state: state)
        }
        .alert("Name Your Island", isPresented: $showSaveDialog) {
            TextField("e.g. My Eco Paradise", text: $islandName)
            Button("Save") {
                if !islandName.isEmpty {
                    state.saveCurrentIsland(name: islandName)
                    islandName = ""
                }
            }
            Button("Cancel", role: .cancel) { islandName = "" }
        }
    }
}

struct StartPageBackground: View {
    var body: some View {
        ZStack {
            BackgroundImageOrGradient()
            LinearGradient(
                colors: [Color.black.opacity(0.05), Color.black.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct BackgroundImageOrGradient: View {
    var body: some View {
        if let img = loadBundleImage(named: "startingmainmenubackground") {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .clipped()
        } else {
            LinearGradient(
                colors: [Color(hex: "7DCFCF"), Color(hex: "A8E6CF"),
                         Color(hex: "FFE5B4"), Color(hex: "FFD6A5")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

struct StartPageContent: View {
    @ObservedObject var state: EcoManager
    @Binding var showSaveDialog: Bool
    @Binding var islandName: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Spacer()
            // Uses Starbim font -- add Starbim.otf to Resources/ folder
            Text("ECOLAND")
                .font(.custom("Starbim", size: 80))
                .fontWeight(.bold)
                .foregroundColor(Color(hex: "3D5A3E"))
            Spacer()
            MenuButtonsStack(state: state, showSaveDialog: $showSaveDialog)
            Spacer()
            Spacer()
        }
    }
}

struct MenuButtonsStack: View {
    @ObservedObject var state: EcoManager
    @Binding var showSaveDialog: Bool

    var body: some View {
        VStack(spacing: 20) {
            MenuButton(title: "START", fgHex: "3D5A3E", bgHex: "C7EABB",
                       width: 240, height: 62, fontSize: 26) {
                withAnimation(.spring()) { state.currentPage = .game }
            }
            MenuButton(title: "LOAD ISLAND", fgHex: "1A3A5C", bgHex: "BBDCE5",
                       width: 240, height: 62, fontSize: 26) {
                state.showLoadIsland = true
            }
            MenuButton(title: "SAVE ISLAND", fgHex: "7A3D10", bgHex: "FFE8CD",
                       width: 240, height: 58, fontSize: 24) {
                showSaveDialog = true
            }
        }
    }
}

struct MenuButton: View {
    let title: String
    let fgHex: String
    let bgHex: String
    let width: CGFloat
    let height: CGFloat
    let fontSize: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundColor(Color(hex: fgHex))
                .frame(width: width, height: height)
                .background(Color(hex: bgHex))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color(hex: fgHex), lineWidth: 3))
        }
    }
}

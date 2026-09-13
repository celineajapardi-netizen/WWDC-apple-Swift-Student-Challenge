import SwiftUI

// MARK: - LOAD ISLAND VIEW

struct LoadIslandView: View {
    @ObservedObject var state: EcoManager
    @Environment(\.dismiss) var dismiss
    @State private var deleteIdx: Int? = nil
    @State private var showDeleteAlert: Bool = false

    var fmt: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF8DE").ignoresSafeArea()
                if state.savedIslands.isEmpty {
                    EmptyIslandsView()
                } else {
                    SavedIslandsList(
                        state: state, fmt: fmt,
                        deleteIdx: $deleteIdx,
                        showDeleteAlert: $showDeleteAlert,
                        onDismiss: { dismiss() }
                    )
                }
            }
            .navigationTitle("Load Island 🏝️")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }.foregroundColor(Color(hex: "3D5A3E"))
                }
            }
            .alert("Delete Island?", isPresented: $showDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let i = deleteIdx { state.savedIslands.remove(at: i) }
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This cannot be undone.") }
        }
    }
}

struct EmptyIslandsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("🏝️").font(.custom("Arial", size: 60))
            Text("No saved islands yet!")
                .font(.custom("Arial-BoldMT", size: 18)).foregroundColor(Color(hex: "5A7A5A"))
            Text("Play and save from the main menu.")
                .font(.custom("Arial", size: 14)).foregroundColor(.gray)
                .multilineTextAlignment(.center).padding(.horizontal, 40)
        }
    }
}

struct SavedIslandsList: View {
    @ObservedObject var state: EcoManager
    let fmt: DateFormatter
    @Binding var deleteIdx: Int?
    @Binding var showDeleteAlert: Bool
    let onDismiss: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ForEach(Array(state.savedIslands.enumerated()), id: \.element.id) { i, island in
                    SavedIslandRow(
                        island: island, fmt: fmt,
                        onLoad: { state.loadIsland(island); onDismiss() },
                        onDelete: { deleteIdx = i; showDeleteAlert = true }
                    )
                }
            }.padding(20)
        }
    }
}

struct SavedIslandRow: View {
    let island: SavedIsland
    let fmt: DateFormatter
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text("🏝️").font(.custom("Arial", size: 38))
            VStack(alignment: .leading, spacing: 3) {
                Text(island.name).font(.custom("Arial-BoldMT", size: 16)).foregroundColor(Color(hex: "3D5A3E"))
                Text("Lvl \(island.level) • 🔥\(island.streak) • \(island.contributionPoints) pts")
                    .font(.custom("Arial", size: 12)).foregroundColor(.gray)
                Text(fmt.string(from: island.savedDate))
                    .font(.custom("Arial", size: 11)).foregroundColor(.gray.opacity(0.7))
            }
            Spacer()
            VStack(spacing: 8) {
                Button("Load", action: onLoad)
                    .font(.custom("Arial-BoldMT", size: 13)).foregroundColor(Color(hex: "3D5A3E"))
                    .padding(.horizontal, 16).padding(.vertical, 7)
                    .background(Color(hex: "C7EABB")).clipShape(Capsule())
                    .overlay(Capsule().stroke(Color(hex: "3D5A3E"), lineWidth: 1.5))
                Button("Delete", action: onDelete)
                    .font(.custom("Arial", size: 12)).foregroundColor(.red)
            }
        }
        .padding(16).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "C7EABB"), lineWidth: 2))
    }
}

// MARK: - MAIN GAME VIEW

struct MainGameView: View {
    @ObservedObject var state: EcoManager
    @State private var hasCheckedStreak = false

    var body: some View {
        VStack(spacing: 0) {
            HUDView(state: state)
            GameMapArea(state: state)
            BottomTabBar(state: state)
        }
        .onAppear {
            // Only run once per app session — not on every sheet dismiss
            if !hasCheckedStreak {
                hasCheckedStreak = true
                state.checkStreakOnAppear()
            }
        }
        .sheet(isPresented: $state.showShop) { ShopView(state: state) }
        .sheet(isPresented: $state.showInstructions) { InstructionsView() }
        .sheet(isPresented: $state.showStreakPanel) { StreakPanelView(state: state) }
        .sheet(isPresented: $state.showGoals) { GoalsView(state: state) }
        .sheet(isPresented: $state.showTasks) { TasksView(state: state) }
        .sheet(isPresented: $state.showFacts) { FactsView() }
        .fullScreenCover(isPresented: $state.showCamera) { CameraVerificationView(state: state) }
    }
}

// MARK: - GAME MAP AREA

struct GameMapArea: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        ZStack {
            SkyBackgroundView(timeOfDay: state.timeOfDay)
            if state.zoomedIsland != nil {
                ZoomedIslandView(state: state)
                    .transition(.scale.combined(with: .opacity))
            } else {
                MapView(state: state)
                    .transition(.scale.combined(with: .opacity))
            }
            if state.showRealContribution {
                ContributionBanner(message: state.lastContributionMessage) {
                    state.showRealContribution = false
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(10)
            }
            if state.showDevastatingFact {
                DevastatingFactView(message: state.lastDevastatingFact) {
                    state.showDevastatingFact = false
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: state.zoomedIsland)
    }
}

// MARK: - SKY BACKGROUND
// Morning = light blue (skymorning.jpeg)
// Day = yellow (skyafternoon.jpeg)
// Evening + Night = dark blue (skynight.jpeg)

struct SkyBackgroundView: View {
    let timeOfDay: String

    var imageName: String {
        if timeOfDay == "Morning" { return "skymorning" }
        if timeOfDay == "Day"     { return "skyafternoon" }
        return "skynight"  // Evening AND Night → dark blue
    }

    var fallbackColors: [Color] {
        if timeOfDay == "Morning" {
            return [Color(hex: "C8E6F5"), Color(hex: "DAEEFB")]
        }
        if timeOfDay == "Day" {
            return [Color(hex: "FFF9C4"), Color(hex: "FFFDE7")]
        }
        return [Color(hex: "0D1B4B"), Color(hex: "243580")]
    }

    var body: some View {
        SkyImageOrFallback(imageName: imageName, fallbackColors: fallbackColors)
    }
}

struct SkyImageOrFallback: View {
    let imageName: String
    let fallbackColors: [Color]

    var body: some View {
        GeometryReader { geo in
            if let img = loadBundleImage(named: imageName) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: fallbackColors,
                    startPoint: .top, endPoint: .bottom
                )
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .ignoresSafeArea()
    }
}


struct MapView: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        ZStack {
            VStack {
                TimeOfDayBubble(state: state).padding(.top, 8)
                Spacer()
            }
            MainIslandView(state: state)
                .onTapGesture {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                        state.zoomedIsland = .main
                    }
                }
            ForEach(IslandType.allCases, id: \.self) { type in
                SubIslandView(type: type, state: state)
            }
        }
    }
}

// MARK: - HUD

struct HUDView: View {
    @ObservedObject var state: EcoManager

    var body: some View {
        HStack {
            Text("LVL \(state.level) • \(state.currentSeason)")
                .font(.custom("Arial-BoldMT", size: 13)).foregroundColor(Color(hex: "3D5A3E"))
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "flame.fill").foregroundColor(Color(hex: "FF7043"))
                Text("STREAK: \(state.streak)")
                    .font(.custom("Arial-BoldMT", size: 14)).foregroundColor(Color(hex: "3D5A3E"))
            }
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(Color(hex: "FFF8DE")).clipShape(Capsule())
            .overlay(Capsule().stroke(Color(hex: "FFD54F"), lineWidth: 1.5))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(hex: "C7EABB").opacity(0.6))
    }
}

// MARK: - TIME BUBBLE

struct TimeOfDayBubble: View {
    @ObservedObject var state: EcoManager
    @State private var timeStr: String = ""

    var body: some View {
        HStack(spacing: 6) {
            Text(state.timeIcon)
            Text("\(state.timeOfDay) • \(timeStr)")
                .font(.custom("Arial-BoldMT", size: 13)).foregroundColor(Color(hex: "3D5A3E"))
        }
        .padding(.horizontal, 14).padding(.vertical, 7)
        .background(Color(hex: "FFF8DE").opacity(0.95)).clipShape(Capsule())
        .overlay(Capsule().stroke(Color(hex: "FFD54F").opacity(0.5), lineWidth: 1.5))
        .onAppear { timeStr = state.currentTimeString() }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            timeStr = state.currentTimeString()
        }
    }
}

// MARK: - GOALS VIEW

struct GoalsView: View {
    @ObservedObject var state: EcoManager
    @Environment(\.dismiss) var dismiss
    @State private var goalText: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF8DE").ignoresSafeArea()
                VStack(spacing: 20) {
                    Text("My Eco Goals 🎯")
                        .font(.custom("Arial-BoldMT", size: 16))
                        .foregroundColor(Color(hex: "3D5A3E")).padding(.top, 20)
                    GoalInputRow(goalText: $goalText, onAdd: {
                        if !goalText.isEmpty {
                            state.savedGoals.append(goalText)
                            goalText = ""
                        }
                    })
                    if state.savedGoals.isEmpty {
                        VStack(spacing: 10) {
                            Text("🌱").font(.custom("Arial", size: 50))
                            Text("No goals yet — add one above!")
                                .font(.custom("Arial", size: 14)).foregroundColor(.gray)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 10) {
                                ForEach(Array(state.savedGoals.enumerated()), id: \.offset) { i, goal in
                                    GoalRow(goal: goal, onDelete: { state.savedGoals.remove(at: i) })
                                }
                            }.padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("My Eco Goals 🎯")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Color(hex: "3D5A3E"))
                }
            }
        }
    }
}

struct GoalInputRow: View {
    @Binding var goalText: String
    let onAdd: () -> Void

    var body: some View {
        HStack {
            TextField("e.g. Recycle 3 bottles", text: $goalText)
                .foregroundColor(Color.black)          // BLACK text so visible on white
                .accentColor(Color(hex: "3D5A3E"))
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "C7EABB"), lineWidth: 2))
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.custom("Arial", size: 32)).foregroundColor(Color(hex: "3D5A3E"))
            }
        }.padding(.horizontal)
    }
}

struct GoalRow: View {
    let goal: String
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Text("🌿").font(.custom("Arial", size: 18))
            Text(goal).font(.custom("Arial", size: 14)).foregroundColor(Color(hex: "3D5A3E"))
            Spacer()
            Button(action: onDelete) {
                Image(systemName: "trash").foregroundColor(Color(hex: "C0392B").opacity(0.7))
            }
        }
        .padding(14).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "C7EABB"), lineWidth: 1.5))
    }
}

// MARK: - TASKS VIEW

struct TasksView: View {
    @ObservedObject var state: EcoManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "FFF2C6").opacity(0.5).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        Text("Complete tasks to earn points! 📋")
                            .font(.custom("Arial-BoldMT", size: 15))
                            .foregroundColor(Color(hex: "3D5A3E")).padding(.top, 10)
                        Text("Tasks refresh daily 🌅")
                            .font(.custom("Arial", size: 12)).foregroundColor(.gray)
                        if state.todaysTasks.isEmpty {
                            Text("Loading today's tasks...")
                                .font(.custom("Arial", size: 14)).foregroundColor(.gray).padding(.top, 30)
                        } else {
                            ForEach(0..<state.todaysTasks.count, id: \.self) { i in
                                TaskRow(
                                    icon: state.todaysTasks[i].0,
                                    title: state.todaysTasks[i].1,
                                    points: state.todaysTasks[i].2,
                                    completed: state.taskCompletionForToday[i],
                                    onToggle: {
                                        if !state.taskCompletionForToday[i] {
                                            state.taskCompletionForToday[i] = true
                                            state.contributionPoints += state.todaysTasks[i].2
                                        }
                                    }
                                )
                            }
                        }
                    }.padding(16)
                }
            }
            .navigationTitle("Daily Tasks 📋")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Color(hex: "3D5A3E"))
                }
            }
            .onAppear { state.refreshTasksIfNeeded() }
        }
    }
}

struct TaskRow: View {
    let icon: String
    let title: String
    let points: Int
    let completed: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Text(icon).font(.custom("Arial", size: 28))
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.custom("Arial-BoldMT", size: 14))
                    .foregroundColor(completed ? .gray : Color(hex: "3D5A3E"))
                    .strikethrough(completed)
                Text("+\(points) pts").font(.custom("Arial", size: 12)).foregroundColor(Color(hex: "5A8A5A"))
            }
            Spacer()
            Button(action: onToggle) {
                Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                    .font(.custom("Arial", size: 28))
                    .foregroundColor(completed ? Color(hex: "C7EABB") : Color.gray.opacity(0.4))
            }
        }
        .padding(16).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(completed ? Color(hex: "C7EABB") : Color(hex: "FFF2C6"), lineWidth: 2))
        .opacity(completed ? 0.7 : 1.0)
    }
}

// MARK: - FACTS VIEW (randomly shuffled from large pool)

struct FactsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentIndex: Int = 0
    @State private var shuffledFacts: [(String, String, String)] = []

    let allFacts: [(String, String, String)] = [
        ("🌊","Ocean Plastic","Over 8 million tons of plastic enter our oceans every year — equal to dumping a garbage truck of plastic every single minute."),
        ("🌳","Deforestation","The world loses about 15 billion trees per year. We have lost nearly half of Earth's original forests since humans arrived."),
        ("✈️","Carbon Footprint","One transatlantic flight emits about 1.5 tonnes of CO2 per passenger — more than some people emit in an entire year."),
        ("🪸","Coral Reefs","50% of the world's coral reefs have been lost since 1950. At current rates, 90% could disappear by 2050 without action."),
        ("👗","Fast Fashion","The fashion industry produces 10% of all global carbon emissions and is the second-largest consumer of the world's water supply."),
        ("🐝","Biodiversity","We are in Earth's sixth mass extinction — species are disappearing at 1,000 times the natural rate due to human activity."),
        ("💡","Energy Savings","Switching to LED bulbs saves up to 80% of lighting energy. One bulb swap per US home would light 3 million homes."),
        ("🚗","Transport","Transport causes 24% of global CO2 emissions. Choosing public transport over a car can cut your travel footprint by 70%."),
        ("🍔","Food Choices","Beef production uses 20x more land and emits 20x more greenhouse gas than plant proteins like beans per gram of protein."),
        ("💧","Water","A 5-minute shorter shower saves 50 litres of water. Agriculture accounts for 70% of all global freshwater withdrawals."),
        ("🌡️","Global Warming","Earth has already warmed 1.1°C above pre-industrial levels. Every fraction of a degree matters for ecosystems worldwide."),
        ("🗑️","Landfill","Over 2 billion tonnes of solid waste are generated globally per year. Only about 13.5% of it is currently recycled."),
        ("🌬️","Wind Energy","Wind power is now the cheapest source of new electricity in many countries, producing zero emissions once installed."),
        ("🐘","Wildlife Loss","About 1 million plant and animal species are currently threatened with extinction — the highest number in human history."),
        ("🏙️","Cities","Cities cover just 3% of Earth's land but account for 75% of global energy use and about 80% of CO2 emissions worldwide."),
        ("🧴","Microplastics","Microplastics have been found in human blood, lungs, and even placentas. We may be consuming a credit card worth of plastic weekly."),
        ("🌿","Rainforests","Rainforests produce 20% of the world's oxygen and house 50% of its species, yet cover only 6% of Earth's surface."),
        ("⚡","Solar Power","The amount of solar energy hitting Earth in one hour is enough to power the entire world's energy needs for a full year."),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F9DFDF").opacity(0.4).ignoresSafeArea()
                VStack(spacing: 24) {
                    Spacer()
                    if !shuffledFacts.isEmpty {
                        FactCard(fact: shuffledFacts[currentIndex])
                        FactNavRow(currentIndex: $currentIndex, total: shuffledFacts.count)
                    }
                    Spacer()
                }.padding()
            }
            .navigationTitle("Eco Facts 🔬")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }.foregroundColor(Color(hex: "3D5A3E"))
                }
            }
            .onAppear { shuffledFacts = allFacts.shuffled(); currentIndex = 0 }
        }
    }
}

struct FactNavRow: View {
    @Binding var currentIndex: Int
    let total: Int

    var body: some View {
        HStack(spacing: 20) {
            Button(action: { if currentIndex > 0 { currentIndex -= 1 } }) {
                Image(systemName: "arrow.left.circle.fill").font(.custom("Arial", size: 40))
                    .foregroundColor(currentIndex == 0 ? Color.gray.opacity(0.3) : Color(hex: "C7EABB"))
            }
            Text("\(currentIndex + 1) / \(total)")
                .font(.custom("Arial-BoldMT", size: 14)).foregroundColor(Color(hex: "3D5A3E"))
            Button(action: { if currentIndex < total - 1 { currentIndex += 1 } }) {
                Image(systemName: "arrow.right.circle.fill").font(.custom("Arial", size: 40))
                    .foregroundColor(currentIndex == total - 1 ? Color.gray.opacity(0.3) : Color(hex: "C7EABB"))
            }
        }
    }
}

struct FactCard: View {
    let fact: (String, String, String)

    var body: some View {
        VStack(spacing: 16) {
            Text(fact.0).font(.custom("Arial", size: 60))
            Text(fact.1).font(.custom("Arial-BoldMT", size: 20)).foregroundColor(Color(hex: "3D5A3E"))
            Text(fact.2).font(.custom("Arial", size: 15)).foregroundColor(Color(hex: "4A5A4A"))
                .multilineTextAlignment(.center).lineSpacing(5)
        }
        .padding(28).background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color(hex: "F9DFDF"), lineWidth: 2))
    }
}

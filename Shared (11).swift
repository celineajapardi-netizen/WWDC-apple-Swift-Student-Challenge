// ============================================================
// ECOLAND — Shared Models & Utilities
// ============================================================
// SETUP (.swiftpm): Add to Resources/:
//   Starbim.otf, skymorning.jpeg, skyafternoon.jpeg, skynight.jpeg
//   mainisland.jpeg, expandisland.jpeg
//   oaktree.jpeg, pinetree.jpeg, pinkflower.jpeg, yellowflower.jpeg,
//   blueflower.jpeg, rock.jpeg, mushroom.jpeg,
//   bunny.jpeg, bird.jpeg, cow.jpeg, sheep.jpeg, fox.jpeg, deer.jpeg,
//   house.jpeg, sideisland.jpeg
//   achievementscharacter.jpeg, goalscharacter.jpeg, taskcharacter.jpeg,
//   factscharacter.jpeg, logincharacter.jpeg
// ============================================================

import SwiftUI
import AVFoundation
import Vision
import CoreText

// MARK: - HELPERS

func registerCustomFonts() {
    let fontFiles: [String] = ["Starbim.otf"]
    for filename in fontFiles {
        let parts = filename.split(separator: ".").map(String.init)
        guard parts.count == 2 else { continue }
        guard let url = Bundle.main.url(forResource: parts[0], withExtension: parts[1]) else {
            print("Font not found in bundle: \(filename)")
            continue
        }
        var err: Unmanaged<CFError>?
        let ok = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &err)
        print("Font \(filename): \(ok ? "registered" : "already registered or error")")
    }
}

func loadBundleImage(named name: String) -> UIImage? {
    let exts: [String] = ["png", "jpg", "jpeg", "PNG", "JPG", "JPEG"]
    for ext in exts {
        if let url = Bundle.main.url(forResource: name, withExtension: ext),
           let data = try? Data(contentsOf: url),
           let img = UIImage(data: data) { return img }
    }
    return nil
}

// MARK: - COLOR

extension Color {
    init(hex: String) {
        let sc = Scanner(string: hex)
        var rgb: UInt64 = 0
        sc.scanHexInt64(&rgb)
        let r: Double = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g: Double = Double((rgb & 0x00FF00) >> 8)  / 255.0
        let b: Double = Double(rgb & 0x0000FF)          / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - TOP-LEVEL ENUMS

enum AppPage { case start, game }

enum IslandType: String, CaseIterable {
    case achievements = "Achievements"
    case goals        = "Set Goals"
    case tasks        = "Daily Tasks"
    case facts        = "Eco Facts"
    case login        = "Log In"
}

enum ZoomedTarget: Equatable {
    case main
    case sub(IslandType)
}

// MARK: - PLACED ITEM (draggable, resizable)

struct PlacedItem: Identifiable {
    let id: UUID = UUID()
    let imageName: String   // filename in Resources (no extension)
    let emoji: String       // fallback if image not found
    var xOffset: CGFloat
    var yOffset: CGFloat
    var scale: CGFloat      // user can resize
}

struct SavedIsland: Identifiable, Codable {
    let id: UUID
    var name: String
    var streak: Int
    var level: Int
    var contributionPoints: Int
    var islandHealth: Double
    var placedItemEmojis: [String]
    var savedDate: Date

    init(name: String, streak: Int, level: Int,
         contributionPoints: Int, islandHealth: Double,
         placedItemEmojis: [String]) {
        self.id = UUID()
        self.name = name; self.streak = streak; self.level = level
        self.contributionPoints = contributionPoints
        self.islandHealth = islandHealth
        self.placedItemEmojis = placedItemEmojis
        self.savedDate = Date()
    }
}

struct ShopItem: Identifiable {
    let id: UUID = UUID()
    let name: String
    let imageName: String   // filename in Resources
    let emoji: String       // fallback
    let cost: Int
    let streakRequired: Int
    let description: String
    let category: String    // "Nature", "Animals", "Structures"
}

// MARK: - ECO MANAGER

class EcoManager: ObservableObject {
    @Published var currentPage: AppPage = AppPage.start
    @Published var streak: Int = 0
    @Published var islandHealth: CGFloat = 0.75
    @Published var level: Int = 1
    @Published var contributionPoints: Int = 0
    @Published var showCamera: Bool = false
    @Published var zoomedIsland: ZoomedTarget? = nil
    @Published var placedItems: [PlacedItem] = []
    @Published var showShop: Bool = false
    @Published var showInstructions: Bool = false
    @Published var showRealContribution: Bool = false
    @Published var lastContributionMessage: String = ""
    @Published var lastDevastatingFact: String = ""
    @Published var showDevastatingFact: Bool = false
    @Published var showStreakPanel: Bool = false
    @Published var savedIslands: [SavedIsland] = []
    @Published var showLoadIsland: Bool = false
    @Published var showGoals: Bool = false
    @Published var showTasks: Bool = false
    @Published var showFacts: Bool = false
    @Published var savedGoals: [String] = []

    // MARK: - STREAK DATE TRACKING
    @Published var lastLoggedDate: String = ""           // "yyyy-MM-dd" of last successful log
    @Published var streakPenaltyAppliedDate: String = "" // prevents double-penalising same day

    // MARK: - DAILY TASKS
    @Published var taskLastRefreshDate: String = ""
    @Published var taskIndicesForToday: [Int] = []
    @Published var taskCompletionForToday: [Bool] = [false, false, false, false, false]

    let allPossibleTasks: [(String, String, Int)] = [
        ("♻️", "Recycle something today", 20),
        ("🚶", "Walk or cycle instead of driving", 30),
        ("💧", "Save water — take a shorter shower", 15),
        ("🛍️", "Use a reusable bag", 20),
        ("🌱", "Learn one eco fact today", 10),
        ("🌳", "Plant or water a plant", 25),
        ("🥗", "Eat a plant-based meal", 20),
        ("🚿", "Turn off the tap while brushing teeth", 10),
        ("🔌", "Unplug unused electronics", 15),
        ("🚌", "Take public transport instead of driving", 30),
        ("🥡", "Bring your own container for takeaway", 20),
        ("📦", "Reuse or repurpose packaging", 15),
        ("🌊", "Pick up litter near water", 35),
        ("💡", "Switch to energy-saving lighting", 20),
        ("🍎", "Buy locally grown food", 25),
        ("🧴", "Avoid single-use plastics today", 25),
        ("🚲", "Cycle instead of taking a car", 30),
        ("🌿", "Compost food scraps", 20),
        ("📵", "Reduce screen time to save energy", 10),
        ("☀️", "Air-dry clothes instead of using a dryer", 20),
    ]

    // Shop items with real image names and categories
    let shopItems: [ShopItem] = [
        // Nature
        ShopItem(name: "Oak Tree",     imageName: "oaktree",     emoji: "🌳", cost: 50,  streakRequired: 0,  description: "A classic oak tree",    category: "Nature"),
        ShopItem(name: "Pine Tree",    imageName: "pinetree",    emoji: "🌲", cost: 60,  streakRequired: 0,  description: "A tall pine tree",       category: "Nature"),
        ShopItem(name: "Pink Flower",  imageName: "pinkflower",  emoji: "🌸", cost: 30,  streakRequired: 0,  description: "Lovely pink flowers",    category: "Nature"),
        ShopItem(name: "Yellow Flower",imageName: "yellowflower",emoji: "🌼", cost: 30,  streakRequired: 0,  description: "Sunny yellow flowers",   category: "Nature"),
        ShopItem(name: "Blue Flower",  imageName: "blueflower",  emoji: "💙", cost: 30,  streakRequired: 0,  description: "Pretty blue flowers",    category: "Nature"),
        ShopItem(name: "Rock",         imageName: "rock",        emoji: "🪨", cost: 20,  streakRequired: 0,  description: "A mossy stone",          category: "Nature"),
        ShopItem(name: "Mushroom",     imageName: "mushroom",    emoji: "🍄", cost: 35,  streakRequired: 0,  description: "Spotted mushroom",       category: "Nature"),
        // Animals
        ShopItem(name: "Bunny",        imageName: "bunny",       emoji: "🐇", cost: 80,  streakRequired: 5,  description: "Unlock at 5 streak",     category: "Animals"),
        ShopItem(name: "Bird",         imageName: "bird",        emoji: "🐦", cost: 90,  streakRequired: 5,  description: "Unlock at 5 streak",     category: "Animals"),
        ShopItem(name: "Cow",          imageName: "cow",         emoji: "🐄", cost: 120, streakRequired: 7,  description: "Unlock at 7 streak",     category: "Animals"),
        ShopItem(name: "Sheep",        imageName: "sheep",       emoji: "🐑", cost: 100, streakRequired: 7,  description: "Unlock at 7 streak",     category: "Animals"),
        ShopItem(name: "Fox",          imageName: "fox",         emoji: "🦊", cost: 150, streakRequired: 10, description: "Unlock at 10 streak",    category: "Animals"),
        ShopItem(name: "Deer",         imageName: "deer",        emoji: "🦌", cost: 200, streakRequired: 14, description: "Unlock at 14 streak",    category: "Animals"),
        // Structures
        ShopItem(name: "House", imageName: "house", emoji: "🏠", cost: 200, streakRequired: 20, description: "Unlock at 20 streak", category: "Structures"),
    ]

    let devastatingFacts: [String] = [
        "Boo! Without your help the Amazon lost another 2,000 football fields of forest today. 🌳",
        "Aw, you missed! 15 million plastic bottles entered the ocean while you were away. 🌊",
        "Your island weeps… Global temperatures crept up another fraction without your help. 🌡️",
        "Sad! 137 plant and animal species became extinct today. 🦋",
    ]

    var currentSeason: String {
        if level >= 1 && level <= 3 { return "Winter" }
        if level >= 4 && level <= 6 { return "Spring" }
        if level >= 7 && level <= 9 { return "Summer" }
        return "Autumn"
    }

    var skyColors: [Color] {
        let h: Int = Calendar.current.component(.hour, from: Date())
        if h >= 5 && h <= 7  { return morningColors() }
        if h >= 8 && h <= 16 { return dayColors() }
        return nightColors()
    }

    func morningColors() -> [Color] { [Color(hex: "C8E6F5"), Color(hex: "DAEEFB")] }
    func dayColors()     -> [Color] { [Color(hex: "FFF9C4"), Color(hex: "FFFDE7")] }
    func nightColors()   -> [Color] { [Color(hex: "0D1B4B"), Color(hex: "243580")] }

    var timeOfDay: String {
        let h: Int = Calendar.current.component(.hour, from: Date())
        if h >= 5  && h <= 11 { return "Morning" }
        if h >= 12 && h <= 16 { return "Day" }
        return "Night"   // Evening + Night → dark
    }

    var timeIcon: String {
        let t = timeOfDay
        if t == "Morning" { return "🌅" }
        if t == "Day"     { return "☀️" }
        return "🌙"
    }

    func currentTimeString() -> String {
        let f = DateFormatter(); f.dateFormat = "h:mm a"
        return f.string(from: Date())
    }

    func logAction(actionText: String, contribution: Int) {
        streak += 1
        contributionPoints += contribution
        islandHealth = min(islandHealth + 0.08, 1.5)
        // Record today so checkStreakOnAppear knows we logged in
        let today = todayDateString()
        lastLoggedDate = today
        streakPenaltyAppliedDate = today
        let l: String = actionText.lowercased()
        if l.contains("recycle") || l.contains("bottle") {
            lastContributionMessage = "Amazing! Recycling one bottle saves enough energy to power a bulb for 3 hours."
        } else if l.contains("walk") || l.contains("cycle") || l.contains("bike") {
            lastContributionMessage = "Great! Walking/cycling instead of driving 1km saves ~0.21kg CO2."
        } else if l.contains("meat") || l.contains("vegan") || l.contains("plant") {
            lastContributionMessage = "Fantastic! A plant-based meal saves ~1.5kg CO2 vs a beef meal."
        } else if l.contains("bag") || l.contains("reusable") {
            lastContributionMessage = "Wonderful! One reusable bag prevents ~700 plastic bags from landfill."
        } else {
            lastContributionMessage = "Thank you for caring! Every action counts."
        }
        showRealContribution = true
        if contributionPoints >= level * 150 { level += 1 }
    }

    func failLogin() {
        streak = max(streak - 1, 0)
        islandHealth = max(islandHealth - 0.15, 0.3)
        lastDevastatingFact = devastatingFacts.randomElement()!
        if !placedItems.isEmpty { placedItems.removeLast() }
        showDevastatingFact = true
    }

    // MARK: - DATE HELPERS

    func todayDateString() -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - DAILY TASKS

    func refreshTasksIfNeeded() {
        let today = todayDateString()
        if taskLastRefreshDate == today && taskIndicesForToday.count == 5 { return }
        var pool = Array(0..<allPossibleTasks.count); pool.shuffle()
        taskIndicesForToday = Array(pool.prefix(5))
        taskCompletionForToday = [false, false, false, false, false]
        taskLastRefreshDate = today
    }

    var todaysTasks: [(String, String, Int)] {
        taskIndicesForToday.map { allPossibleTasks[$0] }
    }

    // MARK: - AUTO STREAK CHECK
    // Called from MainGameView.onAppear every time the game screen appears.
    // If a full calendar day has passed since the last successful log,
    // automatically reduces streak by 1 and removes the last placed island item.
    func checkStreakOnAppear() {
        let today = todayDateString()
        // Already penalised today — don't run again
        guard streakPenaltyAppliedDate != today else { return }
        // Never logged anything yet — nothing to penalise
        guard !lastLoggedDate.isEmpty else { return }

        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        guard let lastDate = fmt.date(from: lastLoggedDate),
              let todayDate = fmt.date(from: today) else { return }

        let daysDiff = Calendar.current.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0

        // Only penalise if at least 1 full day missed
        if daysDiff >= 1 {
            applyMissedDayPenalty()
            streakPenaltyAppliedDate = today
        }
    }

    private func applyMissedDayPenalty() {
        streak = max(streak - 1, 0)
        islandHealth = max(islandHealth - 0.15, 0.0)
        // Remove last placed item from island and name it in the message
        let removedEmoji: String
        if !placedItems.isEmpty {
            removedEmoji = placedItems.removeLast().emoji
        } else {
            removedEmoji = "🌿"
        }
        let messages = [
            "You missed a day! \(removedEmoji) was lost from your island. Log in daily to protect it. 🌍",
            "A missed day costs the planet. \(removedEmoji) disappeared from your island. Come back stronger! 🌱",
            "Streak dropped! \(removedEmoji) was removed from your island. Don't give up! 🏝️",
            "Miss a day, lose a piece. \(removedEmoji) vanished from your island. Stay consistent! 🌿",
        ]
        lastDevastatingFact = messages.randomElement()!
        showDevastatingFact = true
    }

    var maxItems: Int { 16 }

    func buyItem(_ item: ShopItem) {
        guard contributionPoints >= item.cost else { return }
        guard streak >= item.streakRequired else { return }
        contributionPoints -= item.cost
        guard placedItems.count < maxItems else { return }
        let offsets: [(CGFloat, CGFloat)] = [
            (-60,20),(-30,-30),(30,-40),(50,15),(0,30),
            (-50,-10),(40,-20),(20,10),(-20,25),(0,-50),
            (-70,-50),(70,-50),(-80,0),(80,0),(0,60),(-40,50)
        ]
        let o = offsets[placedItems.count % offsets.count]
        placedItems.append(PlacedItem(
            imageName: item.imageName, emoji: item.emoji,
            xOffset: o.0, yOffset: o.1, scale: 1.0
        ))
    }

    func saveCurrentIsland(name: String) {
        let island = SavedIsland(
            name: name, streak: streak, level: level,
            contributionPoints: contributionPoints,
            islandHealth: Double(islandHealth),
            placedItemEmojis: placedItems.map { $0.imageName }
        )
        savedIslands.append(island)
    }

    func loadIsland(_ island: SavedIsland) {
        streak = island.streak; level = island.level
        contributionPoints = island.contributionPoints
        islandHealth = CGFloat(island.islandHealth)
        let offsets: [(CGFloat, CGFloat)] = [
            (-60,20),(-30,-30),(30,-40),(50,15),(0,30),(-50,-10),(40,-20)
        ]
        placedItems = island.placedItemEmojis.enumerated().map { i, name in
            let o = offsets[i % offsets.count]
            let match = shopItems.first { $0.imageName == name }
            return PlacedItem(imageName: name, emoji: match?.emoji ?? "🌿",
                              xOffset: o.0, yOffset: o.1, scale: 1.0)
        }
        currentPage = AppPage.game
    }
}

// MARK: - OBJECT DETECTION

struct EcoObjectMatcher {

    static func expectedLabels(for action: String) -> [String] {
        let l = action.lowercased()
        var kw: [String] = []
        if l.contains("plastic bottle") || l.contains("water bottle") {
            kw += ["bottle", "water bottle", "plastic bottle", "beverage", "drink bottle", "drinking water"]
        } else if l.contains("bottle") {
            kw += ["bottle", "water bottle", "glass bottle"]
        }
        if l.contains("plastic bag") { kw += ["plastic bag"] }
        else if l.contains("tote") || l.contains("reusable bag") { kw += ["tote bag", "reusable bag"] }
        else if l.contains("bag") { kw += ["bag", "shopping bag"] }
        if l.contains("can") || l.contains("tin") { kw += ["can", "tin", "beverage can"] }
        if l.contains("recycl") && kw.isEmpty { kw += ["bottle", "can", "cardboard", "recycling"] }
        if l.contains("cardboard") { kw += ["cardboard"] }
        if l.contains("paper") { kw += ["paper", "newspaper"] }
        if l.contains("trash") || l.contains("garbage") { kw += ["trash", "garbage", "waste"] }
        if l.contains("litter") { kw += ["litter", "trash", "garbage"] }
        if l.contains("compost") || l.contains("food waste") { kw += ["compost", "food waste", "vegetable", "fruit"] }
        if l.contains("tree") { kw += ["tree"] }
        if l.contains("plant") && !l.contains("plant-based") { kw += ["plant", "flower"] }
        if l.contains("garden") { kw += ["garden", "plant", "flower"] }
        if l.contains("bike") || l.contains("bicycle") || l.contains("cycling") { kw += ["bicycle", "cycling", "bike"] }
        if kw.isEmpty { kw = ["nature", "outdoor", "environment"] }
        return Array(Set(kw))
    }

    static func requiresPhoto(for action: String) -> Bool {
        let triggers = ["plastic", "bottle", "recycle", "recycl", "trash", "litter",
                        "can", "tin", "paper", "cardboard", "compost", "bag", "tote",
                        "bike", "bicycle", "garbage", "waste", "plant", "tree", "garden", "food waste"]
        return triggers.contains { action.lowercased().contains($0) }
    }

    static func classify(image: UIImage, expectedKeywords: [String],
                         completion: @escaping (Bool, [String], String?) -> Void) {
        guard let cgImage = image.cgImage else { completion(false, [], nil); return }
        let request = VNClassifyImageRequest { req, err in
            guard err == nil, let obs = req.results as? [VNClassificationObservation] else {
                completion(false, [], nil); return
            }
            let allLabels = obs.filter { $0.confidence > 0.04 }.prefix(40)
                .map { (label: $0.identifier.lowercased(), conf: $0.confidence) }
            let labelStrings = allLabels.map { "\($0.label) (\(Int($0.conf * 100))%)" }
            var matched: String? = nil
            outer: for item in allLabels {
                for kw in expectedKeywords {
                    let labelWords = Set(item.label.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty })
                    let kwWords = kw.components(separatedBy: " ").filter { !$0.isEmpty }
                    if kwWords.allSatisfy({ labelWords.contains($0) }) {
                        matched = item.label; break outer
                    }
                }
            }
            DispatchQueue.main.async { completion(matched != nil, Array(labelStrings.prefix(10)), matched) }
        }
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cgImage, options: [:]).perform([request])
        }
    }
}

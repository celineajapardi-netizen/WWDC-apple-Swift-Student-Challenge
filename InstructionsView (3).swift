import SwiftUI

// MARK: - INSTRUCTIONS

struct InstructionsSection: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let body: String
}

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss

    let sections: [InstructionsSection] = [
        InstructionsSection(icon: "🎯", title: "Goal of EcoLand",
            body: "EcoLand is a daily eco-habit tracker game. Each day you do something for the environment, log it here. Your virtual island grows — trees, animals, buildings. Miss a day and your island shrinks."),
        InstructionsSection(icon: "🏝️", title: "Your Main Island",
            body: "Your main island is in the centre of the screen. Tap it to zoom in and see all your placed items up close. The island grows bigger as your streak increases."),
        InstructionsSection(icon: "👥", title: "Mini Island Characters",
            body: "Five smaller islands float around your main island:\n• 👨‍🌾 Achievements\n• 👩‍💻 Set Goals\n• 👦 Daily Tasks\n• 👩‍🔬 Eco Facts\n• 🧑 Log In\n\nTap any mini island to zoom in and interact."),
        InstructionsSection(icon: "📸", title: "Logging Your Action",
            body: "Tap the Log In character and say YES. Type what you did. If the action involves recycling, plastic, trash etc — a photo is required. Apple Vision scans the photo on-device."),
        InstructionsSection(icon: "🔥", title: "Streaks",
            body: "Streak increases by 1 every day you log successfully.\n• 5 streak → Rabbit, Bird\n• 7 streak → Cow, Sheep\n• 10 streak → Fox\n• 14 streak → Deer\n• 20 streak → House"),
        InstructionsSection(icon: "🛍️", title: "The Shop",
            body: "Spend Contribution Points to place items on your island. Nature, Animals, and Structures — all unlockable by earning points and building your streak."),
        InstructionsSection(icon: "🌍", title: "Real World Impact",
            body: "After every verified action the app shows the real environmental impact — how much CO₂ you saved or what difference you made."),
        InstructionsSection(icon: "💾", title: "Saving & Loading",
            body: "Save multiple islands from the main menu. Each save stores your streak, level, points, and placed items. Load any island at any time."),
        InstructionsSection(icon: "🌤️", title: "Real-Time Day Cycle",
            body: "The sky changes based on your clock:\n• Morning: warm sunrise\n• Day: bright blue sky\n• Evening: purple and orange\n• Night: dark blue"),
    ]

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "F0FAF0").ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 14) {
                        ForEach(sections) { s in
                            InstructionCard(section: s)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("How to Play 📖")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct InstructionCard: View {
    let section: InstructionsSection

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text(section.icon).font(.custom("Arial", size: 28))
                Text(section.title)
                    .font(.custom("Arial-BoldMT", size: 16))
                    .foregroundColor(Color(hex: "3D5A3E"))
            }
            Text(section.body)
                .font(.custom("Arial", size: 13))
                .foregroundColor(Color(hex: "4A5A4A"))
                .lineSpacing(4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(hex: "C7EABB"), lineWidth: 2)
        )
    }
}
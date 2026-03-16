import SwiftUI

struct MiniGameItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let colors: [Color]
}

struct MiniGamesHubView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedGame: String?

    private var theme: ColorTheme { settings.selectedTheme }

    private let games: [MiniGameItem] = [
        MiniGameItem(title: "Sudoku", subtitle: "Classic 9x9 puzzle", icon: "square.grid.3x3.fill", colors: [.blue, .indigo]),
        MiniGameItem(title: "2048", subtitle: "Merge tiles to 2048", icon: "square.grid.2x2.fill", colors: [.orange, .red]),
        MiniGameItem(title: "Number Memory", subtitle: "Remember the sequence", icon: "brain.head.profile", colors: [.purple, .pink]),
        MiniGameItem(title: "Math Pairs", subtitle: "Match equations & answers", icon: "rectangle.on.rectangle", colors: [.green, .mint]),
        MiniGameItem(title: "Number Sequence", subtitle: "Find the pattern", icon: "chart.line.uptrend.xyaxis", colors: [.cyan, .blue]),
        MiniGameItem(title: "Magic Square", subtitle: "Fill the grid", icon: "square.grid.3x3.topleft.filled", colors: [.red, .orange]),
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        headerSection

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            ForEach(games) { game in
                                miniGameCard(game)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .miniGameGoHome)) { _ in
                dismiss()
            }
            .fullScreenCover(item: Binding(
                get: {
                    if let name = selectedGame { return SelectedGameWrapper(name: name) }
                    return nil
                },
                set: { selectedGame = $0?.name }
            )) { wrapper in
                gameView(for: wrapper.name)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Math Games")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text("Fun brain training puzzles")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 8)
    }

    private func miniGameCard(_ game: MiniGameItem) -> some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            selectedGame = game.title
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: game.colors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 52, height: 52)

                    Image(systemName: game.icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text(game.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(game.subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .padding(.horizontal, 8)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [game.colors[0].opacity(0.3), game.colors[1].opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    @ViewBuilder
    private func gameView(for name: String) -> some View {
        switch name {
        case "Sudoku":          SudokuGameView()
        case "2048":            Game2048View()
        case "Number Memory":   NumberMemoryGameView()
        case "Math Pairs":      MathPairsGameView()
        case "Number Sequence": NumberSequenceGameView()
        case "Magic Square":    MagicSquareGameView()
        default:                EmptyView()
        }
    }
}

private struct SelectedGameWrapper: Identifiable {
    let id = UUID()
    let name: String
}

// MARK: - Notification for Home navigation
extension Notification.Name {
    static let miniGameGoHome = Notification.Name("miniGameGoHome")
}

// MARK: - Reusable Pause Overlay for Mini Games
struct MiniGamePauseOverlay: View {
    let theme: ColorTheme
    let onResume: () -> Void
    let onRestart: () -> Void
    let onGameSelection: () -> Void
    let onHome: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
                .onTapGesture { onResume() }

            VStack(spacing: 20) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(theme.primary)

                Text("Paused")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                VStack(spacing: 12) {
                    // Resume
                    Button(action: onResume) {
                        HStack { Image(systemName: "play.fill"); Text("Resume") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                    }

                    // Restart
                    Button(action: onRestart) {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Restart") }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }

                    // Game Selection
                    Button(action: onGameSelection) {
                        HStack { Image(systemName: "gamecontroller.fill"); Text("Game Selection") }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }

                    // Home
                    Button(action: onHome) {
                        HStack { Image(systemName: "house.fill"); Text("Home") }
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24).fill(theme.background).shadow(color: .black.opacity(0.3), radius: 20, y: 10))
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    MiniGamesHubView()
}

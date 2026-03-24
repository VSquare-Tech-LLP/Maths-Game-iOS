import SwiftUI
import StoreKit

struct IntroPage {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    let features: [(icon: String, text: String)]
    let isRatingPage: Bool

    init(title: String, subtitle: String, icon: String, gradientColors: [Color], features: [(icon: String, text: String)], isRatingPage: Bool = false) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.gradientColors = gradientColors
        self.features = features
        self.isRatingPage = isRatingPage
    }
}

struct IntroView: View {
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @State private var currentPage = 0
    @State private var iconPulse = false
    @Environment(\.requestReview) private var requestReview
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var isIPad: Bool { hSizeClass == .regular }

    private let pages: [IntroPage] = [
        IntroPage(
            title: "Welcome to\nMathQ",
            subtitle: "Your Brain's Favourite Workout",
            icon: "brain.head.profile",
            gradientColors: [Color(red: 0.2, green: 0.85, blue: 0.5), Color(red: 0.1, green: 0.65, blue: 0.4)],
            features: [
                (icon: "plus.forwardslash.minus", text: "Addition, Subtraction & more"),
                (icon: "gamecontroller.fill", text: "Fun Mini Games"),
                (icon: "chart.line.uptrend.xyaxis", text: "Track your progress")
            ]
        ),
        IntroPage(
            title: "Master Every\nOperation",
            subtitle: "6 Game Modes to Challenge You",
            icon: "function",
            gradientColors: [Color(red: 0.35, green: 0.6, blue: 1.0), Color(red: 0.25, green: 0.4, blue: 0.9)],
            features: [
                (icon: "plus", text: "Addition & Subtraction"),
                (icon: "multiply", text: "Multiplication & Division"),
                (icon: "shuffle", text: "Mixed Mode & True/False")
            ]
        ),
        IntroPage(
            title: "Beyond\nthe Basics",
            subtitle: "Mini Games That Train Your Brain",
            icon: "puzzlepiece.fill",
            gradientColors: [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.4, blue: 0.15)],
            features: [
                (icon: "square.grid.3x3.fill", text: "Sudoku & 2048"),
                (icon: "bolt.fill", text: "Quick Maths Challenge"),
                (icon: "memorychip", text: "Number Memory & Sequences")
            ]
        ),
        IntroPage(
            title: "Play Every\nDay",
            subtitle: "Build Streaks & Earn Achievements",
            icon: "calendar.badge.clock",
            gradientColors: [Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 0.9, green: 0.25, blue: 0.5)],
            features: [
                (icon: "flame.fill", text: "Daily Challenges"),
                (icon: "trophy.fill", text: "Unlock Achievements"),
                (icon: "pencil.and.outline", text: "Learn from your Mistakes")
            ]
        ),
        IntroPage(
            title: "Enjoying\nMathQ?",
            subtitle: "Rate us to keep the games coming!",
            icon: "heart.fill",
            gradientColors: [Color(red: 1.0, green: 0.85, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
            features: [],
            isRatingPage: true
        ),
        IntroPage(
            title: "Ready to\nBegin?",
            subtitle: "Let's boost that brain power!",
            icon: "rocket.fill",
            gradientColors: [Color(red: 0.7, green: 0.4, blue: 1.0), Color(red: 0.55, green: 0.25, blue: 0.9)],
            features: [
                (icon: "star.fill", text: "Choose your difficulty level"),
                (icon: "person.2.fill", text: "Compete on leaderboards"),
                (icon: "heart.fill", text: "Have fun learning maths!")
            ]
        )
    ]

    var body: some View {
        GeometryReader { geo in
            let maxW: CGFloat = isIPad ? 520 : .infinity

            ZStack {
                // Background
                Color(red: 0.06, green: 0.06, blue: 0.10)
                    .ignoresSafeArea()

                // Radial glow
                RadialGradient(
                    colors: [
                        pages[currentPage].gradientColors[0].opacity(0.18),
                        pages[currentPage].gradientColors[1].opacity(0.04),
                        Color.clear
                    ],
                    center: .init(x: 0.5, y: 0.28),
                    startRadius: 5,
                    endRadius: geo.size.height * 0.45
                )
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.6), value: currentPage)

                // Floating math symbols
                floatingSymbols(in: geo.size)
                    .id(currentPage)

                VStack(spacing: 0) {
                    // Content
                    TabView(selection: $currentPage) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            if pages[index].isRatingPage {
                                ratingPageView(page: pages[index], screenSize: geo.size)
                                    .tag(index)
                            } else {
                                introPageView(page: pages[index], screenSize: geo.size)
                                    .tag(index)
                            }
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Page indicator dots
                    HStack(spacing: isIPad ? 12 : 10) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage
                                      ? pages[currentPage].gradientColors[0]
                                      : Color.white.opacity(0.25))
                                .frame(
                                    width: index == currentPage ? (isIPad ? 32 : 28) : (isIPad ? 10 : 8),
                                    height: isIPad ? 10 : 8
                                )
                                .animation(.spring(response: 0.35), value: currentPage)
                        }
                    }
                    .padding(.bottom, isIPad ? 28 : 20)

                    // Bottom button
                    Button {
                        if currentPage < pages.count - 1 {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation { hasSeenIntro = true }
                        }
                    } label: {
                        Text(currentPage < pages.count - 1 ? "Continue" : "Get Started")
                            .font(.system(size: isIPad ? 22 : 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: maxW)
                            .padding(.vertical, isIPad ? 20 : 18)
                            .background(
                                LinearGradient(
                                    colors: pages[currentPage].gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(isIPad ? 20 : 18)
                            .shadow(color: pages[currentPage].gradientColors[0].opacity(0.4), radius: 10, y: 5)
                    }
                    .padding(.horizontal, isIPad ? 60 : 30)
                    .padding(.bottom, isIPad ? 44 : 36)
                    .animation(.easeInOut(duration: 0.3), value: currentPage)
                }
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: currentPage) { _, newPage in
            if pages[newPage].isRatingPage {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    requestReview()
                }
            }
            iconPulse = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    iconPulse = true
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconPulse = true
            }
        }
    }

    // MARK: - Floating Symbols

    @ViewBuilder
    private func floatingSymbols(in size: CGSize) -> some View {
        let symbols = ["＋", "−", "×", "÷", "＝", "π", "∑", "%", "√"]
        let positions: [(CGFloat, CGFloat)] = [
            (0.08, 0.07), (0.90, 0.04), (0.04, 0.30),
            (0.93, 0.25), (0.12, 0.55), (0.88, 0.50),
            (0.50, 0.02), (0.70, 0.60), (0.30, 0.65)
        ]
        ZStack {
            ForEach(0..<min(symbols.count, positions.count), id: \.self) { i in
                FloatingMathSymbol(
                    symbol: symbols[i],
                    fontSize: CGFloat.random(in: (isIPad ? 20 : 14)...(isIPad ? 34 : 24)),
                    delay: Double(i) * 0.3
                )
                .position(
                    x: size.width * positions[i].0,
                    y: size.height * positions[i].1
                )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Intro Page

    @ViewBuilder
    private func introPageView(page: IntroPage, screenSize: CGSize) -> some View {
        let iconSz: CGFloat = isIPad ? 88 : 70
        let maxW: CGFloat = isIPad ? 520 : .infinity

        ScrollView(showsIndicators: false) {
            VStack(spacing: isIPad ? 28 : 22) {
                Spacer().frame(height: isIPad ? 60 : 30)

                // Icon - rounded square with glow rings
                ZStack {
                    // Outer glow
                    RoundedRectangle(cornerRadius: isIPad ? 36 : 28)
                        .stroke(
                            page.gradientColors[0].opacity(0.2),
                            lineWidth: isIPad ? 2 : 1.5
                        )
                        .frame(width: iconSz + 32, height: iconSz + 32)
                        .scaleEffect(iconPulse ? 1.0 : 0.85)
                        .opacity(iconPulse ? 1 : 0)

                    // Icon background
                    RoundedRectangle(cornerRadius: isIPad ? 28 : 22)
                        .fill(
                            LinearGradient(
                                colors: page.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: iconSz, height: iconSz)
                        .shadow(color: page.gradientColors[0].opacity(0.45), radius: 20, y: 8)
                        .scaleEffect(iconPulse ? 1.0 : 0.85)

                    Image(systemName: page.icon)
                        .font(.system(size: isIPad ? 40 : 32, weight: .bold))
                        .foregroundColor(.white)
                        .scaleEffect(iconPulse ? 1.0 : 0.85)
                }

                // Title
                Text(page.title)
                    .font(.system(size: isIPad ? 44 : 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(isIPad ? 6 : 4)

                // Subtitle
                Text(page.subtitle)
                    .font(.system(size: isIPad ? 20 : 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                // Feature list with card backgrounds
                VStack(spacing: isIPad ? 14 : 10) {
                    ForEach(0..<page.features.count, id: \.self) { i in
                        HStack(spacing: isIPad ? 18 : 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: isIPad ? 14 : 11)
                                    .fill(page.gradientColors[0].opacity(0.12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isIPad ? 14 : 11)
                                            .stroke(page.gradientColors[0].opacity(0.15), lineWidth: 1)
                                    )
                                    .frame(width: isIPad ? 50 : 40, height: isIPad ? 50 : 40)

                                Image(systemName: page.features[i].icon)
                                    .font(.system(size: isIPad ? 20 : 16, weight: .semibold))
                                    .foregroundColor(page.gradientColors[0])
                            }

                            Text(page.features[i].text)
                                .font(.system(size: isIPad ? 19 : 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))

                            Spacer()
                        }
                        .padding(.horizontal, isIPad ? 18 : 14)
                        .padding(.vertical, isIPad ? 14 : 11)
                        .background(
                            RoundedRectangle(cornerRadius: isIPad ? 16 : 13)
                                .fill(Color.white.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: isIPad ? 16 : 13)
                                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                                )
                        )
                    }
                }
                .frame(maxWidth: maxW)
                .padding(.horizontal, isIPad ? 40 : 20)
                .padding(.top, isIPad ? 8 : 4)

                Spacer().frame(height: 20)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, isIPad ? 20 : 0)
    }

    // MARK: - Rating Page

    @ViewBuilder
    private func ratingPageView(page: IntroPage, screenSize: CGSize) -> some View {
        let iconSz: CGFloat = isIPad ? 88 : 70

        VStack(spacing: isIPad ? 28 : 22) {
            Spacer()

            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: isIPad ? 36 : 28)
                    .stroke(
                        page.gradientColors[0].opacity(0.2),
                        lineWidth: isIPad ? 2 : 1.5
                    )
                    .frame(width: iconSz + 32, height: iconSz + 32)
                    .scaleEffect(iconPulse ? 1.0 : 0.85)
                    .opacity(iconPulse ? 1 : 0)

                RoundedRectangle(cornerRadius: isIPad ? 28 : 22)
                    .fill(
                        LinearGradient(
                            colors: page.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: iconSz, height: iconSz)
                    .shadow(color: page.gradientColors[0].opacity(0.45), radius: 20, y: 8)
                    .scaleEffect(iconPulse ? 1.0 : 0.85)

                Image(systemName: page.icon)
                    .font(.system(size: isIPad ? 40 : 32, weight: .bold))
                    .foregroundColor(.white)
                    .scaleEffect(iconPulse ? 1.0 : 0.85)
            }

            // Title
            Text(page.title)
                .font(.system(size: isIPad ? 44 : 32, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(isIPad ? 6 : 4)

            // Subtitle
            Text(page.subtitle)
                .font(.system(size: isIPad ? 20 : 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)

            // Star rating display
            HStack(spacing: isIPad ? 16 : 12) {
                ForEach(0..<5, id: \.self) { i in
                    Image(systemName: "star.fill")
                        .font(.system(size: isIPad ? 44 : 34))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.9, blue: 0.2), Color(red: 1.0, green: 0.7, blue: 0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.0).opacity(0.4), radius: 8, y: 3)
                        .scaleEffect(iconPulse ? 1.0 : 0.4)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.6).delay(Double(i) * 0.1),
                            value: iconPulse
                        )
                }
            }
            .padding(.top, isIPad ? 12 : 8)

            Text("Your support means the world to us!")
                .font(.system(size: isIPad ? 17 : 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.4))

            Spacer()
        }
        .padding(.horizontal, isIPad ? 40 : 20)
    }
}

// MARK: - Floating Math Symbol

struct FloatingMathSymbol: View {
    let symbol: String
    let fontSize: CGFloat
    let delay: Double
    @State private var animate = false

    var body: some View {
        Text(symbol)
            .font(.system(size: fontSize, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(animate ? 0.1 : 0.04))
            .rotationEffect(.degrees(animate ? 15 : -15))
            .offset(y: animate ? -10 : 10)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: Double.random(in: 3.5...5.5))
                    .repeatForever(autoreverses: true)
                    .delay(delay)
                ) {
                    animate = true
                }
            }
    }
}

#Preview {
    IntroView()
}

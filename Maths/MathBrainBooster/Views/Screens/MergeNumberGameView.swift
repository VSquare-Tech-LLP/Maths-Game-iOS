import SwiftUI

// MARK: - Merge Ball Model

struct MergeBall: Identifiable {
    let id = UUID()
    var value: Int
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat = 0
    var vy: CGFloat = 0
    var radius: CGFloat { MergeBall.radius(for: value) }
    var isStatic = false
    var justMerged = false
    var mergeScale: CGFloat = 1.0

    static func radius(for value: Int) -> CGFloat {
        switch value {
        case 2:    return 20
        case 4:    return 24
        case 8:    return 28
        case 16:   return 32
        case 32:   return 36
        case 64:   return 40
        case 128:  return 44
        case 256:  return 48
        case 512:  return 52
        case 1024: return 56
        case 2048: return 60
        default:   return 64
        }
    }

    static func ballColors(for value: Int) -> (main: Color, light: Color, dark: Color) {
        switch value {
        case 2:    return (Color(red: 0.96, green: 0.60, blue: 0.60), Color(red: 1.0, green: 0.80, blue: 0.80), Color(red: 0.75, green: 0.35, blue: 0.35))
        case 4:    return (Color(red: 0.96, green: 0.82, blue: 0.55), Color(red: 1.0, green: 0.92, blue: 0.75), Color(red: 0.80, green: 0.60, blue: 0.30))
        case 8:    return (Color(red: 0.98, green: 0.65, blue: 0.38), Color(red: 1.0, green: 0.82, blue: 0.60), Color(red: 0.82, green: 0.45, blue: 0.20))
        case 16:   return (Color(red: 0.92, green: 0.42, blue: 0.55), Color(red: 1.0, green: 0.65, blue: 0.72), Color(red: 0.72, green: 0.25, blue: 0.38))
        case 32:   return (Color(red: 0.65, green: 0.45, blue: 0.82), Color(red: 0.82, green: 0.68, blue: 0.95), Color(red: 0.45, green: 0.28, blue: 0.62))
        case 64:   return (Color(red: 0.40, green: 0.60, blue: 0.88), Color(red: 0.62, green: 0.78, blue: 1.0), Color(red: 0.22, green: 0.40, blue: 0.68))
        case 128:  return (Color(red: 0.30, green: 0.78, blue: 0.72), Color(red: 0.55, green: 0.92, blue: 0.88), Color(red: 0.15, green: 0.55, blue: 0.50))
        case 256:  return (Color(red: 0.42, green: 0.80, blue: 0.42), Color(red: 0.65, green: 0.95, blue: 0.65), Color(red: 0.25, green: 0.58, blue: 0.25))
        case 512:  return (Color(red: 0.88, green: 0.82, blue: 0.28), Color(red: 1.0, green: 0.95, blue: 0.55), Color(red: 0.68, green: 0.62, blue: 0.15))
        case 1024: return (Color(red: 0.95, green: 0.55, blue: 0.25), Color(red: 1.0, green: 0.75, blue: 0.50), Color(red: 0.75, green: 0.38, blue: 0.12))
        case 2048: return (Color(red: 0.95, green: 0.30, blue: 0.30), Color(red: 1.0, green: 0.55, blue: 0.55), Color(red: 0.72, green: 0.15, blue: 0.15))
        default:   return (Color(red: 0.40, green: 0.35, blue: 0.50), Color(red: 0.60, green: 0.55, blue: 0.70), Color(red: 0.25, green: 0.20, blue: 0.35))
        }
    }
}

// MARK: - Merge Particle

struct MergeParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var life: CGFloat = 1.0
    var color: Color
    var size: CGFloat
}

// MARK: - Game View

struct MergeNumberGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    @State private var balls: [MergeBall] = []
    @State private var particles: [MergeParticle] = []
    @State private var nextValue: Int = 2
    @State private var dropX: CGFloat = 0
    @State private var score: Int = 0
    @State private var bestScore: Int = UserDefaults.standard.integer(forKey: "mergeNumberBest")
    @State private var isGameOver = false
    @State private var isPaused = false
    @State private var canDrop = true
    @State private var timer: Timer?
    @State private var isDragging = false
    @State private var dangerPulse = false
    @State private var highestValue = 2
    @State private var comboCount = 0
    @State private var showCombo = false

    // Physics
    private let gravity: CGFloat = 0.45
    private let damping: CGFloat = 0.65
    private let friction: CGFloat = 0.97
    private let containerPadding: CGFloat = 4
    private let topDangerY: CGFloat = 55
    private let dropStartY: CGFloat = 25

    private var theme: ColorTheme { settings.selectedTheme }
    private let containerWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let containerHeight: CGFloat = UIScreen.main.bounds.height * 0.52

    var body: some View {
        ZStack {
            // Rich gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.15, blue: 0.25),
                    Color(red: 0.25, green: 0.18, blue: 0.30),
                    Color(red: 0.20, green: 0.16, blue: 0.28)
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ).ignoresSafeArea()

            // Subtle pattern overlay
            VStack(spacing: 40) {
                ForEach(0..<20, id: \.self) { _ in
                    HStack(spacing: 40) {
                        ForEach(0..<10, id: \.self) { _ in
                            Circle()
                                .fill(Color.white.opacity(0.015))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
            }
            .ignoresSafeArea()

            VStack(spacing: 8) {
                topBar
                scoreSection
                dropArea
                gameContainer
                Spacer(minLength: 4)
            }
            .padding(.top, 8)

            // Combo popup
            if showCombo && comboCount >= 2 {
                Text("COMBO x\(comboCount)!")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.yellow)
                    .shadow(color: .orange, radius: 10)
                    .shadow(color: .orange.opacity(0.5), radius: 20)
                    .transition(.scale.combined(with: .opacity))
                    .zIndex(200)
            }

            if isGameOver { gameOverOverlay }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: { isPaused = false; startPhysics() },
                    onRestart: { isPaused = false; resetGame() },
                    onGameSelection: { isPaused = false; timer?.invalidate(); dismiss() },
                    onHome: {
                        timer?.invalidate(); dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .miniGameGoHome, object: nil)
                        }
                    }
                )
            }
        }
        .onAppear {
            dropX = containerWidth / 2
            nextValue = randomDropValue()
            startPhysics()
        }
        .onDisappear { timer?.invalidate() }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                dangerPulse = true
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { timer?.invalidate(); dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(Color.white.opacity(0.1))
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    )
            }
            Spacer()
            Text("Merge Numbers")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(colors: [.white, .white.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                )
            Spacer()
            Button { isPaused = true; timer?.invalidate() } label: {
                Image(systemName: "pause.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 38, height: 38)
                    .background(
                        Circle().fill(Color.white.opacity(0.1))
                            .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 1))
                    )
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Score Section

    private var scoreSection: some View {
        HStack(spacing: 0) {
            // Best
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "trophy.fill").font(.system(size: 10)).foregroundColor(.yellow.opacity(0.7))
                    Text("BEST").font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundColor(.white.opacity(0.5))
                }
                Text("\(bestScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
            }
            .frame(maxWidth: .infinity)

            // Score - center, larger
            VStack(spacing: 1) {
                Text("SCORE")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(2)
                Text("\(score)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.white, .white.opacity(0.85)], startPoint: .top, endPoint: .bottom)
                    )
            }
            .frame(maxWidth: .infinity)

            // Highest ball
            VStack(spacing: 3) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.orange.opacity(0.7))
                    Text("MAX").font(.system(size: 9, weight: .heavy, design: .rounded)).foregroundColor(.white.opacity(0.5))
                }
                Text("\(highestValue)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
    }

    // MARK: - Drop Area

    private var dropArea: some View {
        ZStack {
            // Dotted drop guide line
            Path { path in
                path.move(to: CGPoint(x: dropX, y: 40))
                path.addLine(to: CGPoint(x: dropX, y: 65))
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
            .foregroundColor(Color.white.opacity(0.2))

            // The ball to drop
            if canDrop {
                glossyBallView(value: nextValue, radius: MergeBall.radius(for: nextValue))
                    .position(x: dropX, y: 18)
                    .shadow(color: MergeBall.ballColors(for: nextValue).main.opacity(0.4), radius: 8)
            }

            // "Next" label
            Text("NEXT")
                .font(.system(size: 8, weight: .heavy, design: .rounded))
                .foregroundColor(.white.opacity(0.3))
                .tracking(2)
                .position(x: containerWidth / 2, y: 58)
        }
        .frame(width: containerWidth, height: 65)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isDragging = true
                    let r = MergeBall.radius(for: nextValue)
                    dropX = max(r + 4, min(containerWidth - r - 4, value.location.x))
                }
                .onEnded { _ in
                    isDragging = false
                    dropBall()
                }
        )
    }

    // MARK: - Game Container

    private var gameContainer: some View {
        ZStack(alignment: .topLeading) {
            // Container bg with inner shadow effect
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.12, green: 0.10, blue: 0.18),
                            Color(red: 0.15, green: 0.13, blue: 0.20)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.15),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .top, endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, y: 4)

            // Floor gradient (settle area)
            VStack {
                Spacer()
                LinearGradient(
                    colors: [Color.clear, Color.white.opacity(0.03)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 80)
                .cornerRadius(14)
            }

            // Danger line with glow
            ZStack {
                Rectangle()
                    .fill(Color.red.opacity(dangerPulse ? 0.35 : 0.15))
                    .frame(height: 1.5)
                    .blur(radius: dangerPulse ? 3 : 1)
                Rectangle()
                    .fill(Color.red.opacity(0.5))
                    .frame(height: 0.5)
                // Danger zone hatching
                HStack(spacing: 12) {
                    ForEach(0..<20, id: \.self) { _ in
                        Rectangle()
                            .fill(Color.red.opacity(0.08))
                            .frame(width: 6, height: 8)
                            .rotationEffect(.degrees(-45))
                    }
                }
                .offset(y: -6)
                .opacity(dangerPulse ? 0.6 : 0.3)
            }
            .offset(y: topDangerY)

            // Particles
            ForEach(particles) { p in
                Circle()
                    .fill(p.color)
                    .frame(width: p.size * p.life, height: p.size * p.life)
                    .position(x: p.x, y: p.y)
                    .opacity(Double(p.life))
                    .blur(radius: 0.5)
            }

            // Balls
            ForEach(balls) { ball in
                glossyBallView(value: ball.value, radius: ball.radius, flash: ball.justMerged)
                    .position(x: ball.x, y: ball.y)
                    .scaleEffect(ball.mergeScale)
                    .shadow(color: MergeBall.ballColors(for: ball.value).main.opacity(0.3), radius: ball.justMerged ? 12 : 4)
            }
        }
        .frame(width: containerWidth, height: containerHeight)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 4)
    }

    // MARK: - Glossy Ball View

    private func glossyBallView(value: Int, radius: CGFloat, flash: Bool = false) -> some View {
        let colors = MergeBall.ballColors(for: value)
        let size = radius * 2

        return ZStack {
            // Outer glow on merge
            if flash {
                Circle()
                    .fill(colors.main.opacity(0.4))
                    .frame(width: size + 16, height: size + 16)
                    .blur(radius: 8)
            }

            // Drop shadow
            Circle()
                .fill(colors.dark.opacity(0.5))
                .frame(width: size - 2, height: size - 2)
                .offset(x: 1, y: 3)
                .blur(radius: 2)

            // Main ball body - radial gradient for 3D sphere look
            Circle()
                .fill(
                    RadialGradient(
                        colors: [colors.light, colors.main, colors.dark],
                        center: .init(x: 0.35, y: 0.30),
                        startRadius: 0,
                        endRadius: radius * 1.1
                    )
                )
                .frame(width: size, height: size)

            // Top shine (crescent highlight)
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.6), Color.white.opacity(0.0)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: size * 0.6, height: size * 0.35)
                .offset(x: -radius * 0.1, y: -radius * 0.35)

            // Small specular highlight dot
            Circle()
                .fill(Color.white.opacity(0.7))
                .frame(width: size * 0.12, height: size * 0.12)
                .offset(x: -radius * 0.25, y: -radius * 0.35)
                .blur(radius: 1)

            // Subtle inner edge ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.25), Color.clear, colors.dark.opacity(0.3)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: size - 1, height: size - 1)

            // Number
            Text("\(value)")
                .font(.system(size: radius * 0.65, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: colors.dark.opacity(0.6), radius: 2, x: 0, y: 1)
        }
        .scaleEffect(flash ? 1.15 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: flash)
    }

    // MARK: - Game Logic

    private func randomDropValue() -> Int {
        let choices = [2, 2, 2, 2, 4, 4, 4, 8, 8, 16]
        return choices.randomElement()!
    }

    private func dropBall() {
        guard canDrop, !isPaused, !isGameOver else { return }
        canDrop = false
        comboCount = 0

        let ball = MergeBall(value: nextValue, x: dropX, y: dropStartY, vy: 2)
        balls.append(ball)

        SoundManager.shared.playButtonTap()
        HapticManager.shared.buttonTap()

        nextValue = randomDropValue()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            canDrop = true
        }
    }

    private func startPhysics() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in physicsTick() }
        }
    }

    private func physicsTick() {
        guard !isPaused, !isGameOver else { return }

        let bottom = containerHeight - containerPadding
        let left: CGFloat = containerPadding
        let right = containerWidth - containerPadding

        // Move balls
        for i in 0..<balls.count {
            balls[i].vy += gravity
            balls[i].vx *= friction
            balls[i].vy *= friction
            balls[i].x += balls[i].vx
            balls[i].y += balls[i].vy

            let r = balls[i].radius

            // Floor
            if balls[i].y + r > bottom {
                balls[i].y = bottom - r
                balls[i].vy = -balls[i].vy * damping
                if abs(balls[i].vy) < 0.5 { balls[i].vy = 0 }
            }
            // Walls
            if balls[i].x - r < left {
                balls[i].x = left + r
                balls[i].vx = -balls[i].vx * damping
            }
            if balls[i].x + r > right {
                balls[i].x = right - r
                balls[i].vx = -balls[i].vx * damping
            }
        }

        // Collisions
        var mergeOccurred = false
        var toRemove = Set<UUID>()
        var toAdd: [MergeBall] = []

        for i in 0..<balls.count {
            for j in (i+1)..<balls.count {
                if toRemove.contains(balls[i].id) || toRemove.contains(balls[j].id) { continue }

                let dx = balls[j].x - balls[i].x
                let dy = balls[j].y - balls[i].y
                let dist = sqrt(dx * dx + dy * dy)
                let minDist = balls[i].radius + balls[j].radius

                if dist < minDist && dist > 0.1 {
                    let nx = dx / dist
                    let ny = dy / dist
                    let overlap = minDist - dist

                    balls[i].x -= nx * overlap * 0.5
                    balls[i].y -= ny * overlap * 0.5
                    balls[j].x += nx * overlap * 0.5
                    balls[j].y += ny * overlap * 0.5

                    if balls[i].value == balls[j].value {
                        let newValue = balls[i].value * 2
                        let midX = (balls[i].x + balls[j].x) / 2
                        let midY = (balls[i].y + balls[j].y) / 2

                        toRemove.insert(balls[i].id)
                        toRemove.insert(balls[j].id)

                        var newBall = MergeBall(value: newValue, x: midX, y: midY)
                        newBall.justMerged = true
                        newBall.mergeScale = 1.2
                        toAdd.append(newBall)

                        score += newValue
                        if newValue > highestValue { highestValue = newValue }
                        mergeOccurred = true

                        // Spawn particles
                        spawnParticles(at: midX, y: midY, color: MergeBall.ballColors(for: newValue).main, count: 8)
                    } else {
                        let relVx = balls[j].vx - balls[i].vx
                        let relVy = balls[j].vy - balls[i].vy
                        let relVDotN = relVx * nx + relVy * ny

                        if relVDotN < 0 {
                            let m1 = balls[i].radius * balls[i].radius
                            let m2 = balls[j].radius * balls[j].radius
                            let totalM = m1 + m2
                            let impulse = relVDotN * damping

                            balls[i].vx += (impulse * m2 / totalM) * nx
                            balls[i].vy += (impulse * m2 / totalM) * ny
                            balls[j].vx -= (impulse * m1 / totalM) * nx
                            balls[j].vy -= (impulse * m1 / totalM) * ny
                        }
                    }
                }
            }
        }

        if mergeOccurred {
            balls.removeAll { toRemove.contains($0.id) }
            balls.append(contentsOf: toAdd)
            comboCount += 1
            SoundManager.shared.playCorrect()
            HapticManager.shared.correctAnswer()

            if comboCount >= 2 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showCombo = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation { showCombo = false }
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                for i in 0..<balls.count {
                    balls[i].justMerged = false
                    balls[i].mergeScale = 1.0
                }
            }
        }

        // Update particles
        particles = particles.compactMap { p in
            var p = p
            p.x += p.vx
            p.y += p.vy
            p.vy += 0.15  // particle gravity
            p.life -= 0.03
            return p.life > 0 ? p : nil
        }

        // Game over check
        let settled = balls.filter { abs($0.vy) < 1 && abs($0.vx) < 1 }
        for ball in settled {
            if ball.y - ball.radius < topDangerY {
                gameOver()
                return
            }
        }
    }

    private func spawnParticles(at x: CGFloat, y: CGFloat, color: Color, count: Int) {
        for _ in 0..<count {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 2...6)
            let particle = MergeParticle(
                x: x, y: y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - 2,
                color: [color, .white, color.opacity(0.7)].randomElement()!,
                size: CGFloat.random(in: 3...7)
            )
            particles.append(particle)
        }
    }

    private func gameOver() {
        isGameOver = true
        timer?.invalidate()
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "mergeNumberBest")
        }
        SoundManager.shared.playWrong()
        HapticManager.shared.wrongAnswer()
    }

    private func resetGame() {
        balls.removeAll()
        particles.removeAll()
        score = 0
        highestValue = 2
        isGameOver = false
        canDrop = true
        comboCount = 0
        showCombo = false
        nextValue = randomDropValue()
        dropX = containerWidth / 2
        startPhysics()
    }

    // MARK: - Game Over

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.65).ignoresSafeArea()

            VStack(spacing: 18) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.orange.opacity(0.3), .clear],
                                center: .center, startRadius: 20, endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: "circle.circle.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                        )
                }

                Text("Game Over")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 28) {
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("Score")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    VStack(spacing: 4) {
                        Text("\(highestValue)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Text("Highest")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    VStack(spacing: 4) {
                        Text("\(bestScore)")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("Best")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                if score >= bestScore && score > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                        Text("New Best!")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Image(systemName: "star.fill").foregroundColor(.yellow)
                    }
                }

                VStack(spacing: 12) {
                    Button { resetGame() } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.3), radius: 8, y: 4)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.18, green: 0.16, blue: 0.24), Color(red: 0.14, green: 0.12, blue: 0.20)],
                            startPoint: .top, endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
            )
            .padding(.horizontal, 28)
        }
    }
}

#Preview { MergeNumberGameView() }

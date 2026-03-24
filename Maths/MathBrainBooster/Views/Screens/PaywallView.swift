//
//  PaywallView.swift
//  MathBrainBooster
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @ObservedObject var paywallManager = PaywallManager.shared
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass

    /// Optional close handler for when PaywallView is used as a direct view (not sheet).
    /// When nil, uses dismiss() for sheet/fullScreenCover presentations.
    var onClose: (() -> Void)? = nil

    @ObservedObject var remoteConfig = RemoteConfigManager.shared

    @State private var selectedProductIndex: Double = 0
    @State private var featureScrollOffset: CGFloat = 0
    @State private var autoScrollTimer: Timer?
    @State private var purchaseSuccess = false
    @State private var titleGlow = false

    private var theme: ColorTheme { settings.selectedTheme }
    private var isIPad: Bool { hSizeClass == .regular }

    private var selectedProduct: Product? {
        let index = Int(selectedProductIndex.rounded())
        guard !paywallManager.products.isEmpty,
              index >= 0 && index < paywallManager.products.count else { return nil }
        return paywallManager.products[index]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.45, blue: 0.85),
                    Color(red: 0.0, green: 0.3, blue: 0.7),
                    Color(red: 0.0, green: 0.15, blue: 0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button {
                        closePaywall()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: isIPad ? 34 : 30))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.trailing, isIPad ? 24 : 16)
                    .padding(.top, 8)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: isIPad ? 24 : 10) {
                        // Title
                        proTitle
                            .padding(.top, isIPad ? 4 : -4)

                        // Auto-scrolling feature showcase
                        featureCarousel

                        // Content constrained for iPad
                        VStack(spacing: isIPad ? 24 : 18) {
                            // Benefits list
                            benefitsList

                            // Pricing section
                            pricingSection

                            // Continue button
                            continueButton

                            // Restore & links
                            footerLinks
                        }
                        .frame(maxWidth: isIPad ? 520 : .infinity)
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .padding(.bottom, isIPad ? 20 : 10)
                }
            }

            if purchaseSuccess {
                successOverlay
            }
        }
        .onAppear {
            startAutoScroll()
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                titleGlow = true
            }
            // Fresh fetch remote config every time paywall opens
            RemoteConfigManager.shared.fetchConfig()
            applyDefaultPlan()
            AnalyticsManager.shared.logScreenViewed(screenName: "paywall")
        }
        .onChange(of: remoteConfig.defaultPlanSelected) { _, _ in
            applyDefaultPlan()
        }
        .onChange(of: paywallManager.products) { _, _ in
            // Products loaded after view appeared — apply default now
            applyDefaultPlan()
        }
        .onDisappear {
            autoScrollTimer?.invalidate()
        }
    }

    // MARK: - Default Plan from Remote Config

    private func applyDefaultPlan() {
        let products = paywallManager.products
        guard !products.isEmpty else { return }

        // Remote config value is 1-based (1 = first, 2 = second, 3 = third, 4 = fourth)
        let configIndex = remoteConfig.defaultPlanSelected
        let zeroBasedIndex = max(0, min(configIndex - 1, products.count - 1))

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            selectedProductIndex = Double(zeroBasedIndex)
        }
    }

    // MARK: - Close Helper

    private func closePaywall() {
        if let onClose = onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    // MARK: - Pro Title

    private var proTitle: some View {
        VStack(spacing: isIPad ? 10 : 6) {
            HStack(spacing: isIPad ? 14 : 10) {
                Image(systemName: "crown.fill")
                    .font(.system(size: isIPad ? 36 : 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(titleGlow ? 0.8 : 0.3), radius: titleGlow ? 12 : 6)

                Text("MathQ Pro")
                    .font(.system(size: isIPad ? 40 : 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(red: 0.85, green: 0.92, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }

            Text("Unlock the full math experience")
                .font(.system(size: isIPad ? 18 : 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Feature Carousel (Auto-scrolling)

    private var featureCarousel: some View {
        let features: [(icon: String, title: String, colors: [Color])] = [
            ("plus.forwardslash.minus", "Add & Subtract", [.green, .mint]),
            ("multiply", "Multiply", [.orange, .red]),
            ("divide", "Divide", [.purple, .pink]),
            ("brain.head.profile", "Brain Training", [.pink, .purple]),
            ("square.grid.3x3.fill", "Sudoku", [.blue, .indigo]),
            ("square.grid.2x2.fill", "2048 Puzzle", [.orange, .yellow]),
            ("bolt.fill", "Quick Maths", [.cyan, .teal]),
            ("number.circle.fill", "Number Memory", [.indigo, .blue]),
            ("equal.circle.fill", "Math Pairs", [.green, .cyan]),
            ("list.number", "Sequences", [.red, .orange]),
            ("square.grid.3x3.topleft.filled", "Magic Square", [.purple, .blue]),
            ("arrow.down.circle.fill", "Drop Numbers", [.teal, .green]),
            ("flag.checkered", "Daily Challenge", [.yellow, .orange]),
            ("trophy.fill", "Achievements", [.yellow, .red]),
        ]

        let cardSize: CGFloat = isIPad ? 100 : 80
        let iconSize: CGFloat = isIPad ? 80 : 64
        let iconFont: CGFloat = isIPad ? 34 : 26
        let labelFont: CGFloat = isIPad ? 13 : 11
        let cornerR: CGFloat = isIPad ? 22 : 18
        let spacing: CGFloat = isIPad ? 20 : 16

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(0..<features.count * 3, id: \.self) { i in
                    let feature = features[i % features.count]
                    VStack(spacing: isIPad ? 10 : 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerR)
                                .fill(
                                    LinearGradient(
                                        colors: feature.colors,
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: iconSize, height: iconSize)
                                .shadow(color: feature.colors[0].opacity(0.5), radius: 8, y: 4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: cornerR)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )

                            Image(systemName: feature.icon)
                                .font(.system(size: iconFont, weight: .bold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                        }

                        Text(feature.title)
                            .font(.system(size: labelFont, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(1)
                    }
                    .frame(width: cardSize)
                }
            }
            .padding(.horizontal, 8)
            .offset(x: featureScrollOffset)
        }
        .frame(height: isIPad ? 150 : 120)
        .allowsHitTesting(false)
    }

    private func startAutoScroll() {
        let cardWidth: CGFloat = isIPad ? 120 : 96 // cardSize + spacing
        autoScrollTimer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            Task { @MainActor in
                featureScrollOffset -= (isIPad ? 0.8 : 0.6)
                let totalWidth = cardWidth * 14
                if featureScrollOffset <= -totalWidth {
                    featureScrollOffset = 0
                }
            }
        }
    }

    // MARK: - Benefits List

    private var benefitsList: some View {
        VStack(spacing: 0) {
            benefitRow(emoji: "\u{1F3AE}", text: "5+ brain games & puzzles unlocked")
            benefitRow(emoji: "\u{1F4CA}", text: "Detailed stats & progress tracking")
            benefitRow(emoji: "\u{1F6AB}", text: "No ads forever, distraction-free")
            benefitRow(emoji: "\u{1F3C6}", text: "Exclusive achievements & badges")
        }
        .padding(.vertical, isIPad ? 20 : 16)
        .padding(.horizontal, isIPad ? 24 : 16)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func benefitRow(emoji: String, text: String) -> some View {
        HStack(spacing: isIPad ? 16 : 12) {
            Text(emoji)
                .font(.system(size: isIPad ? 26 : 20))
                .frame(width: isIPad ? 38 : 30)

            Text(text)
                .font(.system(size: isIPad ? 18 : 15, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.95))

            Spacer()
        }
        .padding(.vertical, isIPad ? 10 : 8)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: isIPad ? 18 : 14) {
            Text("Pay what you want")
                .font(.system(size: isIPad ? 24 : 20, weight: .heavy, design: .rounded))
                .foregroundColor(.white)

            // Price display
            if let product = selectedProduct {
                Text(product.displayPrice)
                    .font(.system(size: isIPad ? 56 : 48, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 0.3, green: 0.9, blue: 1.0), Color(red: 0.5, green: 0.7, blue: 1.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: selectedProduct?.id)
            } else if paywallManager.isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(height: isIPad ? 66 : 56)
            } else {
                Text("--")
                    .font(.system(size: isIPad ? 56 : 48, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Custom slider
            if !paywallManager.products.isEmpty {
                VStack(spacing: isIPad ? 14 : 10) {
                    // Custom track with dots
                    customSlider

                    // Price labels
                    HStack {
                        ForEach(Array(paywallManager.products.enumerated()), id: \.element.id) { idx, product in
                            Text(product.displayPrice)
                                .font(.system(size: isIPad ? 14 : 12, weight: .bold, design: .rounded))
                                .foregroundColor(
                                    Int(selectedProductIndex.rounded()) == idx
                                        ? Color(red: 1.0, green: 0.8, blue: 0.0)
                                        : .white.opacity(0.4)
                                )
                                .frame(maxWidth: .infinity)
                                .animation(.easeInOut(duration: 0.2), value: selectedProductIndex)
                        }
                    }
                }
            }

            // One-time payment badge
            HStack(spacing: isIPad ? 8 : 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: isIPad ? 16 : 14))
                    .foregroundColor(.orange)
                Text("One time payment. No Subscription.")
                    .font(.system(size: isIPad ? 15 : 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 2)
        }
        .padding(isIPad ? 28 : 22)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 28 : 24)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isIPad ? 28 : 24)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Custom Slider

    private var customSlider: some View {
        GeometryReader { geo in
            let count = paywallManager.products.count
            let trackHeight: CGFloat = isIPad ? 8 : 6
            let thumbSize: CGFloat = isIPad ? 34 : 28
            let padding: CGFloat = thumbSize / 2
            let usableWidth = geo.size.width - thumbSize
            let selectedIdx = Int(selectedProductIndex.rounded())
            let thumbX = count > 1
                ? padding + usableWidth * CGFloat(selectedIdx) / CGFloat(count - 1)
                : geo.size.width / 2

            ZStack(alignment: .leading) {
                // Track background
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .frame(height: trackHeight)
                    .padding(.horizontal, padding)

                // Filled track
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.8, blue: 0.0), Color(red: 1.0, green: 0.55, blue: 0.0)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(thumbX, padding), height: trackHeight)
                    .padding(.leading, padding)

                // Step dots
                HStack {
                    ForEach(0..<count, id: \.self) { i in
                        Circle()
                            .fill(i <= selectedIdx ? Color(red: 1.0, green: 0.75, blue: 0.0) : Color.white.opacity(0.3))
                            .frame(width: isIPad ? 10 : 8, height: isIPad ? 10 : 8)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, padding - 4)

                // Thumb
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.9, blue: 0.3), Color(red: 1.0, green: 0.65, blue: 0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: .orange.opacity(0.5), radius: 6, y: 2)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
                    .position(x: thumbX, y: geo.size.height / 2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIdx)
            }
            .frame(height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = value.location.x - padding
                        let fraction = x / usableWidth
                        let clamped = min(max(fraction, 0), 1)
                        let newIndex = Double(round(clamped * Double(count - 1)))
                        selectedProductIndex = newIndex
                    }
            )
        }
        .frame(height: isIPad ? 42 : 36)
        .padding(.horizontal, 4)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        VStack(spacing: isIPad ? 14 : 10) {
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    let success = await paywallManager.purchase(product)
                    if success {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            purchaseSuccess = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            closePaywall()
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    if paywallManager.isLoading {
                        ProgressView()
                            .tint(Color(red: 0.3, green: 0.15, blue: 0.0))
                    } else {
                        Text("Continue")
                            .font(.system(size: isIPad ? 22 : 20, weight: .heavy, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.0))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIPad ? 20 : 18)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.85, blue: 0.0),
                            Color(red: 1.0, green: 0.65, blue: 0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(isIPad ? 18 : 16)
                .shadow(color: Color.orange.opacity(0.4), radius: 10, y: 5)
            }
            .disabled(selectedProduct == nil || paywallManager.isLoading)
            .opacity(selectedProduct == nil ? 0.6 : 1.0)

            if let error = paywallManager.errorMessage {
                Text(error)
                    .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Footer Links

    private var footerLinks: some View {
        HStack(spacing: isIPad ? 20 : 16) {
            Button("Restore") {
                Task {
                    await paywallManager.restorePurchases()
                    if paywallManager.isProUser {
                        closePaywall()
                    }
                }
            }
            .font(.system(size: isIPad ? 16 : 14, weight: .medium))
            .foregroundColor(.white.opacity(0.6))

            Text("|")
                .foregroundColor(.white.opacity(0.3))

            Button("Privacy Policy") {
                if let url = URL(string: "https://nowifigames.app/privacy-policy") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: isIPad ? 16 : 14, weight: .medium))
            .foregroundColor(.white.opacity(0.6))

            Text("|")
                .foregroundColor(.white.opacity(0.3))

            Button("Terms of Use") {
                if let url = URL(string: "https://nowifigames.app/terms-conditions") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: isIPad ? 16 : 14, weight: .medium))
            .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Success Overlay

    private var successOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()

            VStack(spacing: isIPad ? 24 : 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: isIPad ? 88 : 72))
                    .foregroundColor(.green)

                Text("You're Pro! \u{1F389}")
                    .font(.system(size: isIPad ? 34 : 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text("All premium features unlocked.\nNo more ads, ever!")
                    .font(.system(size: isIPad ? 19 : 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .padding(isIPad ? 50 : 40)
            .background(
                RoundedRectangle(cornerRadius: isIPad ? 32 : 28)
                    .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
            )
            .padding(.horizontal, isIPad ? 80 : 40)
            .transition(.scale.combined(with: .opacity))
        }
    }
}

#Preview {
    PaywallView()
}

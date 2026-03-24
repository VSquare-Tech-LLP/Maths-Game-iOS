//
//  PaywallManager.swift
//  MathBrainBooster
//

import Foundation
import StoreKit
import FirebaseAnalytics

/// Manages in-app purchases using StoreKit 2.
/// 4 lifetime plans with "pay what you want" pricing tiers.
@MainActor
final class PaywallManager: ObservableObject {
    static let shared = PaywallManager()

    // MARK: - Product IDs (ordered by price tier)
    static let productIDs: [String] = [
        "com.mathq.app.first",
        "com.mathq.app.second",
        "com.mathq.app.third",
        "com.mathq.app.four"
    ]

    // MARK: - Published State
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published var showPaywall = false

    /// True if user has purchased ANY of the lifetime plans
    var isProUser: Bool {
        !purchasedProductIDs.intersection(Self.productIDs).isEmpty
    }

    /// UserDefaults key for caching pro status (offline fallback)
    private static let proStatusKey = "isProUserCached"

    /// Cached pro status for quick checks (e.g. ad blocking)
    var isProUserCached: Bool {
        get { UserDefaults.standard.bool(forKey: Self.proStatusKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.proStatusKey) }
    }

    private var transactionListener: Task<Void, Error>?

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await Product.products(for: Self.productIDs)
            // Sort by price ascending
            products = storeProducts.sorted { $0.price < $1.price }
            isLoading = false
        } catch {
            print("[PaywallManager] Failed to load products: \(error)")
            errorMessage = "Unable to load products. Please check your connection."
            isLoading = false
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                isLoading = false
                Analytics.logEvent("iap_purchase_success", parameters: [
                    "product_id": product.id,
                    "price": product.displayPrice
                ])
                return true

            case .userCancelled:
                isLoading = false
                Analytics.logEvent("iap_purchase_cancelled", parameters: [
                    "product_id": product.id
                ])
                return false

            case .pending:
                isLoading = false
                errorMessage = "Purchase is pending approval."
                return false

            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            print("[PaywallManager] Purchase failed: \(error)")
            isLoading = false
            errorMessage = "Purchase failed. Please try again."
            Analytics.logEvent("iap_purchase_failed", parameters: [
                "product_id": product.id,
                "error": error.localizedDescription
            ])
            return false
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
            isLoading = false

            if isProUser {
                Analytics.logEvent("iap_restore_success", parameters: [:])
            } else {
                errorMessage = "No previous purchases found."
            }
        } catch {
            print("[PaywallManager] Restore failed: \(error)")
            isLoading = false
            errorMessage = "Unable to restore purchases. Please try again."
        }
    }

    // MARK: - Update Purchased Products

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result) {
                if Self.productIDs.contains(transaction.productID) {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
        isProUserCached = !purchased.isEmpty
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                if let transaction = try? await self?.checkVerified(result) {
                    await self?.updatePurchasedProducts()
                    await transaction.finish()
                }
            }
        }
    }

    // MARK: - Verify Transaction

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}

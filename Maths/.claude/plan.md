# Ad Manager Integration Plan

## Overview
Create `InterstitialAdManager` and `RewardAdManager` in the `Admob Ads` folder, following the project's singleton pattern. GoogleMobileAds SDK v13.1.0 is already installed.

## Files to Create

### 1. `Admob Ads/InterstitialAdManager.swift`
- Singleton (`shared`) using `@MainActor` + `ObservableObject`
- Preloads interstitial ad on init and after each show
- `showAd(from:completion:)` method to present from any view controller
- Game counter: shows interstitial every 3 games (not every time — avoids user frustration)
- Tracks `gamesPlayedSinceLastAd` in UserDefaults for persistence
- Logs analytics events: `interstitial_shown`, `interstitial_failed`
- Uses test ad unit ID with a placeholder for production

### 2. `Admob Ads/RewardAdManager.swift`
- Singleton (`shared`) using `@MainActor` + `ObservableObject`
- Preloads reward ad on init and after each show
- `showAd(from:onReward:)` method — calls `onReward` callback with reward amount
- Published `isRewardAdReady` property so UI can show/hide reward buttons
- Reward types: extra time hint, score multiplier, skip question
- Logs analytics events: `reward_ad_shown`, `reward_earned`, `reward_ad_failed`
- Uses test ad unit ID with a placeholder for production

### 3. Update `MathBrainBoosterApp.swift`
- Import `GoogleMobileAds`
- Initialize Google Mobile Ads SDK in `didFinishLaunchingWithOptions` via `MobileAds.shared.start()`
- Call `ATTConsent.requestIfNeeded()` on app appear

### 4. Update `GameViewModel.swift`
- Add `InterstitialAdManager.shared` reference
- Call `interstitialManager.gameCompleted()` in `endGame()` — this increments game counter and shows ad when threshold reached

### 5. Update `GameOverView.swift`
- Add a "Watch Ad for Bonus" reward button (only visible when reward ad is ready)
- On tap: shows reward ad → grants 2x score bonus
- Integrates with existing theme/styling

## Ad Unit IDs
- Will use Google test ad unit IDs for development
- Marked with `// TODO: Replace with production ad unit IDs` comments

## Key Design Decisions
- Interstitial shows every 3 games (not every game) to balance monetization and UX
- Reward ad is optional — user-initiated only
- Both managers auto-preload the next ad after showing
- Follows existing singleton + analytics pattern exactly

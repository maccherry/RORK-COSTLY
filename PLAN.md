# Costly — The Cost of Living

## Overview

A premium life-cost tracker that measures every habit in **minutes gained or lost** from your life. Light, airy glass-morphism aesthetic with the **Satoshi** font family throughout. Features a "Costly Age" — a biological age score refined by HealthKit data and logged activities. Backed by Supabase for auth and cloud sync.

---

## Tech Stack

- **Language**: Swift / SwiftUI (iOS 18+)
- **Architecture**: MVVM with `@Observable` classes (`DataStore`, `HealthKitService`, `SupabaseService`)
- **Font**: Satoshi (Light, Regular, Medium, Bold, Black) — custom `.otf` files registered via `CTFontManagerRegisterFontsForURL`, accessed through `Font.satoshi(_ weight:size:)` extension
- **Backend**: Supabase (auth + Postgres) via the `supabase-swift` SPM package
- **Health**: HealthKit (steps, active minutes, sleep, heart rate, distance, calories)
- **Persistence**: Local `UserDefaults` (source of truth) with async Supabase sync
- **Color Scheme**: Forced `.preferredColorScheme(.light)`

---

## Design System (`GlassTheme` + `PremiumStyles`)

### Colors
| Token | Value | Usage |
|---|---|---|
| `bgPrimary` | `rgb(241, 240, 244)` — warm off-white | Full-screen backgrounds |
| `bgCard` | `Color.white` | Card fills |
| `bgCardSecondary` | `rgb(247, 246, 249)` | Secondary card fills |
| `textPrimary` | `rgb(26, 26, 31)` — near-black | Headlines, primary text, CTA button fills, active tab pill |
| `textSecondary` | `rgb(102, 102, 115)` | Icons, secondary labels |
| `textTertiary` | `rgb(153, 153, 166)` | Captions, placeholders, timestamps |
| `separator` | `rgb(224, 224, 230)` | 0.5pt dividers |
| `accent` | `rgb(107, 89, 166)` — muted purple | Icon backgrounds, accent details, progress rings |
| `positive` | `rgb(51, 191, 128)` — teal green | Minutes gained |
| `negative` | `rgb(230, 82, 89)` — warm red | Minutes lost |
| `neutral` | `rgb(140, 140, 153)` | Zero / neutral values |

### Typography Scale (all Satoshi)
- Hero age display: `.light`, 58pt
- Screen titles: `.bold`, 28pt
- Section headers: `.bold`, 18pt
- Body / row labels: `.regular` or `.medium`, 14pt
- Captions: `.regular`, 11–12pt
- Uppercase tracking labels: `.bold`, 9pt, `tracking(1.5)`

### Card Styles
- **`.glassCard()`** — White fill, dual soft shadows (`0.04` + `0.02` opacity), 0.5pt white stroke, 20pt corner radius
- **`.frostCard()`** — `.ultraThinMaterial` fill, gradient white stroke, heavier shadow
- **`.premiumShimmer()`** — Animated horizontal white gradient overlay

### Button Styles
- `PremiumButtonStyle` — Scale 0.97 + opacity 0.85 on press, spring animation
- `PremiumCardButtonStyle` — Scale 0.975 + opacity 0.9
- `PremiumPillButtonStyle` — Scale 0.93 + brightness shift
- `PremiumCTAButtonStyle` — Scale 0.96 + brightness shift

### Animation Patterns
- **Stagger entrance**: `.premiumStagger(appeared:index:baseDelay:)` — opacity + 14pt Y offset with staggered spring delay
- **Spring defaults**: `response: 0.35–0.7`, `dampingFraction: 0.75–0.85`
- **Haptics**: `.sensoryFeedback()` on tab switches, log confirmations, button presses

---

## Data Models

### `Activity` (nonisolated, Codable)
- `id: String`, `name: String`, `icon: String` (SF Symbol), `minutesDelta: Int`, `category: ActivityCategory`
- Categories: Substances, Food & Drink, Exercise, Wellness, Sleep, Lifestyle

### `LogEntry` (nonisolated, Codable)
- `id: UUID`, `activityId`, `activityName`, `activityIcon`, `minutesDelta: Int`, `timestamp: Date`
- Computed: `isPositive`, `formattedDelta` ("+26" / "-11")

### `UserProfile` (nonisolated, Codable)
- `name`, `birthDate`, `memberSince`, `hasCompletedOnboarding`, `hasActiveSubscription`
- `freeScansUsed: Int` (1 free scan before paywall)
- `okxRedeemed: Bool`, `walletConnected: Bool` (legacy fields, unused in current UI flow)
- Computed: `preciseAge` (years as Double), `estimatedLifeMinutesRemaining` (based on 78.5 life expectancy)
- `costlyAge(netMinutes:healthMinutes:steps:sleepHours:activeMinutes:)` — chronological age adjusted by logged activities + HealthKit metrics
- `baselineCostlyAge` — `preciseAge + 0.3` (default when HealthKit not connected)

---

## Services

### `DataStore` (@Observable, @MainActor)
- Holds `profile: UserProfile` and `entries: [LogEntry]`
- Persists to `UserDefaults` locally, syncs to Supabase async
- Computed properties: `todayEntries`, `todayNetMinutes`, `weekEntries`, `weekNetMinutes`, `allTimeNetMinutes`, `totalMinutesGained`, `totalMinutesLost`

### `SupabaseService` (@Observable, @MainActor)
- Email sign-up / sign-in with validation (email format, 6+ char password)
- Anonymous sign-in fallback
- Session persistence check on launch
- CRUD: `syncProfile`, `fetchProfile`, `syncLogEntry`, `deleteLogEntry`, `fetchLogEntries`
- Tables: `profiles`, `log_entries`

### `HealthKitService` (@Observable, @MainActor)
- Reads: step count, active energy, heart rate, sleep analysis, exercise time, walking/running distance
- `healthMinutesBalance` — derived bonus: `steps/1000 + activeMinutes + sleep bonus (±15/0/-10)`
- All queries use `HKStatisticsQuery` or `HKSampleQuery` with today predicates

### `ActivityDatabase` (static)
- 37 predefined activities across 6 categories with SF Symbol icons
- `search(_:)` — `localizedStandardContains` filter
- `byCategory()` — grouped by `ActivityCategory`

### `InstagramStoriesService`
- Shares a rendered story card image via `instagram-stories://` URL scheme
- Falls back to `UIActivityViewController` share sheet

---

## App Flow (`ContentView`)

1. **Splash** → animated "Costly" title + "The cost of living." tagline on white background, auto-dismisses after ~3.2s
2. **Auth** → checks for existing Supabase session; if none, shows email sign-in/sign-up form
3. **Onboarding** (4 paged screens) → Hook ("Every choice has a price"), Impact (activity cards), Proof (example log list), Personalization (name + birth date input)
4. **Paywall** → hard paywall after onboarding; Monthly $9.99/mo or Yearly $39.99/yr with 3-day free trial toggle; "BEST VALUE" badge on yearly
5. **Main App** → `MainTabView` with floating tab bar + FAB

---

## Screens (Current Build)

### 1. Splash (`SplashView`)
- White background, "Costly" in Satoshi Light 52pt
- Gradient divider line animates in, tagline fades up
- Spring + blur entrance, scale exit after 3.2s

### 2. Auth (`AuthView`)
- "Costly" header in Satoshi Light 38pt
- Email + password fields with `.glassCard()` styling
- Sign-up mode adds confirm password field
- Toggle between Sign In / Sign Up with animated transition
- Error/success banners with colored backgrounds
- Form validation: email format + 6-char password minimum

### 3. Onboarding (`OnboardingView`)
- **Page 0 — Hook**: Ticking minute counter (decrements every 2.5s with `.numericText()` transition), "Every choice has a price."
- **Page 1 — Impact**: Two side-by-side impact cards (30-min Run +26, Cigarette -11) with Satoshi Light 36pt deltas
- **Page 2 — Proof**: Example activity list (Cigarette, Morning Run, Wine, Meditation, Coffee) in a `.glassCard()`
- **Page 3 — Personalization**: Name text field + date picker, "See My Time" CTA triggers paywall
- Animated progress dots (expanding capsule for active page)
- Continue button with Satoshi Bold 17pt on `textPrimary` background, 27pt corner radius pill

### 4. Paywall (`PaywallView`)
- Hourglass icon in circle with glass card shadow
- "Unlock Costly" in Satoshi Light 30pt
- 3 feature rows: AI Scanning, Biological Age, Every Minute Visualized
- Plan cards: Monthly $9.99/mo vs Yearly $39.99/yr ("BEST VALUE" badge, "Just $3.33/mo")
- 3-Day Free Trial toggle with `.tint(GlassTheme.textPrimary)`
- Subscribe CTA pill button
- Footer: Restore Purchases, Terms, Privacy links

### 5. Home (`HomeView`)
- Time-of-day greeting + user name header
- Streak badge (flame icon + count) in material capsule
- Week strip: M–S day letters with active day circled in `textPrimary`
- **Costly Age Orb** (`CostlyAgeOrbView`): central 58pt age number surrounded by animated concentric rings, orbiting particle motes (Canvas + TimelineView), arc gauge showing delta, ambient glow — all color-coded green/red based on delta direction
- 3 stat cards row: Minutes today, All time, Logged today — each with icon, `.glassCard()`, accent-tinted icon background
- Recently Logged section: entry rows with SF Symbol, name, timestamp, colored delta; empty state with dashed plus icon

### 6. Log Activity (`LogActivityView`)
- Full-screen cover with close button (material circle)
- Camera / Manual mode toggle (pill segmented control)
- **Camera mode**: `CameraProxyView` placeholder (pulsing viewfinder icon, "Install on device" message), shutter button (concentric circles)
- **Manual mode**: Search bar + categorized activity list grouped by `ActivityCategory` with uppercase tracking headers
- Scan result overlay: detected activity card with "Log This" CTA + Instagram share button
- Share generates a `ShareCardView` image (dark cinematic card with radial gradients, activity icon, delta number, Costly Age)

### 7. Progress (`LifeProgressView`)
- "Progress" header with streak badge
- 2 summary ring cards: Net Minutes + Activities (animated `Circle.trim` rings)
- Period picker: 7 Days / 30 Days / 90 Days / All time (capsule segmented control)
- Balance section: horizontal gain/loss bar, +gained / -lost numbers, motivational message
- Health dashboard (when HealthKit authorized): 2x2 grid of tiles — Steps, Active Minutes, Calories, Sleep — each with progress bar and percentage
- Weekly bar chart: M–S bars colored by positive/negative
- Milestones: First Log, 3-Day Streak, 100 Minutes, Week Warrior — checkmark badges

### 8. Settings/Profile (`ProfileView`)
- Avatar circle with first-letter initial in Satoshi Light
- Name + "Member since" date
- Account section: email display, subscription status, restore purchases, sign out (with confirmation alert)
- Preferences: Health Access toggle, Notifications
- Support: Help Center, Terms of Service, Privacy Policy
- Footer: "Costly" + "Version 1.0.0"

### 9. Time Bank (`TimeBankView`)
- Exists in codebase but **not wired into the main tab bar** (legacy screen)
- Contains USDC rewards, OKX integration references

---

## Navigation

### Tab Bar (`MainTabView`)
- Custom floating capsule tab bar with `.ultraThickMaterial` + white stroke
- 3 tabs: Home (house), Progress (chart.bar), Settings (gearshape)
- Active tab: pill with `textPrimary` fill + white icon/label
- Animated transitions between tabs (spring, directional offset)
- **Floating Action Button**: bottom-right, 52pt dark circle with "+" icon, opens `LogActivityView` as full-screen cover
- Paywall gate: FAB checks `canScan` (subscription or free scan available) before opening logger

---

## Entitlements & Permissions

- HealthKit: read access to steps, active energy, heart rate, sleep, exercise time, distance
- App Groups: `group.app.rork.costly-life-cost-tracker`

---

## SPM Dependencies

- `supabase-swift` — Supabase client (auth, database)

---

## App Icon

- Minimal white hourglass on dark background — thin, elegant lines

---

## Environment Variables

| Key | Purpose |
|---|---|
| `EXPO_PUBLIC_SUPABASE_URL` | Supabase project URL |
| `EXPO_PUBLIC_SUPABASE_ANON_KEY` | Supabase anonymous API key |

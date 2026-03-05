# Costly — The Cost of Living

## Overview

A premium, existential time-ledger app. Pure black OLED aesthetic with white serif typography and massive hero numbers. Every action you take — smoking, drinking, exercising, meditating — is measured in **minutes gained or lost** from your life.

---

## **Features**

### Onboarding (5 screens, full-screen paged)

- **Splash**: App name "Costly" fades in with the tagline "The cost of living." — dramatic, cinematic
- **Education**: "Every choice has a price. We measure it in minutes." — animated counter ticking down
- **Value Prop**: "See what your habits are really costing you." — shows example: 🚬 Cigarette → −11 minutes
- **Personalization**: User enters their name and birthdate (used to calculate estimated life remaining)
- **Hard Paywall**: Monthly & Yearly subscription options with savings badge. Restore purchases link at the bottom.

### Home Screen

- **Massive hero number** at top showing today's net minutes (e.g. "−47" or "+12") with color coding (red for negative, green for positive)
- **Life balance bar** — a thin horizontal line showing your cumulative minutes gained vs lost
- **Today's log** — vertical timeline of entries (e.g. "☕ Coffee −2 min", "🏃 Run +26 min") with timestamps
- **Running total** section showing: Today / This Week / All Time

### Floating Camera Button

- Persistent floating button (bottom-right, above tab bar) with camera icon
- Opens camera to scan food/drinks/items
- AI-powered placeholder screen: shows the scanned item name, its predefined time cost, and a confirm button to log it
- Falls back to a clean placeholder on simulator ("Install on your device via Rork App to use camera")

### Profile Screen

- User avatar, name, and member-since date
- **Life stats**: Total minutes gained, total lost, net balance, estimated days added/removed
- Settings: Subscription status, Restore Purchases, Terms, Privacy

### Activity Database

- Predefined list of common activities with their minute values (smoking −11, coffee −2, 30-min run +26, meditation +12, glass of wine −5, salad +4, etc.)
- Searchable when logging manually
- Each entry shows the activity name, icon, and time impact

---

## **Design**

- **Background**: Pure black (#000000) everywhere — OLED optimized
- **Typography**: White serif font (New York / SF Serif) for headlines and hero numbers; SF Pro for body text
- **Hero numbers**: Extremely large (80–120pt) with thin serif weight for the main daily balance
- **Color accents**: Red for time lost, green for time gained — used sparingly on numbers only
- **Cards**: Very dark gray (#111111) with subtle 1px borders (#222222), no shadows
- **Animations**: Numbers count up/down with spring animations when logging; entries slide in from bottom
- **Haptics**: Impact feedback on log confirmation; success/error on positive/negative entries
- **Tab bar**: Minimal — two tabs (Home, Profile) with thin white icons on black
- **Overall feel**: Like a luxury watch interface crossed with a death clock — beautiful, inevitable, slightly unsettling

---

## **Screens**

1. **Splash Screen** — Black screen, "Costly" fades in with serif font, tagline appears below
2. **Onboarding (3 education pages)** — Paged horizontal scroll with dramatic copy and subtle animations
3. **Paywall** — Monthly/Yearly toggle, pricing cards on black
4. **Home** — Hero number, today's timeline, weekly stats
5. **Camera Scan** — Camera view (or placeholder) → item recognition → confirm log
6. **Manual Log** — Search predefined activities, tap to log with timestamp
7. **Profile** — Stats, settings, subscription management

---

## **App Icon**

- Pure black background with a minimal white hourglass symbol — thin, elegant lines. The sand appears to be running out. Premium and existential.

# Mitrai — Frontend Architecture & UI Screen Specifications

This document outlines the **complete, genuine UI architecture**, required screens, real-world commerce metrics, and UI components needed for the **Mitrai AI Commerce** mobile application.

---


---

## 2. Required App Screens & Features

### Screen 1: AI Commerce Onboarding & Login (`LoginScreen`)
*Purpose: Introduce the conversational commerce value proposition and provide frictionless authentication.*
- **Top Header**: Logo only on the left + `AI COMMERCE` pill badge on the right.
- **Hero Value Proposition**:
  - Heading: `"Natural-language commerce experience."`
  - Subtitle: `"Discover, compare specifications, and complete payments through conversational AI."`
  - Micro-badges: `"Discovery: Conversational AI"`, `"Payments: Razorpay Secured"`.
- **Interactive AI Visualizer**: Animated harmonic shopping intelligence waveform with active reasoning indicators and floating intent badges (`Wireless Audio`, `Under ₹3,000`, `Compare Specs`, `Razorpay Pay`).
- **Auth Actions**:
  - Primary CTA: `"Sign In with Google"` (Lilac pill button).
  - Secondary CTA: `"Continue as Guest"` (Dark slate pill button).

---

### Screen 2: Genuine AI Commerce Dashboard (`HomeScreen`)
*Purpose: Provide real, genuine shopping intelligence, budget health, live deal radar, and active cart overview.*

#### Key Stats & Genuine Widgets:
1. **Top Header**: Logo only on the left + `AGENT ACTIVE` pill on the right.
2. **Personalized Greeting Card**:
   - `"Welcome back, {User}"`
   - `"Shopping Intent Engine Ready with 7 Grounded Merchant Catalogs."`
3. **Monthly Shopping Budget & Smart Savings Tracker**:
   - Header: `"Monthly Shopping Budget"` $\to$ `₹3,999 / ₹5,000` (80%).
   - Metric Subtitle: `"₹1,240 saved via AI price matching & multi-source deal discovery."`
   - Segmented vertical tick progress bar (`||||||||||||||||||||`).
4. **Live Deal Radar / Researched Recommendation Card**:
   - Badge: `UNDER ₹3,000` • `94% COMMUNITY MATCH`
   - Title: `"boAt Rockerz 550 vs Sony WH-CH520"`
   - Button: `EXPLORE` (Switches directly to AI agent comparison flow).
5. **Dual Commerce Metric Cards**:
   - **Card A (Active Cart)**: `1 Item Ready` • `₹2,999`
   - **Card B (Payment & Security)**: `Razorpay Protected` • `100% HMAC Verified`
6. **AI Assistant Capabilities Trigger Card**:
   - Icon: Glowing bolt icon.
   - Text: `"Conversational Shopping • Zero-Friction Checkout"`
7. **Segmented Floating Bottom Navigation Capsule**:
   - `[ ⚑ Dashboard | AI Agent | Deals Radar | Cart (1) ]`

---

### Screen 3: Conversational AI Shopping & Live Telemetry (`AiShoppingScreen`)
*Purpose: Full natural-language product discovery, review synthesis, and instant checkout.*
- **Top App Bar**: Logo only + `LANGGRAPH ENGINE` pill badge.
- **Chat Stream with Real-Time Telemetry**:
  - **Live Agent Thinking Step Pill**:
    - Displays current step as the agent reasons:
      `[1/4] Classifying intent...` $\to$ `[2/4] Querying merchant inventory...` $\to$ `[3/4] Synthesizing YouTube & Reddit reviews...` $\to$ `[4/4] 92% Match calculated!`
  - **Rich Grounded Recommendation Cards**:
    - Product thumbnail, brand, rating (`4.6 ★ (1,240)`), price (`₹1,999` with strikethrough `₹4,999`).
    - Specs summary pill: `"20h Battery • Passive Noise Isolation"`.
  - **Interactive Side-by-Side Comparison Matrix**:
    - Side-by-side spec comparison table (Price, Display, Battery, Camera).
    - **Community Verdict**: `"YouTube 94% Positive (praised for battery) • Reddit: Great daily reliability"`.
  - **Action Suggestion Chips**:
    - `[Add boAt to Cart (₹1,999)]`
    - `[Compare Top 2 Specs & Reviews]`
    - `[Pay with Razorpay]`
- **Bottom Input Bar**: Rounded dark pill input field with microphone button and send button.

---

### Screen 4: Deep Product & Multi-Source Review Modal (`ProductDetailSheet`)
*Purpose: Detailed hardware specs, multi-store price comparisons, and YouTube/Reddit sentiment research.*
- **Product Gallery**: High-res image carousel.
- **Multi-Store Price Comparison Table**:
  - Amazon: `₹2,199` (In Stock)
  - Flipkart: `₹2,099` (In Stock)
  - Direct Brand / Mitrai Store: `₹1,999` (Lowest Price • Free Express Delivery)
- **Multi-Source Sentiment Breakdown**:
  - **YouTube Tech Reviewer Consensus**: Summary from Geekyranjit, Beebom, MKBHD (battery test, camera low-light analysis, build quality).
  - **Reddit Community Verdict**: Key insights from `r/IndiaTech` and `r/gadgets` (long-term durability, software updates, known quirks).
- **CTA**: Sticky bottom button `"Add to Cart & Checkout"`.

---

### Screen 5: Cart & Razorpay Payment Sheet (`CartScreen` & `CheckoutSheet`)
*Purpose: Frictionless cart review and cryptographic Razorpay payment.*
- **Cart Item List**: Item card with quantity stepper `[ - 1 + ]` and remove action.
- **Cost Summary**:
  - Subtotal: `₹2,999.00`
  - AI Deal Match Discount: `-₹500.00`
  - Delivery: `FREE`
  - Total: `₹2,499.00`
- **Shipping Address Selector**: Quick delivery address pill.
- **Razorpay Checkout Trigger**:
  - `"Pay ₹2,499 with Razorpay"` button.
  - Launches Razorpay payment modal supporting UPI (GPay, PhonePe, Paytm), Cards, and Netbanking.
  - Server-side cryptographic HMAC-SHA256 verification with real-time success dialog.

---

### Screen 6: Order History & Real-Time Tracking (`OrderTrackingScreen`)
*Purpose: Track order status, payment receipts, and delivery timeline.*
- **Order Header**: `Order #ORD-84920` • `₹2,499 Paid via Razorpay`.
- **Live Logistics Timeline**:
  - `[✓] Order Placed & Payment Verified`
  - `[✓] Packed at Merchant Warehouse`
  - `[●] In Transit (Expected Tomorrow by 5:00 PM)`
  - `[○] Out for Delivery`
- **Actions**: `"Download Invoice"`, `"Ask AI about this Order"`.

---

## 3. Summary of UI File Structure

```
frontend/lib/
├── core/
│   ├── theme/
│   │   └── brik_theme.dart          # Brik color tokens, text styles, radius (28px)
│   └── services/
│       ├── api_service.dart         # Backend REST client + SSE stream reader
│       └── supabase_auth_service.dart # Supabase & Google Auth + Local Persistence
├── shared/widgets/
│   ├── app_logo.dart                # Strictly Logo only widget (PNG / SVG)
│   ├── brik_card.dart               # Bento container & JoinedCardGroup notch engine
│   ├── brik_button.dart             # Pill buttons
│   ├── pill_badge.dart              # Status & category badges
│   ├── brik_progress_bar.dart       # Segmented tick progress bar
│   ├── ai_commerce_visualizer.dart  # Animated shopping waveform
│   └── segmented_pill_nav.dart      # Floating bottom navigation capsule
└── features/
    ├── auth/screens/
    │   └── login_screen.dart        # Screen 1: Onboarding & Auth
    ├── home/screens/
    │   └── home_screen.dart         # Screen 2: Dashboard & Smart Stats
    ├── chat/screens/
    │   └── ai_shopping_screen.dart  # Screen 3: Chat + Live Step Telemetry
    ├── product/screens/
    │   └── product_detail_sheet.dart# Screen 4: Specs + YouTube/Reddit Sentiment
    ├── cart/screens/
    │   └── cart_screen.dart         # Screen 5: Cart Management
    ├── checkout/screens/
    │   └── checkout_sheet.dart      # Screen 5: Razorpay Checkout & HMAC Verify
    ├── orders/screens/
    │   └── order_tracking_screen.dart # Screen 6: Logistics Timeline
    └── settings/screens/
        └── settings_screen.dart     # Screen 7: Profile, Preferences & Logout
```

---

## 4. Design Concept & Implementation: The "Joined Ticket Notch" (Concave Fillet Notch)

### What is this effect called?
In UI/UX design, this visual pattern is known by several industry names:
1. **Joined Ticket Notch** (or **Coupon Stub Notch**) — *Inspired by physical perforated tickets, airline boarding passes, and receipts.*
2. **Concave Fillet Notch** — *The mathematical term in CAD and geometric UI design for inward rounded corners.*
3. **Continuous Dual-Arc Capsule Notch** — *The procedural path description combining convex shoulder arcs and a concave tip.*
4. **Neo-Bento Slit Cutout** — *The modern fintech variant popularized by Cash App, Apple Wallet, and luxury design systems.*

---

### UX Purpose & Design Rationale
Instead of separating related cards with generic empty gaps or hard divider lines:
* **Tactile Physicality**: Merges two semantically paired cards (e.g. *User Greeting + Budget*, *Profile + Address*, *Active Cart + Payment Security*) into a single cohesive physical unit.
* **Focal Anchoring**: Directs the user's eye along the horizontal/vertical division without cluttering the screen with unnecessary borders.

---

### How it was implemented under the hood in Flutter ([`brik_card.dart`](file:///Users/nishantmaurya/projects/razorpay/frontend/lib/shared/widgets/brik_card.dart))

The effect is procedurally generated using Flutter's **`Path`** drawing API, encapsulated in two specialized widgets:
* **`JoinedCardGroup`** (Horizontal side-notches for vertically stacked cards)
* **`HorizontalJoinedCardGroup`** (Vertical slit notches for side-by-side metric cards)

#### 1. Procedural Vector Geometry (`_buildNotchedPath` & `_buildHorizontalNotchedPath`):
Each card border and clip is computed dynamically in 4 geometric phases:
```
1. Outer Corner Arc     ╭───────────────────╮
2. Convex Entry Shoulder│                   │
3. Concave Notch Tip    ╰─╮               ╭─╯  <--- Inward Symmetrical Notch
4. Convex Exit Shoulder ╭─╯               ╰─╮
5. Bottom Corner Arc    │                   │
                        ╰───────────────────╯
```

```dart
// Snippet from brik_card.dart: Procedural arc generation
// 1. Line down to entry shoulder
path.lineTo(size.width, entryY);

// 2. Convex shoulder curve entering the notch
path.arcToPoint(
  Offset(size.width - cr, y - h),
  radius: Radius.circular(cr),
  clockwise: true,
);

// 3. Concave U-capsule tip inside the card
path.arcToPoint(
  Offset(size.width - d + h, y),
  radius: Radius.circular(h),
  clockwise: false,
);

// 4. Mirror return arc exiting the notch
path.arcToPoint(
  Offset(size.width, exitY),
  radius: Radius.circular(cr),
  clockwise: true,
);
```

#### 2. Dual Pipeline: Clipping + Stroking
* **`CustomClipper<Path>` (`_NotchedClipper`)**: Clips child widgets so background colors, gestures, and content respect the curved notch.
* **`CustomPainter` (`_NotchedBorderPainter`)**: Renders the exact hairline stroke (`#F4A776`) with sub-pixel anti-aliasing along the identical path.
* **Internal Divider Line**: Draws a subtle semi-transparent divider directly between the notch apexes to complete the perforated ticket look.


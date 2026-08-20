# Mitrai AI Commerce — Flutter Design System & Guidelines

## 1. Design System & Theme Specs (Brik Aesthetic)

The mobile client strictly follows the visual identity displayed in `app_ui_inspiration1.png` and `app_ui_inspiration2.png`:

### Color Palette
- **Canvas / Background**: `#F6F7F2` (Warm, clean ivory/off-white)
- **Primary Brik Card Surface**: `#0C1818` (Deep midnight slate / dark forest teal)
- **Secondary Card / Inset**: `#142424` (Muted dark slate for chart bars / inner containers)
- **Accent Badge / Pill**: `#D3C7F8` (Soft pastel lilac / lavender)
- **Text on Brik Cards**: `#FFFFFF` (Heading/primary), `#A1B3B3` (Subtitles/meta)
- **Text on Light Canvas**: `#0C1818` (Headings), `#5A6B6B` (Body)
- **Accent Button / CTA**: `#D3C7F8` (Lilac background with `#0C1818` text) or `#0C1818` with `#FFFFFF` text

---

## 2. Core UI Components

### 1. `AppLogo`
- Renders **strictly the SVG logo** (`assets/images/logo.svg` / `images/new1.svg`) with zero added brand text beside it.

### 2. `NotchedBrikCard`
- Modular, connected card system with smooth border radius (28px) and top/bottom concave scalloped notches that visually connect adjacent cards.
- Supports pill badges (e.g. `AI COMMERCE`, `AGENT ACTIVE`, `UNDER ₹3,000`).

### 3. `AiCommerceVisualizer`
- Animated dynamic shopping waveform with glowing orbital tokens representing active AI reasoning, category discovery, price matching, and Razorpay payment states.

### 4. `BrikProgressBar`
- Horizontal row of segmented vertical tick pills (`80% ||||||||||||||||||`) tracking budget progress.

### 5. `SegmentedPillNav`
- Floating bottom bar with dark rounded pill capsule (`#0C1818`), displaying active tab in lavender pill container (`#D3C7F8`) with crisp black text.

---

## 3. Directory Structure

```
frontend/
├── assets/
│   └── images/
│       └── logo.svg          # Mitrai logo (from new1.svg)
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/            # Brik colors, text styles, card decorations
│   │   ├── constants/        # API URLs, Supabase Keys, Razorpay Test Key
│   │   └── services/         # Supabase Auth, Google Sign-In, HTTP Client
│   ├── features/
│   │   ├── auth/             # AI Commerce Login Screen (Google Sign-In, Supabase)
│   │   ├── home/             # Connected Brik Dashboard & Commerce Metrics
│   │   ├── chat/             # AI Shopping Agent, natural language recommendations
│   │   ├── product/          # Product discovery, details, comparison modal
│   │   ├── cart/             # Cart sheet, item quantity, pricing breakdown
│   │   └── checkout/         # Razorpay checkout bridge & Order Confirmation
│   └── shared/
│       └── widgets/          # AppLogo, NotchedBrikCard, PillBadge, AiCommerceVisualizer, BrikButton
```

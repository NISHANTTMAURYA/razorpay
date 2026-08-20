# Mitrai AI Commerce — Project Status & Roadmap

Last Updated: August 2026

---

## 1. Executive Summary
**Mitrai** is an AI-powered conversational commerce platform combining:
- **Backend**: Django REST Framework + LangGraph state machine + Supabase Auth + Razorpay payments + Multi-source review research (YouTube + Reddit + Tavily) + Real-time agent step telemetry.
- **Frontend**: Flutter mobile app featuring a clean Bento "Brik" design system, strictly logo-based branding, and an interactive AI shopping intelligence waveform.

---

## 2. What Has Been Built Till Now

### A. Django Backend & AI Agent Engine (`backend/`)
- [x] **LangGraph Cyclical State Machine**:
  - `intent_router_node`: Natural language classification (`SEARCH_RECOMMEND`, `COMPARE`, `MANAGE_CART`, `CHECKOUT`, `TRACK_ORDER`).
  - `search_recommend_node`: Budget and spec parsing with grounded merchant catalog lookup.
  - `comparison_node`: Side-by-side hardware spec matrix, price delta, and community verdict.
  - `cart_management_node`: Cart synchronization and live subtotal computation.
  - `checkout_decision_node`: Razorpay order creation and HMAC payload generation.
  - `order_tracking_node`: Real-time logistics state lookup.
- [x] **Real-Time Agent Step Telemetry (`AgentExecutionTracer`)**:
  - Emits granular, observable steps (`step_name`, `description`, `tool_name`, `status`, `duration_ms`, `details`).
  - Standard REST JSON endpoint (`POST /api/agent/chat/`).
  - Real-time Server-Sent Events (SSE) streaming endpoint (`POST /api/agent/stream/`).
- [x] **Multi-Source Review Research Engine (`MultiSourceResearchService`)**:
  - **YouTube Review Consensus**: Synthesizes top tech reviewer opinions (battery endurance, camera noise, thermal tests) without paid API keys.
  - **Reddit Discussions**: Queries subreddits (`r/IndiaTech`, `r/gadgets`) for real user feedback and complaints.
  - **Tavily Web Search**: Live pricing and merchant deals.
- [x] **Razorpay Integration & Security**:
  - Test mode keys integrated (`rzp_test_TS9z7ilhd69feu`).
  - Backend cryptographic signature verification (`hmac_sha256`) before order confirmation.
- [x] **Supabase Authentication**:
  - JWT verification backend (`SupabaseAuthentication`) and `UserProfile` synchronization.
- [x] **Catalog & Seed Data**:
  - 7 seeded products across Smartphones, Audio, and Footwear with attribute JSON specs.
- [x] **Automated Test Suite**:
  - 7/7 backend unit tests passing in 4.1s.

---

### B. Flutter Mobile Client (`frontend/`)
- [x] **Clean Bento / Brik UI System**:
  - Warm canvas (`#F6F7F2`) with deep forest slate cards (`#0C1818`), subtle borders, and pastel lilac accents (`#D3C7F8`).
  - Removed clippers in favor of clean high-radius Bento containers (`BorderRadius.circular(28)`).
- [x] **Branding**:
  - `AppLogo` widget displaying strictly the SVG logo (`assets/images/logo.svg`) with zero added brand text in headers.
- [x] **Interactive Animation**:
  - `AiCommerceVisualizer` shopping waveform with floating intent badges (`Wireless Audio`, `Under ₹3,000`, `Compare Specs`, `Razorpay Pay`).
- [x] **Commerce Screens**:
  - `LoginScreen`: AI Commerce onboarding, Google Sign-In, and Guest mode.
  - `HomeScreen`: Monthly budget progress bar (`80% ||||||||||||||||`), instant recommendation cards, and dual metrics.
  - `AiShoppingScreen`: Conversational shopping interface with suggested action chips.
  - `CartScreen` & `CheckoutSheet`: Bottom sheets for cart management and Razorpay payment triggers.

---

### C. Documentation Architecture (`docs/`)
- [x] [`docs/AGENT_ARCHITECTURE.md`](file:///Users/nishantmaurya/projects/razorpay/docs/AGENT_ARCHITECTURE.md): Multi-step shopping lifecycle, LangGraph state machine, tool definitions, and review synthesis.
- [x] [`docs/BACKEND_GUIDELINES.md`](file:///Users/nishantmaurya/projects/razorpay/docs/BACKEND_GUIDELINES.md): DRF conventions, Supabase JWT auth, Razorpay HMAC-SHA256 verification, and research service.
- [x] [`docs/FLUTTER_GUIDELINES.md`](file:///Users/nishantmaurya/projects/razorpay/docs/FLUTTER_GUIDELINES.md): Brik UI tokens, Bento card specifications, and state management rules.
- [x] [`docs/API_CONTRACTS.md`](file:///Users/nishantmaurya/projects/razorpay/docs/API_CONTRACTS.md): REST endpoints, request/response JSON schemas, and SSE stream contracts.
- [x] [`features.md`](file:///Users/nishantmaurya/projects/razorpay/features.md): 5 core AI Commerce features specification.

---

## 3. What Has to Be Done (Roadmap)

### Priority 1: Frontend Agent Step Telemetry Visualizer
- [ ] Connect Flutter chat client to the backend SSE streaming endpoint (`/api/agent/stream/`).
- [ ] Add an animated "Agent Thinking / Researching" step pill in the chat UI (e.g. `Searching YouTube reviews...` $\to$ `Comparing prices across 3 stores...` $\to$ `92% Match calculated`).

### Priority 2: Native Razorpay Checkout SDK Bridge
- [ ] Integrate `razorpay_flutter` plugin with Android `MainActivity` and test end-to-end checkout with test cards and UPI QR.

### Priority 3: Dynamic Multi-Store Web Scraper Extension
- [ ] Connect live Playwright/Crawl4AI worker to pull dynamic prices from Amazon.in and Flipkart.com when products are not in local inventory.

### Priority 4: Production Deployment & Vector Indexing
- [ ] Configure Supabase `pgvector` for product embedding vector similarity search.
- [ ] Set up production environment secrets and Docker deployment.

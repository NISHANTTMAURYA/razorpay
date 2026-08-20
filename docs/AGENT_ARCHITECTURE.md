# Mitrai AI Commerce — Agent Architecture & Workflows

## 1. System Overview

Mitrai is an AI-driven conversational commerce platform that compresses the traditional multi-step e-commerce journey (search, filter, compare, cart, payment, tracking) into an intelligent, natural-language dialog with integrated direct actions.

```
+-------------------------------------------------------------------------+
|                              Customer UI                                |
|   (Flutter App - Brik Design System, Voice/Visualizer, Gesture Canvas)  |
+------------------------------------+------------------------------------+
                                     |
                                     | REST / WebSocket / SSE
                                     v
+-------------------------------------------------------------------------+
|                           Mitrai Django Backend                         |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                     Supabase Authentication & JWT                 |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                      Mitrai Commerce Agent Engine                 |  |
|  |  * Intent & Preference Parser                                     |  |
|  |  * Catalog & Search Tool Invoker                                  |  |
|  |  * Comparative Reasoner & Recommendation Engine                   |  |
|  |  * Controlled Cart & Checkout Action Executor                     |  |
|  |  * Razorpay Payment Layer & Order State Machine                   |  |
|  |  * Post-Purchase Resolution Handler                               |  |
|  +-------------------------------------------------------------------+  |
|                                                                         |
|  +-------------------------------------------------------------------+  |
|  |                      Database & External Services                 |  |
|  |  * PostgreSQL / Supabase DB (Merchants, Products, Carts, Orders)  |  |
|  |  * Razorpay API (Orders, Payments, Webhook Verification)          |  |
|  |  * LLM Providers (OpenAI / Gemini / Claude via standard API)      |  |
|  +-------------------------------------------------------------------+  |
+-------------------------------------------------------------------------+
```

---

## 2. Agent Operational Lifecycle

The Commerce Agent operates strictly under a **Grounded Action Model**. It never invents stock, prices, or payment confirmations.

```text
[User Prompt]
     │
     ▼
[Intent Extraction]
     │── Parse Category, Budget, Key Features, Constraints, Intent Type
     ▼
[Tool Decision & Execution]
     ├─► `search_catalog(query, category, max_price, attributes)`
     ├─► `compare_products(product_ids, attributes)`
     ├─► `modify_cart(user_id, action, product_id, quantity)`
     ├─► `create_checkout(user_id, cart_id, shipping_address)`
     ├─► `verify_payment(order_id, razorpay_payment_id, signature)`
     └─► `get_order_status(order_id)`
     │
     ▼
[Grounded Synthesis]
     │── Format concise, transparent recommendations with clear trade-offs
     ▼
[UI Action Card Response]
     └── Structured JSON + Natural Language payload returned to Flutter client
```

---

## 3. Core Agent Tools & Capabilities

### Tool 1: `search_catalog` (Cross-Platform Discovery)
- **Purpose**: Search multi-merchant product catalogue across categories and price brackets.
- **Parameters**: `query: str`, `category: str?`, `min_price: float?`, `max_price: float?`, `brand: str?`, `in_stock: bool?`.
- **Response**: Array of product objects with specs, prices, images, ratings, merchant details.

### Tool 2: `compare_products` (Intelligent Spec & Price Comparison)
- **Purpose**: Side-by-side comparison of prices, hardware specifications, battery life, camera, and ratings.
- **Parameters**: `product_ids: list[int]`, `focus_attributes: list[str]?`.
- **Response**: Attribute matrix, price delta, and objective pros/cons.

### Tool 3: `analyze_product_reviews` (Multi-Source Sentiment Research)
- **Purpose**: Synthesizes verified customer reviews, YouTube consensus, Reddit threads, and tech blog sentiment.
- **Parameters**: `product_id: int`.
- **Response**: `sentiment_score`, `pros_summary`, `cons_summary`, `real_world_verdict`.

### Tool 4: `manage_cart`
- **Purpose**: Add, remove, update quantities in user's active cart.
- **Parameters**: `cart_id: str`, `action: 'ADD'|'REMOVE'|'UPDATE'|'CLEAR'`, `product_id: int`, `quantity: int`.
- **Response**: Updated cart items, subtotal, discount, taxes, final total.

### Tool 5: `initiate_checkout`
- **Purpose**: Convert cart into a locked checkout and generate a Razorpay Order ID.
- **Parameters**: `cart_id: str`, `shipping_address: dict`.
- **Response**: `order_id`, `razorpay_order_id`, `amount_in_paise`, `currency`, `key_id`.

### Tool 6: `verify_payment`
- **Purpose**: Cryptographically verify Razorpay HMAC signature on the backend before order confirmation.
- **Parameters**: `razorpay_order_id: str`, `razorpay_payment_id: str`, `razorpay_signature: str`.
- **Response**: `status: 'PAID'|'FAILED'`, `order_details`.

### Tool 7: `track_order`
- **Purpose**: Fetch current order tracking status and delivery updates.
- **Parameters**: `order_id: str`.
- **Response**: `tracking_status`, `estimated_delivery`, `timeline`.

---

## 4. Agent Safety & Grounding Principles

1. **Strict Zero-Hallucination Policy**: All prices, discounts, stock levels, and product specifications must originate from the database records.
2. **Explicit Consent on Purchase**: The agent must ask for explicit customer confirmation prior to generating checkout and launching Razorpay.
3. **Server-Side Payment Verification**: An order is NEVER marked `CONFIRMED` or `PAID` based on client claims. The HMAC-SHA256 signature must be verified using the secret key on Django.
4. **Resilient Failure Recovery**: When a payment fails or is dismissed, the agent offers actionable alternatives (e.g. retry payment, change payment method, keep cart saved).

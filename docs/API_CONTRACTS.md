# Mitrai REST API Contracts & Telemetry Specifications

Base URL: `http://localhost:8000/api/`

---

## 1. Agent Endpoints & Telemetry

### 1.1 `POST /api/agent/chat/`
Standard synchronous endpoint returning grounded response, product cards, comparison matrix, and full step-by-step execution trace.

#### Request Body:
```json
{
  "message": "I need the best phone under 30k with a great camera",
  "cart_id": "optional-uuid"
}
```

#### Response (200 OK):
```json
{
  "response": "Based on real-world testing from YouTube (Geekyranjit / MKBHD), Reddit discussions, and hardware specs...",
  "intent": "SEARCH_RECOMMEND",
  "products": [
    {
      "id": 1,
      "name": "OnePlus Nord CE 3 Lite 5G",
      "brand": "OnePlus",
      "price": "19999.00",
      "rating": 4.6,
      "attributes": {"camera": "108MP", "battery": "5000mAh", "charging": "67W"}
    }
  ],
  "comparison": null,
  "cart": null,
  "suggested_actions": [
    {
      "label": "Add OnePlus to Cart (₹19,999)",
      "action": "ADD_TO_CART",
      "payload": {"product_id": 1, "quantity": 1}
    }
  ],
  "steps": [
    {
      "step_name": "Intent Understanding",
      "description": "Classifying natural language shopping intent and query parameters",
      "tool_name": null,
      "status": "COMPLETED",
      "duration_ms": 1,
      "details": {"detected_intent": "SEARCH_RECOMMEND", "raw_query": "I need the best phone under 30k with a great camera"}
    },
    {
      "step_name": "Catalog Search & Extraction",
      "description": "Searching multi-merchant catalog and filtering by price/specs",
      "tool_name": "search_catalog",
      "status": "COMPLETED",
      "duration_ms": 5,
      "details": {"matched_count": 1, "top_match": "OnePlus Nord CE 3 Lite 5G"}
    },
    {
      "step_name": "Multi-Source Review Research",
      "description": "Synthesizing YouTube tech reviews (Geekyranjit / MKBHD) & Reddit sentiment for OnePlus Nord CE 3 Lite 5G",
      "tool_name": "analyze_product_reviews",
      "status": "COMPLETED",
      "duration_ms": 420,
      "details": {
        "overall_match_score": "91%",
        "youtube_consensus": "Highly recommended by tech reviewers in its price category as a top tier daily driver.",
        "reddit_threads_analyzed": 2
      }
    },
    {
      "step_name": "Response Assembly",
      "description": "Assembling structured JSON payload with product cards and Razorpay action triggers",
      "tool_name": null,
      "status": "COMPLETED",
      "duration_ms": 0,
      "details": {"suggested_actions_count": 1}
    }
  ]
}
```

---

### 1.2 `POST /api/agent/stream/`
Real-time **Server-Sent Events (SSE)** endpoint streaming atomic execution steps as they happen.

#### Stream Events:
1. `CONNECTED`: `data: {"event": "CONNECTED", "message": "Agent initialized"}`
2. `STEP_UPDATE`: `data: {"event": "STEP_UPDATE", "step": { "step_name": "...", "status": "COMPLETED", ... }}`
3. `FINAL_RESPONSE`: `data: {"event": "FINAL_RESPONSE", "payload": { ... }}`
4. `[DONE]`: `data: [DONE]`

---

## 2. Commerce & Razorpay Payment Endpoints

### 2.1 `POST /api/commerce/checkout/initiate/`
- **Request**: `{"cart_id": "uuid", "shipping_address": {...}}`
- **Response**: `{"order_id": "...", "razorpay_order_id": "order_...", "amount_in_paise": 299900, "currency": "INR", "key_id": "rzp_test_TS9z7ilhd69feu"}`

### 2.2 `POST /api/commerce/payment/verify/`
- **Request**: `{"razorpay_order_id": "order_...", "razorpay_payment_id": "pay_...", "razorpay_signature": "hmac_sha256"}`
- **Response**: `{"status": "PAID", "order": {...}}`

# 🚀 Mitrai — Project Idea & Vision

## 📌 Executive Summary
**Mitrai** is an AI-powered commerce and shopping assistant platform that unifies product discovery, honest community research, and direct brand ordering into a single, seamless experience. 

Instead of opening 10 browser tabs to compare prices across marketplaces, search YouTube for video reviews, and read Reddit for long-term user feedback, Mitrai's AI handles the entire pre-purchase research in seconds and connects shoppers directly to brand backends for 1-tap checkout via **Razorpay**.

---

## 🎯 The Core Problem

1. **Buyer Decision Fatigue:**
   - Buyers spend hours switching between Amazon, Flipkart, brand websites, YouTube tech reviews, and Reddit discussion threads just to make a confident purchase decision.
2. **High Middleman Fees for D2C Brands:**
   - Direct-to-consumer (D2C) brands (like boAt, Snitch, The Derma Co, MuscleBlaze) lose 20–35% of their revenue to big marketplaces just to get discovered by customers.
3. **Fragmented Cart & Price Tracking:**
   - Shoppers miss out on price drops and flash sales because monitoring multiple stores manually is tedious.

---

## 💡 How Mitrai Solves It (The AI Commerce Model)

### 1. Direct Brand API Integration (Zero Inventory Model)
- D2C brands already run their own online stores (on Shopify, WooCommerce, or custom ERP systems) which provide APIs for searching products, reading inventory, and placing orders.
- Mitrai connects directly to these brand APIs:
  - **Search & Catalog:** Mitrai queries brand catalogs in real-time.
  - **Order Placement:** When a user buys on Mitrai, the order payload is pushed directly to the brand’s order API.
  - **Zero Warehouse / Zero Logistics:** The brand packs, invoices, and delivers the order directly to the customer. Mitrai remains a 100% lightweight, software-only intelligence layer.

### 2. Autonomous Multi-Source Research
- When a user asks about a product, Mitrai’s AI agent automatically:
  - Compares prices and variants across direct brand stores and external platforms.
  - Synthesizes real community feedback from **YouTube video reviews** and **Reddit discussions** into clear, unbiased Pros & Cons.
  - Highlights critical real-world details like battery life, build quality, and after-sales service.

### 3. Smart Price-Drop & Deal Radar
- Users can set a target budget or "watch" any product.
- The platform tracks price fluctuations in the background and notifies users the moment an item hits their target price.

### 4. Unified One-Tap Checkout with Razorpay
- Users never have to create separate accounts on 10 different brand websites.
- Transactions are processed securely via **Razorpay**, with cryptographic backend HMAC-SHA256 signature verification ensuring payment authenticity.

---

## 🛠️ Build Challenges & How We Tackled Them

1. **AI Agent Reliability & Decision Loops:**
   - *Challenge:* Multi-step reasoning (searching, extracting reviews, comparing prices) can get stuck or return messy formats when using standard LLMs.
   - *Solution:* Broke down the complex agent workflow into modular steps with strict JSON schemas and deterministic rule-based fallback parsers so the application never crashes.

2. **Handling Unstructured Reviews (YouTube / Reddit):**
   - *Challenge:* Raw comments and transcripts contain sarcasm, spam, and noise.
   - *Solution:* Implemented specialized prompt chaining to extract only factual pros, cons, and sentiment summaries.

3. **Standardizing Brand APIs Without Production Keys:**
   - *Challenge:* Every D2C brand uses different API standards (Shopify GraphQL, REST, WooCommerce).
   - *Solution:* Created a universal adapter layer that normalizes product schemas and order creation payloads across different merchant backends.

4. **Secure Razorpay Payment Verification:**
   - *Challenge:* Preventing state synchronization discrepancies between mobile app callbacks and backend order statuses.
   - *Solution:* Enforced strict server-side HMAC-SHA256 signature validation before marking any order as confirmed.

---

## 🏆 Razorpay AI Builder Internship Submission Details

- **Selected Track:** `Track 1: AI Growth & Agentic Commerce`
- **Project Title:** `Mitrai - Autonomous AI Agentic Commerce & Unified Shopping Platform`
- **Value Proposition:** Empowers D2C brands with zero-commission discovery while saving buyers hours of research friction through autonomous AI synthesis and direct Razorpay checkout.

# AI Commerce — Project Requirements

## 1. Project Summary

Build **AI Commerce**, an AI-powered commerce platform where users can discover products, compare options, make purchase decisions, complete payments, and manage orders through natural-language interaction.

The product should be designed as a standalone commerce experience and should not depend on any particular chat application, frontend framework, backend framework, database, or other implementation technology.

The system should connect merchants, their product catalogues, customers, order workflows, and Razorpay-powered payments into one AI-driven commerce experience.

### Core concept

```text
Customer
   ↓
AI Commerce Experience
   ↓
AI Commerce Agent
   ↓
Product & Merchant Information
   ↓
Discovery → Recommendation → Cart → Checkout
   ↓
Razorpay Payment
   ↓
Order Confirmation
   ↓
Post-Purchase Support
```

---

## 2. Primary Users

### Customer

A consumer who wants to shop using natural language rather than manually navigating multiple product pages.

Example:

> "I need wireless headphones under ₹3,000 with good battery life."

### Merchant

A business that wants its products to be discoverable through the AI Commerce platform and wants to accept payments through Razorpay.

### Platform Administrator

An operator who manages merchants, catalogues, transactions, agent behaviour, permissions, and platform-level configuration.

---

## 3. Problem

Traditional e-commerce requires customers to:

1. Search for products.
2. Apply filters.
3. Open multiple product pages.
4. Compare products manually.
5. Decide what to buy.
6. Add items to a cart.
7. Complete checkout.
8. Return later to track the order.

AI Commerce should compress this journey into a natural conversation or AI-assisted experience.

Example:

> "I need running shoes under ₹5,000 for daily running."

The system should understand the intent, find suitable products, explain the recommendations, help the customer make a decision, create the cart, and facilitate payment.

---

## 4. Core Product Objective

The primary objective is to demonstrate:

**Conversation / natural-language intent → product discovery → intelligent recommendation → purchase decision → payment → order → post-purchase assistance**

The product should not be merely a product-search chatbot.

The AI agent should be capable of progressing a customer through the commerce journey and using controlled actions to perform real commerce operations.

---

# 5. Merchant Onboarding

Merchants should be able to join the platform and make their products available to the AI Commerce agent.

### Merchant onboarding flow

```text
Merchant registration
        ↓
Merchant verification / setup
        ↓
Catalogue connection or upload
        ↓
Product information available
        ↓
Razorpay payment account connection
        ↓
Merchant becomes active
        ↓
Products become discoverable
```

### Merchant catalogue

The platform should support at least one practical catalogue-ingestion method for the MVP.

Possible approaches include:

- Catalogue upload
- Merchant API
- Product feed
- Manual product entry

The implementation approach can be selected later.

### Merchant product information

Each product should support:

- Product ID
- Merchant ID
- Name
- Description
- Category
- Brand
- Price
- Currency
- Availability
- Images
- Attributes
- Variants
- Rating, where available
- Discount, where available
- Delivery information, where available

---

# 6. Customer Discovery Flow

A customer should be able to express a shopping requirement naturally.

Example:

> "I need a phone under ₹25,000 with a good camera and at least 8 GB RAM."

The system should extract:

```text
Category: Smartphone
Maximum price: ₹25,000
Primary preference: Camera
RAM: >= 8 GB
Intent: Product discovery / purchase
```

The agent should then search the available catalogue.

---

# 7. Product Search

The product search system should support:

- Natural-language queries
- Category filtering
- Price filtering
- Brand filtering
- Availability filtering
- Attribute filtering
- Rating filtering
- Use-case matching
- Preference matching

The agent should not invent products or product information.

All product claims should be grounded in available merchant/product data.

---

# 8. Intelligent Recommendation

The agent should return a small set of relevant products rather than overwhelming the customer.

Example:

> "I found three good options. For daily running, I'd choose Product B because it has the best combination of cushioning, rating and price."

Recommendations should be explainable.

The system should be able to answer:

- Why did you recommend this?
- Why is this better than the second option?
- What is the cheapest option?
- Which has the best rating?
- Which has the best battery life?
- Which is available right now?

---

# 9. Product Comparison

Customers should be able to compare products using natural language.

Example:

> "Compare these two."

The agent should compare relevant attributes such as:

- Price
- Rating
- Specifications
- Features
- Availability
- Delivery information
- Discounts
- Customer preferences

The agent should provide a clear recommendation when appropriate, while explaining the reason.

---

# 10. Cart

The system should allow the AI agent to:

- Create a cart
- Add products
- Remove products
- Change quantities
- Show cart contents
- Calculate subtotal
- Apply valid discounts
- Calculate final amount
- Confirm the cart before payment

Example:

> "Add the second one to my cart."

The agent should perform the cart operation through a controlled commerce action.

---

# 11. Checkout

Before payment, the system should clearly show:

- Merchant
- Products
- Quantities
- Subtotal
- Discount
- Shipping charges, if applicable
- Final amount
- Currency
- Delivery information, where applicable

The customer must explicitly confirm the purchase before the payment action is initiated.

Example:

> "The total is ₹2,799. Shall I proceed with the payment?"

---

# 12. Razorpay Payment

Razorpay should be the payment layer for the commerce transaction.

The system should support:

1. Creating a payment/order request.
2. Initiating checkout.
3. Receiving payment status.
4. Verifying payment on the server side.
5. Updating the internal order state.
6. Handling failed payments.
7. Preventing duplicate payment/order processing.

The AI agent must never claim that a payment succeeded until the backend has verified the payment result.

---

# 13. Payment Failure Flow

```text
Payment initiated
       ↓
Payment fails
       ↓
Payment status recorded
       ↓
Agent understands the failure state
       ↓
Agent offers an appropriate next action
       ↓
Customer retries / chooses another option
       ↓
Payment succeeds
       ↓
Order confirmed
```

The agent should not invent the reason for a payment failure.

If the actual failure reason is unavailable, it should communicate that clearly.

---

# 14. Order Creation

An order should be created only after the required payment state has been verified.

Minimum order information:

```text
Order ID
Customer ID
Merchant ID
Cart ID
Payment reference
Amount
Currency
Payment status
Order status
Shipping information
Created time
Updated time
```

Suggested order states:

```text
CREATED
PAYMENT_PENDING
PAID
PAYMENT_FAILED
CONFIRMED
CANCELLED
FULFILLED
```

---

# 15. Post-Purchase Experience

After a successful transaction, the AI agent should be able to help the customer with:

- Order confirmation
- Order status
- Delivery information
- Order details
- Cancellation requests
- Return requests
- Basic product/order questions

Example:

> "Where is my order?"

The agent should retrieve the actual order state and respond using verified data.

---

# 16. Personalisation

The platform should support customer-specific shopping context.

Possible information:

- Previous purchases
- Recent searches
- Preferred categories
- Preferred brands
- Typical budget
- Saved preferences

Example:

> "You usually prefer products below ₹5,000. I found two options matching your usual budget."

Personalisation must be based on actual stored information and must not be fabricated.

---

# 17. AI Agent Capabilities

The AI agent should have controlled capabilities for:

```text
Search products
Get product details
Compare products
Check availability
Create cart
Update cart
Calculate total
Create order
Initiate payment
Check payment status
Verify payment
Get order status
Request cancellation
Request return
```

The AI model should not directly modify sensitive commerce or payment data.

Sensitive operations must go through controlled backend actions with validation and authorisation.

---

# 18. Agent Behaviour Rules

The agent MUST:

- Never invent product information.
- Never invent prices.
- Never invent stock availability.
- Never invent discounts.
- Never claim payment success without verification.
- Ask for confirmation before purchase.
- Use the customer's actual cart.
- Use the actual merchant catalogue.
- Respect merchant-specific rules.
- Respect customer permissions.
- Explain important actions before executing them.
- Escalate unsupported or exceptional cases.

---

# 19. Agent Decision Flow

```text
Customer request
       ↓
Understand intent
       ↓
Extract relevant preferences
       ↓
Determine required action
       ↓
Call appropriate commerce capability
       ↓
Receive verified result
       ↓
Reason over result
       ↓
Respond to customer
       ↓
Continue conversation
```

Example:

```text
"I need a phone under 25k with a good camera."

        ↓

Identify:
category = smartphone
max_price = 25000
preference = camera

        ↓

Search product catalogue

        ↓

Rank relevant products

        ↓

Present recommendations

        ↓

Customer selects product

        ↓

Create/update cart

        ↓

Confirm purchase

        ↓

Initiate Razorpay payment

        ↓

Verify payment

        ↓

Create/confirm order
```

---

# 20. Multi-Merchant Discovery

The platform should be designed so that products can eventually come from multiple onboarded merchants.

Example:

> "Find me the best laptop under ₹70,000."

The system can search across eligible merchants and return relevant options.

The platform should maintain clear separation between merchant data.

For the MVP, a single-merchant checkout is recommended conceptually because it keeps the transaction flow straightforward.

Multi-merchant checkout can be a future capability.

---

# 21. Merchant Value

The platform should create measurable value for merchants.

Potential benefits:

- More product discovery
- Higher conversion
- Lower checkout friction
- Better customer engagement
- Personalised recommendations
- Conversational sales
- Repeat purchases
- Post-purchase support

A key business metric is:

**Natural-language interaction → completed purchase conversion rate**

Other useful metrics:

- Search-to-product-selection rate
- Product-selection-to-cart rate
- Cart-to-payment rate
- Payment success rate
- Average order value
- Repeat purchase rate
- Agent-assisted revenue

---

# 22. Differentiation

The platform should not be positioned as:

> "An AI chatbot that recommends products."

It should be positioned as:

> **An AI commerce agent that can take a customer from product discovery all the way to a completed transaction and post-purchase support.**

The important loop is:

```text
DISCOVER
   ↓
UNDERSTAND
   ↓
RECOMMEND
   ↓
COMPARE
   ↓
DECIDE
   ↓
CART
   ↓
PAY
   ↓
ORDER
   ↓
SUPPORT
```

The key differentiator is **conversation-to-transaction**, not conversation alone.

---

# 23. MVP Demo

The final prototype should demonstrate one complete end-to-end journey.

### Example

Customer:

> "I need wireless headphones under ₹3,000 for travelling."

Agent:

> "I found three options. Do you care more about battery life, sound quality, or overall value?"

Customer:

> "Best value."

Agent presents the best matching products.

Customer:

> "I'll take the second one."

Agent:

> "It's ₹2,799. Shall I proceed?"

Customer confirms.

Payment is initiated through Razorpay.

Payment succeeds.

Agent:

> "Payment successful. Your order is confirmed."

Customer:

> "Where is my order?"

Agent retrieves the actual order state and responds.

---

# 24. Future Roadmap

### Phase 1 — Core prototype

- Customer experience
- Merchant onboarding concept
- Product catalogue
- Natural-language discovery
- Recommendations
- Comparison
- Cart
- Razorpay payment
- Order confirmation

### Phase 2 — Merchant platform

- Merchant dashboard
- Self-service onboarding
- Catalogue management
- Merchant analytics
- Payment/revenue analytics
- Order management

### Phase 3 — Advanced AI Commerce

- Cross-merchant discovery
- Advanced personalisation
- Voice commerce
- Multilingual commerce
- Repeat purchase automation
- Subscription/reordering workflows
- Loyalty and offers

### Phase 4 — Agentic Commerce

- AI-native shopping surfaces
- External agent integrations
- More autonomous commerce workflows
- Multi-agent collaboration
- User-controlled autonomous purchasing

---

# 25. Razorpay Alignment and Official References

The project should use Razorpay as the transaction layer while solving a broader AI-commerce problem.

The following official Razorpay sources provide context for the direction:

### Razorpay Sprint 2026

Razorpay's Sprint 2026 materials describe AI-led shopping experiences where customers can browse, decide and pay through conversations, along with conversational product discovery and payments.

Source:

https://razorpay.com/sprint/26

### Razorpay Agent Studio

Razorpay describes Agent Studio as a platform for businesses to use and build AI agents for business workflows.

Source:

https://razorpay.com/agent-studio/

### Razorpay Agent Studio announcement

Razorpay's official announcement describes capabilities for building agents around business systems, tools and rules.

Source:

https://razorpay.com/newsroom/?p=4704

### Razorpay Agentic Payments / Voice AI

Official Razorpay material describing agentic payment experiences and the movement from AI conversation toward transaction completion.

Source:

https://razorpay.com/blog/razorpay-agentic-payments-voice-ai/

### Razorpay and Sarvam — conversational commerce

Official Razorpay announcement describing conversational product discovery, ordering and payments.

Source:

https://razorpay.com/newsroom/razorpay-partners-with-sarvam-to-power-voice-first-conversational-commerce/

These references are intended to establish the product direction and Razorpay alignment. They do not prescribe a specific implementation technology.

---

# 26. Definition of Done

The product is considered complete when a reviewer can start with:

> "I want wireless headphones under ₹3,000."

and observe the system:

1. Understand the request.
2. Search available products.
3. Recommend relevant products.
4. Answer follow-up questions.
5. Compare products when requested.
6. Add a selected product to a cart.
7. Calculate the final amount.
8. Ask for purchase confirmation.
9. Create the payment request.
10. Complete a Razorpay test payment.
11. Verify the payment.
12. Create/confirm the order.
13. Provide confirmation.
14. Retrieve the order status later.

The entire journey should work end-to-end without manually changing database/payment state during the demonstration.

---

# 27. Implementation Independence

This document intentionally does **not** prescribe:

- Frontend framework
- Backend framework
- Database technology
- Hosting provider
- LLM provider
- Programming language
- Messaging platform
- Deployment platform

Those decisions should be made separately during implementation.

The implementation must satisfy the product behaviour, business requirements, agent capabilities, payment requirements, security requirements, and end-to-end flow defined above.

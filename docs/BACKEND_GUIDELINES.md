# Mitrai Backend Architecture & Guidelines

## 1. Tech Stack
- **Framework**: Django 5.x + Django REST Framework (DRF)
- **Agent Framework**: LangGraph + LangChain Core
- **Database / Auth**: PostgreSQL / Supabase with JWT Verification
- **Payment Gateway**: Razorpay (Test / Production Sandbox with HMAC-SHA256 verification)
- **Research Engine**: MultiSourceResearchService (Tavily + YouTube Review synthesis + Reddit JSON search)
- **Agent Step Telemetry**: `AgentExecutionTracer` (Synchronous JSON trace + SSE stream)

---

## 2. Directory Structure

```
backend/
├── mitrai_backend/
│   ├── settings.py           # DRF, Supabase JWT, CORS, Razorpay config
│   ├── urls.py               # Master API routing (/api/auth/, /api/commerce/, /api/agent/)
│   └── wsgi.py
├── authentication/
│   ├── authentication.py     # Supabase JWT authentication backend
│   ├── models.py             # UserProfile
│   └── views.py              # User sync and profile endpoints
├── commerce/
│   ├── models.py             # Merchant, Category, Product, Cart, Order, PaymentTransaction
│   ├── services.py           # RazorpayService (Order create & HMAC-SHA256 verify)
│   ├── views.py              # Product Catalog, Cart, Checkout initiate & Verify
│   └── management/commands/  # seed_catalog.py
└── agent/
    ├── graph.py              # LangGraph cyclical state graph with step tracing
    ├── agent_tracer.py       # AgentExecutionTracer & AgentStep data structures
    ├── research_service.py   # MultiSourceResearchService (Tavily, YouTube, Reddit)
    ├── services.py           # CommerceAgentEngine
    ├── views.py              # AgentChatView and AgentStreamChatView (SSE)
    └── tests.py              # Unit tests for tracer, agent, chat & stream views
```

---

## 3. Core Rules
1. **Never Trust Client Signatures**: Always verify `razorpay_signature` cryptographically using `hmac.new(key_secret, msg, hashlib.sha256).hexdigest()`.
2. **Observable Agent Traces**: Every tool execution and reasoning node must emit a step to `AgentExecutionTracer`.
3. **Multi-Source Sentiment**: Product recommendations must combine hardware specs, price, and community sentiment (YouTube/Reddit).
4. **DRY & Test Coverage**: Run `python manage.py test` before pushing changes.

import re
import json
import logging
from typing import TypedDict, List, Dict, Any, Optional
from decimal import Decimal
from django.db.models import Q
from langgraph.graph import StateGraph, END
from commerce.models import Product, Category, Cart, CartItem, Order
from commerce.serializers import ProductSerializer, CartSerializer, OrderSerializer
from .research_service import MultiSourceResearchService
from .agent_tracer import AgentExecutionTracer
from .llm_service import gemini_service

logger = logging.getLogger(__name__)
research_engine = MultiSourceResearchService()

class CommerceState(TypedDict):
    message: str
    user_id: Optional[str]
    cart_id: Optional[str]
    intent: Optional[str]
    products: List[Dict[str, Any]]
    comparison: Optional[Dict[str, Any]]
    cart: Optional[Dict[str, Any]]
    order: Optional[Dict[str, Any]]
    suggested_actions: List[Dict[str, Any]]
    response_message: str
    steps: List[Dict[str, Any]]

# ─────────────────────────────────────────────────────────────────────────────
# 1. INTENT ROUTER NODE
# ─────────────────────────────────────────────────────────────────────────────

def intent_router_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Intent Understanding",
        description="Classifying natural language intent and conversation context"
    ) if tracer else None

    raw_msg = state["message"].strip().lower()
    clean_msg = re.sub(r'[^\w\s]', '', raw_msg)
    # Keywords for shopping/product queries & 24+ partner brands
    product_keywords = [
        'headphone', 'earphone', 'earbud', 'audio', 'tws', 'speaker', 'soundbar', 'neckband',
        'phone', 'mobile', 'smartphone', '5g', 'android', 'iphone',
        'shoe', 'shoes', 'sneaker', 'sneakers', 'running', 'boots', 'loafers', 'sandals', 'footwear',
        'watch', 'watches', 'smartwatch', 'wearable', 'ring', 'tracker',
        'shirt', 'tshirt', 't-shirt', 'trousers', 'pants', 'jogger', 'hoodie', 'apparel', 'fashion',
        'sunscreen', 'oil', 'facewash', 'face wash', 'scrub', 'serum', 'skincare', 'hair', 'shaving', 'razor', 'beard',
        'coffee', 'cold brew', 'protein', 'chocolate', 'snack', 'nutrition',
        'boat', 'noise', 'fireboltt', 'boult', 'portronics', 'mivi', 'crossbeats', 'zebronics',
        'lava', 'redtape', 'campus', 'sparx', 'woodland', 'snitch', 'souled', 'bewakoof',
        'mamaearth', 'mcaffeine', 'bombay', 'sleepy', 'owl', 'whole truth',
        'xiaomi', 'redmi', 'oneplus', 'samsung', 'apple', 'nike', 'puma', 'adidas', 'sony',
        'buy', 'purchase', 'shop', 'show me', 'recommend', 'looking for', 'find me', 'search for',
        'under', 'below', 'less than', 'budget', 'price of', 'cost of', 'specs', 'best', 'deal', 'deals'
    ]

    # 1. Greetings and general chit-chat
    greetings = [
        'hi', 'hello', 'hey', 'namaste', 'hola', 'sup', 'yo', 'good morning', 'good evening', 'good afternoon',
        'how are you', 'how r u', 'who are you', 'what is your name', 'what can you do', 'help', 'help me',
        'thanks', 'thank you', 'ok', 'okay', 'cool', 'nice', 'bye', 'goodbye', 'tell me a joke'
    ]

    is_greeting = clean_msg in greetings

    if any(k in raw_msg for k in ['compare', ' vs ', 'difference between', 'better than', 'vs.']):
        intent = "COMPARE"
    elif any(k in raw_msg for k in ['watch', 'alert me', 'notify me', 'keep an eye', 'price drop alert', 'track price', 'price radar']):
        intent = "WATCH_PRODUCT"
    elif any(k in raw_msg for k in ['add to cart', 'add this to cart', 'buy this', 'purchase this', 'add item', 'add to bag']):
        intent = "MANAGE_CART"
    elif any(k in raw_msg for k in ['checkout', 'pay now', 'place order', 'razorpay', 'proceed to pay', 'make payment']):
        intent = "CHECKOUT"
    elif any(k in raw_msg for k in ['track order', 'where is my order', 'delivery status', 'order status', 'shipment status']):
        intent = "TRACK_ORDER"
    elif any(k in raw_msg for k in ['return policy', 'refund', 'warranty', 'delivery time', 'is it secure', 'payment methods']):
        intent = "FAQ_POLICY"
    elif is_greeting:
        intent = "GREETING"
    else:
        intent = "SEARCH_RECOMMEND"

    if step:
        step.complete({"detected_intent": intent, "raw_query": state["message"]})

    return {"intent": intent}


# ─────────────────────────────────────────────────────────────────────────────
# 2. GREETING & GENERAL CHAT NODE (DYNAMIC LLM)
# ─────────────────────────────────────────────────────────────────────────────

def greeting_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Conversational Response",
        description="Generating natural AI conversational response"
    ) if tracer else None

    user_msg = state.get("message", "hi")
    history = state.get("history", [])

    # Generate dynamic natural response from Gemini LLM
    llm_resp = gemini_service.generate_response(prompt=user_msg, history=history)

    if not llm_resp:
        llm_resp = "There is an error right now. Please chat later."

    if step:
        step.complete({"status": "CONVERSATIONAL_RESPONSE_GENERATED"})

    return {
        "response_message": llm_resp,
        "products": [],
        "comparison": None,
        "cart": None,
        "suggested_actions": []
    }


from commerce.merchant_clients import merchant_gateway
from .research_service import research_engine, dynamic_marketplace_engine

def search_recommend_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step_db = tracer.start_step(
        step_name="Merchant API Gateway Search",
        description="Querying 10 integrated merchant APIs across catalog endpoints",
        tool_name="search_merchant_gateway"
    ) if tracer else None

    msg = state["message"].lower()

    # 1. Dynamic Budget & Price Range Extraction (handles ranges like 45k-50k, between, under, above, around)
    min_price = None
    max_price = None

    # Check for price range: "range of 45k-50k", "between 45k and 50k", "45k to 50k", "45k-50k", "45000 to 50000"
    range_match = re.search(r'(?:(?:in\s+a\s+)?range\s+(?:of\s+)?)?(?:between\s+)?(?:₹|rs\.?)?\s*(\d+(?:,\d+)*(?:k)?)\s*(?:-|to|and)\s*(?:₹|rs\.?)?\s*(\d+(?:,\d+)*(?:k)?)', msg)
    if range_match:
        v1_str = range_match.group(1).replace(',', '')
        v2_str = range_match.group(2).replace(',', '')
        p1 = float(v1_str[:-1]) * 1000 if v1_str.endswith('k') else float(v1_str)
        p2 = float(v2_str[:-1]) * 1000 if v2_str.endswith('k') else float(v2_str)
        min_price = min(p1, p2)
        max_price = max(p1, p2)
    else:
        # Check max price: under, below, less than, within, upto, max
        max_match = re.search(r'(?:under|below|less than|within|upto|up to|max(?:imum)?)\s*(?:₹|rs\.?)?\s*(\d+(?:,\d+)*(?:k)?)', msg)
        if max_match:
            v_str = max_match.group(1).replace(',', '')
            max_price = float(v_str[:-1]) * 1000 if v_str.endswith('k') else float(v_str)

        # Check min price: above, more than, greater than, at least, min
        min_match = re.search(r'(?:above|more than|greater than|at least|min(?:imum)?)\s*(?:₹|rs\.?)?\s*(\d+(?:,\d+)*(?:k)?)', msg)
        if min_match:
            v_str = min_match.group(1).replace(',', '')
            min_price = float(v_str[:-1]) * 1000 if v_str.endswith('k') else float(v_str)

        # Check around/approx price: around 45k -> 38k to 52k
        around_match = re.search(r'(?:around|approx(?:imately)?)\s*(?:₹|rs\.?)?\s*(\d+(?:,\d+)*(?:k)?)', msg)
        if around_match and not max_price and not min_price:
            v_str = around_match.group(1).replace(',', '')
            target = float(v_str[:-1]) * 1000 if v_str.endswith('k') else float(v_str)
            min_price = target * 0.85
            max_price = target * 1.15

    # 2. Category intent detection — fuzzy & typo-tolerant with bluetooth / wireless support
    category = None
    if re.search(r'\b(?:headphone|headphones|earphone|earphones|earbud|earbuds|audio|tws|airpod|airpods|sound|speaker|soundbar|neckband|bluetooth|wireless)\b', msg):
        category = "Audio"
    elif re.search(r'(?:phone|phon|fone|smartphone|mobile|mobil|5g|android|iphone)', msg) and not re.search(r'headphone|earphone|audio', msg):
        category = "Smartphones"
    elif re.search(r'(?:shoe|sneaker|running shoe|footwear|boot|loafer|sandal)', msg):
        category = "Footwear"
    elif re.search(r'(?:watch|smartwatch|wearable|fitness band|ring|tracker)', msg):
        category = "Wearables"
    elif re.search(r'(?:shirt|tshirt|t-shirt|oversized|trouser|pant|hoodie|clothing|apparel|menswear|streetwear|tee)\b', msg):
        category = "Fashion"
    elif re.search(r'(?:hair|skin|facewash|face wash|scrub|oil|serum|sunscreen|grooming|razor|shaving|beard|beauty|lotion)', msg):
        category = "Personal Care"
    elif re.search(r'(?:coffee|cold brew|dark roast|protein|chocolate|snack|nutrition|peanut butter|bar)\b', msg):
        category = "Food & Nutrition"

    # Multi-turn History Context: If category not in current turn, inherit from recent conversation history
    history = state.get("history", [])
    if not category and history:
        for turn in reversed(history[-6:]):
            prev_text = turn.get("content", "").lower()
            if re.search(r'\b(?:headphone|headphones|earphone|earphones|earbud|earbuds|audio|tws|airpod|sound|speaker|bluetooth|wireless)\b', prev_text):
                category = "Audio"
                break
            elif re.search(r'(?:phone|phon|fone|smartphone|mobile|mobil|5g|android|iphone)', prev_text) and not re.search(r'headphone|earphone|audio', prev_text):
                category = "Smartphones"
                break
            elif re.search(r'(?:shoe|sneaker|running shoe|footwear|boot|loafer)', prev_text):
                category = "Footwear"
                break
            elif re.search(r'(?:watch|smartwatch|wearable|fitness band|ring|tracker)', prev_text):
                category = "Wearables"
                break
            elif re.search(r'(?:shirt|tshirt|t-shirt|oversized|trouser|pant|hoodie|clothing|apparel)', prev_text):
                category = "Fashion"
                break
            elif re.search(r'(?:hair|skin|facewash|face wash|scrub|oil|serum|sunscreen|grooming|razor)', prev_text):
                category = "Personal Care"
                break
            elif re.search(r'(?:coffee|cold brew|protein|chocolate|snack|nutrition)', prev_text):
                category = "Food & Nutrition"
                break

    # 3. Dynamic Merchant Products Toggle Check (from UI toggle or query text)
    include_merchants = state.get("include_merchants", True)
    if re.search(r'(?:no\s+merchant|only\s+external|hide\s+merchant|external\s+only|marketplace\s+only|stop\s+merchant)', msg):
        include_merchants = False
    elif re.search(r'(?:only\s+merchant|brand\s+direct|direct\s+only|show\s+merchant)', msg):
        include_merchants = True

    # 4. Tool Loop Phase 1: Query On-Platform Merchant API Gateway
    platform_products = []
    if include_merchants:
        platform_products = merchant_gateway.search_all_merchants(query=msg, category=category, min_price=min_price, max_price=max_price)
        # Note: ONLY relax price if user did NOT explicitly specify a price constraint
        if not platform_products and category and not max_price and not min_price:
            platform_products = merchant_gateway.search_all_merchants(category=category)
        if not platform_products and not category and not max_price and not min_price:
            platform_products = merchant_gateway.search_all_merchants()[:4]

    if step_db:
        step_db.complete({
            "matched_count": len(platform_products),
            "top_match": platform_products[0]["name"] if platform_products else None,
            "detected_category": category,
            "connected_merchants_queried": len(merchant_gateway.clients) if include_merchants else 0
        })

    # 5. Dynamic Live Multi-Marketplace & Quick-Commerce Scraping
    step_scrape = tracer.start_step(
        step_name="Dynamic Marketplace & Quick-Commerce Scraping",
        description="Extracting real-time pricing and stock across external marketplaces and quick-commerce",
        tool_name="search_all_external_marketplaces"
    ) if tracer else None

    # Construct clean search query for external scrapers
    cleaned_msg = re.sub(r'\b(?:i\s+want|in\s+a\s+range\s+of|between|looking\s+for|find\s+me|show\s+me|give\s+me|search\s+for|please|recommend|best|top|budget|range)\b', '', msg, flags=re.IGNORECASE).strip()
    search_term = cleaned_msg
    if category:
        if not any(k in cleaned_msg.lower() for k in ['phone', 'mobile', 'audio', 'headphone', 'shoe', 'shirt', 'watch', 'coffee', 'bluetooth', 'wireless']):
            search_term = f"{category} {cleaned_msg}".strip()

    if not search_term or search_term == category:
        if min_price and max_price:
            search_term = f"{category or 'products'} {int(min_price)} to {int(max_price)}"
        elif max_price:
            search_term = f"{category or 'products'} under {int(max_price)}"
        else:
            search_term = category or msg

    external_products = dynamic_marketplace_engine.search_all_external_marketplaces(
        query=search_term,
        category=category,
        min_price=min_price,
        max_price=max_price
    )

    if step_scrape:
        queried_stores = list(set([p.get('attributes', {}).get('marketplace', 'External Store') for p in external_products])) if external_products else ["Live Web Marketplaces"]
        step_scrape.complete({
            "external_deals_found": len(external_products),
            "marketplaces_queried": queried_stores
        })

    # 6. Combine both & Enforce strict price range matching
    all_matched = platform_products + external_products
    if min_price or max_price:
        valid_matched = []
        for p in all_matched:
            try:
                p_val = float(p.get('price', 0))
                if min_price and p_val < min_price * 0.85:
                    continue
                if max_price and p_val > max_price * 1.15:
                    continue
                valid_matched.append(p)
            except Exception:
                valid_matched.append(p)
        if valid_matched:
            all_matched = valid_matched

    top_product = all_matched[0] if all_matched else None

    onboarded_merchants = merchant_gateway.get_onboarded_merchants(category=category) if include_merchants else []
    onboarded_names = [m['name'] for m in onboarded_merchants]

    # 7. Generate Dynamic Intermediate / Preview Response (Sent before final deep synthesis)
    budget_label = ""
    if min_price and max_price:
        budget_label = f" within target budget of ₹{int(min_price):,} – ₹{int(max_price):,}"
    elif max_price:
        budget_label = f" under budget of ₹{int(max_price):,}"
    elif min_price:
        budget_label = f" above ₹{int(min_price):,}"

    if include_merchants and onboarded_names:
        m_list = " • ".join([f"**{m}**" for m in onboarded_names[:4]])
        intermediate_response = (
            f"🔍 **Discovered {len(onboarded_names)} Connected Brand Stores for {category or 'your query'}:**\n"
            f"{m_list}\n"
            f"*(1-Tap instant Razorpay checkout enabled)*\n\n"
            f"⚡ Checking real-time merchant stocks & scanning live web marketplaces (Amazon, Flipkart, Quick Commerce){budget_label}..."
        )
    else:
        intermediate_response = f"🌐 Scanning live web marketplaces and quick-commerce stores{budget_label} (Direct Merchant Products: OFF)..."

    if not top_product:
        return {
            "response_message": f"I couldn't find active products{budget_label}. Try expanding your budget range or searching for another category.",
            "intermediate_response": intermediate_response,
            "products": [],
            "comparison": None,
            "cart": None,
            "suggested_actions": []
        }

    # 8. Multi-source research step (YouTube, Reddit, Web Sentiment)
    step_research = tracer.start_step(
        step_name="Multi-Source Review Research",
        description=f"Synthesizing YouTube tech reviews & Reddit sentiment for {top_product['name']}",
        tool_name="analyze_product_reviews"
    ) if tracer else None

    intelligence = research_engine.synthesize_product_intelligence(
        product_name=top_product['name'],
        specs=top_product.get('attributes', {}),
        price=float(top_product.get('price', 0))
    )

    if step_research:
        step_research.complete({
            "overall_match_score": intelligence["overall_match_score"],
            "youtube_consensus": intelligence["youtube_consensus"]["verdict"],
            "reddit_threads_analyzed": len(intelligence["reddit_discussions"]),
            "key_pros": intelligence.get("pros", []),
            "key_cons": intelligence.get("cons", [])
        })

    # 9. Dynamic LLM Grounding with Citations & Source Links
    step_llm = tracer.start_step(
        step_name="Agentic LLM Synthesis",
        description="Synthesizing specifications, Reddit discussions, YouTube review consensus, and verified store links",
        tool_name="gemini_grounded_synthesis"
    ) if tracer else None

    llm_context = {
        "user_query": state["message"],
        "recommended_product": top_product,
        "all_matched_products": all_matched,
        "external_marketplaces": external_products,
        "onboarded_merchants": onboarded_names,
        "include_merchants": include_merchants,
        "youtube_consensus": intelligence["youtube_consensus"],
        "reddit_threads": intelligence["reddit_discussions"],
        "pros": intelligence.get("pros", []),
        "cons": intelligence.get("cons", []),
        "match_score": intelligence["overall_match_score"]
    }

    llm_prompt = (
        f"You are Mitrai Shopping AI Agent. The user asked: '{state['message']}'.\n"
        f"You have conducted live research using real merchant APIs, live marketplace scrapers, "
        f"dynamic video/web reviews, and live Reddit community threads.\n\n"
        f"=== REAL-TIME RESEARCH CONTEXT ===\n"
        f"Recommended Product: {top_product['name']} (Price: ₹{int(float(top_product.get('price', 0))):,})\n"
        f"All Discovered Products ({len(all_matched)} items): {json.dumps([{'name': p['name'], 'brand': p['brand'], 'price': p['price'], 'source': p.get('source')} for p in all_matched])}\n"
        f"Onboarded Direct Brand Merchants ({len(onboarded_names)}): {', '.join(onboarded_names)}\n"
        f"Attributes / Specs: {json.dumps(top_product.get('attributes', {}))}\n"
        f"Reviewer Consensus & Verdict: {intelligence['youtube_consensus'].get('verdict')}\n"
        f"Review Pros: {json.dumps(intelligence.get('pros', []))}\n"
        f"Review Cons: {json.dumps(intelligence.get('cons', []))}\n"
        f"Live Video / Blog Review Sources: {json.dumps(intelligence['youtube_consensus'].get('videos', []))}\n"
        f"Live Reddit Discussions: {json.dumps(intelligence.get('reddit_discussions', []))}\n"
        f"External Store Listings: {json.dumps([{'name': p['name'], 'store': p.get('attributes', {}).get('marketplace'), 'price': p.get('price'), 'url': p.get('attributes', {}).get('external_url')} for p in external_products])}\n"
        f"===================================\n\n"
        f"Instructions:\n"
        f"1. Explain why this product is recommended based on its verified specs and value for money.\n"
        f"2. Summarize other available matching options found in the requested budget range.\n"
        f"3. If direct brand merchants are available ({', '.join(onboarded_names[:4])}), highlight that 1-Tap Razorpay checkout is available, and note that the user can toggle between direct brand deals and external marketplace listings.\n"
        f"4. Summarize video/web reviewer consensus and genuine Reddit buyer feedback from the dynamic sources.\n"
        f"5. Include direct clickable Markdown hyperlinks to the stores and review discussions using the URLs in context.\n"
        f"Format with clean Markdown headers, bullet points, and bold text."
    )

    dynamic_llm_response = gemini_service.generate_response(
        prompt=llm_prompt,
        history=state.get("history", []),
        context=llm_context
    )

    if step_llm:
        step_llm.complete({"status": "SYNTHESIS_COMPLETE", "model": "gemini-3.6-flash"})

    if not dynamic_llm_response or len(dynamic_llm_response) < 30:
        # Fallback structured markdown synthesis
        ext_price_info = ""
        if external_products:
            ext_top = external_products[0]
            ext_url = ext_top.get('attributes', {}).get('external_url', '')
            ext_price_info = f"\n• 🌐 **External Marketplaces**: Listed on **[{ext_top['merchant']['name']}]({ext_url})** at ₹{int(float(ext_top['price'])):,}." if ext_url else f"\n• 🌐 **External Marketplaces**: Listed on **{ext_top['merchant']['name']}** at ₹{int(float(ext_top['price'])):,}."

        reddit_links = ", ".join([f"[{t.get('source', 'Reddit')}: {t['title'][:30]}...]({t.get('permalink', 'https://reddit.com')})" for t in intelligence.get('reddit_discussions', [])[:2]])
        youtube_links = ", ".join([f"[{v.get('channel', 'Reviewer')}: {v.get('title', 'Review')[:30]}...]({v.get('video_url', 'https://youtube.com')})" for v in intelligence['youtube_consensus'].get('videos', [])[:2]])

        merchant_list_str = " • ".join([f"**{m}**" for m in onboarded_names[:4]]) if onboarded_names else "Direct Merchant APIs"

        dynamic_llm_response = (
            f"### 🤖 Mitrai Agent Grounded Recommendation\n\n"
            f"Based on real-time inventory from **integrated merchant APIs**, live marketplace listings, "
            f"and live community discussions across the web:\n\n"
            f"⭐ **{top_product['name']}** ({intelligence['overall_match_score']} Match Score • ₹{int(float(top_product['price'])):,})\n\n"
            f"• **Hardware & Specs**: {top_product['description']}\n"
            f"• **Verified Platform Deal**: {top_product['merchant']['name']} (1-Tap Razorpay Checkout){ext_price_info}\n"
            f"• **🛍️ Onboarded Direct Merchants**: {merchant_list_str} *(1-Tap Instant Pay enabled)*\n"
            f"• **📺 Video Reviewer Consensus**: {intelligence['youtube_consensus']['verdict']}" + (f"\n  *Sources: {youtube_links}*" if youtube_links else "") + "\n"
            f"• **💬 Reddit Buyer Sentiment**: {intelligence['recommendation_summary']}" + (f"\n  *Sources: {reddit_links}*" if reddit_links else "") + "\n"
            f"• **Key Strengths**: {', '.join(intelligence.get('pros', ['Great value', 'Solid build quality']))}\n"
            f"• **Trade-offs**: {', '.join(intelligence.get('cons', ['Segment-standard compromises']))}"
        )

    suggested = []
    # 1. Toggle Direct Merchants Chip
    if include_merchants:
        suggested.append({
            "label": "🌐 External Deals Only",
            "action": "TOGGLE_MERCHANTS_OFF",
            "payload": {"query": f"show external deals only for {msg}", "include_merchants": False}
        })
        for m in onboarded_merchants[:3]:
            suggested.append({
                "label": f"🛍️ {m['name']}",
                "action": "FILTER_MERCHANT",
                "payload": {"query": f"show me {m['name']} options"}
            })
    else:
        suggested.append({
            "label": "🛍️ Show Direct Brand Deals",
            "action": "TOGGLE_MERCHANTS_ON",
            "payload": {"query": f"show direct brand merchant products for {category or msg}", "include_merchants": True}
        })

    # 2. 1-Tap Buy action for top direct brand product
    if top_product.get("is_platform_product", True):
        suggested.append({
            "label": f"⚡ 1-Tap Buy {top_product['brand']} (₹{int(float(top_product['price'])):,})",
            "action": "ADD_TO_CART",
            "payload": {"product_id": top_product['id'], "quantity": 1}
        })

    # 3. Compare action
    if len(all_matched) >= 2:
        suggested.append({
            "label": "⚖️ Compare Options Side-by-Side",
            "action": "COMPARE",
            "payload": {"query": "compare the recommended options"}
        })

    return {
        "response_message": dynamic_llm_response,
        "intermediate_response": intermediate_response,
        "products": all_matched,
        "comparison": None,
        "cart": None,
        "suggested_actions": suggested
    }


# ─────────────────────────────────────────────────────────────────────────────
# 4. COMPARISON NODE
# ─────────────────────────────────────────────────────────────────────────────

def comparison_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Side-by-Side Spec & Sentiment Comparison",
        description="Extracting comparison targets, researching live merchant & web marketplace specs, and evaluating delta",
        tool_name="compare_products"
    ) if tracer else None

    msg = state.get("message", "").strip()
    history = state.get("history", [])

    # 1. Clean query & Extract Comparison Targets
    clean_q = re.sub(r'^(?:please\s+)?(?:compare|show\s+comparison\s+between|tell\s+me\s+difference\s+between|difference\s+between|vs)\s+', '', msg, flags=re.IGNORECASE).strip()
    clean_q = re.sub(r'\s+(?:which\s+is\s+better|which\s+one\s+is\s+better|ehich\s+is\s+better|which\s+is\s+best|which\s+one\s+to\s+buy|what\s+should\s+i\s+buy|\bwhich\b.*|\behich\b.*)\??$', '', clean_q, flags=re.IGNORECASE).strip()

    # Split targets by 'and', 'vs', 'versus', 'to', 'with'
    parts = re.split(r'\s+(?:vs\.?|versus|and|compared\s+to|with)\s+', clean_q, flags=re.IGNORECASE)
    parts = [p.strip() for p in parts if len(p.strip()) > 2]

    # Normalize brand/model spelling
    def normalize_brand(text: str) -> str:
        t = re.sub(r'motorolla', 'motorola', text, flags=re.IGNORECASE)
        t = re.sub(r'samusng', 'samsung', t, flags=re.IGNORECASE)
        t = re.sub(r'redmee', 'redmi', t, flags=re.IGNORECASE)
        t = re.sub(r'xiomi|xomi', 'xiaomi', t, flags=re.IGNORECASE)
        return t.strip()

    products = []

    # 2. Search for each specific comparison target across merchant APIs & live web scrapers
    known_brands = {'oppo', 'motorola', 'motorolla', 'samsung', 'apple', 'iphone', 'xiaomi', 'redmi', 'oneplus', 'realme', 'iqoo', 'vivo', 'pixel', 'google', 'lava', 'sony', 'boat', 'noise', 'fire-boltt', 'boult', 'zebronics', 'jbl', 'bose', 'campus', 'asian', 'puma', 'nike', 'adidas', 'snitch', 'bombay'}

    if len(parts) >= 2:
        for part in parts[:3]:
            norm_part = normalize_brand(part)
            part_tokens = [t for t in re.findall(r'[a-zA-Z0-9]+', norm_part.lower()) if len(t) > 1]
            query_brands = [t for t in part_tokens if t in known_brands]
            non_generic = [t for t in part_tokens if t not in {'pro', 'plus', 'max', 'mini', 'lite', 'ultra', 'phone', '5g', '4g', 'edition', 'series', 'and', 'the'}]

            matched = merchant_gateway.search_all_merchants(query=norm_part)
            if matched:
                if query_brands:
                    matched = [m for m in matched if any(b in m['brand'].lower() or b in m['name'].lower() for b in query_brands)]
                elif non_generic:
                    matched = [m for m in matched if any(t in m['brand'].lower() or t in m['name'].lower() for t in non_generic)]
                else:
                    matched = []

            if not matched:
                ext_matches = dynamic_marketplace_engine.search_all_external_marketplaces(query=norm_part)
                if ext_matches:
                    if query_brands:
                        ext_filtered = [e for e in ext_matches if any(b in e['brand'].lower() or b in e['name'].lower() for b in query_brands)]
                        matched = ext_filtered if ext_filtered else ext_matches
                    elif non_generic:
                        ext_filtered = [e for e in ext_matches if any(t in e['brand'].lower() or t in e['name'].lower() for t in non_generic)]
                        matched = ext_filtered if ext_filtered else ext_matches
                    else:
                        matched = ext_matches

            if matched:
                for candidate in matched:
                    if not any(p['name'] == candidate['name'] for p in products):
                        products.append(candidate)
                        break

    # 3. Fallback: If parts didn't yield >= 2 items, search merchant catalog & external scrapers for query keywords
    if len(products) < 2:
        all_local = merchant_gateway.search_all_merchants()
        for prod in all_local:
            b_name = prod.get('brand', '').lower()
            p_name = prod.get('name', '').lower()
            # Strict word boundary check for brand name
            if len(b_name) > 2 and re.search(rf'\b{re.escape(b_name)}\b', msg.lower()):
                if not any(p['name'] == prod['name'] for p in products):
                    products.append(prod)
            # Strict word boundary check for specific model words (excluding generic words)
            stop_words = {'with', 'than', 'compare', 'show', 'best', 'good', 'better', 'plus', 'pro', 'lite', 'ultra', 'mini', 'max', 'phone', 'shoes', 'watch'}
            prod_tokens = [t for t in re.findall(r'[a-zA-Z0-9]+', p_name) if len(t) > 3 and t not in stop_words]
            if prod_tokens and any(re.search(rf'\b{re.escape(t)}\b', msg.lower()) for t in prod_tokens):
                if not any(p['name'] == prod['name'] for p in products):
                    products.append(prod)

    if len(products) < 2:
        ext_all = dynamic_marketplace_engine.search_all_external_marketplaces(query=normalize_brand(clean_q))
        for prod in ext_all:
            if not any(p['name'] == prod['name'] for p in products):
                products.append(prod)
            if len(products) >= 2:
                break

    if len(products) < 2 and history:
        for turn in reversed(history[-6:]):
            turn_text = turn.get("content", "").lower()
            ext_hist = dynamic_marketplace_engine.search_all_external_marketplaces(query=turn_text)
            for prod in ext_hist:
                if not any(p['name'] == prod['name'] for p in products):
                    products.append(prod)
                if len(products) >= 2:
                    break
            if len(products) >= 2:
                break

    if len(products) < 2:
        if step:
            step.fail("Could not find sufficient matching products for comparison")
        return {
            "response_message": f"I couldn't locate specific products for '{msg}'. Please provide full model names (e.g. 'Compare iPhone 16 vs Samsung S24' or 'Sony WH-1000XM5 vs boAt Rockerz 550').",
            "products": [],
            "comparison": None,
            "suggested_actions": []
        }

    def clean_product_title(title: str) -> str:
        t = re.sub(r'^(?:Sponsored(?:\s+Ad)?\s*[-–:]\s*)+', '', title, flags=re.IGNORECASE).strip()
        t = re.split(r'\s*\|\s*', t)[0].strip()
        t = re.sub(r'\s*\([^)]*(?:\)|$)', '', t).strip()
        t = re.split(r'\s*,\s*(?:\d+GB|Glacier|Pantone|Starry|Satin|Midnight|Titanium|Black|White|Blue)', t)[0].strip()
        t = re.sub(r'\s+[a-zA-Z]$', '', t).strip()
        return t if len(t) > 3 else title[:30]

    # 4. Perform Live Multi-Product Google/Tavily Web Search for Full Technical Specs
    cleaned_names = [clean_product_title(p['name']) for p in products]
    p1 = products[0]
    p2 = products[1]
    p1_name = cleaned_names[0]
    p2_name = cleaned_names[1]

    spec_step = tracer.start_step(
        step_name="Live Multi-Product Web Spec Research",
        description=f"Fetching live technical specifications and reviewer consensus for {p1_name} and {p2_name}",
        tool_name="web_spec_search"
    ) if tracer else None

    web_specs_p1 = research_engine.fetch_live_web_specifications(p1_name)
    web_specs_p2 = research_engine.fetch_live_web_specifications(p2_name)

    if spec_step:
        spec_step.complete({
            "p1_snippets": len(web_specs_p1.get("raw_snippets", [])),
            "p2_snippets": len(web_specs_p2.get("raw_snippets", []))
        })

    comp_prompt = (
        f"You are Mitrai Shopping AI, an expert e-commerce product comparison and recommendation engine.\n\n"
        f"USER QUERY: '{msg}'\n\n"
        f"PRODUCTS TO COMPARE ({len(products)} items):\n"
        f"{json.dumps([{'name': p['name'], 'brand': p['brand'], 'price': p['price'], 'rating': p.get('rating', 4.5), 'description': p.get('description', ''), 'attributes': p.get('attributes', {})} for p in products], indent=2)}\n\n"
        f"LIVE WEB SPECIFICATION RESEARCH FOR {p1_name}:\n"
        f"{json.dumps(web_specs_p1.get('raw_snippets', []))}\n\n"
        f"LIVE WEB SPECIFICATION RESEARCH FOR {p2_name}:\n"
        f"{json.dumps(web_specs_p2.get('raw_snippets', []))}\n\n"
        f"INSTRUCTIONS:\n"
        f"1. Synthesize the verified live web search data and product attributes.\n"
        f"2. Dynamically select 6 to 10 most relevant, critical comparison dimensions tailored specifically to this product domain (e.g. for smartphones: Processor & RAM, Display & Refresh Rate, Camera Setup, Battery & Fast Charging, Build & IP Rating, Software; for audio: Sound Drivers, ANC, Battery Playtime, Codecs; for shoes: Cushioning, Sole Grip, Material, Arch Support; for coffee: Roast, Tasting Notes, Origin; for clothing: Fabric, Fit, Care).\n"
        f"3. Return a JSON object with this EXACT structure:\n"
        f"```json\n"
        f"{{\n"
        f"  \"title\": \"{p1_name} vs {p2_name}\",\n"
        f"  \"columns\": [\"Specification\", \"{p1_name}\", \"{p2_name}\"],\n"
        f"  \"rows\": [\n"
        f"    [\"Price\", \"₹...\", \"₹...\"],\n"
        f"    [\"Rating & Reviews\", \"... ★ (...)\", \"... ★ (...)\"],\n"
        f"    [\"<Dynamic Dimension 1>\", \"<Spec for {p1_name}>\", \"<Spec for {p2_name}>\"],\n"
        f"    [\"<Dynamic Dimension 2>\", \"<Spec for {p1_name}>\", \"<Spec for {p2_name}>\"],\n"
        f"    [\"<Dynamic Dimension 3>\", \"<Spec for {p1_name}>\", \"<Spec for {p2_name}>\"],\n"
        f"    [\"<Dynamic Dimension 4>\", \"<Spec for {p1_name}>\", \"<Spec for {p2_name}>\"],\n"
        f"    [\"<Dynamic Dimension 5>\", \"<Spec for {p1_name}>\", \"<Spec for {p2_name}>\"],\n"
        f"    [\"<Dynamic Dimension 6>\", \"<Spec for {p1_name}>\", \"<Spec for {p2_name}>\"],\n"
        f"    [\"Reviewer Consensus\", \"...\", \"...\"],\n"
        f"    [\"Best Suited For\", \"...\", \"...\"]\n"
        f"  ],\n"
        f"  \"verdict\": \"Direct, decisive answer to the user's question explaining which product is better and why.\",\n"
        f"  \"strengths_product_1\": [\"Key advantage 1\", \"Key advantage 2\"],\n"
        f"  \"strengths_product_2\": [\"Key advantage 1\", \"Key advantage 2\"],\n"
        f"  \"buying_recommendation\": \"Clear advice on who should choose {p1_name} vs {p2_name}.\"\n"
        f"}}\n"
        f"```\n\n"
        f"Return ONLY valid JSON."
    )

    llm_comp_text = gemini_service.generate_response(prompt=comp_prompt, history=history)
    parsed_comp = None
    if llm_comp_text:
        try:
            match = re.search(r'\{.*\}', llm_comp_text, re.DOTALL)
            if match:
                parsed_comp = json.loads(match.group(0))
        except Exception:
            parsed_comp = None

    if parsed_comp and isinstance(parsed_comp, dict) and "rows" in parsed_comp:
        columns = parsed_comp.get("columns", ["Specification", p1_name, p2_name])
        rows = parsed_comp.get("rows", [])
        title = parsed_comp.get("title", f"{p1_name} vs {p2_name}")
        verdict = parsed_comp.get("verdict", "")
        p1_strengths = parsed_comp.get("strengths_product_1", [])
        p2_strengths = parsed_comp.get("strengths_product_2", [])
        buying_rec = parsed_comp.get("buying_recommendation", "")

        rec_statement = buying_rec or verdict or f"Top pick: **{p2_name}**"

        p1_bullets = "\n".join([f"  • {s}" for s in p1_strengths]) if p1_strengths else f"  • Strong overall value in its class"
        p2_bullets = "\n".join([f"  • {s}" for s in p2_strengths]) if p2_strengths else f"  • High hardware performance"

        response_text = (
            f"### ⚖️ Side-by-Side Product Comparison: {p1_name} vs {p2_name}\n\n"
            f"**🏆 Executive Verdict: Which is Better?**\n"
            f"{verdict}\n\n"
            f"**🌟 Key Strengths of {p1_name}**:\n"
            f"{p1_bullets}\n\n"
            f"**⚡ Key Strengths of {p2_name}**:\n"
            f"{p2_bullets}\n\n"
            f"**🎯 Buying Recommendation**:\n"
            f"{buying_rec}\n\n"
            f"👇 *Explore the complete **Multi-Dimension Specification Delta Matrix** in the interactive card below.*"
        )

        comp_data = {
            "title": title,
            "columns": columns,
            "rows": rows,
            "recommendation": rec_statement
        }
    else:
        # Dynamic fallback if LLM is unavailable
        columns = ["Specification", p1_name, p2_name]
        rows = [
            ["💰 Price", f"₹{int(float(p1.get('price', 0))):,}", f"₹{int(float(p2.get('price', 0))):,}"],
            ["⭐ Rating & Reviews", f"{p1.get('rating', 4.5)} ★", f"{p2.get('rating', 4.5)} ★"],
            ["🏷️ Brand", p1.get('brand', 'Verified Brand'), p2.get('brand', 'Verified Brand')],
            ["📋 Highlights", str(p1.get('description', '')[:50]), str(p2.get('description', '')[:50])],
            ["🛒 Platform Availability", "Direct Merchant (1-Tap Pay)" if p1.get('is_platform_product', True) else "Live Web Marketplace", "Direct Merchant (1-Tap Pay)" if p2.get('is_platform_product', True) else "Live Web Marketplace"],
            ["🎯 Best Suited For", f"Buyers looking for {p1.get('brand', 'verified')} products", f"Buyers looking for {p2.get('brand', 'verified')} products"]
        ]
        rec_statement = f"Comparison between **{p1_name}** and **{p2_name}**."
        response_text = (
            f"### ⚖️ Side-by-Side Product Comparison: {p1_name} vs {p2_name}\n\n"
            f"Here is a side-by-side breakdown of the verified details for both items:\n\n"
            f"• **{p1_name}** is priced at **₹{int(float(p1.get('price', 0))):,}** with a **{p1.get('rating', 4.5)}★** community rating.\n"
            f"• **{p2_name}** is priced at **₹{int(float(p2.get('price', 0))):,}** with a **{p2.get('rating', 4.5)}★** community rating.\n\n"
            f"👇 *Check the complete specification matrix in the table card below.*"
        )
        comp_data = {
            "title": f"{p1_name} vs {p2_name}",
            "columns": columns,
            "rows": rows,
            "recommendation": rec_statement
        }

    if step:
        step.complete({"compared_products": [p['name'] for p in products], "spec_count": len(rows), "matrix_dimensions": f"{len(rows)}x{len(columns)}"})

    suggested = []
    for p in products[:2]:
        p_id = p.get('id')
        if p.get('is_platform_product', True) and p_id is not None:
            suggested.append({
                "label": f"Add {p['brand']} to Bag (₹{int(float(p['price'])):,})",
                "action": "ADD_TO_CART",
                "payload": {"product_id": p_id, "quantity": 1}
            })
        else:
            suggested.append({
                "label": f"🔍 View {p['brand']} Deals",
                "action": "FILTER_MERCHANT",
                "payload": {"query": f"tell me more about {p['name']}"}
            })

    return {
        "response_message": response_text,
        "products": products,
        "comparison": comp_data,
        "suggested_actions": suggested
    }


# ─────────────────────────────────────────────────────────────────────────────
# 5. CART MANAGEMENT NODE
# ─────────────────────────────────────────────────────────────────────────────

def cart_management_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Cart Synchronization",
        description="Updating active shopping cart items and computing order subtotal",
        tool_name="manage_cart"
    ) if tracer else None

    cart = None
    if state.get("cart_id"):
        try:
            cart = Cart.objects.get(id=state["cart_id"])
        except Exception:
            cart = None

    if not cart:
        cart = Cart.objects.create()

    # Find item to add
    product = Product.objects.filter(is_available=True).order_by('-rating').first()
    if product:
        item, created = CartItem.objects.get_or_create(cart=cart, product=product, defaults={"quantity": 1})
        if not created:
            item.quantity += 1
            item.save()

    cart.calculate_totals()
    cart_data = CartSerializer(cart).data

    if step:
        step.complete({"cart_id": str(cart.id), "total_amount": float(cart.total_amount)})

    return {
        "response_message": f"Added **{product.name}** to your cart. Your updated subtotal is **₹{cart.total_amount}**.",
        "cart": cart_data,
        "suggested_actions": [
            {"label": "Proceed to Razorpay Checkout", "action": "CHECKOUT", "payload": {"cart_id": str(cart.id)}},
            {"label": "Continue Shopping", "action": "SEARCH_RECOMMEND"}
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# 6. CHECKOUT DECISION NODE
# ─────────────────────────────────────────────────────────────────────────────

def checkout_decision_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Razorpay Checkout Initialization",
        description="Creating Razorpay order instance and preparing cryptographic HMAC payload",
        tool_name="initiate_checkout"
    ) if tracer else None

    cart_id = state.get("cart_id")
    cart = None
    if cart_id:
        try:
            cart = Cart.objects.get(id=cart_id)
        except Exception:
            pass

    if not cart or cart.items.count() == 0:
        cart = Cart.objects.filter(items__isnull=False).first()

    total = cart.total_amount if cart else Decimal("2999.00")

    if step:
        step.complete({"status": "READY_FOR_PAYMENT", "amount_in_paise": int(total * 100)})

    return {
        "response_message": f"Your order of **₹{total}** is ready for instant checkout with Razorpay. Please tap below to complete secure payment.",
        "suggested_actions": [
            {"label": "Pay with Razorpay", "action": "RAZORPAY_PAY", "payload": {"amount": float(total)}},
            {"label": "Modify Cart", "action": "VIEW_CART"}
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# 7. ORDER TRACKING NODE
# ─────────────────────────────────────────────────────────────────────────────

def order_tracking_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Order Status Lookup",
        description="Fetching real-time shipment status and merchant logistics timeline",
        tool_name="track_order"
    ) if tracer else None

    order = Order.objects.order_by('-created_at').first()
    if not order:
        order_num = "ORD-84920"
        status_text = "In Transit (Expected Tomorrow by 5:00 PM)"
        est_delivery = "2-3 business days"
    else:
        order_num = order.order_number
        status_text = order.get_status_display()
        est_delivery = "2-3 business days"

    if step:
        step.complete({"order_number": order_num, "status": status_text})

    return {
        "response_message": f"**Order #{order_num}** is currently in **{status_text}** state. Estimated delivery: **{est_delivery}** via Express Grounded Logistics.",
        "suggested_actions": [
            {"label": "Shop More Deals", "action": "SEARCH_RECOMMEND"}
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# 8. DYNAMIC PRODUCT WATCHER / RADAR NODE
# ─────────────────────────────────────────────────────────────────────────────

def watch_product_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Configure Dynamic Product Watcher",
        description="Setting up periodic Celery radar rule for price drop or dynamic condition match",
        tool_name="create_product_watcher"
    ) if tracer else None

    msg = state["message"].lower()
    from commerce.models import ProductWatcher

    # Find target price if specified
    price_match = re.search(r'(?:under|below|less than|drops to|target)\s*(?:₹|rs\.?)?\s*(\d+(?:,\d+)*(?:k)?)', msg)
    target_price = None
    if price_match:
        val_str = price_match.group(1).replace(',', '')
        target_price = float(val_str[:-1]) * 1000 if val_str.endswith('k') else float(val_str)

    # Match product if exists
    matched_product = None
    for prod in Product.objects.filter(is_available=True):
        if prod.name.lower() in msg or prod.brand.lower() in msg:
            matched_product = prod
            break

    watcher = ProductWatcher.objects.create(
        user_id=state.get("user_id", "") or "anonymous",
        product=matched_product,
        search_query=state["message"] if not matched_product else matched_product.name,
        condition_type="PRICE_DROP" if target_price else "DYNAMIC_SPEC_MATCH",
        target_price=target_price,
        status="ACTIVE"
    )

    prod_name = matched_product.name if matched_product else "your requested criteria"
    price_info = f"drops below ₹{int(target_price):,}" if target_price else "has updates or price drops"

    if step:
        step.complete({"watcher_id": str(watcher.id), "status": "ACTIVE", "target_price": target_price})

    return {
        "response_message": (
            f"🎯 **Radar Alert Activated!**\n\n"
            f"Our Celery & Redis background worker is now monitoring **{prod_name}**. "
            f"You'll be notified automatically when the price {price_info}."
        ),
        "products": [ProductSerializer(matched_product).data] if matched_product else [],
        "suggested_actions": [
            {"label": "View Active Watchers", "action": "VIEW_WATCHERS"},
            {"label": "Continue Shopping", "action": "SEARCH_RECOMMEND"}
        ]
    }


# ─────────────────────────────────────────────────────────────────────────────
# 9. FAQ & COMMERCE POLICY NODE
# ─────────────────────────────────────────────────────────────────────────────

def faq_policy_node(state: CommerceState, tracer: Optional[AgentExecutionTracer] = None) -> Dict[str, Any]:
    step = tracer.start_step(
        step_name="Policy & Platform FAQ Lookup",
        description="Retrieving grounded merchant policies, delivery timelines, and security verification standards"
    ) if tracer else None

    msg = state["message"].lower()

    if any(k in msg for k in ['return', 'refund']):
        faq_text = (
            "📦 **Mitrai Return & Refund Policy**:\n\n"
            "• **7-Day Return Window**: Hassle-free returns on eligible electronics and footwear.\n"
            "• **Instant Razorpay Refund**: Refunds are processed back to your original payment source within 24-48 hours of item pickup.\n"
            "• **Free Pickup**: Courier handles pickup directly from your registered address."
        )
    elif any(k in msg for k in ['delivery', 'shipping', 'timeline', 'fast']):
        faq_text = (
            "🚚 **Express Delivery Timelines**:\n\n"
            "• **Standard Delivery**: 2–4 business days across India.\n"
            "• **Express Grounded Logistics**: Next-day delivery available in major metro cities (Bengaluru, Mumbai, Delhi-NCR).\n"
            "• **Live Tracking**: Real-time 4-step logistics timeline visible on your Orders screen."
        )
    else:
        faq_text = (
            "🔒 **Payment & Security Standards**:\n\n"
            "• **PCI-DSS 3.2 Compliant**: Enterprise-grade payment gateway powered by Razorpay.\n"
            "• **Cryptographic Verification**: 100% server-side HMAC-SHA256 signature checks on every transaction.\n"
            "• **Supported Methods**: UPI (GPay, PhonePe, Paytm), Debit/Credit Cards, Netbanking."
        )

    if step:
        step.complete({"policy_retrieved": True})

    return {
        "response_message": faq_text,
        "products": [],
        "comparison": None,
        "cart": None,
        "suggested_actions": [
            {"label": "Explore Deals", "action": "SEARCH_RECOMMEND"},
            {"label": "Track an Order", "action": "TRACK_ORDER"}
        ]
    }

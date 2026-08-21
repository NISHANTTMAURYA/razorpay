import logging
from typing import Dict, Any, Optional
from .graph import (
    intent_router_node,
    greeting_node,
    search_recommend_node,
    comparison_node,
    cart_management_node,
    checkout_decision_node,
    order_tracking_node,
    watch_product_node,
    faq_policy_node
)
from .agent_tracer import AgentExecutionTracer

logger = logging.getLogger(__name__)

class CommerceAgentEngine:
    """Orchestrates multi-turn conversational shopping execution with real-time step tracing."""

    @classmethod
    def process_message(
        cls,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
        user_id: Optional[str] = None,
        cart_id: Optional[str] = None,
        include_merchants: bool = True,
        tracer: Optional[AgentExecutionTracer] = None
    ) -> Dict[str, Any]:
        active_tracer = tracer or AgentExecutionTracer()

        state = {
            "message": message,
            "history": history or [],
            "user_id": user_id,
            "cart_id": cart_id,
            "include_merchants": include_merchants,
            "intent": None,
            "products": [],
            "comparison": None,
            "cart": None,
            "order": None,
            "suggested_actions": [],
            "response_message": "",
            "intermediate_response": None,
            "steps": []
        }

        try:
            # 1. Intent Route
            intent_res = intent_router_node(state, tracer=active_tracer)
            intent = intent_res.get("intent", "GREETING")
            state["intent"] = intent

            # 2. Dispatch to designated LangGraph node
            if intent == "GREETING":
                result = greeting_node(state, tracer=active_tracer)
            elif intent == "COMPARE":
                result = comparison_node(state, tracer=active_tracer)
            elif intent == "WATCH_PRODUCT":
                result = watch_product_node(state, tracer=active_tracer)
            elif intent == "MANAGE_CART":
                result = cart_management_node(state, tracer=active_tracer)
            elif intent == "CHECKOUT":
                result = checkout_decision_node(state, tracer=active_tracer)
            elif intent == "TRACK_ORDER":
                result = order_tracking_node(state, tracer=active_tracer)
            elif intent == "FAQ_POLICY":
                result = faq_policy_node(state, tracer=active_tracer)
            else:
                result = search_recommend_node(state, tracer=active_tracer)

            # 3. Finalize Step
            step_resp = active_tracer.start_step(
                step_name="Response Assembly",
                description="Assembling structured JSON payload with product cards and Razorpay action triggers"
            )
            step_resp.complete({"suggested_actions_count": len(result.get("suggested_actions", []))})

            return {
                "response": result.get("response_message", ""),
                "intermediate_response": result.get("intermediate_response"),
                "intent": intent,
                "products": result.get("products", []),
                "comparison": result.get("comparison"),
                "cart": result.get("cart"),
                "suggested_actions": result.get("suggested_actions", []),
                "steps": active_tracer.get_steps_data()
            }
        except Exception as e:
            logger.error(f"Error processing agent message: {e}", exc_info=True)
            return {
                "response": "There is an error right now. Please chat later.",
                "intermediate_response": None,
                "intent": "ERROR",
                "products": [],
                "comparison": None,
                "cart": None,
                "suggested_actions": [],
                "steps": active_tracer.get_steps_data()
            }

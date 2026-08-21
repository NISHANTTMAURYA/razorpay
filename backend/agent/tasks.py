import logging
from celery import shared_task
from commerce.models import WatchNotification
from .services import CommerceAgentEngine

logger = logging.getLogger(__name__)

@shared_task(name='agent.tasks.process_agent_background_query_task')
def process_agent_background_query_task(message: str, user_id: str = None, cart_id: str = None, history: list = None):
    """
    Asynchronous Celery task that executes full LangGraph agent multi-turn loop,
    Tavily live search, merchant API routing, and creates an in-app WatchNotification
    when completed so the user is notified even if they leave the screen or close the app.
    """
    logger.info(f"[Celery Agent Task] Starting background query for user {user_id}: '{message}'")

    try:
        result = CommerceAgentEngine.process_message(
            message=message,
            history=history or [],
            user_id=user_id,
            cart_id=cart_id
        )

        # Truncate summary for notification banner
        agent_msg = result.get("message", "Here are your recommendations.")
        clean_summary = agent_msg.split('\n')[0] if '\n' in agent_msg else agent_msg
        if len(clean_summary) > 120:
            clean_summary = clean_summary[:117] + "..."

        # Create persistent database notification
        notification = WatchNotification.objects.create(
            title=f"⚡ Mitrai AI: '{message[:35]}' Ready",
            message=clean_summary,
            payload={
                "task_type": "AI_AGENT_BACKGROUND_RESEARCH",
                "query": message,
                "response": result.get("message"),
                "products": result.get("products", []),
                "action": result.get("action"),
                "intent": result.get("intent"),
                "steps": result.get("steps", [])
            }
        )

        logger.info(f"[Celery Agent Task] Completed successfully. Notification #{notification.id} created.")
        return {
            "status": "SUCCESS",
            "notification_id": str(notification.id),
            "result": result
        }

    except Exception as e:
        logger.error(f"[Celery Agent Task] Failed: {e}", exc_info=True)
        WatchNotification.objects.create(
            title=f"⚡ Mitrai AI Update",
            message=f"We completed research for '{message[:35]}'. Tap to view results.",
            payload={"error": str(e), "query": message}
        )
        return {"status": "FAILED", "error": str(e)}

import json
import time
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.http import StreamingHttpResponse
from .services import CommerceAgentEngine
from .agent_tracer import AgentExecutionTracer
from .tasks import process_agent_background_query_task

class AgentBackgroundChatView(APIView):
    """
    POST /api/agent/background-chat/
    Dispatches Celery background worker task to process multi-turn query and generate notification.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        message = request.data.get("message", "")
        if not message:
            return Response({"error": "Message is required"}, status=status.HTTP_400_BAD_REQUEST)

        history = request.data.get("history", [])
        cart_id = request.data.get("cart_id")
        user_id = request.data.get("user_id") or (str(request.user.id) if request.user.is_authenticated else "user_shopper_01")

        # Launch Celery background task
        async_task = process_agent_background_query_task.delay(
            message=message,
            user_id=user_id,
            cart_id=cart_id,
            history=history
        )

        return Response({
            "status": "QUEUED_IN_BACKGROUND",
            "task_id": async_task.id,
            "message": "Mitrai AI is researching across integrated brand APIs and live marketplaces in the background via Celery. You will receive a notification when results are ready."
        }, status=status.HTTP_202_ACCEPTED)

class AgentChatView(APIView):
    """
    POST /api/agent/chat/
    Executes LangGraph agent reasoning and returns response along with full execution step trace.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        message = request.data.get("message", "")
        if not message:
            return Response({"error": "Message is required"}, status=status.HTTP_400_BAD_REQUEST)

        history = request.data.get("history", [])
        cart_id = request.data.get("cart_id")
        include_merchants = request.data.get("include_merchants", True)
        user_id = str(request.user.id) if request.user.is_authenticated else None

        result = CommerceAgentEngine.process_message(
            message=message,
            history=history,
            user_id=user_id,
            cart_id=cart_id,
            include_merchants=include_merchants
        )

        return Response(result, status=status.HTTP_200_OK)


class AgentStreamChatView(APIView):
    """
    POST /api/agent/stream/
    Server-Sent Events (SSE) endpoint streaming real-time agent execution steps as they occur.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        message = request.data.get("message", "")
        if not message:
            return Response({"error": "Message is required"}, status=status.HTTP_400_BAD_REQUEST)

        history = request.data.get("history", [])
        cart_id = request.data.get("cart_id")
        include_merchants = request.data.get("include_merchants", True)
        user_id = str(request.user.id) if request.user.is_authenticated else None

        import queue
        import threading

        event_queue = queue.Queue()

        def on_step_callback(event_data):
            event_queue.put(event_data)

        def worker():
            try:
                tracer = AgentExecutionTracer(callback=on_step_callback)
                result = CommerceAgentEngine.process_message(
                    message=message,
                    history=history,
                    user_id=user_id,
                    cart_id=cart_id,
                    include_merchants=include_merchants,
                    tracer=tracer
                )
                event_queue.put({"event": "FINAL_RESPONSE", "payload": result})
            except Exception as e:
                event_queue.put({"event": "ERROR", "error": str(e)})
            finally:
                event_queue.put(None)  # Sentinel to end stream

        # Launch worker in background thread
        t = threading.Thread(target=worker)
        t.start()

        def event_stream():
            yield f"data: {json.dumps({'event': 'CONNECTED', 'message': 'Agent initialized'})}\n\n"

            while True:
                try:
                    item = event_queue.get(timeout=35)
                    if item is None:
                        break
                    yield f"data: {json.dumps(item)}\n\n"
                except queue.Empty:
                    break

            yield "data: [DONE]\n\n"

        response = StreamingHttpResponse(event_stream(), content_type="text/event-stream")
        response['Cache-Control'] = 'no-cache'
        response['X-Accel-Buffering'] = 'no'
        return response

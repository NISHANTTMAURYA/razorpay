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
            "message": "Mitrai AI is researching across 24 direct brands and live marketplaces in the background via Celery. You will receive a notification when results are ready."
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
        user_id = str(request.user.id) if request.user.is_authenticated else None

        result = CommerceAgentEngine.process_message(
            message=message,
            history=history,
            user_id=user_id,
            cart_id=cart_id
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

        cart_id = request.data.get("cart_id")
        user_id = str(request.user.id) if request.user.is_authenticated else None

        def event_stream():
            tracer = AgentExecutionTracer()

            # Yield initial connect event
            yield f"data: {json.dumps({'event': 'CONNECTED', 'message': 'Agent initialized'})}\n\n"

            # Execute with active tracer
            result = CommerceAgentEngine.process_message(
                message=message,
                user_id=user_id,
                cart_id=cart_id,
                tracer=tracer
            )

            # Stream each executed step
            for step in result.get("steps", []):
                yield f"data: {json.dumps({'event': 'STEP_UPDATE', 'step': step})}\n\n"
                time.sleep(0.05)

            # Stream final payload
            yield f"data: {json.dumps({'event': 'FINAL_RESPONSE', 'payload': result})}\n\n"
            yield "data: [DONE]\n\n"

        response = StreamingHttpResponse(event_stream(), content_type="text/event-stream")
        response['Cache-Control'] = 'no-cache'
        response['X-Accel-Buffering'] = 'no'
        return response

import json
import time
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
from django.http import StreamingHttpResponse
from .services import CommerceAgentEngine
from .agent_tracer import AgentExecutionTracer

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

        cart_id = request.data.get("cart_id")
        user_id = str(request.user.id) if request.user.is_authenticated else None

        result = CommerceAgentEngine.process_message(
            message=message,
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

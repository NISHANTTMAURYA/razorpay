from django.urls import path
from .views import AgentChatView, AgentStreamChatView

urlpatterns = [
    path('chat/', AgentChatView.as_view(), name='agent_chat'),
    path('stream/', AgentStreamChatView.as_view(), name='agent_stream_chat'),
]

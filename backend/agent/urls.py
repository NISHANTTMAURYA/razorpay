from django.urls import path
from .views import AgentChatView, AgentStreamChatView, AgentBackgroundChatView

urlpatterns = [
    path('chat/', AgentChatView.as_view(), name='agent_chat'),
    path('stream/', AgentStreamChatView.as_view(), name='agent_stream_chat'),
    path('background-chat/', AgentBackgroundChatView.as_view(), name='agent_background_chat'),
]

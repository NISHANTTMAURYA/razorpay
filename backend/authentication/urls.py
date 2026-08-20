from django.urls import path
from .views import SyncSupabaseUserView, UserProfileView

urlpatterns = [
    path('sync-supabase/', SyncSupabaseUserView.as_view(), name='sync-supabase'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
]

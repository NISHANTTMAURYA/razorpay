import uuid
from django.db import models
from django.contrib.auth.models import User

class UserProfile(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile', null=True, blank=True)
    supabase_uid = models.CharField(max_length=128, unique=True, db_index=True)
    email = models.EmailField(blank=True)
    full_name = models.CharField(max_length=255, blank=True)
    avatar_url = models.URLField(max_length=1024, blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True)
    delivery_address = models.TextField(blank=True, default='')
    
    # Geolocation & Permissions
    latitude = models.FloatField(null=True, blank=True)
    longitude = models.FloatField(null=True, blank=True)
    city = models.CharField(max_length=100, blank=True, default='')
    state = models.CharField(max_length=100, blank=True, default='')
    pincode = models.CharField(max_length=20, blank=True, default='')
    location_permission_granted = models.BooleanField(default=False)
    notifications_enabled = models.BooleanField(default=False)
    
    # Personalization preferences
    preferred_categories = models.JSONField(default=list, blank=True)
    preferred_brands = models.JSONField(default=list, blank=True)
    typical_budget = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)
    recent_searches = models.JSONField(default=list, blank=True)
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.full_name or self.email} ({self.supabase_uid[:8]})"

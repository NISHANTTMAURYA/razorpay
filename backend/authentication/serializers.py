from rest_framework import serializers
from .models import UserProfile

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            'id', 'supabase_uid', 'email', 'full_name', 'avatar_url', 'phone', 'delivery_address',
            'latitude', 'longitude', 'city', 'state', 'pincode',
            'location_permission_granted', 'notifications_enabled',
            'preferred_categories', 'preferred_brands', 'typical_budget', 'recent_searches',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

class SyncUserSerializer(serializers.Serializer):
    supabase_uid = serializers.CharField(max_length=128, required=False)
    email = serializers.EmailField()
    full_name = serializers.CharField(max_length=255, required=False, allow_blank=True)
    avatar_url = serializers.URLField(required=False, allow_blank=True, allow_null=True)
    phone = serializers.CharField(max_length=20, required=False, allow_blank=True)
    delivery_address = serializers.CharField(required=False, allow_blank=True)
    latitude = serializers.FloatField(required=False, allow_null=True)
    longitude = serializers.FloatField(required=False, allow_null=True)
    city = serializers.CharField(max_length=100, required=False, allow_blank=True)
    state = serializers.CharField(max_length=100, required=False, allow_blank=True)
    pincode = serializers.CharField(max_length=20, required=False, allow_blank=True)
    location_permission_granted = serializers.BooleanField(required=False)
    notifications_enabled = serializers.BooleanField(required=False)

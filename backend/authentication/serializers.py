from rest_framework import serializers
from .models import UserProfile

class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = [
            'id', 'supabase_uid', 'email', 'full_name', 'avatar_url', 'phone',
            'preferred_categories', 'preferred_brands', 'typical_budget', 'recent_searches',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']

class SyncUserSerializer(serializers.Serializer):
    supabase_uid = serializers.CharField(max_length=128, required=False)
    email = serializers.EmailField()
    full_name = serializers.CharField(max_length=255, required=False, allow_blank=True)
    avatar_url = serializers.URLField(required=False, allow_blank=True, allow_null=True)

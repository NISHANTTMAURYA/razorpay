from rest_framework import status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from .models import UserProfile
from .serializers import UserProfileSerializer, SyncUserSerializer

class SyncSupabaseUserView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = SyncUserSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        data = serializer.validated_data
        supabase_uid = data.get('supabase_uid')
        
        # If user is authenticated via Supabase header, grab sub
        if request.user and request.user.is_authenticated and hasattr(request.user, 'profile'):
            profile = request.user.profile
            profile.email = data.get('email', profile.email)
            profile.full_name = data.get('full_name', profile.full_name)
            if data.get('avatar_url'):
                profile.avatar_url = data.get('avatar_url')
            profile.save()
            return Response({
                'status': 'success',
                'user': UserProfileSerializer(profile).data
            })

        if not supabase_uid:
            supabase_uid = f"guest_{data['email'].split('@')[0]}"

        defaults = {
            'email': data['email'],
            'full_name': data.get('full_name', ''),
            'avatar_url': data.get('avatar_url', ''),
        }
        if data.get('phone'):
            defaults['phone'] = data['phone']
        if data.get('delivery_address'):
            defaults['delivery_address'] = data['delivery_address']

        profile, created = UserProfile.objects.update_or_create(
            supabase_uid=supabase_uid,
            defaults=defaults
        )

        return Response({
            'status': 'success',
            'created': created,
            'user': UserProfileSerializer(profile).data
        })

class UserProfileView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        if request.user and request.user.is_authenticated and hasattr(request.user, 'profile'):
            return Response(UserProfileSerializer(request.user.profile).data)
        
        uid = request.query_params.get('uid', 'demo_user')
        profile, _ = UserProfile.objects.get_or_create(
            supabase_uid=uid,
            defaults={
                'email': 'shopper@mitrai.ai',
                'full_name': 'Mitrai Explorer',
                'typical_budget': 5000.00,
                'preferred_categories': ['Smartphones', 'Audio', 'Footwear']
            }
        )
        return Response(UserProfileSerializer(profile).data)

    def patch(self, request):
        uid = request.data.get('supabase_uid') or request.query_params.get('uid', 'demo_user')
        profile, _ = UserProfile.objects.get_or_create(supabase_uid=uid)

        for field in [
            'full_name', 'email', 'phone', 'avatar_url', 'delivery_address',
            'latitude', 'longitude', 'city', 'state', 'pincode',
            'location_permission_granted', 'notifications_enabled',
            'typical_budget', 'preferred_categories', 'preferred_brands'
        ]:
            if field in request.data:
                setattr(profile, field, request.data[field])
        profile.save()
        return Response(UserProfileSerializer(profile).data)

    def post(self, request):
        return self.patch(request)

import jwt
from django.conf import settings
from django.contrib.auth.models import User
from rest_framework import authentication, exceptions
from .models import UserProfile

class SupabaseAuthentication(authentication.BaseAuthentication):
    """
    Custom DRF Authentication class for Supabase Auth JWTs.
    Validates token and automatically creates/retrieves Django User and UserProfile.
    """
    def authenticate(self, request):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return None

        parts = auth_header.split()
        if len(parts) != 2 or parts[0].lower() != 'bearer':
            return None

        token = parts[1]

        try:
            # Decode token (unverified for development/mock fallback or verified with SUPABASE_JWT_SECRET)
            jwt_secret = getattr(settings, 'SUPABASE_JWT_SECRET', '')
            
            if jwt_secret and jwt_secret != 'supabase_jwt_secret_placeholder':
                payload = jwt.decode(token, jwt_secret, algorithms=['HS256'], audience='authenticated')
            else:
                # Permissive decoding for local dev/testing
                payload = jwt.decode(token, options={"verify_signature": False})
                
            sub = payload.get('sub')
            if not sub:
                raise exceptions.AuthenticationFailed('Invalid Supabase token payload: missing sub')

            email = payload.get('email', '')
            user_metadata = payload.get('user_metadata', {})
            full_name = user_metadata.get('full_name') or user_metadata.get('name') or email.split('@')[0]
            avatar_url = user_metadata.get('avatar_url') or user_metadata.get('picture')

            # Get or create User
            user, _ = User.objects.get_or_create(
                username=f"sb_{sub[:30]}",
                defaults={'email': email, 'first_name': full_name[:30]}
            )

            # Get or create UserProfile
            profile, _ = UserProfile.objects.get_or_create(
                supabase_uid=sub,
                defaults={
                    'user': user,
                    'email': email,
                    'full_name': full_name,
                    'avatar_url': avatar_url
                }
            )

            return (user, token)

        except jwt.PyJWTError as e:
            # Fallback for mock client tokens during development
            if token.startswith("mock_token_"):
                mock_uid = token.replace("mock_token_", "")
                user, _ = User.objects.get_or_create(
                    username=f"mock_{mock_uid[:20]}",
                    defaults={'email': f"{mock_uid}@example.com"}
                )
                profile, _ = UserProfile.objects.get_or_create(
                    supabase_uid=mock_uid,
                    defaults={'user': user, 'email': f"{mock_uid}@example.com", 'full_name': "Demo User"}
                )
                return (user, token)
            raise exceptions.AuthenticationFailed(f'Invalid token: {str(e)}')

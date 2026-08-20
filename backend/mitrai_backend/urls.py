from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse

def api_health(request):
    return JsonResponse({
        'name': 'Mitrai AI Commerce API',
        'status': 'healthy',
        'version': '1.0.0',
        'sprint': 'Razorpay AI Sprint 2026',
        'endpoints': {
            'auth': '/api/auth/',
            'commerce': '/api/commerce/',
            'agent': '/api/agent/'
        }
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', api_health, name='api-health'),
    path('api/health/', api_health, name='api-health-check'),
    path('api/auth/', include('authentication.urls')),
    path('api/commerce/', include('commerce.urls')),
    path('api/agent/', include('agent.urls')),
]

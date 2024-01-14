from django.utils.deprecation import MiddlewareMixin
import jwt
from django.conf import settings
from django.http import JsonResponse


class JWTAuthenticationMiddleware(MiddlewareMixin):
    def process_request(self, request):
        token = request.META.get('HTTP_AUTHORIZATION')
        if not token:
            return JsonResponse({'error': 'No token provided'}, status=401)
        try:
            token = token.split(' ')[1]  # Assumes the token is prefixed with 'Bearer'
            payload = jwt.decode(token, settings.JWT_PUBLIC_KEY, algorithms=['RS256'])
            request.user = payload  # Add the payload to the request object
        except jwt.ExpiredSignatureError:
            return JsonResponse({'error': 'Token expired'}, status=401)
        except jwt.InvalidTokenError:
            return JsonResponse({'error': 'Invalid token'}, status=401)

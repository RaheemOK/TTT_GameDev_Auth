from django.contrib.auth import authenticate, get_user_model
from django.http import HttpResponse
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import AllowAny
from .serializers import UserRegistrationSerializer, UserLoginSerializer
from rest_framework_simplejwt.tokens import RefreshToken
import requests

User = get_user_model()


class RegisterUserView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        serializer = UserRegistrationSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()  # Save the user and get the instance

            # Notify the Tournament Structure service
            try:
                response = requests.post(
                    'http://127.0.0.1:8000/api/create-user/',
                    json={'auth_user_id': user.id}
                )
                if response.status_code != 201:
                    # Handle unsuccessful user creation in the Tournament service
                    # Log the error or take other actions as needed
                    pass
            except requests.RequestException as e:
                # Log this exception or take necessary actions
                pass

            return Response(serializer.data, status=201)
        return Response(serializer.errors, status=400)


class LoginUserView(APIView):

    def post(self, request, *args, **kwargs):
        serializer = UserLoginSerializer(data=request.data)
        if serializer.is_valid():
            # Retrieve user data from serializer
            email = serializer.validated_data['email']

            # Fetch user instance from the database
            try:
                user = User.objects.get(email=email)
            except User.DoesNotExist:
                return Response({'error': 'User not found'}, status=404)

            # Generate tokens for the user
            refresh = RefreshToken.for_user(user)

            # Set refresh token in HTTP-only cookie
            response = Response()
            response.set_cookie(key='refreshtoken', value=str(refresh), httponly=True)
            response.data = {
                'access': str(refresh.access_token)
            }

            return response
        return Response(serializer.errors, status=400)


class LogoutView(APIView):
    permission_classes = [AllowAny]

    def post(self, request, *args, **kwargs):
        response = HttpResponse("Logged out")
        response.delete_cookie('refreshtoken')  # The name of your refresh token cookie
        return response

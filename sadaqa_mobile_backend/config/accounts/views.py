from django.contrib.auth import get_user_model, authenticate
from django.conf import settings
from django.contrib.auth.hashers import make_password
from django.utils.decorators import method_decorator

from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny, IsAuthenticated

from rest_framework_simplejwt.tokens import RefreshToken

from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests
import requests

# ✅ django-ratelimit
from django_ratelimit.decorators import ratelimit

from .serializers import RegisterSerializer, UserSerializer, MeSerializer
from .models import EmailVerificationToken, PasswordResetToken
from .utils import send_verification_email, send_password_reset_email

User = get_user_model()


# =========================
# ✅ Helper: key by email (from JSON request.data)
# =========================
def email_key(group, request):
    try:
        email = (request.data.get("email") or "").strip().lower()
    except Exception:
        email = ""
    return email or "no-email"


# =========================
# ✅ Register
# =========================
@method_decorator(
    ratelimit(key="ip", rate="10/m", method="POST", block=True),
    name="dispatch",
)
class RegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()

            updates = []
            if hasattr(user, "is_email_verified"):
                user.is_email_verified = False
                updates.append("is_email_verified")
            if hasattr(user, "is_active"):
                user.is_active = False
                updates.append("is_active")
            if updates:
                user.save(update_fields=updates)

            token_obj = EmailVerificationToken.objects.create(user=user)
            send_verification_email(user, str(token_obj.token))

            return Response(
                {
                    "detail": "Account created. Verification email sent.",
                    "user": UserSerializer(user).data,
                },
                status=status.HTTP_201_CREATED,
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# =========================
# ✅ Verify Email
# =========================
@method_decorator(
    ratelimit(key="ip", rate="30/m", method="GET", block=True),
    name="dispatch",
)
class VerifyEmailView(APIView):
    permission_classes = [AllowAny]

    def get(self, request, token):
        try:
            token_obj = EmailVerificationToken.objects.select_related("user").get(
                token=token
            )
        except EmailVerificationToken.DoesNotExist:
            return Response(
                {"detail": "Invalid or expired token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = token_obj.user
        updates = []
        if hasattr(user, "is_email_verified"):
            user.is_email_verified = True
            updates.append("is_email_verified")
        if hasattr(user, "is_active"):
            user.is_active = True
            updates.append("is_active")
        if updates:
            user.save(update_fields=updates)

        token_obj.delete()
        return Response(
            {"detail": "Email verified successfully. You can login now."},
            status=status.HTTP_200_OK,
        )


# =========================
# ✅ Me
# =========================
class MeView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        return Response(MeSerializer(request.user).data)


# =========================
# ✅ Login (JWT)  🔐 3 attempts فقط
# =========================
@method_decorator(
    ratelimit(key="ip", rate="3/m", method="POST", block=True),
    name="dispatch",
)
@method_decorator(
    ratelimit(key=email_key, rate="3/m", method="POST", block=True),
    name="dispatch",
)
class LoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = (request.data.get("email") or "").strip().lower()
        password = (request.data.get("password") or "").strip()

        if not email or not password:
            return Response(
                {"detail": "Email et mot de passe requis."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = authenticate(request, email=email, password=password)
        if not user:
            return Response(
                {"detail": "Email ou mot de passe incorrect."},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        if hasattr(user, "is_active") and not user.is_active:
            return Response(
                {"detail": "Compte non activé."},
                status=status.HTTP_403_FORBIDDEN,
            )

        refresh = RefreshToken.for_user(user)
        return Response(
            {"access": str(refresh.access_token), "refresh": str(refresh)},
            status=status.HTTP_200_OK,
        )


# =========================
# ✅ Google Login
# =========================
@method_decorator(
    ratelimit(key="ip", rate="20/m", method="POST", block=True),
    name="dispatch",
)
class GoogleLoginView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        google_token = request.data.get("id_token") or request.data.get("access_token")
        if not google_token:
            return Response(
                {"detail": "id_token أو access_token مطلوب."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        try:
            client_id = getattr(settings, "GOOGLE_CLIENT_ID", "")

            try:
                idinfo = google_id_token.verify_oauth2_token(
                    google_token, google_requests.Request(), client_id
                )
            except Exception:
                resp = requests.get(
                    "https://www.googleapis.com/oauth2/v3/userinfo",
                    headers={"Authorization": f"Bearer {google_token}"},
                    timeout=10,
                )
                if resp.status_code != 200:
                    raise Exception("Google token invalid")
                idinfo = resp.json()

            email = (idinfo.get("email") or "").strip().lower()
            first_name = idinfo.get("given_name", "")
            last_name = idinfo.get("family_name", "")

            if not email:
                return Response({"detail": "Email Google introuvable."}, status=400)

            user, _ = User.objects.get_or_create(
                email=email,
                defaults={"username": email, "first_name": first_name, "last_name": last_name},
            )

            updates = []
            if hasattr(user, "is_email_verified") and not user.is_email_verified:
                user.is_email_verified = True
                updates.append("is_email_verified")
            if hasattr(user, "is_active") and not user.is_active:
                user.is_active = True
                updates.append("is_active")
            if updates:
                user.save(update_fields=updates)

            refresh = RefreshToken.for_user(user)
            return Response(
                {"access": str(refresh.access_token), "refresh": str(refresh)},
                status=200,
            )

        except Exception as e:
            return Response({"detail": "توكن Google غير صالح.", "error": str(e)}, status=400)


# =========================
# ✅ Forgot Password  🔐 3 attempts فقط
# =========================
@method_decorator(
    ratelimit(key="ip", rate="3/m", method="POST", block=True),
    name="dispatch",
)
@method_decorator(
    ratelimit(key=email_key, rate="3/m", method="POST", block=True),
    name="dispatch",
)
class ForgotPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        email = (request.data.get("email") or "").strip().lower()
        if not email:
            return Response({"detail": "Email requis."}, status=status.HTTP_400_BAD_REQUEST)

        # ✅ لا نكشف إن الإيميل موجود أم لا
        user = User.objects.filter(email__iexact=email).first()
        if not user:
            return Response({"detail": "Si l'adresse existe, un e-mail a été envoyé."}, status=status.HTTP_200_OK)

        PasswordResetToken.objects.filter(user=user, is_used=False).update(is_used=True)

        token_obj = PasswordResetToken.objects.create(user=user)
        send_password_reset_email(user, str(token_obj.token))

        return Response({"detail": "Si l'adresse existe, un e-mail a été envoyé."}, status=status.HTTP_200_OK)


# =========================
# ✅ Reset Password  🔐 3 attempts فقط
# =========================
@method_decorator(
    ratelimit(key="ip", rate="3/m", method="POST", block=True),
    name="dispatch",
)
class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        token = (request.data.get("token") or "").strip()
        new_password = (request.data.get("new_password") or "").strip()
        confirm_password = (request.data.get("confirm_password") or "").strip()

        if not token or not new_password or not confirm_password:
            return Response({"detail": "Token et mot de passe requis."}, status=status.HTTP_400_BAD_REQUEST)

        if new_password != confirm_password:
            return Response({"detail": "Les mots de passe ne correspondent pas."}, status=status.HTTP_400_BAD_REQUEST)

        if len(new_password) < 6:
            return Response({"detail": "Mot de passe trop court (min 6 caractères)."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            token_obj = PasswordResetToken.objects.select_related("user").get(token=token)
        except PasswordResetToken.DoesNotExist:
            return Response({"detail": "Token invalide."}, status=status.HTTP_400_BAD_REQUEST)

        if token_obj.is_used:
            return Response({"detail": "Token déjà utilisé."}, status=status.HTTP_400_BAD_REQUEST)

        if token_obj.is_expired():
            return Response({"detail": "Token expiré."}, status=status.HTTP_400_BAD_REQUEST)

        user = token_obj.user
        user.password = make_password(new_password)
        user.save(update_fields=["password"])

        token_obj.is_used = True
        token_obj.save(update_fields=["is_used"])

        return Response({"detail": "Mot de passe réinitialisé avec succès ✅"}, status=status.HTTP_200_OK)

# config/accounts/urls.py
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterView,
    VerifyEmailView,
    LoginView,          # ✅ NEW
    MeView,
    GoogleLoginView,
    ForgotPasswordView,
    ResetPasswordView,
)

urlpatterns = [
    # Auth
    path("register/", RegisterView.as_view(), name="register"),
    path("verify-email/<uuid:token>/", VerifyEmailView.as_view(), name="verify-email"),

    # 🔐 Login (محمي بـ 3 محاولات)
    path("login/", LoginView.as_view(), name="login"),

    # JWT Refresh فقط
    path("token/refresh/", TokenRefreshView.as_view(), name="token_refresh"),

    # Profile
    path("me/", MeView.as_view(), name="me"),

    # Social login
    path("google-login/", GoogleLoginView.as_view(), name="google-login"),

    # Password reset
    path("forgot-password/", ForgotPasswordView.as_view(), name="forgot-password"),
    path("reset-password/", ResetPasswordView.as_view(), name="reset-password"),
]

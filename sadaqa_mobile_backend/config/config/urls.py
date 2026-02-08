from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path("admin/", admin.site.urls),

    # Auth
    path("api/auth/", include("accounts.urls")),

    # Campaigns
    path("api/", include("campaigns.urls")),   # مرة واحدة فقط ✅

    # Donations + Payments
    path("api/", include("donations.urls")),

    # Organizations
    path("api/", include("organizations.urls")),

    # Volunteers ✅ (مهم)
    path("api/volunteers/", include("volunteers.urls")),
]

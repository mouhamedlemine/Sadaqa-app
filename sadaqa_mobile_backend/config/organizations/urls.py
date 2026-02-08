from django.urls import path
from .views import (
    OrgRegisterView,
    MyOrgProfileView,
    SubmitOrgForReviewView,
    AdminPendingOrgsView,
    AdminReviewOrgView,
)

urlpatterns = [
    # ✅ org register
    path("register/", OrgRegisterView.as_view(), name="org-register"),

    # ✅ org profile + status
    path("me/", MyOrgProfileView.as_view(), name="org-me"),

    # ✅ submit for admin review
    path("submit/", SubmitOrgForReviewView.as_view(), name="org-submit"),

    # ✅ admin endpoints
    path("admin/pending/", AdminPendingOrgsView.as_view(), name="admin-orgs-pending"),
    path("admin/review/<int:org_id>/", AdminReviewOrgView.as_view(), name="admin-orgs-review"),
]

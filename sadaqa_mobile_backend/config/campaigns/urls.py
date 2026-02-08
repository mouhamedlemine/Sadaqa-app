# campaigns/urls.py
from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    PublicCampaignViewSet,
    PublicOrganizationViewSet,
    MyCampaignViewSet,
    MyOrganizationViewSet,
)

router = DefaultRouter()
router.register(r"public/campaigns", PublicCampaignViewSet, basename="public-campaigns")
router.register(r"public/organizations", PublicOrganizationViewSet, basename="public-organizations")
router.register(r"my/campaigns", MyCampaignViewSet, basename="my-campaigns")
router.register(r"my/organization", MyOrganizationViewSet, basename="my-organization")

urlpatterns = [
    path("", include(router.urls)),
]

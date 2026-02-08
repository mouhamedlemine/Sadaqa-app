# campaigns/views.py
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response

from .models import Campaign, Organization
from .serializers import CampaignSerializer, OrganizationSerializer

# ✅ استيراد OrganizationProfile من تطبيق organizations
# (غيّر المسار إذا كان اسم الموديل/الملف مختلف عندك)
from organizations.models import OrganizationProfile


# =========================
# الحملات العامة (للعرض فقط)
# ✅ للجميع: فقط APPROVED
# =========================
class PublicCampaignViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = CampaignSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = (
            Campaign.objects
            .select_related("owner", "organization")
            .filter(status=Campaign.Status.APPROVED, is_active=True)
        )

        source = self.request.query_params.get("source", "normal").lower()

        if source == "org":
            qs = qs.filter(organization__isnull=False)   # حملات المنظمات فقط
        elif source == "all":
            pass                                         # كل الحملات
        else:
            qs = qs.filter(organization__isnull=True)    # الحملات العامة فقط

        return qs.order_by("-created_at")


# =========================
# المنظمات الموثقة (للعرض)
# =========================
class PublicOrganizationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = OrganizationSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        return Organization.objects.filter(is_verified=True).order_by("-created_at")


# =========================
# منظمة المستخدم (إنشاء/عرض/تعديل)
# =========================
class MyOrganizationViewSet(viewsets.ModelViewSet):
    serializer_class = OrganizationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Organization.objects.filter(owner=self.request.user).order_by("-created_at")

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)

    @action(detail=False, methods=["post"])
    def submit(self, request):
        org = Organization.objects.filter(owner=request.user).first()
        if not org:
            return Response({"detail": "لا توجد منظمة لهذا المستخدم"}, status=404)
        org.save()
        return Response({"detail": "تم الإرسال للمراجعة ✅"}, status=200)


# =========================
# حملاتي (إنشاء / تعديل)
# ✅ المستخدم يرى حملاته حتى لو PENDING / REJECTED
# =========================
class MyCampaignViewSet(viewsets.ModelViewSet):
    serializer_class = CampaignSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Campaign.objects.filter(owner=self.request.user).order_by("-created_at")

    def _get_or_create_campaigns_org_from_profile(self):
        """
        ✅ لو المستخدم عنده OrganizationProfile Approved
        ننشئ/نحدّث Organization داخل campaigns ثم نستخدمها كـ FK
        """
        profile = OrganizationProfile.objects.filter(user=self.request.user).first()
        if not profile:
            return None

        # ✅ شرط الاعتماد (غيّر النص إذا عندك status مختلف)
        if str(getattr(profile, "status", "")).lower() != "approved":
            return None

        # ✅ أنشئ Organization في campaigns إذا لم تكن موجودة
        org, created = Organization.objects.get_or_create(
            owner=self.request.user,
            defaults={
                "name": getattr(profile, "name", "") or "Organization",
                "description": getattr(profile, "description", "") or "",
                "phone": getattr(profile, "phone", "") or "",
                "address": getattr(profile, "address", "") or "",
                "website": getattr(profile, "website", "") or "",
                "is_verified": True,  # لأن profile Approved
            },
        )

        # ✅ إذا كانت موجودة حدثها حتى تبقى متزامنة مع profile
        changed = False
        new_name = getattr(profile, "name", "") or org.name
        if org.name != new_name:
            org.name = new_name
            changed = True

        for field in ["description", "phone", "address", "website"]:
            v = getattr(profile, field, "")
            if v is None:
                v = ""
            if getattr(org, field) != v:
                setattr(org, field, v)
                changed = True

        if org.is_verified is not True:
            org.is_verified = True
            changed = True

        if changed:
            org.save()

        return org

    def perform_create(self, serializer):
        # ✅ إن كانت منظمة Approved في organizations → اربطها
        org = self._get_or_create_campaigns_org_from_profile()

        serializer.save(
            owner=self.request.user,
            organization=org,                 # ✅ الآن لن تكون null للمنظمة Approved
            status=Campaign.Status.PENDING,   # كل الحملات تحتاج موافقة
            is_active=True,
            rejection_reason="",
            approved_by=None,
            approved_at=None,
        )

    @action(detail=True, methods=["post"])
    def close(self, request, pk=None):
        campaign = self.get_object()
        campaign.is_active = False
        campaign.save(update_fields=["is_active"])
        return Response({"detail": "Campaign closed"}, status=status.HTTP_200_OK)

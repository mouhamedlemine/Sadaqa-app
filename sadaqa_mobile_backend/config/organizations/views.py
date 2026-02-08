from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny, IsAuthenticated

from .models import OrganizationProfile
from .serializers import (
    OrgRegisterSerializer,
    OrganizationProfileSerializer,
    AdminReviewSerializer
)

# ✅ تسجيل منظمة
class OrgRegisterView(APIView):
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = OrgRegisterSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        return Response({"detail": "Organization registered", "user_id": user.id}, status=status.HTTP_201_CREATED)


# ✅ جلب بروفايل المنظمة الحالية + الحالة
class MyOrgProfileView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        org = OrganizationProfile.objects.filter(user=request.user).first()
        if not org:
            return Response({"detail": "No organization profile"}, status=404)
        return Response(OrganizationProfileSerializer(org).data)


# ✅ إرسال المنظمة للمراجعة (أو إعادة الإرسال بعد الرفض)
class SubmitOrgForReviewView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        org = OrganizationProfile.objects.filter(user=request.user).first()
        if not org:
            return Response({"detail": "No organization profile"}, status=404)

        # شرط اختياري: وجود وثيقة
        # if not org.document:
        #     return Response({"detail": "Document required"}, status=400)

        # إذا كانت Approved لا داعي للإرسال
        if org.status == OrganizationProfile.Status.APPROVED:
            return Response({"detail": "Already approved"}, status=400)

        org.status = OrganizationProfile.Status.PENDING
        org.rejection_reason = ""
        org.submitted_at = timezone.now()
        org.save()

        return Response({"detail": "Submitted for review", "status": org.status})


# ✅ للأدمن: عرض المنظمات Pending
class AdminPendingOrgsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(status=403)

        qs = OrganizationProfile.objects.filter(
            status=OrganizationProfile.Status.PENDING
        ).order_by("-submitted_at", "-created_at")

        return Response(OrganizationProfileSerializer(qs, many=True).data)


# ✅ للأدمن: Approve / Reject
class AdminReviewOrgView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, org_id: int):
        if not (request.user.is_staff or request.user.is_superuser):
            return Response(status=403)

        org = OrganizationProfile.objects.filter(id=org_id).first()
        if not org:
            return Response({"detail": "Not found"}, status=404)

        serializer = AdminReviewSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        action = serializer.validated_data["action"]
        reason = serializer.validated_data.get("reason", "")

        # لا مراجعة إذا لم تكن Pending
        if org.status != OrganizationProfile.Status.PENDING:
            return Response({"detail": "Organization is not pending"}, status=400)

        if action == "approve":
            org.status = OrganizationProfile.Status.APPROVED
            org.rejection_reason = ""
        else:
            org.status = OrganizationProfile.Status.REJECTED
            org.rejection_reason = reason

        org.reviewed_at = timezone.now()
        org.save()

        return Response({"detail": "Done", "status": org.status})

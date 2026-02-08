from decimal import Decimal
from django.conf import settings
from django.db import transaction
import stripe

from rest_framework import viewsets, permissions
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.exceptions import ValidationError, NotFound

from .models import Campaign, Donation
from .serializers import (
    CampaignSerializer,
    DonationSerializer,
    CreateIntentSerializer,
    ConfirmIntentSerializer,
)

stripe.api_key = settings.STRIPE_SECRET_KEY


class IsOwnerOrReadOnly(permissions.BasePermission):
    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        return getattr(obj, "owner", None) == request.user


class CampaignViewSet(viewsets.ModelViewSet):
    queryset = Campaign.objects.all().order_by("-created_at")
    serializer_class = CampaignSerializer
    permission_classes = [IsOwnerOrReadOnly]

    def perform_create(self, serializer):
        serializer.save(owner=self.request.user)


class DonationViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = DonationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Donation.objects.filter(donor=self.request.user).order_by("-created_at")


class CreatePaymentIntentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        if not settings.STRIPE_SECRET_KEY:
            return Response({"detail": "Stripe secret key غير مضبوط"}, status=500)

        ser = CreateIntentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        campaign_id = ser.validated_data["campaign_id"]
        amount = Decimal(str(ser.validated_data["amount"]))

        if amount <= 0:
            raise ValidationError({"amount": "المبلغ يجب أن يكون أكبر من 0."})

        try:
            campaign = Campaign.objects.get(id=campaign_id)
        except Campaign.DoesNotExist:
            raise NotFound("الحملة غير موجودة.")

        if not campaign.is_active:
            raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

        remaining = campaign.goal_amount - campaign.collected_amount
        if amount > remaining:
            raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

        amount_cents = int(amount * 100)

        intent = stripe.PaymentIntent.create(
            amount=amount_cents,
            currency=getattr(settings, "STRIPE_CURRENCY", "usd"),
            automatic_payment_methods={"enabled": True},
            metadata={
                "campaign_id": str(campaign_id),
                "user_id": str(request.user.id),
                "amount": str(amount),
            },
        )

        return Response({
            "client_secret": intent["client_secret"],
            "payment_intent_id": intent["id"],
        }, status=200)


class ConfirmPaymentView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        ser = ConfirmIntentSerializer(data=request.data)
        ser.is_valid(raise_exception=True)

        campaign_id = ser.validated_data["campaign_id"]
        payment_intent_id = ser.validated_data["payment_intent_id"]

        try:
            campaign = Campaign.objects.get(id=campaign_id)
        except Campaign.DoesNotExist:
            raise NotFound("الحملة غير موجودة.")

        # ✅ لا تكرر نفس الدفع مرتين
        if Donation.objects.filter(payment_intent_id=payment_intent_id).exists():
            donation = Donation.objects.get(payment_intent_id=payment_intent_id)
            return Response(DonationSerializer(donation).data, status=200)

        intent = stripe.PaymentIntent.retrieve(payment_intent_id)

        if intent["status"] != "succeeded":
            raise ValidationError({"payment": f"الدفع ليس ناجحًا بعد. status={intent['status']}"})

        # ✅ مهم: amount_received قد يكون 0 في بعض الحالات، لذلك استخدم fallback
        cents = intent.get("amount_received") or intent.get("amount") or 0
        amount = Decimal(cents) / Decimal("100")

        meta_campaign_id = intent.get("metadata", {}).get("campaign_id")
        if meta_campaign_id and int(meta_campaign_id) != int(campaign_id):
            raise ValidationError({"campaign": "PaymentIntent لا يطابق هذه الحملة."})

        if not campaign.is_active:
            raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

        remaining = campaign.goal_amount - campaign.collected_amount
        if amount > remaining:
            raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

        with transaction.atomic():
            campaign_locked = Campaign.objects.select_for_update().get(id=campaign.id)

            donation = Donation.objects.create(
                campaign=campaign_locked,
                donor=request.user,
                amount=amount,
                payment_intent_id=payment_intent_id,
                status="SUCCEEDED",
            )

            campaign_locked.collected_amount = campaign_locked.collected_amount + amount

            if campaign_locked.collected_amount >= campaign_locked.goal_amount:
                campaign_locked.is_active = False

            campaign_locked.save(update_fields=["collected_amount", "is_active"])

        return Response(DonationSerializer(donation).data, status=201)

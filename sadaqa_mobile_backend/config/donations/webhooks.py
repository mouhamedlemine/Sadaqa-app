import stripe
from decimal import Decimal, ROUND_HALF_UP

from django.conf import settings
from django.db import transaction
from django.views.decorators.csrf import csrf_exempt

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from campaigns.models import Campaign
from donations.models import Donation


stripe.api_key = settings.STRIPE_SECRET_KEY


def _to_decimal_money(cents: int) -> Decimal:
    return (Decimal(cents) / Decimal("100")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


@csrf_exempt
@api_view(["POST"])
@permission_classes([AllowAny])
def stripe_webhook(request):
    payload = request.body
    sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
    endpoint_secret = getattr(settings, "STRIPE_WEBHOOK_SECRET", "")

    if not endpoint_secret:
        return Response({"detail": "STRIPE_WEBHOOK_SECRET غير مضبوط"}, status=500)

    try:
        event = stripe.Webhook.construct_event(
            payload=payload,
            sig_header=sig_header,
            secret=endpoint_secret,
        )
    except ValueError:
        return Response({"detail": "Invalid payload"}, status=400)
    except stripe.error.SignatureVerificationError:
        return Response({"detail": "Invalid signature"}, status=400)

    event_type = event.get("type")
    obj = event["data"]["object"]

    # ✅ أهم حدث: نجاح Stripe Checkout
    if event_type == "checkout.session.completed":
        session_id = obj.get("id")
        payment_status = obj.get("payment_status")
        amount_total = obj.get("amount_total")
        metadata = obj.get("metadata") or {}

        campaign_id = metadata.get("campaign_id")
        user_id = metadata.get("user_id")
        payment_intent_id = obj.get("payment_intent")  # غالباً string

        # لا نكسر webhook
        if payment_status != "paid":
            return Response({"ok": True, "detail": "not paid"}, status=200)

        if not session_id or amount_total is None or not campaign_id:
            return Response({"ok": True, "detail": "missing fields"}, status=200)

        # ✅ idempotency: منع التكرار
        if Donation.objects.filter(stripe_checkout_session_id=session_id).exists():
            return Response({"ok": True, "detail": "already recorded"}, status=200)

        amount = _to_decimal_money(int(amount_total))

        # ✅ سجل التبرع + حدّث الحملة
        with transaction.atomic():
            try:
                campaign = Campaign.objects.select_for_update().get(id=int(campaign_id))
            except Campaign.DoesNotExist:
                return Response({"ok": True, "detail": "campaign not found"}, status=200)

            remaining = (campaign.goal_amount - campaign.collected_amount).quantize(Decimal("0.01"))
            if amount > remaining:
                return Response({"ok": True, "detail": "amount > remaining"}, status=200)

            donation = Donation.objects.create(
                campaign=campaign,
                donor_id=int(user_id) if user_id else None,
                amount=amount,
                is_confirmed=True,
                stripe_payment_intent_id=payment_intent_id,
                stripe_checkout_session_id=session_id,
            )

            campaign.collected_amount = (campaign.collected_amount + amount).quantize(Decimal("0.01"))
            if campaign.collected_amount >= campaign.goal_amount:
                campaign.is_active = False

            campaign.save(update_fields=["collected_amount", "is_active"])

        return Response({"ok": True, "donation_id": donation.id}, status=200)

    # أحداث أخرى لا تهمنا الآن
    return Response({"ok": True, "type": event_type}, status=200)

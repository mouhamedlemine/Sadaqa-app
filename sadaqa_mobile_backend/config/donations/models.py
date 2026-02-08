from django.db import models
from django.conf import settings

from campaigns.models import Campaign

User = settings.AUTH_USER_MODEL


class Donation(models.Model):
    campaign = models.ForeignKey(
        Campaign,
        on_delete=models.CASCADE,
        related_name="donations"
    )

    donor = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="donations"
    )

    # 💰 مبلغ التبرع
    amount = models.DecimalField(max_digits=12, decimal_places=2)

    # 🕒 تاريخ التبرع
    created_at = models.DateTimeField(auto_now_add=True)

    # ✅ تأكيد الدفع (Stripe)
    is_confirmed = models.BooleanField(default=False)

    # 🔐 معرف PaymentIntent (Mobile أو Checkout أحيانًا)
    stripe_payment_intent_id = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        unique=True,      # ✅ يمنع تكرار نفس الدفع
        db_index=True
    )

    # 🔐 معرف Checkout Session (Web) - مهم جدًا
    stripe_checkout_session_id = models.CharField(
        max_length=255,
        blank=True,
        null=True,
        unique=True,      # ✅ يمنع تكرار نفس session
        db_index=True
    )

    def __str__(self):
        return f"{self.amount} to {self.campaign.title}"

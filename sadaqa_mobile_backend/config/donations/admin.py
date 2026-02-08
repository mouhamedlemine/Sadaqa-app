from django.contrib import admin
from .models import Donation


@admin.register(Donation)
class DonationAdmin(admin.ModelAdmin):
    list_display = (
        "id",
        "campaign",
        "donor",
        "amount",
        "is_confirmed",
        "created_at",
    )
    list_filter = ("is_confirmed", "created_at", "campaign")
    search_fields = (
        "campaign__title",
        "donor__username",
        "donor__email",
        "stripe_payment_intent_id",
        "stripe_checkout_session_id",
    )
    ordering = ("-created_at",)
    list_select_related = ("campaign", "donor")

    # لتحسين واجهة الـ admin
    readonly_fields = ("created_at",)

    fieldsets = (
        ("معلومات التبرع", {
            "fields": ("campaign", "donor", "amount", "is_confirmed", "created_at")
        }),
        ("Stripe (تقني)", {
            "fields": ("stripe_payment_intent_id", "stripe_checkout_session_id")
        }),
    )

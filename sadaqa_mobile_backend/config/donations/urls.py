# from django.urls import path, include
# from rest_framework.routers import DefaultRouter

# from .views import (
#     CampaignViewSet,
#     DonationViewSet,
#     CreatePaymentIntentView,
#     ConfirmPaymentView,
# )

# from .payment_views import (
#     CreateCheckoutSessionView,
#     ConfirmCheckoutSessionView,
# )

# # ✅ Webhook
# from .webhooks import stripe_webhook


# router = DefaultRouter()
# router.register("campaigns", CampaignViewSet, basename="campaign")
# router.register("donations", DonationViewSet, basename="donation")

# urlpatterns = [
#     path("", include(router.urls)),

#     # Stripe Mobile (PaymentIntent)
#     path("payments/create-intent/", CreatePaymentIntentView.as_view(), name="create_payment_intent"),
#     path("payments/confirm/", ConfirmPaymentView.as_view(), name="confirm_payment"),

#     # Stripe Web (Checkout Session)
#     path("payments/create-checkout-session/", CreateCheckoutSessionView.as_view(), name="create_checkout_session"),
#     path("payments/confirm-checkout-session/", ConfirmCheckoutSessionView.as_view(), name="confirm_checkout_session"),

#     # ✅ Stripe Webhook (Production-safe)
#     path("payments/webhook/", stripe_webhook, name="stripe_webhook"),
# ]


from django.urls import path, include
from rest_framework.routers import DefaultRouter

# ViewSets (API عامة)
from .views import (
    CampaignViewSet,
    DonationViewSet,
    ConfirmPaymentView,
)

# Stripe Views (Web + Mobile)
from .payment_views import (
    CreatePaymentIntentView,        # ✅ Mobile (PaymentIntent)
    CreateCheckoutSessionView,      # ✅ Web (Checkout Session)
    ConfirmCheckoutSessionView,     # ✅ Web Confirm
)

# Stripe Webhook
from .webhooks import stripe_webhook


router = DefaultRouter()
router.register("campaigns", CampaignViewSet, basename="campaign")
router.register("donations", DonationViewSet, basename="donation")

urlpatterns = [
    # REST API
    path("", include(router.urls)),

    # ==========================
    # Stripe Mobile (Flutter)
    # ==========================
    path(
        "payments/create-intent/",
        CreatePaymentIntentView.as_view(),
        name="create_payment_intent",
    ),
    path(
        "payments/confirm/",
        ConfirmPaymentView.as_view(),
        name="confirm_payment",
    ),

    # ==========================
    # Stripe Web (Checkout)
    # ==========================
    path(
        "payments/create-checkout-session/",
        CreateCheckoutSessionView.as_view(),
        name="create_checkout_session",
    ),
    path(
        "payments/confirm-checkout-session/",
        ConfirmCheckoutSessionView.as_view(),
        name="confirm_checkout_session",
    ),

    # ==========================
    # Stripe Webhook (Production)
    # ==========================
    path(
        "payments/webhook/",
        stripe_webhook,
        name="stripe_webhook",
    ),
]

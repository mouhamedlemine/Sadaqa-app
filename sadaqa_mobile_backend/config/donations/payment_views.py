# # import stripe
# # from decimal import Decimal, ROUND_HALF_UP

# # from django.conf import settings
# # from django.db import transaction

# # from rest_framework.views import APIView
# # from rest_framework.response import Response
# # from rest_framework.permissions import IsAuthenticated
# # from rest_framework import status
# # from rest_framework.exceptions import ValidationError, NotFound

# # from campaigns.models import Campaign
# # from donations.models import Donation

# # stripe.api_key = settings.STRIPE_SECRET_KEY


# # def _to_decimal_money(cents: int) -> Decimal:
# #     return (Decimal(cents) / Decimal("100")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


# # class CreateCheckoutSessionView(APIView):
# #     """
# #     ✅ Web:
# #     إنشاء Stripe Checkout Session وإرجاع URL لفتحه في المتصفح
# #     """
# #     permission_classes = [IsAuthenticated]

# #     def post(self, request):
# #         campaign_id = request.data.get("campaign_id")
# #         amount = request.data.get("amount")

# #         if not campaign_id or amount is None:
# #             return Response({"detail": "campaign_id و amount مطلوبان"}, status=400)

# #         try:
# #             campaign_id_int = int(campaign_id)
# #         except Exception:
# #             return Response({"detail": "campaign_id غير صحيح"}, status=400)

# #         try:
# #             amount_decimal = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
# #         except Exception:
# #             return Response({"detail": "Invalid amount"}, status=400)

# #         if amount_decimal <= 0:
# #             return Response({"detail": "Amount must be > 0"}, status=400)

# #         try:
# #             campaign = Campaign.objects.get(id=campaign_id_int)
# #         except Campaign.DoesNotExist:
# #             raise NotFound("الحملة غير موجودة.")

# #         if not campaign.is_active:
# #             raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

# #         remaining = (campaign.goal_amount - campaign.collected_amount).quantize(Decimal("0.01"))
# #         if amount_decimal > remaining:
# #             raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

# #         amount_cents = int(amount_decimal * 100)

# #         # ✅ Flutter web hash routing
# #         success_url = f"{settings.FRONTEND_BASE_URL}/#/payment-success?session_id={{CHECKOUT_SESSION_ID}}"
# #         cancel_url = f"{settings.FRONTEND_BASE_URL}/#/payment-cancel"

# #         session = stripe.checkout.Session.create(
# #             mode="payment",
# #             payment_method_types=["card"],
# #             line_items=[
# #                 {
# #                     "price_data": {
# #                         "currency": getattr(settings, "STRIPE_CURRENCY", "usd"),
# #                         "product_data": {"name": f"Donation to: {campaign.title}"},
# #                         "unit_amount": amount_cents,
# #                     },
# #                     "quantity": 1,
# #                 }
# #             ],
# #             success_url=success_url,
# #             cancel_url=cancel_url,
# #             metadata={
# #                 "campaign_id": str(campaign_id_int),
# #                 "user_id": str(request.user.id),
# #                 "amount": str(amount_decimal),
# #             },
# #         )

# #         return Response(
# #             {"url": session.url, "session_id": session.id},
# #             status=status.HTTP_201_CREATED
# #         )


# # class ConfirmCheckoutSessionView(APIView):
# #     """
# #     ✅ Web Confirm:
# #     - يتحقق paid
# #     - يمنع التكرار
# #     - ينشئ Donation ويحدّث Campaign
# #     """
# #     permission_classes = [IsAuthenticated]

# #     def _get_session_id(self, request):
# #         return request.query_params.get("session_id") or request.data.get("session_id")

# #     def get(self, request):
# #         return self._confirm(request)

# #     def post(self, request):
# #         return self._confirm(request)

# #     def _confirm(self, request):
# #         session_id = self._get_session_id(request)

# #         # ✅ DEBUG: هل endpoint يُستدعى؟
# #         print("✅ CONFIRM HIT session_id =", session_id)

# #         if not session_id:
# #             return Response({"detail": "session_id مطلوب"}, status=400)

# #         # ✅ منع التكرار بالأقوى: session_id أولاً
# #         existing_by_session = Donation.objects.filter(stripe_checkout_session_id=session_id).first()
# #         if existing_by_session:
# #             return Response(
# #                 {
# #                     "ok": True,
# #                     "detail": "تم تسجيل هذا الدفع مسبقًا (session).",
# #                     "amount": str(existing_by_session.amount),
# #                     "stripe_checkout_session_id": session_id,
# #                     "stripe_payment_intent_id": existing_by_session.stripe_payment_intent_id,
# #                 },
# #                 status=200
# #             )

# #         try:
# #             session = stripe.checkout.Session.retrieve(
# #                 session_id,
# #                 expand=["payment_intent"]
# #             )
# #         except Exception as e:
# #             return Response({"detail": f"Stripe error: {str(e)}"}, status=400)

# #         # ✅ DEBUG
# #         print("Stripe payment_status =", session.get("payment_status"))
# #         print("Stripe amount_total =", session.get("amount_total"))

# #         if session.get("payment_status") != "paid":
# #             return Response(
# #                 {"detail": f"الدفع غير مكتمل. payment_status={session.get('payment_status')}"},
# #                 status=400
# #             )

# #         md = session.get("metadata") or {}
# #         campaign_id = md.get("campaign_id")
# #         meta_user_id = md.get("user_id")

# #         if not campaign_id:
# #             return Response({"detail": "metadata ناقصة (campaign_id)"}, status=400)

# #         if meta_user_id and str(request.user.id) != str(meta_user_id):
# #             raise ValidationError({"user": "هذه العملية لا تخص المستخدم الحالي"})

# #         amount_total = session.get("amount_total")
# #         if amount_total is None:
# #             return Response({"detail": "amount_total غير موجود في session"}, status=400)

# #         amount = _to_decimal_money(int(amount_total))

# #         # payment_intent_id (dict أو string أو None)
# #         pi = session.get("payment_intent")
# #         payment_intent_id = None
# #         if isinstance(pi, dict):
# #             payment_intent_id = pi.get("id")
# #         elif isinstance(pi, str):
# #             payment_intent_id = pi

# #         # ✅ DEBUG
# #         print("Stripe payment_intent_id =", payment_intent_id)

# #         # ✅ منع التكرار بـ payment_intent لو موجود
# #         if payment_intent_id:
# #             existing_by_pi = Donation.objects.filter(stripe_payment_intent_id=payment_intent_id).first()
# #             if existing_by_pi:
# #                 if not existing_by_pi.stripe_checkout_session_id:
# #                     existing_by_pi.stripe_checkout_session_id = session_id
# #                 if not existing_by_pi.is_confirmed:
# #                     existing_by_pi.is_confirmed = True
# #                 existing_by_pi.save(update_fields=["stripe_checkout_session_id", "is_confirmed"])

# #                 return Response(
# #                     {
# #                         "ok": True,
# #                         "detail": "تم تسجيل هذا الدفع مسبقًا (payment_intent).",
# #                         "amount": str(existing_by_pi.amount),
# #                         "stripe_checkout_session_id": session_id,
# #                         "stripe_payment_intent_id": payment_intent_id,
# #                     },
# #                     status=200
# #                 )

# #         # ✅ campaign_id صحيح
# #         try:
# #             campaign_id_int = int(campaign_id)
# #         except Exception:
# #             return Response({"detail": "campaign_id داخل metadata غير صحيح"}, status=400)

# #         try:
# #             campaign = Campaign.objects.get(id=campaign_id_int)
# #         except Campaign.DoesNotExist:
# #             raise NotFound("الحملة غير موجودة.")

# #         with transaction.atomic():
# #             campaign_locked = Campaign.objects.select_for_update().get(id=campaign.id)

# #             if not campaign_locked.is_active:
# #                 raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

# #             remaining = (campaign_locked.goal_amount - campaign_locked.collected_amount).quantize(Decimal("0.01"))
# #             if amount > remaining:
# #                 raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

# #             donation = Donation.objects.create(
# #                 campaign=campaign_locked,
# #                 donor=request.user,
# #                 amount=amount,
# #                 is_confirmed=True,
# #                 stripe_payment_intent_id=payment_intent_id,
# #                 stripe_checkout_session_id=session_id,
# #             )

# #             campaign_locked.collected_amount = (campaign_locked.collected_amount + amount).quantize(Decimal("0.01"))
# #             if campaign_locked.collected_amount >= campaign_locked.goal_amount:
# #                 campaign_locked.is_active = False

# #             campaign_locked.save(update_fields=["collected_amount", "is_active"])

# #         return Response(
# #             {
# #                 "ok": True,
# #                 "amount": str(amount),
# #                 "stripe_payment_intent_id": payment_intent_id,
# #                 "stripe_checkout_session_id": session_id,
# #                 "donation_id": donation.id,
# #             },
# #             status=201
# #         )





# import stripe
# from decimal import Decimal, ROUND_HALF_UP

# from django.conf import settings
# from django.db import transaction

# from rest_framework.views import APIView
# from rest_framework.response import Response
# from rest_framework.permissions import IsAuthenticated
# from rest_framework import status
# from rest_framework.exceptions import ValidationError, NotFound

# from campaigns.models import Campaign
# from donations.models import Donation

# stripe.api_key = settings.STRIPE_SECRET_KEY


# def _to_decimal_money(cents: int) -> Decimal:
#     return (Decimal(cents) / Decimal("100")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


# class CreateCheckoutSessionView(APIView):
#     """
#     ✅ Web:
#     إنشاء Stripe Checkout Session وإرجاع URL لفتحه في المتصفح
#     """
#     permission_classes = [IsAuthenticated]

#     def post(self, request):
#         campaign_id = request.data.get("campaign_id")
#         amount = request.data.get("amount")

#         if not campaign_id or amount is None:
#             return Response({"detail": "campaign_id و amount مطلوبان"}, status=400)

#         try:
#             campaign_id_int = int(campaign_id)
#         except Exception:
#             return Response({"detail": "campaign_id غير صحيح"}, status=400)

#         try:
#             amount_decimal = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
#         except Exception:
#             return Response({"detail": "Invalid amount"}, status=400)

#         if amount_decimal <= 0:
#             return Response({"detail": "Amount must be > 0"}, status=400)

#         try:
#             campaign = Campaign.objects.get(id=campaign_id_int)
#         except Campaign.DoesNotExist:
#             raise NotFound("الحملة غير موجودة.")

#         if not campaign.is_active:
#             raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

#         remaining = (campaign.goal_amount - campaign.collected_amount).quantize(Decimal("0.01"))
#         if amount_decimal > remaining:
#             raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

#         amount_cents = int(amount_decimal * 100)

#         # ✅ Flutter web hash routing
#         success_url = f"{settings.FRONTEND_BASE_URL}/#/payment-success?session_id={{CHECKOUT_SESSION_ID}}"
#         cancel_url = f"{settings.FRONTEND_BASE_URL}/#/payment-cancel"

#         session = stripe.checkout.Session.create(
#             mode="payment",
#             payment_method_types=["card"],
#             line_items=[
#                 {
#                     "price_data": {
#                         "currency": getattr(settings, "STRIPE_CURRENCY", "usd"),
#                         "product_data": {"name": f"Donation to: {campaign.title}"},
#                         "unit_amount": amount_cents,
#                     },
#                     "quantity": 1,
#                 }
#             ],
#             success_url=success_url,
#             cancel_url=cancel_url,
#             metadata={
#                 "campaign_id": str(campaign_id_int),
#                 "user_id": str(request.user.id),
#                 "amount": str(amount_decimal),
#             },
#         )

#         return Response(
#             {"url": session.url, "session_id": session.id},
#             status=status.HTTP_201_CREATED
#         )


# class ConfirmCheckoutSessionView(APIView):
#     """
#     ✅ Web Confirm:
#     - يتحقق paid
#     - يمنع التكرار
#     - ينشئ Donation ويحدّث Campaign
#     """
#     permission_classes = [IsAuthenticated]

#     def _get_session_id(self, request):
#         return request.query_params.get("session_id") or request.data.get("session_id")

#     def get(self, request):
#         return self._confirm(request)

#     def post(self, request):
#         return self._confirm(request)

#     def _confirm(self, request):
#         session_id = self._get_session_id(request)

#         # ✅ DEBUG: هل endpoint يُستدعى؟
#         print("✅ CONFIRM HIT session_id =", session_id)

#         if not session_id:
#             return Response({"detail": "session_id مطلوب"}, status=400)

#         # ✅ منع التكرار بالأقوى: session_id أولاً
#         existing_by_session = Donation.objects.filter(stripe_checkout_session_id=session_id).first()
#         if existing_by_session:
#             return Response(
#                 {
#                     "ok": True,
#                     "detail": "تم تسجيل هذا الدفع مسبقًا (session).",
#                     "amount": str(existing_by_session.amount),
#                     "stripe_checkout_session_id": session_id,
#                     "stripe_payment_intent_id": existing_by_session.stripe_payment_intent_id,
#                 },
#                 status=200
#             )

#         try:
#             session = stripe.checkout.Session.retrieve(
#                 session_id,
#                 expand=["payment_intent"]
#             )
#         except Exception as e:
#             return Response({"detail": f"Stripe error: {str(e)}"}, status=400)

#         # ✅ DEBUG
#         print("Stripe payment_status =", session.get("payment_status"))
#         print("Stripe amount_total =", session.get("amount_total"))

#         if session.get("payment_status") != "paid":
#             return Response(
#                 {"detail": f"الدفع غير مكتمل. payment_status={session.get('payment_status')}"},
#                 status=400
#             )

#         md = session.get("metadata") or {}
#         campaign_id = md.get("campaign_id")
#         meta_user_id = md.get("user_id")

#         if not campaign_id:
#             return Response({"detail": "metadata ناقصة (campaign_id)"}, status=400)

#         if meta_user_id and str(request.user.id) != str(meta_user_id):
#             raise ValidationError({"user": "هذه العملية لا تخص المستخدم الحالي"})

#         amount_total = session.get("amount_total")
#         if amount_total is None:
#             return Response({"detail": "amount_total غير موجود في session"}, status=400)

#         amount = _to_decimal_money(int(amount_total))

#         # payment_intent_id (dict أو string أو None)
#         pi = session.get("payment_intent")
#         payment_intent_id = None
#         if isinstance(pi, dict):
#             payment_intent_id = pi.get("id")
#         elif isinstance(pi, str):
#             payment_intent_id = pi

#         # ✅ DEBUG
#         print("Stripe payment_intent_id =", payment_intent_id)

#         # ✅ منع التكرار بـ payment_intent لو موجود
#         if payment_intent_id:
#             existing_by_pi = Donation.objects.filter(stripe_payment_intent_id=payment_intent_id).first()
#             if existing_by_pi:
#                 if not existing_by_pi.stripe_checkout_session_id:
#                     existing_by_pi.stripe_checkout_session_id = session_id
#                 if not existing_by_pi.is_confirmed:
#                     existing_by_pi.is_confirmed = True
#                 existing_by_pi.save(update_fields=["stripe_checkout_session_id", "is_confirmed"])

#                 return Response(
#                     {
#                         "ok": True,
#                         "detail": "تم تسجيل هذا الدفع مسبقًا (payment_intent).",
#                         "amount": str(existing_by_pi.amount),
#                         "stripe_checkout_session_id": session_id,
#                         "stripe_payment_intent_id": payment_intent_id,
#                     },
#                     status=200
#                 )

#         # ✅ campaign_id صحيح
#         try:
#             campaign_id_int = int(campaign_id)
#         except Exception:
#             return Response({"detail": "campaign_id داخل metadata غير صحيح"}, status=400)

#         try:
#             campaign = Campaign.objects.get(id=campaign_id_int)
#         except Campaign.DoesNotExist:
#             raise NotFound("الحملة غير موجودة.")

#         with transaction.atomic():
#             campaign_locked = Campaign.objects.select_for_update().get(id=campaign.id)

#             if not campaign_locked.is_active:
#                 raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

#             remaining = (campaign_locked.goal_amount - campaign_locked.collected_amount).quantize(Decimal("0.01"))
#             if amount > remaining:
#                 raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

#             donation = Donation.objects.create(
#                 campaign=campaign_locked,
#                 donor=request.user,
#                 amount=amount,
#                 is_confirmed=True,
#                 stripe_payment_intent_id=payment_intent_id,
#                 stripe_checkout_session_id=session_id,
#             )

#             campaign_locked.collected_amount = (campaign_locked.collected_amount + amount).quantize(Decimal("0.01"))
#             if campaign_locked.collected_amount >= campaign_locked.goal_amount:
#                 campaign_locked.is_active = False

#             campaign_locked.save(update_fields=["collected_amount", "is_active"])

#         return Response(
#             {
#                 "ok": True,
#                 "amount": str(amount),
#                 "stripe_payment_intent_id": payment_intent_id,
#                 "stripe_checkout_session_id": session_id,
#                 "donation_id": donation.id,
#             },
#             status=201
#         )


# class CreatePaymentIntentView(APIView):
#     """
#     ✅ Mobile (Flutter):
#     إنشاء PaymentIntent وإرجاع client_secret لـ Stripe PaymentSheet
#     """
#     permission_classes = [IsAuthenticated]

#     def post(self, request):
#         campaign_id = request.data.get("campaign_id")
#         amount = request.data.get("amount")

#         if not campaign_id or amount is None:
#             return Response({"detail": "campaign_id و amount مطلوبان"}, status=400)

#         try:
#             campaign_id_int = int(campaign_id)
#         except Exception:
#             return Response({"detail": "campaign_id غير صحيح"}, status=400)

#         try:
#             amount_decimal = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
#         except Exception:
#             return Response({"detail": "Invalid amount"}, status=400)

#         if amount_decimal <= 0:
#             return Response({"detail": "Amount must be > 0"}, status=400)

#         try:
#             campaign = Campaign.objects.get(id=campaign_id_int)
#         except Campaign.DoesNotExist:
#             raise NotFound("الحملة غير موجودة.")

#         if not campaign.is_active:
#             raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

#         remaining = (campaign.goal_amount - campaign.collected_amount).quantize(Decimal("0.01"))
#         if amount_decimal > remaining:
#             raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

#         amount_cents = int(amount_decimal * 100)
#         currency = getattr(settings, "STRIPE_CURRENCY", "usd")

#         try:
#             intent = stripe.PaymentIntent.create(
#                 amount=amount_cents,
#                 currency=currency,
#                 automatic_payment_methods={"enabled": True},
#                 metadata={
#                     "campaign_id": str(campaign_id_int),
#                     "user_id": str(request.user.id),
#                     "amount": str(amount_decimal),
#                     "source": "mobile",
#                 },
#             )

#             # ✅ هذا هو المهم لFlutter
#             return Response(
#                 {"client_secret": intent.client_secret},
#                 status=status.HTTP_201_CREATED
#             )

#         except Exception as e:
#             return Response({"detail": f"Stripe error: {str(e)}"}, status=400)


import stripe
from decimal import Decimal, ROUND_HALF_UP

from django.conf import settings
from django.db import transaction

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from rest_framework.exceptions import ValidationError, NotFound

from campaigns.models import Campaign
from donations.models import Donation

stripe.api_key = settings.STRIPE_SECRET_KEY


def _to_decimal_money(cents: int) -> Decimal:
    return (Decimal(cents) / Decimal("100")).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


class CreateCheckoutSessionView(APIView):
    """
    ✅ Web:
    إنشاء Stripe Checkout Session وإرجاع URL لفتحه في المتصفح
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        campaign_id = request.data.get("campaign_id")
        amount = request.data.get("amount")

        if not campaign_id or amount is None:
            return Response({"detail": "campaign_id و amount مطلوبان"}, status=400)

        try:
            campaign_id_int = int(campaign_id)
        except Exception:
            return Response({"detail": "campaign_id غير صحيح"}, status=400)

        try:
            amount_decimal = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        except Exception:
            return Response({"detail": "Invalid amount"}, status=400)

        if amount_decimal <= 0:
            return Response({"detail": "Amount must be > 0"}, status=400)

        try:
            campaign = Campaign.objects.get(id=campaign_id_int)
        except Campaign.DoesNotExist:
            raise NotFound("الحملة غير موجودة.")

        if not campaign.is_active:
            raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

        remaining = (campaign.goal_amount - campaign.collected_amount).quantize(Decimal("0.01"))
        if amount_decimal > remaining:
            raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

        amount_cents = int(amount_decimal * 100)

        # ✅ Flutter web hash routing
        success_url = f"{settings.FRONTEND_BASE_URL}/#/payment-success?session_id={{CHECKOUT_SESSION_ID}}"
        cancel_url = f"{settings.FRONTEND_BASE_URL}/#/payment-cancel"

        session = stripe.checkout.Session.create(
            mode="payment",
            payment_method_types=["card"],
            line_items=[
                {
                    "price_data": {
                        "currency": getattr(settings, "STRIPE_CURRENCY", "usd"),
                        "product_data": {"name": f"Donation to: {campaign.title}"},
                        "unit_amount": amount_cents,
                    },
                    "quantity": 1,
                }
            ],
            success_url=success_url,
            cancel_url=cancel_url,
            metadata={
                "campaign_id": str(campaign_id_int),
                "user_id": str(request.user.id),
                "amount": str(amount_decimal),
            },
        )

        return Response(
            {"url": session.url, "session_id": session.id},
            status=status.HTTP_201_CREATED
        )


class ConfirmCheckoutSessionView(APIView):
    """
    ✅ Web Confirm:
    - يتحقق paid
    - يمنع التكرار
    - ينشئ Donation ويحدّث Campaign
    """
    permission_classes = [IsAuthenticated]

    def _get_session_id(self, request):
        return request.query_params.get("session_id") or request.data.get("session_id")

    def get(self, request):
        return self._confirm(request)

    def post(self, request):
        return self._confirm(request)

    def _confirm(self, request):
        session_id = self._get_session_id(request)

        # ✅ DEBUG: هل endpoint يُستدعى؟
        print("✅ CONFIRM HIT session_id =", session_id)

        if not session_id:
            return Response({"detail": "session_id مطلوب"}, status=400)

        # ✅ منع التكرار بالأقوى: session_id أولاً
        existing_by_session = Donation.objects.filter(stripe_checkout_session_id=session_id).first()
        if existing_by_session:
            return Response(
                {
                    "ok": True,
                    "detail": "تم تسجيل هذا الدفع مسبقًا (session).",
                    "amount": str(existing_by_session.amount),
                    "stripe_checkout_session_id": session_id,
                    "stripe_payment_intent_id": existing_by_session.stripe_payment_intent_id,
                },
                status=200
            )

        try:
            session = stripe.checkout.Session.retrieve(session_id, expand=["payment_intent"])
        except Exception as e:
            return Response({"detail": f"Stripe error: {str(e)}"}, status=400)

        # ✅ DEBUG
        print("Stripe payment_status =", session.get("payment_status"))
        print("Stripe amount_total =", session.get("amount_total"))

        if session.get("payment_status") != "paid":
            return Response(
                {"detail": f"الدفع غير مكتمل. payment_status={session.get('payment_status')}"},
                status=400
            )

        md = session.get("metadata") or {}
        campaign_id = md.get("campaign_id")
        meta_user_id = md.get("user_id")

        if not campaign_id:
            return Response({"detail": "metadata ناقصة (campaign_id)"}, status=400)

        if meta_user_id and str(request.user.id) != str(meta_user_id):
            raise ValidationError({"user": "هذه العملية لا تخص المستخدم الحالي"})

        amount_total = session.get("amount_total")
        if amount_total is None:
            return Response({"detail": "amount_total غير موجود في session"}, status=400)

        amount = _to_decimal_money(int(amount_total))

        # payment_intent_id (dict أو string أو None)
        pi = session.get("payment_intent")
        payment_intent_id = None
        if isinstance(pi, dict):
            payment_intent_id = pi.get("id")
        elif isinstance(pi, str):
            payment_intent_id = pi

        # ✅ DEBUG
        print("Stripe payment_intent_id =", payment_intent_id)

        # ✅ منع التكرار بـ payment_intent لو موجود
        if payment_intent_id:
            existing_by_pi = Donation.objects.filter(stripe_payment_intent_id=payment_intent_id).first()
            if existing_by_pi:
                if not existing_by_pi.stripe_checkout_session_id:
                    existing_by_pi.stripe_checkout_session_id = session_id
                if not existing_by_pi.is_confirmed:
                    existing_by_pi.is_confirmed = True
                existing_by_pi.save(update_fields=["stripe_checkout_session_id", "is_confirmed"])

                return Response(
                    {
                        "ok": True,
                        "detail": "تم تسجيل هذا الدفع مسبقًا (payment_intent).",
                        "amount": str(existing_by_pi.amount),
                        "stripe_checkout_session_id": session_id,
                        "stripe_payment_intent_id": payment_intent_id,
                    },
                    status=200
                )

        # ✅ campaign_id صحيح
        try:
            campaign_id_int = int(campaign_id)
        except Exception:
            return Response({"detail": "campaign_id داخل metadata غير صحيح"}, status=400)

        try:
            campaign = Campaign.objects.get(id=campaign_id_int)
        except Campaign.DoesNotExist:
            raise NotFound("الحملة غير موجودة.")

        with transaction.atomic():
            campaign_locked = Campaign.objects.select_for_update().get(id=campaign.id)

            if not campaign_locked.is_active:
                raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

            remaining = (campaign_locked.goal_amount - campaign_locked.collected_amount).quantize(Decimal("0.01"))
            if amount > remaining:
                raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

            donation = Donation.objects.create(
                campaign=campaign_locked,
                donor=request.user,
                amount=amount,
                is_confirmed=True,
                stripe_payment_intent_id=payment_intent_id,
                stripe_checkout_session_id=session_id,
            )

            campaign_locked.collected_amount = (campaign_locked.collected_amount + amount).quantize(Decimal("0.01"))
            if campaign_locked.collected_amount >= campaign_locked.goal_amount:
                campaign_locked.is_active = False

            campaign_locked.save(update_fields=["collected_amount", "is_active"])

        return Response(
            {
                "ok": True,
                "amount": str(amount),
                "stripe_payment_intent_id": payment_intent_id,
                "stripe_checkout_session_id": session_id,
                "donation_id": donation.id,
            },
            status=201
        )


class CreatePaymentIntentView(APIView):
    """
    ✅ Mobile (Flutter):
    إنشاء PaymentIntent وإرجاع client_secret لـ Stripe PaymentSheet
    """
    permission_classes = [IsAuthenticated]

    def post(self, request):
        campaign_id = request.data.get("campaign_id")
        amount = request.data.get("amount")

        if not campaign_id or amount is None:
            return Response({"detail": "campaign_id و amount مطلوبان"}, status=400)

        try:
            campaign_id_int = int(campaign_id)
        except Exception:
            return Response({"detail": "campaign_id غير صحيح"}, status=400)

        try:
            amount_decimal = Decimal(str(amount)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)
        except Exception:
            return Response({"detail": "Invalid amount"}, status=400)

        if amount_decimal <= 0:
            return Response({"detail": "Amount must be > 0"}, status=400)

        try:
            campaign = Campaign.objects.get(id=campaign_id_int)
        except Campaign.DoesNotExist:
            raise NotFound("الحملة غير موجودة.")

        if not campaign.is_active:
            raise ValidationError({"campaign": "هذه الحملة غير متاحة للتبرع."})

        remaining = (campaign.goal_amount - campaign.collected_amount).quantize(Decimal("0.01"))
        if amount_decimal > remaining:
            raise ValidationError({"amount": f"المبلغ أكبر من المتبقي. المتبقي: {remaining}"})

        amount_cents = int(amount_decimal * 100)
        currency = getattr(settings, "STRIPE_CURRENCY", "usd")

        try:
            intent = stripe.PaymentIntent.create(
                amount=amount_cents,
                currency=currency,
                automatic_payment_methods={"enabled": True},
                metadata={
                    "campaign_id": str(campaign_id_int),
                    "user_id": str(request.user.id),
                    "amount": str(amount_decimal),
                    "source": "mobile",
                },
            )

            return Response(
                {"client_secret": intent.client_secret},
                status=status.HTTP_201_CREATED
            )

        except Exception as e:
            return Response({"detail": f"Stripe error: {str(e)}"}, status=400)

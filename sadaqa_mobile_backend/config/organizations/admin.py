from django.contrib import admin, messages
from .models import OrganizationProfile
from .utils import send_org_review_email


@admin.action(description="✅ Approuver les organisations sélectionnées (envoyer un e-mail)")
def approve_organizations(modeladmin, request, queryset):
    updated = 0

    for org in queryset.select_related("user"):
        # Mise à jour du statut
        org.status = OrganizationProfile.Status.APPROVED
        org.rejection_reason = ""
        org.save(update_fields=["status", "rejection_reason"])

        # Envoi de l'e-mail
        try:
            send_org_review_email(
                email=org.user.email,
                org_name=org.name,
                status="APPROVED",
            )
        except Exception as e:
            messages.error(
                request,
                f"Échec de l’envoi de l’e-mail à {org.user.email} : {e}"
            )
            continue

        updated += 1

    messages.success(
        request,
        f"{updated} organisation(s) ont été approuvée(s) avec succès et un e-mail de notification a été envoyé. ✅"
    )


@admin.action(description="❌ Rejeter les organisations sélectionnées (envoyer un e-mail)")
def reject_organizations(modeladmin, request, queryset):
    updated = 0

    for org in queryset.select_related("user"):
        # Si aucun motif n'est fourni, définir un motif par défaut
        reason = (
            org.rejection_reason.strip()
            if org.rejection_reason
            else "Les conditions requises n’ont pas été remplies."
        )

        # Mise à jour du statut
        org.status = OrganizationProfile.Status.REJECTED
        org.rejection_reason = reason
        org.save(update_fields=["status", "rejection_reason"])

        # Envoi de l'e-mail
        try:
            send_org_review_email(
                email=org.user.email,
                org_name=org.name,
                status="REJECTED",
                reason=reason,
            )
        except Exception as e:
            messages.error(
                request,
                f"Échec de l’envoi de l’e-mail à {org.user.email} : {e}"
            )
            continue

        updated += 1

    messages.success(
        request,
        f"{updated} organisation(s) ont été rejetée(s) et un e-mail de notification a été envoyé. ❌"
    )


@admin.register(OrganizationProfile)
class OrganizationProfileAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "user", "status", "created_at")
    list_filter = ("status", "created_at")
    search_fields = ("name", "user__email")
    actions = [approve_organizations, reject_organizations]

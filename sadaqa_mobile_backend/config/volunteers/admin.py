# from django.contrib import admin
# from .models import VolunteerRequest

# @admin.register(VolunteerRequest)
# class VolunteerRequestAdmin(admin.ModelAdmin):
#     list_display = ("full_name", "phone", "city", "volunteer_type", "status", "created_at")
#     list_filter = ("status", "volunteer_type", "city")
#     search_fields = ("full_name", "phone", "city")

from django.contrib import admin, messages
from .models import VolunteerRequest


@admin.register(VolunteerRequest)
class VolunteerRequestAdmin(admin.ModelAdmin):
    list_display = (
        "full_name",
        "phone",
        "city",
        "volunteer_type_fr",
        "status_fr",
        "created_at",
    )

    list_filter = ("status", "volunteer_type", "city")
    search_fields = ("full_name", "phone", "city")
    ordering = ("-created_at",)
    readonly_fields = ("created_at",)

    actions = ["approuver", "rejeter"]

    # 🔹 Traduction du statut (affichage seulement)
    def status_fr(self, obj):
        mapping = {
            "pending": "En attente",
            "approved": "Approuvée",
            "rejected": "Rejetée",
        }
        return mapping.get(obj.status, obj.status)
    status_fr.short_description = "Statut"

    # 🔹 Traduction du type de bénévolat (affichage seulement)
    def volunteer_type_fr(self, obj):
        mapping = {
            "field": "Sur le terrain",
            "online": "En ligne",
        }
        return mapping.get(obj.volunteer_type, obj.volunteer_type)
    volunteer_type_fr.short_description = "Type de bénévolat"

    @admin.action(description="✅ Approuver les demandes sélectionnées")
    def approuver(self, request, queryset):
        queryset.update(status="approved")
        self.message_user(
            request,
            "Les demandes sélectionnées ont été approuvées avec succès.",
            level=messages.SUCCESS,
        )

    @admin.action(description="⛔ Rejeter les demandes sélectionnées")
    def rejeter(self, request, queryset):
        queryset.update(status="rejected")
        self.message_user(
            request,
            "Les demandes sélectionnées ont été rejetées.",
            level=messages.WARNING,
        )

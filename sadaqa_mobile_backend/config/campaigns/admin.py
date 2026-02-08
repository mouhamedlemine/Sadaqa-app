from django.contrib import admin
from django.utils import timezone
from .models import Campaign, Organization

@admin.register(Organization)
class OrganizationAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "owner", "is_verified", "created_at")
    list_filter = ("is_verified", "created_at")
    search_fields = ("name", "owner__email")


@admin.register(Campaign)
class CampaignAdmin(admin.ModelAdmin):
    list_display = ("id", "title", "owner", "status", "is_active", "goal_amount", "created_at")
    list_filter = ("status", "is_active", "created_at")
    search_fields = ("title", "owner__email")
    readonly_fields = ("created_at",)

    actions = ["approve_selected", "reject_selected"]

    def approve_selected(self, request, queryset):
        queryset.update(
            status=Campaign.Status.APPROVED,
            approved_by=request.user,
            approved_at=timezone.now(),
            rejection_reason="",
        )
    approve_selected.short_description = "✅ الموافقة على الحملات المحددة"

    def reject_selected(self, request, queryset):
        queryset.update(
            status=Campaign.Status.REJECTED,
            approved_by=None,
            approved_at=None,
        )
    reject_selected.short_description = "❌ رفض الحملات المحددة (بدون سبب)"

from rest_framework import serializers
from django.db.models import Sum

from .models import Campaign, Organization
from donations.models import Donation


class OrganizationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Organization
        fields = [
            "id",
            "owner",
            "name",
            "description",
            "phone",
            "address",
            "website",
            "is_verified",
            "created_at",
        ]
        read_only_fields = ["id", "owner", "is_verified", "created_at"]


class CampaignSerializer(serializers.ModelSerializer):
    collected_amount = serializers.SerializerMethodField()

    class Meta:
        model = Campaign
        fields = [
            "id",
            "owner",
            "organization",
            "title",
            "description",
            "goal_amount",
            "collected_amount",
            "status",
            "is_active",
            "approved_by",
            "approved_at",
            "rejection_reason",
            "created_at",
        ]
        read_only_fields = [
            "id",
            "owner",
            "collected_amount",
            "status",
            "approved_by",
            "approved_at",
            "rejection_reason",
            "created_at",
        ]

    def get_collected_amount(self, obj):
        # ✅ Donation عندك لا يحتوي status، بل يحتوي is_confirmed
        total = Donation.objects.filter(
            campaign=obj,
            is_confirmed=True,
        ).aggregate(s=Sum("amount"))["s"]
        return total or 0

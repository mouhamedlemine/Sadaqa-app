from rest_framework import serializers
from .models import Campaign, Donation

class CampaignSerializer(serializers.ModelSerializer):
    owner = serializers.ReadOnlyField(source="owner.id")

    class Meta:
        model = Campaign
        fields = ["id", "owner", "title", "description", "goal_amount", "collected_amount", "is_active", "created_at"]
        read_only_fields = ["collected_amount", "created_at"]


class DonationSerializer(serializers.ModelSerializer):
    donor = serializers.ReadOnlyField(source="donor.id")

    class Meta:
        model = Donation
        fields = ["id", "campaign", "donor", "amount", "created_at", "payment_intent_id", "status"]
        read_only_fields = ["created_at", "payment_intent_id", "status"]


class CreateIntentSerializer(serializers.Serializer):
    campaign_id = serializers.IntegerField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)

class ConfirmIntentSerializer(serializers.Serializer):
    campaign_id = serializers.IntegerField()
    payment_intent_id = serializers.CharField()

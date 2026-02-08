from rest_framework import serializers
from .models import VolunteerRequest


class VolunteerRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = VolunteerRequest
        fields = [
            "id",
            "full_name", "phone", "city",
            "volunteer_type", "time_slot",
            "skills", "notes",
            "status", "created_at",
        ]
        read_only_fields = ["id", "status", "created_at"]


class VolunteerRequestAdminUpdateSerializer(serializers.ModelSerializer):
    """
    للمشرف فقط: يسمح بتغيير status
    """
    class Meta:
        model = VolunteerRequest
        fields = ["status"]

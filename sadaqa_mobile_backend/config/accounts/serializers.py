from django.contrib.auth import get_user_model
from rest_framework import serializers

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)

    class Meta:
        model = User
        fields = ["id", "email", "username", "first_name", "last_name", "password"]

    def create(self, validated_data):
        password = validated_data.pop("password")
        user = User(**validated_data)
        user.set_password(password)
        user.is_active = False
        user.is_email_verified = False
        user.save()
        return user


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ["id", "email", "username", "first_name", "last_name", "is_email_verified"]
        read_only_fields = fields


# ✅ Serializer جديد فقط (للتحقق بعد تسجيل الدخول)
class MeSerializer(serializers.ModelSerializer):
    org_status = serializers.SerializerMethodField()
    org_name = serializers.SerializerMethodField()
    rejection_reason = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "username",
            "is_email_verified",
            "role",
            "is_staff",
            "is_superuser",
            "org_status",
            "org_name",
            "rejection_reason",
        ]

    def get_org_status(self, obj):
        if hasattr(obj, "org_profile"):
            return obj.org_profile.status
        return None

    def get_org_name(self, obj):
        if hasattr(obj, "org_profile"):
            return obj.org_profile.name
        return None

    def get_rejection_reason(self, obj):
        if hasattr(obj, "org_profile"):
            return obj.org_profile.rejection_reason
        return None

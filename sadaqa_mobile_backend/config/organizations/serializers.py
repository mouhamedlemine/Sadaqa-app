from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import OrganizationProfile

# ✅ استدعاء توكن التفعيل + إرسال الإيميل من accounts
from accounts.models import EmailVerificationToken
from accounts.utils import send_verification_email

User = get_user_model()


class OrgRegisterSerializer(serializers.Serializer):
    email = serializers.EmailField()
    username = serializers.CharField()
    password = serializers.CharField(write_only=True, min_length=6)

    name = serializers.CharField()
    phone = serializers.CharField(required=False, allow_blank=True)
    address = serializers.CharField(required=False, allow_blank=True)

    # ✅ لمنع 500 بسبب UNIQUE
    def validate(self, attrs):
        email = attrs.get("email")
        username = attrs.get("username")

        if User.objects.filter(email=email).exists():
            raise serializers.ValidationError({"email": ["هذا البريد مستخدم من قبل."]})

        if User.objects.filter(username=username).exists():
            raise serializers.ValidationError({"username": ["اسم المستخدم مستخدم من قبل."]})

        return attrs

    def create(self, validated):
        # 1) إنشاء user
        user = User.objects.create_user(
            email=validated["email"],
            username=validated["username"],
            password=validated["password"],
        )

        # 2) تعيين role = ORG (إذا موجود عندك)
        user.role = User.Role.ORG
        user.save()

        # ✅ 3) إنشاء توكن تفعيل + إرسال إيميل
        token_obj = EmailVerificationToken.objects.create(user=user)
        send_verification_email(user, str(token_obj.token))

        # 4) إنشاء بروفايل منظمة بحالة PENDING
        OrganizationProfile.objects.create(
            user=user,
            name=validated["name"],
            phone=validated.get("phone", ""),
            address=validated.get("address", ""),
            status=OrganizationProfile.Status.PENDING,
        )

        return user


class OrganizationProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrganizationProfile
        fields = [
            "id", "name", "phone", "address", "document",
            "status", "rejection_reason",
            "submitted_at", "reviewed_at", "created_at"
        ]
        read_only_fields = ["status", "rejection_reason", "submitted_at", "reviewed_at", "created_at"]


class AdminReviewSerializer(serializers.Serializer):
    action = serializers.ChoiceField(choices=["approve", "reject"])
    reason = serializers.CharField(required=False, allow_blank=True)

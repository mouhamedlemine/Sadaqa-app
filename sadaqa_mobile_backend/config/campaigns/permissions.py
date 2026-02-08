from rest_framework.permissions import BasePermission

class IsApprovedOrganization(BasePermission):
    message = "يجب تأكيد البريد وموافقة المشرف على المنظمة قبل إنشاء حملة."

    def has_permission(self, request, view):
        user = request.user
        if not user or not user.is_authenticated:
            return False

        # لازم يكون منظمة
        if getattr(user, "role", None) != "ORG":
            return False

        # لازم يكون البريد متحقق
        if not getattr(user, "is_email_verified", False):
            return False

        # لازم يكون org_profile موجود ومعتمد
        org = getattr(user, "org_profile", None)
        if not org:
            return False

        return org.status == "APPROVED"

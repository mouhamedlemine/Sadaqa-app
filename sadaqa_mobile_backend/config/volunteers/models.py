from django.db import models
from django.conf import settings


class VolunteerRequest(models.Model):
    class VolunteerType(models.TextChoices):
        FIELD = "field", "ميداني"
        ONLINE = "online", "إلكتروني"

    class TimeSlot(models.TextChoices):
        MORNING = "morning", "صباحاً"
        EVENING = "evening", "مساءً"

    class Status(models.TextChoices):
        PENDING = "pending", "قيد المراجعة"
        APPROVED = "approved", "مقبول"
        REJECTED = "rejected", "مرفوض"

    full_name = models.CharField(max_length=120)
    phone = models.CharField(max_length=40)
    city = models.CharField(max_length=80)

    volunteer_type = models.CharField(
        max_length=30,
        choices=VolunteerType.choices,
    )

    time_slot = models.CharField(
        max_length=30,
        choices=TimeSlot.choices,
    )

    skills = models.CharField(max_length=200, blank=True)
    notes = models.TextField(blank=True)

    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="volunteer_requests",
    )

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
    )

    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.full_name} - {self.city} ({self.status})"

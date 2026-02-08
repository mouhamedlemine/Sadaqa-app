from rest_framework import generics, permissions
from .models import VolunteerRequest
from .serializers import VolunteerRequestSerializer


class VolunteerRequestCreateView(generics.CreateAPIView):
    serializer_class = VolunteerRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

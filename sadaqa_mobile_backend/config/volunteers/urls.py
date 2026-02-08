from django.urls import path
from .views import VolunteerRequestCreateView

urlpatterns = [
    path("requests/", VolunteerRequestCreateView.as_view(), name="volunteer-requests"),
]

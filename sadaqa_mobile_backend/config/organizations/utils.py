from django.conf import settings
from django.core.mail import send_mail


def send_org_review_email(email: str, org_name: str, status: str, reason: str = ""):
    """
    status: 'APPROVED' ou 'REJECTED'
    """

    if status == "APPROVED":
        subject = "Approbation de votre demande d’inscription – Organisation"
        message = (
            "Bonjour,\n\n"
            f"Nous avons le plaisir de vous informer que la demande d’inscription "
            f"de votre organisation « {org_name} » a été approuvée avec succès.\n\n"
            "Vous pouvez désormais vous connecter à votre espace organisation "
            "et commencer à créer et gérer vos campagnes de dons sur notre plateforme.\n\n"
            "Nous vous remercions pour votre confiance.\n\n"
            "Cordialement,\n"
            "L’équipe de la plateforme de dons\n"
        )

    else:
        subject = "Décision concernant votre demande d’inscription – Organisation"
        msg_reason = f"\nMotif du refus : {reason}\n" if reason else "\n"
        message = (
            "Bonjour,\n\n"
            f"Nous vous informons que la demande d’inscription de votre organisation "
            f"« {org_name} » n’a pas été approuvée.{msg_reason}\n"
            "Vous avez la possibilité de corriger les informations demandées "
            "et de soumettre une nouvelle demande ultérieurement.\n\n"
            "Nous restons à votre disposition pour toute information complémentaire.\n\n"
            "Cordialement,\n"
            "L’équipe de la plateforme de dons\n"
        )

    send_mail(
        subject=subject,
        message=message,
        from_email=getattr(settings, "DEFAULT_FROM_EMAIL", None),
        recipient_list=[email],
        fail_silently=False,
    )

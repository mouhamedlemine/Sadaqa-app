from django.conf import settings
from django.core.mail import EmailMultiAlternatives
from email.mime.image import MIMEImage
from pathlib import Path


# ─────────────────────────────────────────────────────────────
# Branding helpers
# ─────────────────────────────────────────────────────────────
def _brand_name() -> str:
    return getattr(settings, "PROJECT_NAME", "Sadaqa")


def _brand_colors():
    # يمكنك تغييرها إذا أردت (تناسق مع تطبيقك)
    return {
        "bg": "#f4f6fb",
        "card": "#ffffff",
        "text": "#111827",
        "muted": "#6b7280",
        "border": "#eef2f7",
        "soft": "#f8fafc",
        "grad1": "#7c3aed",
        "grad2": "#2563eb",
    }


def _attach_inline_logo(email_message: EmailMultiAlternatives) -> str | None:
    """
    Attache le logo en inline (CID) pour garantir l'affichage dans Gmail.
    ⚠️ Le logo doit exister ici:
       config/accounts/photo/logo.png   (selon ton projet)
    """
    logo_path = Path(settings.BASE_DIR) / "accounts" / "photo" / "logo.png"

    if not logo_path.exists():
        return None

    with open(logo_path, "rb") as f:
        img = MIMEImage(f.read())
        img.add_header("Content-ID", "<logo_sadaqa>")
        img.add_header("Content-Disposition", "inline", filename="logo.png")
        email_message.attach(img)

    return "logo_sadaqa"


def _send_html_email(to_email: str, subject: str, text_message: str, html_message: str):
    from_email = getattr(settings, "DEFAULT_FROM_EMAIL", None)

    msg = EmailMultiAlternatives(subject, text_message, from_email, [to_email])
    msg.attach_alternative(html_message, "text/html")

    # ✅ Logo inline CID
    _attach_inline_logo(msg)

    msg.send(fail_silently=False)


# ─────────────────────────────────────────────────────────────
# Templates (HTML)
# ─────────────────────────────────────────────────────────────
def _wrap_email_html(title: str, subtitle: str, greeting_html: str, body_html: str, button_href: str,
                    button_label: str, fallback_href: str) -> str:
    project = _brand_name()
    c = _brand_colors()

    # ✅ Table-based layout (أفضل توافق مع Gmail/Outlook)
    # ✅ max-width + padding للهواتف
    return f"""\
<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="x-apple-disable-message-reformatting">
  <title>{title}</title>
</head>

<body style="margin:0;padding:0;background:{c['bg']};font-family:Arial,Helvetica,sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background:{c['bg']};padding:22px 0;">
    <tr>
      <td align="center" style="padding:0 12px;">

        <!-- Card -->
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
               style="max-width:620px;background:{c['card']};border-radius:18px;overflow:hidden;
                      box-shadow:0 12px 30px rgba(16,24,40,0.10);">

          <!-- Top gradient bar -->
          <tr>
            <td style="height:7px;background:linear-gradient(90deg,{c['grad1']},{c['grad2']});"></td>
          </tr>

          <!-- Header -->
          <tr>
            <td align="center" style="padding:26px 18px 10px;">
              <img src="cid:logo_sadaqa" width="82" height="82" alt="{project}"
                   style="display:block;border-radius:18px;background:#ffffff;border:1px solid {c['border']};padding:8px;">

              <div style="margin-top:14px;font-size:22px;font-weight:900;color:{c['text']};">
                {title}
              </div>

              <div style="margin-top:6px;font-size:13.5px;color:{c['muted']};line-height:1.6;max-width:520px;">
                {subtitle}
              </div>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:14px 22px 6px;color:{c['text']};font-size:15px;line-height:1.85;">
              {greeting_html}
              {body_html}

              <!-- Button: full width on mobile -->
              <div style="margin:16px 0 0;text-align:center;">
                <a href="{button_href}"
                   style="display:inline-block;width:100%;max-width:380px;
                          background:linear-gradient(135deg,{c['grad1']},{c['grad2']});
                          color:#ffffff;text-decoration:none;
                          padding:14px 18px;border-radius:14px;
                          font-weight:900;font-size:15px;">
                  {button_label}
                </a>
              </div>

              <!-- Security note -->
              <div style="margin-top:16px;background:{c['soft']};border:1px solid {c['border']};
                          border-radius:14px;padding:12px 14px;color:{c['muted']};font-size:12.8px;line-height:1.6;">
                <strong style="color:{c['text']};">Conseil de sécurité :</strong>
                ne partagez jamais ce lien. Il est personnel et permet d’accéder à votre compte.
              </div>
            </td>
          </tr>

          <!-- Fallback link -->
          <tr>
            <td style="padding:10px 22px 22px;color:{c['muted']};font-size:12.6px;line-height:1.75;">
              <div style="border-top:1px solid {c['border']};padding-top:14px;">
                Si le bouton ne fonctionne pas, copiez et collez ce lien dans votre navigateur :
                <div style="margin-top:10px;word-break:break-all;background:{c['soft']};border:1px solid {c['border']};
                            padding:12px;border-radius:12px;">
                  <a href="{fallback_href}" style="color:{c['grad2']};text-decoration:none;">{fallback_href}</a>
                </div>
              </div>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td align="center" style="padding:16px 18px;background:#fafbff;color:#9ca3af;font-size:12px;">
              © {project} — Tous droits réservés
              <div style="margin-top:6px;color:#b0b7c3;font-size:11.5px;">
                Message automatique — merci de ne pas répondre.
              </div>
            </td>
          </tr>

        </table>

        <div style="max-width:620px;text-align:center;margin-top:12px;color:#9ca3af;font-size:12px;padding:0 8px;">
          Si vous n’êtes pas à l’origine de cette demande, vous pouvez ignorer ce message en toute sécurité.
        </div>

      </td>
    </tr>
  </table>
</body>
</html>
"""


# ─────────────────────────────────────────────────────────────
# Public functions
# ─────────────────────────────────────────────────────────────
def send_verification_email(user, token: str):
    """
    Email de confirmation d'inscription (FR, HTML, logo CID).
    Conserve: EMAIL_VERIFY_BASE_URL + token + "/"
    """
    verify_url = f"{settings.EMAIL_VERIFY_BASE_URL}{token}/"
    project_name = _brand_name()

    first_name = (getattr(user, "first_name", "") or "").strip()
    display_name = first_name if first_name else "utilisateur"

    subject = f"Confirmation d'inscription – {project_name}"

    # Fallback texte
    text_message = (
        f"Bonjour {display_name},\n\n"
        f"Merci pour votre inscription sur {project_name}.\n"
        "Veuillez confirmer votre adresse e-mail via le lien suivant :\n"
        f"{verify_url}\n\n"
        "Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail.\n\n"
        f"Cordialement,\nL’équipe {project_name}\n"
    )

    greeting_html = f"""<p style="margin:0 0 12px;">Bonjour <strong>{display_name}</strong>,</p>"""

    body_html = f"""
      <p style="margin:0 0 12px;">
        Merci pour votre inscription sur <strong>{project_name}</strong>.
        Pour finaliser la création de votre compte, veuillez confirmer votre adresse e-mail
        en cliquant sur le bouton ci-dessous.
      </p>
    """

    html_message = _wrap_email_html(
        title="Confirmation d'inscription",
        subtitle="Vérifiez votre adresse e-mail pour activer votre compte.",
        greeting_html=greeting_html,
        body_html=body_html,
        button_href=verify_url,
        button_label="Confirmer mon adresse e-mail",
        fallback_href=verify_url,
    )

    _send_html_email(user.email, subject, text_message, html_message)


def send_password_reset_email(user, token: str):
    """
    Email de réinitialisation du mot de passe (FR, HTML, logo CID).
    Conserve: PASSWORD_RESET_BASE_URL + token
    """
    reset_url = f"{settings.PASSWORD_RESET_BASE_URL}{token}"
    project_name = _brand_name()

    first_name = (getattr(user, "first_name", "") or "").strip()
    display_name = first_name if first_name else "utilisateur"

    subject = f"Réinitialisation du mot de passe – {project_name}"

    text_message = (
        f"Bonjour {display_name},\n\n"
        f"Vous avez demandé la réinitialisation de votre mot de passe sur {project_name}.\n"
        "Veuillez utiliser le lien suivant :\n"
        f"{reset_url}\n\n"
        "Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail.\n\n"
        f"Cordialement,\nL’équipe {project_name}\n"
    )

    greeting_html = f"""<p style="margin:0 0 12px;">Bonjour <strong>{display_name}</strong>,</p>"""

    body_html = f"""
      <p style="margin:0 0 12px;">
        Vous avez demandé la réinitialisation de votre mot de passe sur <strong>{project_name}</strong>.
        Cliquez sur le bouton ci-dessous pour continuer.
      </p>
    """

    html_message = _wrap_email_html(
        title="Réinitialisation du mot de passe",
        subtitle="Définissez un nouveau mot de passe via le bouton ci-dessous.",
        greeting_html=greeting_html,
        body_html=body_html,
        button_href=reset_url,
        button_label="Réinitialiser mon mot de passe",
        fallback_href=reset_url,
    )

    _send_html_email(user.email, subject, text_message, html_message)

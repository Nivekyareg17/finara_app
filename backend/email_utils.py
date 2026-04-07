import os
from email.mime.text import MIMEText
import resend

resend.api_key = os.getenv("RESEND_API_KEY")

def send_email(to_email, link):
    resend.Emails.send({
        "from": "onboarding@resend.dev",
        "to": to_email,
        "subject": "Recuperar contraseña",
        "html": f"""
        <p>Haz clic para recuperar tu contraseña:</p>
        <a href="{link}">{link}</a>
        """
    })
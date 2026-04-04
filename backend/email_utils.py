import os
import smtplib
from email.mime.text import MIMEText
import resend

EMAIL = "felipearandia24@gmail.com"
PASSWORD = "aexusudnhvrggzbl"



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
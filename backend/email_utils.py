import smtplib
from email.mime.text import MIMEText

EMAIL = "tuemail@gmail.com"
PASSWORD = "tu_app_password"

def send_email(to_email, link):
    msg = MIMEText(f"Recupera tu contraseña aquí: {link}")
    msg["Subject"] = "Recuperar contraseña"
    msg["From"] = EMAIL
    msg["To"] = to_email

    with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
        server.login(EMAIL, PASSWORD)
        server.send_message(msg)
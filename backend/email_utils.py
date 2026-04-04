import smtplib
from email.mime.text import MIMEText

EMAIL = "felipearandia24@gmail.com"
PASSWORD = "aexusudnhvrggzbl"

def send_email(to_email, link):
    try:
        msg = MIMEText(f"""
Hola,

Recupera tu contraseña aquí:

{link}

Si no fuiste tú, ignora este mensaje.
""")

        msg["Subject"] = "Recuperar contraseña - Finara"
        msg["From"] = EMAIL
        msg["To"] = to_email

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(EMAIL, PASSWORD)
            server.send_message(msg)

        print("EMAIL ENVIADO")

    except Exception as e:
        print("ERROR EMAIL:", e)
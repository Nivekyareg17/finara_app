import smtplib
from email.mime.text import MIMEText

EMAIL = "felipearandia24@gmail.com"
PASSWORD = "aexusudnhvrggzbl"

def send_email(to_email, link):
    print("INTENTANDO ENVIAR EMAIL...")

    try:
        msg = MIMEText(f"""
Recupera tu contraseña:

{link}
""")

        msg["Subject"] = "Recuperar contraseña"
        msg["From"] = EMAIL
        msg["To"] = to_email

        server = smtplib.SMTP("smtp.gmail.com", 587)
        server.starttls()

        server.login(EMAIL, PASSWORD)
        print("Login OK")

        server.send_message(msg)
        print("EMAIL ENVIADO")

        server.quit()

    except Exception as e:
        print("ERROR EMAIL:", e)
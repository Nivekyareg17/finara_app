import os
import resend

resend.api_key = os.getenv("RESEND_API_KEY")

def send_email(to_email, link):

    resend.Emails.send({

        "from": "onboarding@resend.dev",
        "to": to_email,
        "subject": "Recuperar contraseña - Finara",

        "html": f"""
        <h2>Recuperar contraseña</h2>

        <p>Haz clic en el botón para crear una nueva contraseña:</p>

        <a href="{link}"
           style="
           background:#18B47A;
           color:white;
           padding:12px 20px;
           text-decoration:none;
           border-radius:8px;
           display:inline-block;
           ">
            Recuperar contraseña
        </a>

        <p>Si no solicitaste esto, ignora este correo.</p>
        """
    })

def send_verification_email(
    to_email,
    link
):

    resend.Emails.send({

        "from":"onboarding@resend.dev",

        "to":to_email,

        "subject":"Verifica tu cuenta Finara",

        "html":f"""
        <h2>Bienvenido a Finara</h2>

        <p>
        Verifica tu correo
        para activar tu cuenta.
        </p>

        <a href="{link}">
        Verificar cuenta
        </a>
        """
    })
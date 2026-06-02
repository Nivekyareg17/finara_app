import os
import resend

resend.api_key = os.getenv("RESEND_API_KEY")


def send_email(
    to_email,
    link
):

    resend.Emails.send({

        "from":
        "Finara <noreply@finaraapp.online>",

        "to":
        to_email,

        "subject":
        "Recuperar contraseña - Finara",

        "html": f"""
        <h2>Recuperar contraseña</h2>

        <p>
        Haz clic en el botón para crear una nueva contraseña:
        </p>

        <p>
        <a href="{link}"
           style="
           background:#18B47A;
           color:white;
           padding:12px 20px;
           border-radius:8px;
           text-decoration:none;
           display:inline-block;
           font-weight:bold;
           ">
           Recuperar contraseña
        </a>
        </p>

        <p>
        Si el botón no funciona, usa este enlace:
        </p>

        <p>
        <a href="{link}">
        {link}
        </a>
        </p>
        """
    })


def send_verification_email(
    to_email,
    link
):

    resend.Emails.send({

        "from":
        "Finara <noreply@finaraapp.online>",

        "to":
        to_email,

        "subject":
        "Verifica tu cuenta Finara",

        "html": f"""
        <h2>Bienvenido a Finara</h2>

        <p>
        Verifica tu correo para activar tu cuenta.
        </p>

        <p>
        <a href="{link}"
           style="
           background:#18B47A;
           color:white;
           padding:12px 20px;
           border-radius:8px;
           text-decoration:none;
           display:inline-block;
           font-weight:bold;
           ">
           Verificar cuenta
        </a>
        </p>

        <p>
        Si el botón no funciona, usa este enlace:
        </p>

        <p>
        <a href="{link}">
        {link}
        </a>
        </p>
        """
    })
import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Términos y Condiciones"),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            "Términos y Condiciones – Finara\n\n"
            "1. Uso de la aplicación\n"
            "Finara es una herramienta de gestión financiera personal. El usuario es responsable del uso que haga de la información registrada dentro de la app.\n\n"
            "2. Registro de cuenta\n"
            "Para acceder a ciertas funcionalidades, debes crear una cuenta proporcionando información veraz y actualizada. Eres responsable de mantener la confidencialidad de tu contraseña.\n\n"
            "3. Datos y privacidad\n"
            "La aplicación almacena información como ingresos, gastos y datos básicos de usuario con el fin de brindar una mejor experiencia. Finara no comparte tu información personal con terceros sin tu consentimiento.\n\n"
            "4. Seguridad\n"
            "Tomamos medidas para proteger tus datos, incluyendo el uso de contraseñas encriptadas. Sin embargo, el usuario también debe proteger el acceso a su cuenta.\n\n"
            "5. Responsabilidad\n"
            "Finara no se hace responsable por decisiones financieras tomadas por el usuario basadas en la información mostrada en la app.\n\n"
            "6. Uso indebido\n"
            "Está prohibido el uso de la aplicación para actividades ilegales o que afecten el funcionamiento del sistema.\n\n"
            "7. Cambios en los términos\n"
            "Nos reservamos el derecho de modificar estos términos en cualquier momento. El uso continuo de la aplicación implica la aceptación de dichos cambios.\n\n"
            "8. Contacto\n"
            "Si tienes dudas o problemas, puedes comunicarte a través de los canales oficiales de soporte de Finara.",
            style: TextStyle(fontSize: 14),
          ),
        ),
      ),
    );
  }
}

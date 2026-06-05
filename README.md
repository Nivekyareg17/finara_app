# 💰 FINARA — Educación Financiera Personal

> Aplicación móvil multiplataforma de educación financiera desarrollada con **Flutter** (frontend) y **FastAPI** (backend), con base de datos **PostgreSQL** desplegada en **Render**.

![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?style=flat-square&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?style=flat-square&logo=dart&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.135-009688?style=flat-square&logo=fastapi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Render-336791?style=flat-square&logo=postgresql&logoColor=white)
![Estado](https://img.shields.io/badge/Estado-En%20desarrollo-yellow?style=flat-square)

---

## 📌 Descripción del proyecto

**FINARA** es una aplicación móvil multiplataforma orientada a la **educación financiera personal**. Permite a los usuarios aprender a gestionar sus finanzas, registrar ingresos y gastos, visualizar su situación económica, leer noticias financieras en tiempo real, consultar precios de acciones y acceder a contenido educativo en video.

### Funcionalidades principales

- 🔐 Registro e inicio de sesión con autenticación JWT
- 📊 Registro y seguimiento de ingresos y egresos por categoría
- 📈 Visualización de datos financieros con gráficas interactivas
- 📰 Noticias financieras en tiempo real (GNews API)
- 📉 Consulta de precios de acciones (Finnhub API)
- 🎓 Contenido educativo en video (YouTube)
- 📖 Lecturas y notas personales
- 💬 Sistema de mensajes internos
- 📄 Generación de reportes en PDF
- 🌐 Soporte multilenguaje con traducción automática (ML Kit)
- 🤖 Integración con Gemini AI
- 👤 Perfil de usuario con foto, edad, descripción y teléfono

---

## 👥 Equipo de desarrollo

| Integrante | Rol |
|---|---|
| Kevin Guevara | Desarrollador backend |
| Felipe Arandia | Desarrollador backend / DB |
| Cristian Rojas | Desarrollador frontend |
| Alexander Cueto | Desarrollador Flutter |

> Proyecto académico — Programa de formación en desarrollo de software · 2026

---

## 🛠️ Tecnologías utilizadas

| Capa | Tecnología | Versión |
|---|---|---|
| Frontend | Flutter / Dart | SDK >= 3.0.0 |
| Backend | Python + FastAPI | FastAPI 0.135 / Python 3.11 |
| Base de datos | PostgreSQL | Render (cloud) |
| ORM | SQLAlchemy | 2.0.48 |
| Autenticación | JWT (python-jose + passlib) | — |
| Gráficas | fl_chart | 0.68.0 |
| PDF | pdf + printing | 3.11 / 5.13 |
| Video | youtube_player_iframe | 5.0.0 |
| Traducción | google_mlkit_translation | 0.12.0 |
| IA | Gemini API | — |
| Noticias | GNews API | — |
| Acciones | Finnhub API | — |
| Emails | Resend API | — |
| Despliegue backend | Render | — |
| Despliegue BD | PostgreSQL en Render | — |

---

## ⚙️ Instalación y configuración local

### Prerrequisitos

| Herramienta | Versión mínima | Enlace |
|---|---|---|
| Flutter SDK | 3.0.0 | https://flutter.dev/docs/get-started |
| Dart SDK | 3.0.0 | Incluido con Flutter |
| Python | 3.11 | https://www.python.org/downloads |
| PostgreSQL | 14+ | https://www.postgresql.org/download |
| Git | Cualquiera | https://git-scm.com |

---

### 1. Clonar el repositorio

```bash
git clone https://github.com/Nivekyareg17/finara_app.git
cd finara_app
```

### 2. Configurar el backend

```bash
cd backend

# Crear y activar entorno virtual
python -m venv venv

# Windows:
venv\Scripts\activate
# Mac / Linux:
source venv/bin/activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar variables de entorno
cp .env.example .env
# Editar .env con tus valores reales
```

### 3. Configurar el frontend

```bash
# Desde la raíz del proyecto
flutter pub get
```

### 4. Base de datos

Si usas PostgreSQL local:

```sql
CREATE DATABASE finara_db;
```

La API crea y actualiza las tablas automáticamente al arrancar (`models.Base.metadata.create_all`), no necesitas correr scripts SQL manualmente.

---

## ▶️ Ejecución local

### Backend

```bash
cd backend
source venv/bin/activate  # si no está activo

uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Verificar que el servidor esté corriendo:
```
http://localhost:8000/          → {"message": "Finara API is running"}
http://localhost:8000/health    → {"status": "ok"}
http://localhost:8000/docs      → Documentación interactiva (Swagger)
```

### Frontend

```bash
flutter run              # dispositivo/emulador por defecto
flutter run -d chrome    # navegador web
flutter devices          # ver dispositivos disponibles
```

---

## 🔐 Variables de entorno

Crear el archivo `backend/.env` basado en `backend/.env.example`:

```env
# Base de datos (PostgreSQL en Render o local)
DATABASE_URL=postgresql://usuario:contraseña@host:5432/nombre_bd

# Autenticación JWT
SECRET_KEY=tu_clave_secreta_aqui
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=120

# APIs externas
GEMINI_API_KEY=tu_api_key_de_gemini
RESEND_API_KEY=tu_api_key_de_resend
FINNHUB_API_KEY=tu_api_key_de_finnhub
GNEWS_API_KEY=tu_api_key_de_gnews
```

> ⚠️ Nunca subas el archivo `.env` real al repositorio. El `.gitignore` ya lo excluye.

Para obtener las API keys:
- **Gemini:** https://aistudio.google.com/app/apikey
- **Resend:** https://resend.com
- **Finnhub:** https://finnhub.io
- **GNews:** https://gnews.io

---

## 📁 Estructura del repositorio

```
finara_app/
├── backend/                  # API REST con FastAPI (Python)
│   ├── main.py              # Punto de entrada — registra todos los routers
│   ├── database.py          # Configuración de conexión SQLAlchemy
│   ├── models.py            # Modelos de base de datos
│   ├── .env.example         # Plantilla de variables de entorno
│   ├── routers/             # Endpoints organizados por módulo
│   │   ├── auth_routes.py
│   │   ├── user_routes.py
│   │   ├── transaction_routes.py
│   │   ├── category_routes.py
│   │   ├── video_routes.py
│   │   ├── lecturas_routes.py
│   │   ├── stock_routes.py
│   │   ├── message_routes.py
│   │   ├── news_routes.py
│   │   └── notes_routes.py
│   └── static/
│       └── profile_pics/    # Imágenes de perfil de usuarios
│
├── lib/                      # Código Dart / Flutter
├── android/                  # Configuración Android
├── ios/                      # Configuración iOS
├── web/                      # Configuración Web
├── assets/
│   └── images/              # Recursos gráficos e íconos
├── pubspec.yaml              # Dependencias Flutter
├── requirements.txt          # Dependencias Python (backend)
├── runtime.txt               # Versión de Python para Render
└── README.md
```

---

## 🗄️ Base de datos

- **Motor:** PostgreSQL
- **Hosting:** Render (cloud)
- **ORM:** SQLAlchemy 2.0
- **Driver:** psycopg2-binary

Las tablas principales son: `users`, `transactions`, `categories`. La API aplica migraciones automáticas al iniciar mediante `apply_schema_updates()` en `main.py`, por lo que no se requiere ejecutar scripts SQL manualmente.

---

## 🌐 Endpoints principales de la API

| Módulo | Prefijo | Descripción |
|---|---|---|
| Auth | `/auth` | Registro, login, tokens JWT |
| Usuarios | `/users` | Perfil, foto, datos personales |
| Transacciones | `/transactions` | Ingresos y egresos |
| Categorías | `/categories` | Gestión de categorías |
| Videos | `/videos` | Contenido educativo YouTube |
| Lecturas | `/lecturas` | Artículos y lecturas |
| Notas | `/notes` | Notas personales del usuario |
| Acciones | `/stocks` | Precios de acciones (Finnhub) |
| Noticias | `/news` | Noticias financieras (GNews) |
| Mensajes | `/messages` | Sistema de mensajes internos |

Documentación completa disponible en `/docs` cuando el servidor esté corriendo.

---

## 🚀 Despliegue

### Backend en Render

1. Crear cuenta en [render.com](https://render.com)
2. **New → Web Service** → conectar el repositorio
3. Configurar:
   - **Root Directory:** `backend`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `uvicorn main:app --host 0.0.0.0 --port $PORT`
4. Agregar todas las variables del `.env.example` en el panel de Render → Environment
5. Deploy

### Base de datos en Render

1. **New → PostgreSQL** en Render
2. Crear la base de datos
3. Copiar la **Internal Database URL**
4. Usarla como valor de `DATABASE_URL` en el servicio web

### APK Android

```bash
flutter build apk --release
# Salida: build/app/outputs/flutter-apk/app-release.apk
```

### Web

```bash
flutter build web
# Subir build/web/ a Firebase Hosting, GitHub Pages u otro hosting estático
```

---

## 📦 Dependencias principales

### Flutter (`pubspec.yaml`)

| Paquete | Uso |
|---|---|
| `provider` | Gestión de estado |
| `http` | Llamadas a la API REST |
| `flutter_secure_storage` | Almacenamiento seguro de tokens JWT |
| `shared_preferences` | Preferencias locales del usuario |
| `fl_chart` | Gráficas financieras |
| `youtube_player_iframe` | Reproductor de videos educativos |
| `pdf` + `printing` | Generación y vista previa de reportes PDF |
| `google_mlkit_translation` | Traducción automática de contenido |
| `google_mlkit_language_id` | Detección de idioma |
| `image_picker` | Selección de foto de perfil |
| `intl` | Formato de fechas y monedas |
| `url_launcher` | Abrir enlaces externos |
| `flutter_markdown` | Renderizado de contenido Markdown |
| `animated_text_kit` | Animaciones de texto |

### Python (`requirements.txt`)

| Paquete | Uso |
|---|---|
| `fastapi` | Framework del API REST |
| `uvicorn` | Servidor ASGI |
| `sqlalchemy` | ORM para PostgreSQL |
| `psycopg2-binary` | Driver de PostgreSQL |
| `passlib` | Hash seguro de contraseñas |
| `python-jose` | Generación y validación de tokens JWT |
| `pydantic` | Validación de datos y esquemas |
| `requests` | Llamadas HTTP a APIs externas |

---

## 📄 Autoría y licencia académica

Este proyecto fue desarrollado con fines académicos como parte del programa de formación en desarrollo de software.

**Integrantes:**
- Kevin Guevara
- Felipe Arandia
- Cristian Rojas
- Alexander Cueto

**Año:** 2026

---

> Este repositorio es de uso académico. Su distribución o uso comercial requiere autorización explícita de los autores.
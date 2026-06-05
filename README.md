================================================================================
                         FINARA APP - README OFICIAL
                     Aplicación de Educación Financiera

Repositorio: https://github.com/Nivekyareg17/finara_app
Versión:     1.0.0+1
Ficha SENA:  3147272

--------------------------------------------------------------------------------
1. DESCRIPCIÓN DEL PROYECTO
--------------------------------------------------------------------------------

Finara es una aplicación móvil de educación y gestión financiera personal
desarrollada con Flutter (frontend) y FastAPI sobre Python (backend), con
PostgreSQL como base de datos relacional.

La app ofrece calculadoras financieras (interés simple, interés compuesto,
préstamos, ahorro e inflación), seguimiento de metas de ahorro, contenido
educativo financiero con soporte para video y traducción multilingüe, y
generación de reportes en PDF. Está orientada a usuarios hispanohablantes que
desean tomar mejores decisiones con su dinero.

--------------------------------------------------------------------------------
2. TECNOLOGÍAS UTILIZADAS
--------------------------------------------------------------------------------

FRONTEND
  - Flutter SDK >= 3.0.0 < 4.0.0  (Dart)
  - Provider 6.1.2          — gestión de estado
  - fl_chart 0.68.0         — gráficas financieras
  - http 1.2.1              — consumo de la API REST
  - flutter_secure_storage  — almacenamiento seguro de tokens
  - shared_preferences      — preferencias de usuario
  - image_picker            — selección de imágenes
  - pdf + printing          — generación y exportación de reportes PDF
  - google_mlkit_translation / language_id — traducción e identificación de idioma
  - youtube_player_iframe   — reproducción de videos educativos
  - flutter_inappwebview    — navegación web embebida
  - animated_text_kit       — animaciones de texto
  - flutter_multi_formatter — formato de inputs financieros
  - intl 0.20.2             — internacionalización y formato de fechas/moneda
  - app_links               — deep linking

BACKEND
  - Python 3.x
  - FastAPI 0.135.1         — framework REST
  - Uvicorn 0.41.0          — servidor ASGI
  - SQLAlchemy 2.0.48       — ORM
  - Pydantic 2.12.5         — validación de datos / schemas
  - Passlib 1.7.4           — hashing de contraseñas (bcrypt)
  - python-jose 3.5.0       — generación y verificación de JWT
  - psycopg2-binary 2.9.11  — driver de PostgreSQL

BASE DE DATOS
  - PostgreSQL (versión recomendada: 14+)

--------------------------------------------------------------------------------
3. ESTRUCTURA DEL REPOSITORIO
--------------------------------------------------------------------------------

finara_app/
├── backend/                  ← API REST (FastAPI + Python)
│   ├── main.py               ← punto de entrada, configuración de rutas
│   ├── models.py             ← modelos SQLAlchemy (tablas ORM)
│   ├── schemas.py            ← esquemas Pydantic (validación)
│   ├── database.py           ← configuración de conexión a PostgreSQL
│   ├── auth.py               ← lógica JWT y autenticación
│   └── routers/              ← módulos de endpoints por recurso
│       ├── users.py
│       ├── transactions.py
│       └── goals.py
│
├── lib/                      ← Código fuente Flutter (Dart)
│   ├── main.dart             ← entrada de la aplicación
│   ├── screens/              ← pantallas (calculadoras, perfil, home, etc.)
│   │   ├── calculators_screen.dart
│   │   ├── compound_interest_screen.dart
│   │   ├── inflation_screen.dart
│   │   ├── loan_screen.dart
│   │   ├── savings_goal_screen.dart
│   │   └── simple_interest_screen.dart
│   ├── providers/            ← gestión de estado con Provider
│   └── services/             ← consumo de API y almacenamiento
│
├── assets/
│   └── images/               ← logo e imágenes de la app
│
├── android/                  ← configuración Android
├── ios/                      ← configuración iOS
├── web/                      ← configuración Web
├── linux/ / macos/ / windows/← plataformas de escritorio
├── pubspec.yaml              ← dependencias Flutter
├── requirements.txt          ← dependencias Python
└── runtime.txt               ← versión de Python para despliegue

NOTA: La carpeta "database/" con migraciones y scripts SQL debe crearse
siguiendo el esquema documentado en la sección 7.

--------------------------------------------------------------------------------
4. PRE-REQUISITOS
--------------------------------------------------------------------------------

  - Flutter SDK >= 3.0.0   https://docs.flutter.dev/get-started/install
  - Dart SDK (incluido con Flutter)
  - Python >= 3.10          https://www.python.org/downloads/
  - pip (incluido con Python)
  - PostgreSQL >= 14         https://www.postgresql.org/download/
  - Git

Verificar instalaciones:
  flutter --version
  python --version
  psql --version

--------------------------------------------------------------------------------
5. INSTALACIÓN
--------------------------------------------------------------------------------

5.1  CLONAR EL REPOSITORIO
------------------------------
  git clone https://github.com/Nivekyareg17/finara_app.git
  cd finara_app


5.2  FLUTTER (FRONTEND)
------------------------------
Desde la raíz del proyecto:

  flutter pub get

Esto descarga todas las dependencias listadas en pubspec.yaml.

Verificar que los dispositivos/emuladores estén disponibles:
  flutter devices


5.3  BACKEND (FastAPI + Python)
------------------------------
  cd backend
  python -m venv venv

En Windows:
  venv\Scripts\activate

En macOS/Linux:
  source venv/bin/activate

Instalar dependencias:
  pip install -r ../requirements.txt


5.4  BASE DE DATOS (PostgreSQL)
------------------------------
Crear la base de datos y el usuario en psql:

  CREATE USER finara_user WITH PASSWORD 'tu_contrasena_segura';
  CREATE DATABASE finara_db OWNER finara_user;
  GRANT ALL PRIVILEGES ON DATABASE finara_db TO finara_user;

Ejecutar el script de inicialización (ver sección 7):
  psql -U finara_user -d finara_db -f database/schema.sql

--------------------------------------------------------------------------------
6. VARIABLES DE ENTORNO
--------------------------------------------------------------------------------

Crear el archivo backend/.env con las siguientes variables:

  # Base de datos
  DATABASE_URL=postgresql://finara_user:tu_contrasena@localhost:5432/finara_db

  # Seguridad JWT
  SECRET_KEY=clave_secreta_muy_larga_y_aleatoria_minimo_32_caracteres
  ALGORITHM=HS256
  ACCESS_TOKEN_EXPIRE_MINUTES=60

  # Servidor (opcional, para producción)
  HOST=0.0.0.0
  PORT=8000

  # Entorno
  ENVIRONMENT=development

IMPORTANTE: El archivo .env está en .gitignore. Nunca subir credenciales
reales al repositorio.

El frontend (Flutter) se conecta al backend mediante la URL base definida en
lib/services/api_service.dart. Para desarrollo local:
  const String baseUrl = "http://127.0.0.1:8000";

Para pruebas en dispositivo físico, usar la IP local de la máquina:
  const String baseUrl = "http://192.168.X.X:8000";

--------------------------------------------------------------------------------
7. BASE DE DATOS — ESQUEMA SQL
--------------------------------------------------------------------------------

Esquema real extraído del dump de PostgreSQL del proyecto (schema-only).
Guardar como database/schema.sql y ejecutar con el comando de la sección 5.4.
Credenciales y datos de usuarios NO están incluidos en este archivo.

Base de datos: finara_db
Motor:         PostgreSQL 18.4
Zona horaria:  UTC (configurada en la instancia)

------------------------------------------------------------
-- MODULO: USUARIOS Y ROLES
------------------------------------------------------------

-- TABLA: roles
-- Catalogo de roles del sistema (ej. 'admin', 'usuario').
-- Referenciada por users.role_id para control de acceso.
------------------------------------------------------------
CREATE TABLE public.roles (
    id   SERIAL PRIMARY KEY,
    name CHARACTER VARYING
);

-- TABLA: users
-- Usuarios registrados en la aplicacion.
-- password: hash bcrypt (nunca texto plano).
-- is_verified: true si el correo fue confirmado via token.
-- is_deleted: borrado logico; el registro no se elimina fisicamente.
-- role_id: FK a roles; define permisos dentro de la app.
------------------------------------------------------------
CREATE TABLE public.users (
    id                SERIAL PRIMARY KEY,
    name              CHARACTER VARYING,
    email             CHARACTER VARYING,
    password          CHARACTER VARYING,        -- hash bcrypt
    is_verified       BOOLEAN,
    is_deleted        BOOLEAN,
    profile_image_url CHARACTER VARYING,
    username          CHARACTER VARYING,
    age               INTEGER,
    description       CHARACTER VARYING,
    phone             CHARACTER VARYING,
    role_id           INTEGER REFERENCES public.roles(id)
);

------------------------------------------------------------
-- MODULO: AUTENTICACION Y SEGURIDAD
------------------------------------------------------------

-- TABLA: password_reset_tokens
-- Tokens temporales para recuperacion de contrasena via email.
-- expires_at: fecha/hora de vencimiento del token.
------------------------------------------------------------
CREATE TABLE public.password_reset_tokens (
    id         SERIAL PRIMARY KEY,
    token      CHARACTER VARYING,
    expires_at TIMESTAMP WITHOUT TIME ZONE,
    user_id    INTEGER REFERENCES public.users(id)
);

-- TABLA: email_verification_tokens
-- Tokens para verificar la direccion de correo al registrarse.
-- expires_at: fecha/hora de vencimiento del token.
------------------------------------------------------------
CREATE TABLE public.email_verification_tokens (
    id         SERIAL PRIMARY KEY,
    token      CHARACTER VARYING,
    expires_at TIMESTAMP WITHOUT TIME ZONE,
    user_id    INTEGER REFERENCES public.users(id)
);

------------------------------------------------------------
-- MODULO: FINANZAS PERSONALES
------------------------------------------------------------

-- TABLA: categories
-- Categorias de ingresos/gastos, personalizables por usuario.
-- type: 'ingreso' o 'gasto'.
-- currency: moneda asociada a la categoria.
-- user_id: NULL = categoria global del sistema;
--          con valor = categoria privada del usuario.
------------------------------------------------------------
CREATE TABLE public.categories (
    id       SERIAL PRIMARY KEY,
    name     CHARACTER VARYING NOT NULL,
    type     CHARACTER VARYING,
    currency CHARACTER VARYING,
    user_id  INTEGER REFERENCES public.users(id)
);

-- TABLA: transactions
-- Movimientos financieros (ingresos y gastos) del usuario.
-- amount: monto de la transaccion (double precision).
-- type: 'ingreso' o 'gasto'.
-- currency: moneda de la transaccion.
-- category_id: FK a categories para clasificar el movimiento.
-- date: fecha y hora en que ocurrio la transaccion.
------------------------------------------------------------
CREATE TABLE public.transactions (
    id          SERIAL PRIMARY KEY,
    amount      DOUBLE PRECISION,
    type        CHARACTER VARYING,
    description CHARACTER VARYING,
    currency    CHARACTER VARYING,
    user_id     INTEGER REFERENCES public.users(id),
    category_id INTEGER REFERENCES public.categories(id),
    date        TIMESTAMP WITHOUT TIME ZONE
);

------------------------------------------------------------
-- MODULO: CONTENIDO EDUCATIVO
------------------------------------------------------------

-- TABLA: video_categories
-- Categorias tematicas para agrupar los videos educativos.
-- title: nombre de la categoria (ej. 'Ahorro', 'Inversion').
-- description: descripcion corta de la categoria.
------------------------------------------------------------
CREATE TABLE public.video_categories (
    id          SERIAL PRIMARY KEY,
    title       CHARACTER VARYING,
    description CHARACTER VARYING
);

-- TABLA: videos
-- Videos educativos financieros disponibles en la app.
-- url: enlace de YouTube u otro proveedor de video.
-- category_id: FK a video_categories.
------------------------------------------------------------
CREATE TABLE public.videos (
    id          SERIAL PRIMARY KEY,
    title       CHARACTER VARYING,
    url         CHARACTER VARYING,
    category_id INTEGER REFERENCES public.video_categories(id)
);

-- TABLA: lecturas
-- Articulos y lecturas educativas financieras en texto.
-- tiempo_lectura: estimado en texto libre (ej. '5 min').
-- contenido: cuerpo completo del articulo.
------------------------------------------------------------
CREATE TABLE public.lecturas (
    id             SERIAL PRIMARY KEY,
    titulo         CHARACTER VARYING,
    contenido      CHARACTER VARYING,
    tiempo_lectura CHARACTER VARYING
);

------------------------------------------------------------
-- MODULO: INTELIGENCIA ARTIFICIAL
------------------------------------------------------------

-- TABLA: ai_usage_stats
-- Control de consumo de la funcionalidad de IA por usuario.
-- daily_tokens_count: tokens usados en el dia actual.
-- daily_limit: limite diario de tokens permitidos.
-- is_premium: true si el usuario tiene acceso ampliado a IA.
-- last_query_timestamp: fecha/hora de la ultima consulta realizada.
------------------------------------------------------------
CREATE TABLE public.ai_usage_stats (
    id                   SERIAL PRIMARY KEY,
    user_id              INTEGER REFERENCES public.users(id),
    daily_tokens_count   INTEGER,
    daily_limit          INTEGER,
    last_query_timestamp TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW(),
    is_premium           BOOLEAN
);

-- TABLA: ai_chat_history
-- Historial de conversaciones del usuario con el asistente de IA.
-- session_id: identificador unico de la sesion de chat.
-- session_title: titulo descriptivo de la sesion generado automaticamente.
-- tool: herramienta o modulo de IA utilizado en la sesion.
-- user_message: mensaje enviado por el usuario.
-- ai_response: respuesta completa del modelo en formato JSONB.
------------------------------------------------------------
CREATE TABLE public.ai_chat_history (
    id            SERIAL PRIMARY KEY,
    user_id       INTEGER REFERENCES public.users(id),
    session_id    CHARACTER VARYING,
    session_title CHARACTER VARYING,
    tool          CHARACTER VARYING,
    user_message  TEXT,
    ai_response   JSONB,
    created_at    TIMESTAMP WITHOUT TIME ZONE DEFAULT NOW()
);

------------------------------------------------------------
-- MODULO: SOCIAL Y MENSAJERIA
------------------------------------------------------------

-- TABLA: message_requests
-- Solicitudes de contacto entre usuarios antes de habilitar el chat.
-- status: 'pendiente' | 'aceptado' | 'rechazado'.
-- sender_id / receiver_id: FKs a users.
------------------------------------------------------------
CREATE TABLE public.message_requests (
    id          SERIAL PRIMARY KEY,
    sender_id   INTEGER NOT NULL REFERENCES public.users(id),
    receiver_id INTEGER NOT NULL REFERENCES public.users(id),
    status      CHARACTER VARYING,
    created_at  TIMESTAMP WITHOUT TIME ZONE
);

-- TABLA: messages
-- Mensajes directos entre usuarios (chat privado).
-- is_read: false = mensaje no leido por el receptor.
-- timestamp: fecha y hora exacta de envio del mensaje.
------------------------------------------------------------
CREATE TABLE public.messages (
    id          SERIAL PRIMARY KEY,
    content     CHARACTER VARYING NOT NULL,
    "timestamp" TIMESTAMP WITHOUT TIME ZONE,
    sender_id   INTEGER REFERENCES public.users(id),
    receiver_id INTEGER REFERENCES public.users(id),
    is_read     BOOLEAN
);

-- TABLA: blocked_users
-- Registro de bloqueos entre usuarios.
-- blocker_id: usuario que realiza el bloqueo.
-- blocked_id: usuario que es bloqueado.
------------------------------------------------------------
CREATE TABLE public.blocked_users (
    id         SERIAL PRIMARY KEY,
    blocker_id INTEGER REFERENCES public.users(id),
    blocked_id INTEGER REFERENCES public.users(id)
);

------------------------------------------------------------
-- MODULO: NOTAS PERSONALES
------------------------------------------------------------

-- TABLA: notes
-- Notas personales financieras del usuario.
-- category_name: etiqueta libre (texto, no FK a otra tabla).
-- created_at / updated_at: fechas de creacion y ultima edicion.
------------------------------------------------------------
CREATE TABLE public.notes (
    id            SERIAL PRIMARY KEY,
    title         CHARACTER VARYING NOT NULL,
    content       CHARACTER VARYING NOT NULL,
    category_name CHARACTER VARYING,
    user_id       INTEGER REFERENCES public.users(id),
    created_at    TIMESTAMP WITHOUT TIME ZONE,
    updated_at    TIMESTAMP WITHOUT TIME ZONE
);

------------------------------------------------------------
-- RESUMEN: 15 TABLAS EN TOTAL
------------------------------------------------------------
--  roles                      -- catalogo de roles de usuario
--  users                      -- usuarios registrados
--  password_reset_tokens      -- tokens recuperacion de contrasena
--  email_verification_tokens  -- tokens verificacion de email
--  categories                 -- categorias de ingresos/gastos
--  transactions               -- movimientos financieros
--  video_categories           -- categorias de videos educativos
--  videos                     -- videos educativos financieros
--  lecturas                   -- articulos educativos de lectura
--  ai_usage_stats             -- control de uso de IA por usuario
--  ai_chat_history            -- historial de chat con IA
--  message_requests           -- solicitudes de contacto social
--  messages                   -- mensajes directos entre usuarios
--  blocked_users              -- bloqueos entre usuarios
--  notes                      -- notas personales del usuario
------------------------------------------------------------

--------------------------------------------------------------------------------
8. EJECUCIÓN LOCAL
--------------------------------------------------------------------------------

8.1  INICIAR EL BACKEND (FastAPI)
-------------------------------------
  cd backend
  source venv/bin/activate    (o venv\Scripts\activate en Windows)
  uvicorn main:app --reload --host 0.0.0.0 --port 8000

El servidor quedará disponible en:
  http://127.0.0.1:8000

Documentación interactiva (Swagger UI):
  http://127.0.0.1:8000/docs

Documentación alternativa (ReDoc):
  http://127.0.0.1:8000/redoc

Flags útiles:
  --reload          recarga automática al guardar cambios (solo desarrollo)
  --workers 4       múltiples workers para producción (sin --reload)


8.2  INICIAR EL FRONTEND (Flutter)
-------------------------------------
Desde la raíz del proyecto (en otra terminal):

  flutter run

Para elegir un dispositivo específico:
  flutter run -d <device_id>

Para correr en modo release:
  flutter run --release

Para web:
  flutter run -d chrome

Compilar APK para Android:
  flutter build apk --release

--------------------------------------------------------------------------------
9. DESPLIEGUE
--------------------------------------------------------------------------------

BACKEND — Opciones recomendadas:
  - Railway:   conectar el repositorio y configurar las variables de entorno
               del .env directamente en el panel de Railway.
               El archivo runtime.txt especifica la versión de Python.
  - Render:    crear un Web Service con el comando de inicio:
                 uvicorn main:app --host 0.0.0.0 --port $PORT
  - VPS (ej. DigitalOcean): usar Gunicorn + Uvicorn workers detrás de Nginx.
               Comando:
                 gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker

BASE DE DATOS — Opciones recomendadas:
  - Supabase (PostgreSQL gestionado, capa gratuita disponible)
  - ElephantSQL
  - Railway PostgreSQL add-on
  En producción, reemplazar DATABASE_URL en las variables de entorno del
  servicio de despliegue.

FLUTTER — Distribución:
  - Android: Google Play Store (flutter build appbundle --release)
  - iOS:     App Store (requiere cuenta de desarrollador Apple)
  - Web:     Firebase Hosting / Netlify / Vercel (flutter build web)

--------------------------------------------------------------------------------
10. AUTORÍA ACADÉMICA
--------------------------------------------------------------------------------

Este proyecto fue desarrollado como trabajo de grado por el equipo Finara Team
en el marco del programa de formación del SENA, ficha 3147272.

  Cristian Rojas     — Desarrollo backend / integración API
  Felipe Arandia     — Desarrollo frontend Flutter / UI
  Alexander Cueto    — Lógica de calculadoras / arquitectura de datos
  Kevin Guevara      — Base de datos PostgreSQL / despliegue

Institución: Servicio Nacional de Aprendizaje (SENA)
Ficha:       3147272
Repositorio: https://github.com/Nivekyareg17/finara_app

--------------------------------------------------------------------------------
11. LICENCIA
--------------------------------------------------------------------------------

Proyecto académico — uso educativo. Todos los derechos reservados por los
autores. No se permite redistribución comercial sin autorización expresa del
Finara Team.

================================================================================

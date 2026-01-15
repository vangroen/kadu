Kadu: Tu Asistente Inteligente de Alacena 🥑📱

"Deja de tirar comida. Empieza a ahorrar dinero."

🌟 Visión del Proyecto

Kadu nace de una problemática global y cotidiana: el desperdicio de alimentos. Millones de toneladas de comida se tiran cada año simplemente porque olvidamos que estaban en el fondo de la nevera o alacena hasta que caducaron.

Nuestra Misión: Empoderar a los hogares para gestionar su consumo de alimentos de manera inteligente, reduciendo el desperdicio a cero y generando un ahorro económico tangible.

Nuestra Visión: Convertirnos en el estándar de gestión de inventario doméstico en Latinoamérica, integrando Inteligencia Artificial para hacer que el proceso de "hacer la lista de compras" y "cocinar con lo que tienes" sea automático y sin fricción.

🚀 ¿Qué hace Kadu? (Funcionalidades Clave)

Kadu no es solo una lista de tareas. Es un escáner inteligente que entiende tus productos.

📸 Escaneo Híbrido Inteligente:

Paso 1: Escanea el Código de Barras para identificar el producto (nombre, marca) automáticamente consultando bases de datos globales (OpenFoodFacts).

Paso 2: Escanea la Fecha de Vencimiento usando OCR (Reconocimiento Óptico de Caracteres) avanzado que detecta formatos complejos (e.g., "30 SEP 25", "VTO 12/12/2026").

☁️ Almacenamiento en la Nube Privada y Optimizado:

Cada usuario tiene su propia base de datos segura.

Sincronización en tiempo real: Lo que escaneas en tu celular aparece en el de tu familia.

**[NUEVO] Almacenamiento de Fotos "Lightweight":** Implementamos un sistema de compresión inteligente que guarda las fotos de tus productos directamente en la base de datos (Base64), eliminando la dependencia de configuraciones complejas de Storage y asegurando que la app siga siendo rápida y gratuita de operar.

🔍 Vista Previa de Productos:

Ahora puedes tocar la miniatura de cualquier producto en tu alacena para ver la foto en pantalla completa, con capacidad de Zoom para ver los detalles.

🔔 Alertas de Caducidad (Próximamente):

Notificaciones automáticas: "Tu leche vence mañana. ¡Úsala hoy!".

👤 Gestión de Usuarios:

Login seguro con Google o Modo Invitado para probar sin compromiso.

🛠️ Stack Tecnológico

El proyecto está construido con tecnologías modernas, priorizando la escalabilidad, el rendimiento y la experiencia de usuario nativa.

Framework Principal: Flutter (Dart 3.x) - Para despliegue nativo en Android (y iOS a futuro).

Gestión de Estado: Riverpod 2.x - La solución más robusta y testable para el manejo de datos en Flutter.

Backend as a Service (BaaS): Firebase

Auth: Autenticación (Google Sign-In, Anónimo).

Firestore: Base de datos NoSQL en tiempo real para datos e imágenes (Base64).

Librerías Clave:
- google_mlkit_text_recognition: Para leer fechas (OCR).
- google_mlkit_barcode_scanning: Para leer códigos EAN/UPC.
- flutter_image_compress: Para optimización agresiva de imágenes.

Arquitectura: Clean Architecture + Feature-First (Separación clara de Capas: Presentación, Dominio, Datos).

📂 Estructura del Proyecto

El código está organizado modularmente en lib/features/ para facilitar el mantenimiento y la escalabilidad.

lib/
├── core/                  # Configuraciones globales (Temas, Utilidades)
├── features/
│   ├── auth/              # Lógica de Login y Registro
│   │   ├── data/          # Repositorios de Firebase Auth
│   │   └── presentation/  # Pantallas de Login
│   ├── home/              # Dashboard principal y Navegación
│   ├── inventory/         # Gestión de la Alacena (CRUD)
│   │   ├── data/          # Repositorio de Firestore (lógica Base64)
│   │   ├── domain/        # Entidades (ProductEntity)
│   │   └── presentation/  # Pantallas de lista y detalle (con Preview)
│   └── scan/              # Módulo de Cámara e IA
│       ├── data/          # Servicios de OCR y API de Productos
│       └── presentation/  # Pantalla de Escaneo (Máquina de Estados)
└── main.dart              # Punto de entrada y AuthGate


🏁 Cómo Empezar (Para Desarrolladores)

Si quieres colaborar o probar el proyecto en tu máquina local:

Prerrequisitos

Flutter SDK (Versión Stable más reciente).

Android Studio (con SDK y herramientas de línea de comandos).

Dispositivo Android Físico (Recomendado para probar la cámara) o Emulador.

Instalación

Clona el repositorio:

git clone [https://github.com/tu-usuario/kadu.git](https://github.com/tu-usuario/kadu.git)
cd kadu


Instala las dependencias:

flutter pub get


Configura Firebase (Necesario para que funcione):

Necesitarás tu propio archivo google-services.json en android/app/.

Debes registrar las huellas digitales SHA-1 y SHA-256 de tu máquina en la consola de Firebase para que el Login de Google funcione.

Ejecuta la app:

flutter run


🔮 Próximos Pasos (Roadmap)

[x] Guardado eficiente de imágenes (Base64 + Compresión).
[x] Vista previa de imágenes con Zoom.

[ ] Notificaciones Push: Avisar al usuario antes de que algo venza.

[ ] Modo Offline Robusto: Que la app funcione perfectamente en el sótano del supermercado y sincronice al volver.

[ ] Recetas Inteligentes: Sugerir qué cocinar con los ingredientes que están por vencer.

[ ] Soporte iOS: Adaptar permisos y configuraciones para Apple.

## 📄 Historial de Cambios
Para ver el detalle de todas las actualizaciones, consulta el [CHANGELOG.md](CHANGELOG.md).

Hecho con ❤️ y 🥑 por el equipo de Kadu.
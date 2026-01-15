# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.3] - 2026-01-15
### Mejoras (UX)
- **Gestos de Deslizamiento Mejorados**:
  - **Editar**: Deslizar a la DERECHA (Fondo Azul con texto "EDITAR").
  - **Eliminar**: Deslizar a la IZQUIERDA (Fondo Rojo con texto "ELIMINAR").
- **Protección de Borrado**: Se añadió un diálogo de confirmación al intentar eliminar un producto para prevenir accidentes.
- **Edición de Productos**: Ahora es posible editar nombre, cantidad y fecha de los productos existentes reutilizando la pantalla de "Agregar Producto".

## [1.0.2] - 2026-01-15
### Añadido
- **Eliminar Productos**: Ahora es posible eliminar productos de la alacena deslizando la tarjeta hacia los lados (Swipe to Dismiss) con feedback visual y háptico.
- **Conexión Real con Auth**: Se eliminó el usuario de prueba (`test_user_dev_1`) y se conectó el repositorio con `FirebaseAuth`, asegurando que cada usuario tenga su propia base de datos privada.

### Commits
- `985a3a4` feat: eliminacion de pantry de derecha e izquierda
- `5668c1d` (Auth Connection & Fixes)

## [1.0.1] - 2026-01-15
### Añadido
- **Vista Previa de Imágenes**: Modal interactivo en la lista de alacena que permite ver la foto del producto en pantalla completa con soporte para Zoom.
- **Compresión de Imágenes**: Implementación de `flutter_image_compress`.

### Cambiado
- **Almacenamiento de Imágenes**: Migración a Base64 en Firestore para evitar costos de Storage.
- **Optimización**: Compresión agresiva (800x800, 60%).

### Commits
- `f4df6d2` feat: mejora inspeccion foto dede pantry
- `7be8a12` feat: mejora guardado imagenes por producto

## [1.0.0] - 2026-01-14
### Añadido
- **Historial**: Nuevas pantallas para visualizar el historial de escaneos y acciones.
- **Navegación**: Implementación de rutas hacia el historial.
- **Login**: Integración completa con Firebase Auth y migración de base de datos local a nube al iniciar sesión.
- **UI**: Mejoras visuales en la pantalla del escáner (Home).

### Commits
- `f640513` feat: se agrega la navegacion al historial
- `b0653fb` feat: se agrega historial visual
- `4758509` feat: se migra base de datos a firebase al login
- `f9cf585` feat: intento de integracion con firebase

## [0.1.0] - 2026-01-11 (Prototipo)
### Inicial
- **Prototipo Base**: Estructura inicial del proyecto, configuración de Flutter y primeras pantallas.
- **Home**: Dashboard principal con navegación inicial.
- **Escáner**: Primera versión de la cámara con estilos básicos.

### Commits
- `b394f15` feat: se mejora estilos scan camara
- `7f633dd` feat: arreglo home
- `37f4cc8` feat: se sube prototipo del proyecto

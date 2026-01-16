import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:typed_data' as java_typed;

import 'dart:async'; // Para StreamController

class NotificationService {
  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin _notificationsPlugin = fln.FlutterLocalNotificationsPlugin();
  
  // Payload capturado si la app se abrió desde notificación (Cold Start)
  String? initialPayload;

  // Stream para eventos cuando la app ya está corriendo (Foreground/Background)
  final StreamController<String> _onNotificationClick = StreamController<String>.broadcast();
  Stream<String> get onNotificationClick => _onNotificationClick.stream;

  // Inicialización
  Future<void> init() async {
    tz.initializeTimeZones();

    // 1. Verificar si la app se abrió tocando una notificación (Cold Start)
    try {
      final fln.NotificationAppLaunchDetails? details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        final r = details.notificationResponse;
        if (r != null && r.payload != null && r.payload!.isNotEmpty) {
          initialPayload = r.payload;
          debugPrint("🚀 App lanzada desde notificación: $initialPayload");
        }
      }
    } catch (e) {
      debugPrint("Error chequeando launch details: $e");
    }

    // Android: Icono en drawable
    const fln.AndroidInitializationSettings androidSettings = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS: Permisos por defecto
    const fln.DarwinInitializationSettings iosSettings = fln.DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const fln.InitializationSettings settings = fln.InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("🔔 Notificación tocada: ${details.payload}");
        
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          // Emitimos evento en lugar de navegar directo
          _onNotificationClick.add(payload);
        }
      },
    );
  }

  void dispose() {
    _onNotificationClick.close();
  }

  // Solicitar Permisos (Android 13+)
  Future<void> requestPermissions() async {
    await _notificationsPlugin.resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }

  // Agendar Alertas de Vencimiento
  // ID Base: hashCode del productId. 
  // Sub-IDs: base + 1 (3 días), base + 2 (2 días), base + 3 (1 día), base + 4 (Hoy).
  Future<void> scheduleExpiryNotifications(String productId, String productName, DateTime expirationDate, {String? base64Image}) async {
    final int baseId = productId.hashCode;
    final now = DateTime.now();

    // Decodificar imagen para BigPicture (fuera del loop para eficiencia)
    fln.ByteArrayAndroidBitmap? bigPicture;
    if (base64Image != null && base64Image.isNotEmpty) {
      try {
        final List<int> bytes = base64Decode(base64Image);
        bigPicture = fln.ByteArrayAndroidBitmap(java_typed.Uint8List.fromList(bytes));
      } catch (e) {
        debugPrint("Error decodificando imagen para notificación: $e");
      }
    }

    // Notificaciones: 3 días antes, 2 días antes, 1 día antes, y el Día 0.
    final List<int> daysOffsets = [3, 2, 1, 0];

    for (int offset in daysOffsets) {
      final scheduledDate = expirationDate.subtract(Duration(days: offset));
      
      // Configurar hora: 6:00 AM del día correspondiente
      final notificationTime = DateTime(
        scheduledDate.year,
        scheduledDate.month,
        scheduledDate.day,
        6, 0, 0, // 6:00 AM
      );

      // Si la fecha ya pasó, no agendar
      if (notificationTime.isBefore(now)) continue;

      String title;
      String body;

      if (offset == 0) {
        title = "🚨 ¡Vence HOY!";
        body = "Tu producto $productName ha llegado a su fecha límite. ¡Úsalo ya!";
      } else if (offset == 1) {
        title = "⚠️ Vence MAÑANA";
        body = "$productName está a punto de vencer. Prepárate.";
      } else {
        title = "⏳ Vence en $offset días";
        body = "Recuerda consumir $productName antes de que sea tarde.";
      }

      await _scheduleOne(
        id: baseId + offset,
        title: title,
        body: body,
        scheduledDate: notificationTime,
        bigPicture: bigPicture,
        payload: productId, // Pasamos el ID para navegación
      );
    }
  }

  Future<void> _scheduleOne({required int id, required String title, required String body, required DateTime scheduledDate, fln.ByteArrayAndroidBitmap? bigPicture, String? payload}) async {
    
    // Estilo: BigPicture (si hay foto) o BigText (default)
    final fln.StyleInformation styleInfo = bigPicture != null 
        ? fln.BigPictureStyleInformation(
            bigPicture,
            contentTitle: title,
            summaryText: body,
            htmlFormatContentTitle: true,
            htmlFormatSummaryText: true,
          )
        : fln.BigTextStyleInformation(body);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      fln.NotificationDetails(
        android: fln.AndroidNotificationDetails(
          'expiry_channel',
          'Alertas de Vencimiento',
          channelDescription: 'Notificaciones para productos próximos a vencer',
          importance: fln.Importance.high,
          priority: fln.Priority.high,
          styleInformation: styleInfo,
          // PERSONALIZACIÓN VISUAL
          color: const Color(0xFF27E374),
          ledColor: const Color(0xFF27E374),
          ledOnMs: 1000, 
          ledOffMs: 500,
          enableLights: true,
        ),
        iOS: fln.DarwinNotificationDetails(),
      ),
      androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
    debugPrint("📅 Alerta agendada ($id): $title para $scheduledDate");
  }

  // --- DEBUG: Verificar Lista Completa Ahora ---
  Future<int> checkProductsInstant(List<dynamic> products) async {
    int triggered = 0;
    const androidDetails = fln.AndroidNotificationDetails(
      'test_channel',
      'Canal de Prueba',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
    );
    const details = fln.NotificationDetails(android: androidDetails);

    final now = DateTime.now();
    // Normalizamos "hoy" a medianoche para comparar días enteros
    final today = DateTime(now.year, now.month, now.day);

    for (var product in products) {
      if (product.expirationDate == null) continue;
      
      final String productName = product.name;

      // Calcular diferencia en días
      final exp = DateTime(product.expirationDate!.year, product.expirationDate!.month, product.expirationDate!.day);
      final days = exp.difference(today).inDays;

      // Criterio de prueba: Avisar si faltan 15 días o menos (Zona Amarilla/Roja)
      if (days <= 15) {
        triggered++;
        
        String title;
        String body;

        if (days < 0) {
           title = "🔴 ¡Producto Vencido!";
           body = "Tu $productName venció hace ${days.abs()} días. Revisa su estado.";
        } else if (days == 0) {
          title = "🚨 ¡Vence HOY!";
          body = "Tu producto $productName ha llegado a su fecha límite. ¡Úsalo ya!";
        } else if (days == 1) {
          title = "⚠️ Vence MAÑANA";
          body = "$productName está a punto de vencer. Prepárate.";
        } else {
          title = "⏳ Vence en $days días";
          body = "Recuerda consumir $productName antes de que sea tarde.";
        }

        // Decodificar imagen para BigPicture
        fln.ByteArrayAndroidBitmap? bigPicture;
        // Asumimos que 'product' es un Entity o Map con 'imageUrl'
        String? base64Img;
        try {
          // Si es Entity
          base64Img = (product.imageUrl != null && product.imageUrl!.isNotEmpty) ? product.imageUrl : null;
        } catch (_) {}
        
        if (base64Img != null) {
            try {
              final List<int> bytes = base64Decode(base64Img);
              bigPicture = fln.ByteArrayAndroidBitmap(java_typed.Uint8List.fromList(bytes));
            } catch (e) { print(e); }
        }

        final fln.StyleInformation styleInfo = bigPicture != null 
          ? fln.BigPictureStyleInformation(
              bigPicture,
              contentTitle: title,
              summaryText: body,
              htmlFormatContentTitle: true,
              htmlFormatSummaryText: true,
            )
          : fln.BigTextStyleInformation(body);

        await _notificationsPlugin.show(
          product.id.hashCode, // ID único basado en producto
          title, 
          body, 
          fln.NotificationDetails(
            android: fln.AndroidNotificationDetails(
              'test_channel',
              'Canal de Prueba',
              importance: fln.Importance.max,
              priority: fln.Priority.high,
              styleInformation: styleInfo,
              color: const Color(0xFF27E374),
              ledColor: const Color(0xFF27E374),
              ledOnMs: 1000, 
              ledOffMs: 500,
              enableLights: true,
            ),
          ),
          payload: product.id,
        );
      }
    }
    return triggered;
  }

  // Cancelar Alertas (al borrar producto)
  Future<void> cancelNotifications(String productId) async {
    final int baseId = productId.hashCode;
    for (int i = 0; i <= 3; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
    debugPrint("🗑️ Alertas canceladas para $productId");
  }
}

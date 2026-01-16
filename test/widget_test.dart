import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <--- FALTABA ESTE IMPORT
import 'package:kadu/main.dart';
import 'package:kadu/features/auth/data/auth_repository.dart';

void main() {
  testWidgets('KaduApp inicia correctamente (Smoke Test)', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Corrección: Usamos Stream<User?>.value para que coincida exactamente con el proveedor
          authStateProvider.overrideWith((ref) => Stream<User?>.value(null)),
        ],
        child: const KaduApp(),
      ),
    );

    // Forzamos el renderizado
    await tester.pump();

    // Verificamos que la app arrancó (debería mostrar LoginScreen porque el user es null)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
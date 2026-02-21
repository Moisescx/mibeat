import 'package:flutter/material.dart';
import 'pantalla_principal.dart';

// NUEVO: Este es el interruptor global que guardará si estamos en modo oscuro o claro
final ValueNotifier<ThemeMode> notificadorTema = ValueNotifier(ThemeMode.dark);

void main() {
  runApp(const MoiBeatApp());
}

class MoiBeatApp extends StatelessWidget {
  const MoiBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder escucha nuestro interruptor y redibuja la app si cambia
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notificadorTema,
      builder: (context, modoActual, child) {
        return MaterialApp(
          title: 'MiBeat',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(), // El diseño para el Modo Claro
          darkTheme: ThemeData.dark(), // El diseño para el Modo Oscuro
          themeMode: modoActual, // Aplica el modo que esté en el interruptor
          home: const PantallaPrincipal(),
        );
      },
    );
  }
}

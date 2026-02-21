import 'package:flutter/material.dart';
import 'pantalla_principal.dart';
import 'theme_notifier.dart';

void main() {
  runApp(const MoiBeatApp());
}

class MoiBeatApp extends StatelessWidget {
  const MoiBeatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: notificadorTema,
      builder: (context, modoActual, child) {
        return MaterialApp(
          title: 'MiBeat',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(), 
          darkTheme: ThemeData.dark(), 
          themeMode: modoActual, 
          home: const PantallaPrincipal(),
        );
      },
    );
  }
}

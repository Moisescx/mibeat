import 'package:flutter/material.dart';
import 'theme_notifier.dart';

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          
          // --- EL INTERRUPTOR DE MODO OSCURO ---
          ValueListenableBuilder<ThemeMode>(
            valueListenable: notificadorTema,
            builder: (context, modoActual, child) {
              bool esOscuro = modoActual == ThemeMode.dark;
              
              return SwitchListTile(
                title: const Text('Modo Oscuro'),
                subtitle: const Text('Cambiar entre tema claro y oscuro'),
                secondary: Icon(esOscuro ? Icons.dark_mode : Icons.light_mode),
                value: esOscuro,
                activeThumbColor: Colors.greenAccent,
                onChanged: (valor) {
                  notificadorTema.value = valor ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          
          const Spacer(),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              children: [
                const Text(
                  'MiBeat v1.0.0',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 5),
                Text(
                  'Desarrollado con ❤️ por MM',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
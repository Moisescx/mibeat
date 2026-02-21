import 'package:flutter/material.dart';
import 'main.dart'; // Importamos esto para poder usar el notificadorTema

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
                  // Cuando tocas el switch, cambiamos el interruptor global
                  notificadorTema.value = valor ? ThemeMode.dark : ThemeMode.light;
                },
              );
            },
          ),
          
          // Spacer() empuja todo lo que pongas debajo hacia el fondo de la pantalla
          const Spacer(),
          
          // --- EL FOOTER CON TU FIRMA ---
          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              children: [
                const Text(
                  'MoiBeat v1.0.0',
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
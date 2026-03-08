import 'package:flutter/material.dart';
import 'theme_notifier.dart';
import 'ventana_actualizacion.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'pantalla_ecualizador.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // SUSPENDIDO
// import 'services/lyrics_service.dart'; // SUSPENDIDO
// import 'services/genius_service.dart'; // SUSPENDIDO

class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), elevation: 0),
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
                  notificadorTema.value = valor
                      ? ThemeMode.dark
                      : ThemeMode.light;
                },
              );
            },
          ),

          ListTile(
            leading: Icon(
              Icons.update,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            title: Text(
              "Buscar actualizaciones",
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            onTap: () {
              _buscarActualizacion(context);
            },
          ),

          // --- BOTÓN DEL ECUALIZADOR ---
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.greenAccent),
            ),
            title: const Text(
              'Ecualizador',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Ajusta los bajos y agudos',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey,
              size: 16,
            ),
            onTap: () {
              // Navegamos a la pantalla del ecualizador
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PantallaEcualizador(),
                ),
              );
            },
          ),

          // Una línea divisoria sutil (opcional)
          Divider(color: Colors.grey[800], indent: 20, endIndent: 20),

          const Divider(),

          // --- CONFIGURACIÓN DE LETRAS (SUSPENDIDO) ---
          /*
          ListTile(
            leading: const Icon(Icons.lyrics, color: Colors.greenAccent),
            title: const Text(
              "Configurar búsqueda de letras",
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              "Habilita Genius API para buscar letras automáticamente",
              style: TextStyle(fontSize: 12),
            ),
            onTap: () {
              _mostrarDialogoGeniusAPI(context);
            },
          ),
          */
          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 30.0),
            child: Column(
              children: [
                Text(
                  'MiBeat v2.0.0',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Desarrollado con ❤️ por MM',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- CONFIGURACIÓN DE LETRAS (SUSPENDIDO) ---
  /*
  // --- CONFIGURAR GENIUS API ---
  Future<void> _mostrarDialogoGeniusAPI(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final apiKeyGuardada = prefs.getString('genius_api_key') ?? '';
    final geniusHabilitado = prefs.getBool('genius_habilitado') ?? false;

    TextEditingController controladorAPI = TextEditingController(
      text: apiKeyGuardada,
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Configurar Genius API",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "📝 ¿Cómo obtener tu clave API de Genius?",
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "1. Abre genius.com/api-clients\n"
                  "2. Crea una cuenta (si no tienes)\n"
                  "3. Genera una nueva API Token\n"
                  "4. Copia el token aquí",
                  style: TextStyle(color: Colors.grey, height: 1.6),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controladorAPI,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        "qt4sly2PhkKNR_LZ4AJyfn6rjJey-ZOzc5OKftrUJKVnz3l5Jq78LNwdIelUua9_",
                    hintStyle: TextStyle(color: Colors.grey[600]),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.greenAccent),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.greenAccent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  geniusHabilitado
                      ? "✅ Búsqueda de letras HABILITADA"
                      : "⏸️ Búsqueda de letras deshabilitada",
                  style: TextStyle(
                    color: geniusHabilitado ? Colors.greenAccent : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () async {
                final apiKey = controladorAPI.text.trim();

                if (apiKey.isEmpty) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor ingresa tu API token'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                // Guardar en SharedPreferences
                await prefs.setString('genius_api_key', apiKey);
                await prefs.setBool('genius_habilitado', true);

                // Actualizar el servicio
                LyricsService.habilitarGeniusAPI = true;

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '✅ Genius API configurado. '
                        'Las letras se buscarán automáticamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                "Guardar",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
  */

  // --- EL CEREBRO DE LAS ACTUALIZACIONES ---
  Future<void> _buscarActualizacion(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Buscando actualizaciones..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String versionActual = packageInfo.version; // Ej: "2.0.0"

      String urlJson =
          "https://raw.githubusercontent.com/Moisescx/mibeat/main/version.json";

      Dio dio = Dio();
      var respuesta = await dio.get(urlJson);

      var datos = respuesta.data is String
          ? jsonDecode(respuesta.data)
          : respuesta.data;
      String ultimaVersion = datos['ultima_version'];
      String linkApk = datos['link_apk'];

      if (ultimaVersion != versionActual &&
          _esVersionMayor(ultimaVersion, versionActual)) {
        if (!context.mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => VentanaActualizacion(
            urlApk: linkApk,
            versionNueva: ultimaVersion,
          ),
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("¡MiBeat está actualizado a la última versión! 😎"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al conectar con el servidor 😅"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _esVersionMayor(String internet, String actual) {
    List<int> vInternet = internet
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    List<int> vActual = actual
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < 3; i++) {
      if (vInternet.length > i && vActual.length > i) {
        if (vInternet[i] > vActual[i]) return true;
        if (vInternet[i] < vActual[i]) return false;
      }
    }
    return false;
  }
}

import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(const MiReproductorApp());
}

class MiReproductorApp extends StatelessWidget {
  const MiReproductorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Reproductor',
      theme:
          ThemeData.dark(), // Un tema oscuro siempre se ve genial en apps de música
      home: const PantallaPrincipal(),
    );
  }
}

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _reproductor = AudioPlayer();

  SongModel? _cancionActual;
  // NUEVO 1: Variables para recordar la lista entera y la posición actual
  int _indiceActual = -1;
  List<SongModel> _listaCanciones = [];

  bool _tienePermiso = false;
  late Future<List<SongModel>> _cancionesFuture;

  @override
  void initState() {
    super.initState();
    _pedirPermisos();
  }

  Future<void> _pedirPermisos() async {
    PermissionStatus statusStorage = await Permission.storage.request();
    PermissionStatus statusAudio = await Permission.audio.request();

    if (statusStorage.isGranted || statusAudio.isGranted) {
      setState(() {
        _tienePermiso = true;
        _cancionesFuture = _audioQuery.querySongs(
          ignoreCase: true,
          orderType: OrderType.ASC_OR_SMALLER,
          sortType: null,
          uriType: UriType.EXTERNAL,
        );
      });
    }
  }

  // NUEVO 2: Creamos una función centralizada para cambiar de canción
  void _reproducirCancion(int index) async {
    // Evitamos errores si tratamos de retroceder en la primera canción o avanzar en la última
    if (index < 0 || index >= _listaCanciones.length) return;

    var cancion = _listaCanciones[index];

    setState(() {
      _cancionActual = cancion;
      _indiceActual = index; // Guardamos en qué número de canción vamos
    });

    if (cancion.uri != null) {
      try {
        await _reproductor.setAudioSource(
          AudioSource.uri(Uri.parse(cancion.uri!)),
        );
        _reproductor.play();
      } catch (e) {
        print("Error al reproducir: $e");
      }
    }
  }

  // NUEVO: La pantalla gigante de reproducción
  void _mostrarPantallaReproduccion(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // Esto permite que ocupe más de la mitad de la pantalla
      backgroundColor: Colors.grey[900], // Fondo oscuro
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ), // Bordes redondeados arriba
      ),
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
              0.9, // Cubre el 90% de la pantalla
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Una pequeña rayita gris arriba para indicar que se puede deslizar hacia abajo
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 30),

                // Carátula GIGANTE
                QueryArtworkWidget(
                  id: _cancionActual!.id,
                  type: ArtworkType.AUDIO,
                  artworkWidth: 300,
                  artworkHeight: 300,
                  artworkBorder: BorderRadius.circular(20),
                  size: 1000, // ¡NUEVO! Pide una resolución mucho más grande
                  quality: 100, // ¡NUEVO! Calidad al 100% (el defecto es 50)
                  nullArtworkWidget: const Icon(
                    Icons.music_note,
                    size: 150,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),

                // Título y Artista
                Text(
                  _cancionActual!.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _cancionActual!.artist ?? "Artista desconocido",
                  style: TextStyle(fontSize: 18, color: Colors.grey[400]),
                ),
                const SizedBox(height: 30),

                // Barra para adelantar/retroceder (Por ahora visual, luego la conectamos)
                Slider(
                  value: 0,
                  onChanged: (value) {},
                  activeColor: Colors.greenAccent,
                  inactiveColor: Colors.grey[800],
                ),

                // Botones de Control GIGANTES
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 50,
                      color: Colors.white,
                      onPressed: () {
                        _reproducirCancion(_indiceActual - 1);
                        Navigator.pop(context); // Cierra la pantalla actual
                        _mostrarPantallaReproduccion(
                          context,
                        ); // La reabre con la nueva canción
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: _reproductor.playingStream,
                      builder: (context, snapshot) {
                        bool isPlaying = snapshot.data ?? false;
                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                          ),
                          iconSize: 80,
                          color: Colors.greenAccent,
                          onPressed: () {
                            if (isPlaying) {
                              _reproductor.pause();
                            } else {
                              _reproductor.play();
                            }
                          },
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 50,
                      color: Colors.white,
                      onPressed: () {
                        _reproducirCancion(_indiceActual + 1);
                        Navigator.pop(context);
                        _mostrarPantallaReproduccion(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mi Música Local'), elevation: 0),

      body: !_tienePermiso
          ? const Center(child: Text('Necesito permisos para buscar música 😅'))
          : FutureBuilder<List<SongModel>>(
              future: _cancionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No encontré canciones en tu celular 🎵'),
                  );
                }

                // NUEVO 3: Guardamos las canciones en nuestra variable global
                _listaCanciones = snapshot.data!;

                return ListView.builder(
                  itemCount: _listaCanciones.length,
                  itemBuilder: (context, index) {
                    var cancion = _listaCanciones[index];

                    return ListTile(
                      leading: QueryArtworkWidget(
                        id: cancion.id,
                        type: ArtworkType.AUDIO,
                        nullArtworkWidget: const Icon(
                          Icons.music_note,
                          size: 40,
                        ),
                      ),
                      title: Text(
                        cancion.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(cancion.artist ?? "Artista desconocido"),
                      // NUEVO 4: Usamos la función en lugar de escribir el código aquí
                      onTap: () {
                        _reproducirCancion(index);
                        _mostrarPantallaReproduccion(context);
                      },
                    );
                  },
                );
              },
            ),

      // LA BARRA INFERIOR FLOTANTE
      bottomNavigationBar: _cancionActual == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: GestureDetector(
                // NUEVO: Detecta toques en toda la barra
                onTap: () {
                  _mostrarPantallaReproduccion(
                    context,
                  ); // Abre la pantalla gigante
                },
                child: Container(
                  height: 70,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.music_note, size: 30),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Text(
                          _cancionActual!.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),

                      // NUEVO 5: BOTÓN ANTERIOR
                      IconButton(
                        icon: const Icon(Icons.skip_previous),
                        iconSize: 35,
                        color: Colors.white,
                        onPressed: () {
                          _reproducirCancion(_indiceActual - 1);
                        },
                      ),

                      // BOTÓN PLAY/PAUSA
                      StreamBuilder<bool>(
                        stream: _reproductor.playingStream,
                        builder: (context, snapshot) {
                          bool isPlaying = snapshot.data ?? false;
                          return IconButton(
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle
                                  : Icons.play_circle,
                            ),
                            iconSize: 45,
                            color: Colors.greenAccent,
                            onPressed: () {
                              if (isPlaying) {
                                _reproductor.pause();
                              } else {
                                _reproductor.play();
                              }
                            },
                          );
                        },
                      ),

                      // NUEVO 6: BOTÓN SIGUIENTE
                      IconButton(
                        icon: const Icon(Icons.skip_next),
                        iconSize: 35,
                        color: Colors.white,
                        onPressed: () {
                          _reproducirCancion(_indiceActual + 1);
                        },
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
